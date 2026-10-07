import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/esp32_config.dart';
import '../providers/app_state_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/contact_card.dart';
import '../widgets/emergency_banner.dart';
import '../widgets/hardware_status_badge.dart';
import '../widgets/live_map_view.dart';
import '../widgets/sensor_status_card.dart';
import '../widgets/sos_emergency_button.dart';
import '../widgets/speech_announcer.dart';
import 'caregiver_dashboard_screen.dart';
import 'contacts_screen.dart';
import 'emergency_details_screen.dart';
import 'emergency_history_screen.dart';
import 'hardware_settings_screen.dart';
import 'settings_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, color: AppColors.primaryBlueLight, size: 26),
            SizedBox(width: 8),
            Text(
              'SafePath',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ],
        ),
        actions: [
          // Voice Alerts Toggle
          IconButton(
            icon: Icon(
              appState.isVoiceGuidanceEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: appState.isVoiceGuidanceEnabled
                  ? AppColors.safeGreen
                  : Colors.grey,
            ),
            tooltip: appState.isVoiceGuidanceEnabled
                ? 'Voice Alerts Enabled'
                : 'Voice Alerts Muted',
            onPressed: () => appState.toggleVoiceGuidance(),
          ),
          // Switch to Caregiver Mode
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBlueLight),
            tooltip: 'Switch to Caregiver Mode',
            onPressed: () async {
              await appState.setRole('caregiver');
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CaregiverDashboardScreen()),
                );
              }
            },
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings & Accessibility',
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
                // Top Row: Stick Hardware Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HardwareStatusBadge(
                      sensorData: appState.sensorData,
                      ipAddress: settings.esp32Config.ipAddress,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HardwareSettingsScreen()),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: () => appState.speakCurrentStatus(),
                      icon: const Icon(Icons.campaign_rounded, size: 18),
                      label: const Text('Read Status'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Speech Announcer Bar
                SpeechAnnouncer(
                  text: 'Status: ${appState.sensorData.obstacleSeverity.name.toUpperCase()} • '
                      '${appState.sensorData.distanceCm.toInt()}cm • '
                      '${appState.sensorData.surfaceHazard.name}',
                  isSpeaking: false,
                  onRepeat: () => appState.speakCurrentStatus(),
                ),
                const SizedBox(height: 10),

                // Active Emergency Banner (if any)
                if (appState.activeEmergency != null && appState.activeEmergency!.isActive) ...[
                  EmergencyBanner(
                    event: appState.activeEmergency!,
                    isUserRole: true,
                    onCancel: () => appState.cancelActiveEmergency(reason: 'User cancelled false alarm'),
                    onResolve: () => appState.resolveEmergency(appState.activeEmergency!.id),
                    onViewDetails: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EmergencyDetailsScreen(event: appState.activeEmergency!),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 🚨 PROMINENT EMERGENCY SOS BUTTON / COUNTDOWN
                SosEmergencyButton(
                  isCountingDown: appState.countdownState.isCountingDown,
                  countdownSeconds: appState.countdownState.secondsRemaining,
                  onTrigger: () => appState.triggerManualSos(),
                  onCancel: () => appState.cancelEmergencyCountdown(),
                ),
                const SizedBox(height: 18),

                // 📡 SENSOR TELEMETRY CARD (HC-SR04, MPU6050, Moisture, Battery)
                SensorStatusCard(sensorData: appState.sensorData),
                const SizedBox(height: 18),

                // 📍 LIVE GPS LOCATION & MAP CARD
                _buildLocationSection(context, appState, isDark),
                const SizedBox(height: 18),

                // 👥 EMERGENCY CONTACTS SECTION
                _buildContactsSection(context, settings, isDark),
                const SizedBox(height: 18),

                // 🧪 HARDWARE SIMULATION SCENARIO SELECTOR
                _buildSimulationSection(context, appState, isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: const Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => appState.speakCurrentStatus(),
                icon: const Icon(Icons.volume_up_rounded, size: 22),
                label: const Text('SPEAK ALL SENSORS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencyHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Emergency History Log',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, AppStateProvider appState, bool isDark) {
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
                    Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Your GPS Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh GPS',
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
                height: 180,
              ),
              const SizedBox(height: 8),
              Text(
                'Coordinates: ${loc.coordinatesDisplay} (Accuracy: ±${loc.accuracyMeters.toInt()}m)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              if (loc.isMockedOrSimulated)
                const Text(
                  'ℹ️ Fallback simulation coordinates active (GPS permissions/emulator)',
                  style: TextStyle(fontSize: 11, color: AppColors.warningOrange, fontStyle: FontStyle.italic),
                ),
            ] else ...[
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Acquiring high accuracy GPS fix...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSection(BuildContext context, SettingsProvider settings, bool isDark) {
    final contacts = settings.userProfile.contacts;

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
                    Icon(Icons.contacts_rounded, color: AppColors.safeGreen, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Contacts',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ContactsScreen()),
                    );
                  },
                  icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (contacts.isEmpty)
              const Text('No emergency contacts saved. Tap Manage to add contacts.')
            else
              ...contacts.take(2).map((contact) => ContactCard(contact: contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationSection(BuildContext context, AppStateProvider appState, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.warningAmber, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science_rounded, color: AppColors.warningAmber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Hardware Sensor Testing & Simulation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Test real-time sensor reactions and caregiver alerts without physical hardware.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildScenarioChip(context, appState, '🚶 Normal Walk', SimulationScenario.normalWalking),
                _buildScenarioChip(context, appState, '⚠️ Obstacle (90cm)', SimulationScenario.approachingObstacle),
                _buildScenarioChip(context, appState, '🚨 Close Danger (22cm)', SimulationScenario.dangerObstacleClose),
                _buildScenarioChip(context, appState, '💧 Water Puddle', SimulationScenario.waterPuddle),
                _buildScenarioChip(context, appState, '🕳️ Steep Drop/Hole', SimulationScenario.potholeDrop),
                _buildScenarioChip(context, appState, '💥 Fall Detected', SimulationScenario.fallDetected),
                _buildScenarioChip(context, appState, '🪫 Low Battery', SimulationScenario.lowBattery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioChip(
    BuildContext context,
    AppStateProvider appState,
    String label,
    SimulationScenario scenario,
  ) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: AppColors.warningAmber),
      onPressed: () {
        appState.setSimulationScenario(scenario);
      },
    );
  }
}
