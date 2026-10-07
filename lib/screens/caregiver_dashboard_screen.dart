import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/emergency_event.dart';
import '../models/stick_sensor_data.dart';
import '../providers/app_state_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/live_map_view.dart';
import 'emergency_details_screen.dart';
import 'emergency_history_screen.dart';
import 'settings_screen.dart';
import 'user_dashboard_screen.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  Future<void> _callUser(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open phone dialer for $phoneNumber')),
          );
        }
      }
    } catch (e) {
      debugPrint('Call error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = settings.userProfile;
    final activeEmergency = appState.activeEmergency;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_rounded, color: AppColors.safeGreen, size: 26),
            SizedBox(width: 8),
            Text(
              'Caregiver Monitor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Switch to Blind User Mode
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBlueLight),
            tooltip: 'Switch to User Mode',
            onPressed: () async {
              await appState.setRole('user');
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Emergency Logs',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await appState.refreshLocation();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Monitored User Info Banner
                _buildMonitoredUserCard(context, user, isDark),
                const SizedBox(height: 14),

                // 🚨 ACTIVE EMERGENCY DISPATCH CARD (IF ACTIVE)
                if (activeEmergency != null && activeEmergency.isActive) ...[
                  _buildActiveEmergencyCard(context, appState, activeEmergency, isDark),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildAllClearStatusCard(context, isDark),
                  const SizedBox(height: 16),
                ],

                // 📍 LIVE GPS LOCATION & RADAR MAP
                _buildLocationMapCard(context, appState, isDark),
                const SizedBox(height: 16),

                // 🦯 SMART STICK TELEMETRY MONITOR
                _buildStickTelemetryCard(context, appState, isDark),
                const SizedBox(height: 16),

                // 📋 RECENT EMERGENCY ALERTS LOG
                _buildRecentEventsCard(context, appState, isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonitoredUserCard(BuildContext context, user, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
              child: const Icon(Icons.person_rounded, color: AppColors.primaryBlue, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Phone: ${user.phoneNumber} • Blood: ${user.bloodGroup}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.medicalNotes,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _callUser(context, user.phoneNumber),
              icon: const Icon(Icons.call_rounded, color: AppColors.safeGreen),
              tooltip: 'Direct Call User',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEmergencyCard(
    BuildContext context,
    AppStateProvider appState,
    EmergencyEvent event,
    bool isDark,
  ) {
    final timeStr = DateFormat('hh:mm:ss a').format(event.timestamp);

    return Card(
      elevation: 6,
      color: isDark ? const Color(0xFF2C0B0E) : const Color(0xFFFFEBEE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.emergencyRed, width: 2.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.emergencyRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY: ${event.typeDisplayName.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.emergencyRed,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Triggered at $timeStr • Status: ${event.statusDisplayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Emergency Notes / Location Summary
            if (event.notes != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Event details: ${event.notes}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Caregiver Workflow Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (event.status == EmergencyStatus.triggered ||
                    event.status == EmergencyStatus.notificationSent) ...[
                  ElevatedButton.icon(
                    onPressed: () => appState.acknowledgeEmergency(event.id, responderName: 'Caregiver Sarah'),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('1. ACKNOWLEDGE ALERT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (event.status == EmergencyStatus.acknowledged ||
                    event.status == EmergencyStatus.triggered ||
                    event.status == EmergencyStatus.notificationSent) ...[
                  ElevatedButton.icon(
                    onPressed: () => appState.markResponding(event.id, responderName: 'Caregiver Sarah'),
                    icon: const Icon(Icons.directions_run_rounded),
                    label: const Text('2. I AM RESPONDING (EN ROUTE)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => appState.resolveEmergency(event.id, note: 'Caregiver confirmed safe.'),
                        icon: const Icon(Icons.task_alt_rounded),
                        label: const Text('RESOLVE & SAFE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safeGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmergencyDetailsScreen(event: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      tooltip: 'View Full Emergency Details & Sensor Snapshot',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllClearStatusCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.safeGreen, width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: AppColors.safeGreen, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALL SYSTEMS NORMAL',
                  style: TextStyle(
                    color: AppColors.safeGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'No active emergencies. Stick is actively monitoring for obstacles and falls.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapCard(BuildContext context, AppStateProvider appState, bool isDark) {
    final loc = appState.currentLocation;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_rounded, color: AppColors.primaryBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'User Live Location & Tracker',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Update Location',
                  onPressed: () => appState.refreshLocation(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (loc != null) ...[
              LiveMapView(
                latitude: loc.latitude,
                longitude: loc.longitude,
                accuracyMeters: loc.accuracyMeters,
                isEmergency: appState.activeEmergency != null && appState.activeEmergency!.isActive,
                height: 220,
              ),
              const SizedBox(height: 8),
              Text(
                'Coordinates: ${loc.coordinatesDisplay} • Accuracy: ±${loc.accuracyMeters.toInt()}m',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStickTelemetryCard(BuildContext context, AppStateProvider appState, bool isDark) {
    final sensor = appState.sensorData;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sensors_rounded, color: AppColors.primaryBlueLight, size: 22),
                SizedBox(width: 8),
                Text(
                  'Stick Telemetry (ESP32 Live Feed)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTelemetryTile(
                    'Obstacle Distance',
                    '${sensor.distanceCm.toInt()} cm',
                    sensor.obstacleSeverity == ObstacleSeverity.clear
                        ? AppColors.safeGreen
                        : AppColors.emergencyRed,
                    Icons.radar_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTelemetryTile(
                    'Stick Battery',
                    '${sensor.batteryPercent}% (${sensor.batteryVoltage.toStringAsFixed(1)}V)',
                    sensor.batteryPercent < 20 ? AppColors.emergencyRed : AppColors.safeGreen,
                    Icons.battery_charging_full_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTelemetryTile(
                    'Surface Condition',
                    sensor.surfaceHazard.name,
                    sensor.surfaceHazard == SurfaceHazardType.normalDry
                        ? AppColors.safeGreen
                        : AppColors.warningOrange,
                    Icons.terrain_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTelemetryTile(
                    'Fall Status',
                    sensor.fallDetected ? 'FALL DETECTED' : 'Upright Normal',
                    sensor.fallDetected ? AppColors.emergencyRed : AppColors.safeGreen,
                    Icons.accessibility_new_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsCard(BuildContext context, AppStateProvider appState, bool isDark) {
    final history = appState.emergencyHistory;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu_rounded, color: AppColors.primaryBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Log History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmergencyHistoryScreen()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No emergency records in log.'),
              )
            else
              ...history.take(3).map((event) {
                final dateStr = DateFormat('MMM d, hh:mm a').format(event.timestamp);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: event.status == EmergencyStatus.resolved
                        ? AppColors.safeGreen.withValues(alpha: 0.15)
                        : AppColors.emergencyRed.withValues(alpha: 0.15),
                    child: Icon(
                      event.status == EmergencyStatus.resolved
                          ? Icons.check_circle_rounded
                          : Icons.emergency_rounded,
                      color: event.status == EmergencyStatus.resolved
                          ? AppColors.safeGreen
                          : AppColors.emergencyRed,
                    ),
                  ),
                  title: Text(
                    event.typeDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text('$dateStr • ${event.statusDisplayName}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EmergencyDetailsScreen(event: event),
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
