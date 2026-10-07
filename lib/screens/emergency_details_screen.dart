import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/emergency_event.dart';
import '../providers/app_state_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/live_map_view.dart';

class EmergencyDetailsScreen extends StatelessWidget {
  final EmergencyEvent event;

  const EmergencyDetailsScreen({
    super.key,
    required this.event,
  });

  Future<void> _callPhone(BuildContext context, String number) async {
    final clean = number.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMMM d, yyyy • hh:mm:ss a').format(event.timestamp);

    // Fetch the freshest instance of this event from provider if updated
    final EmergencyEvent currentEvent = appState.emergencyHistory.firstWhere(
      (e) => e.id == event.id,
      orElse: () => event,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: currentEvent.isActive ? AppColors.emergencyRed : AppColors.safeGreen,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            currentEvent.isActive ? Icons.emergency_rounded : Icons.check_circle_rounded,
                            color: currentEvent.isActive ? AppColors.emergencyRed : AppColors.safeGreen,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentEvent.typeDisplayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentEvent.isActive ? AppColors.emergencyRed : AppColors.safeGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentEvent.statusDisplayName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (currentEvent.notes != null) ...[
                        const Divider(height: 24),
                        Text(
                          'Notes: ${currentEvent.notes}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Location Map
              if (currentEvent.latitude != null && currentEvent.longitude != null) ...[
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Captured Emergency Location',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        LiveMapView(
                          latitude: currentEvent.latitude!,
                          longitude: currentEvent.longitude!,
                          accuracyMeters: currentEvent.accuracyMeters ?? 15.0,
                          isEmergency: currentEvent.isActive,
                          height: 220,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Lifecycle Progress Timeline
              _buildTimelineCard(context, currentEvent, isDark),
              const SizedBox(height: 16),

              // Sensor Snapshot at trigger instant
              if (currentEvent.sensorSnapshot != null) ...[
                _buildSensorSnapshotCard(context, currentEvent.sensorSnapshot!, isDark),
                const SizedBox(height: 16),
              ],

              // Emergency Calling & Response Buttons
              _buildActionButtons(context, appState, settings, currentEvent),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, EmergencyEvent ev, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Lifecycle Timeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 14),
            _buildTimelineStep(
              title: '1. Alarm Triggered',
              subtitle: DateFormat('hh:mm:ss a').format(ev.timestamp),
              isCompleted: true,
              isCurrent: ev.status == EmergencyStatus.triggered,
            ),
            _buildTimelineStep(
              title: '2. Alert Dispatched to Network',
              subtitle: ev.status != EmergencyStatus.triggered ? 'Dispatched successfully' : 'Pending dispatch',
              isCompleted: ev.status != EmergencyStatus.triggered,
              isCurrent: ev.status == EmergencyStatus.notificationSent,
            ),
            _buildTimelineStep(
              title: '3. Caregiver Acknowledged',
              subtitle: ev.acknowledgedBy != null
                  ? '${ev.acknowledgedBy} acknowledged at ${DateFormat("hh:mm a").format(ev.acknowledgedAt ?? ev.timestamp)}'
                  : 'Awaiting acknowledgment',
              isCompleted: ev.acknowledgedBy != null,
              isCurrent: ev.status == EmergencyStatus.acknowledged,
            ),
            _buildTimelineStep(
              title: '4. Caregiver Responding (En Route)',
              subtitle: ev.respondingBy != null
                  ? '${ev.respondingBy} responding at ${DateFormat("hh:mm a").format(ev.respondingAt ?? ev.timestamp)}'
                  : 'Awaiting responder',
              isCompleted: ev.respondingBy != null,
              isCurrent: ev.status == EmergencyStatus.responding,
            ),
            _buildTimelineStep(
              title: '5. Emergency Resolved & Safe',
              subtitle: ev.resolvedAt != null
                  ? 'Resolved at ${DateFormat("hh:mm a").format(ev.resolvedAt!)}: ${ev.resolutionNotes ?? "Marked safe"}'
                  : (ev.status == EmergencyStatus.cancelled ? 'Cancelled false alarm' : 'In progress'),
              isCompleted: ev.status == EmergencyStatus.resolved || ev.status == EmergencyStatus.cancelled,
              isCurrent: ev.status == EmergencyStatus.resolved || ev.status == EmergencyStatus.cancelled,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    Color iconColor = isCompleted ? AppColors.safeGreen : Colors.grey;
    if (isCurrent && !isCompleted) iconColor = AppColors.warningOrange;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.safeGreen : Colors.transparent,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isCurrent
                      ? const Icon(Icons.radio_button_checked, size: 14, color: AppColors.warningOrange)
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? AppColors.safeGreen : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCompleted || isCurrent ? null : Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorSnapshotCard(BuildContext context, snapshot, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlueLight, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sensor Snapshot at Trigger Instant',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('• Obstacle Distance: ${snapshot.distanceCm.toInt()} cm (${snapshot.obstacleSeverity.name})'),
            Text('• Surface Condition: ${snapshot.surfaceHazard.name} (Moisture: ${snapshot.moistureLevelPercent.toInt()}%)'),
            Text('• Fall Sensor: ${snapshot.fallDetected ? "TRIGGERED (Impact: ${snapshot.ax.toStringAsFixed(1)} m/s²)" : "Normal"}'),
            Text('• Stick Battery: ${snapshot.batteryPercent}% (${snapshot.batteryVoltage.toStringAsFixed(2)}V)'),
            Text('• Accelerometer (X, Y, Z): ${snapshot.ax.toStringAsFixed(1)}, ${snapshot.ay.toStringAsFixed(1)}, ${snapshot.az.toStringAsFixed(1)} m/s²'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppStateProvider appState,
    SettingsProvider settings,
    EmergencyEvent ev,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ev.isActive) ...[
          if (ev.status == EmergencyStatus.triggered || ev.status == EmergencyStatus.notificationSent) ...[
            ElevatedButton.icon(
              onPressed: () => appState.acknowledgeEmergency(ev.id, responderName: 'Caregiver Sarah'),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('ACKNOWLEDGE ALERT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (ev.status != EmergencyStatus.responding) ...[
            ElevatedButton.icon(
              onPressed: () => appState.markResponding(ev.id, responderName: 'Caregiver Sarah'),
              icon: const Icon(Icons.directions_run_rounded),
              label: const Text('MARK RESPONDING (EN ROUTE)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton.icon(
            onPressed: () => appState.resolveEmergency(ev.id, note: 'Safety verified.'),
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('RESOLVE EMERGENCY AS SAFE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safeGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callPhone(context, settings.userProfile.phoneNumber),
                icon: const Icon(Icons.call_rounded, color: AppColors.safeGreen),
                label: const Text('Call User'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callPhone(context, '911'),
                icon: const Icon(Icons.emergency_rounded, color: AppColors.emergencyRed),
                label: const Text('Call 911 / 112'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emergencyRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
