import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/stick_sensor_data.dart';

class SensorStatusCard extends StatelessWidget {
  final StickSensorData sensorData;

  const SensorStatusCard({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _getOverallStatusBorderColor(),
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Battery & Hardware Mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getBatteryIcon(sensorData.batteryPercent),
                      color: sensorData.batteryPercent < 20
                          ? AppColors.emergencyRed
                          : (sensorData.batteryPercent < 50
                              ? AppColors.warningOrange
                              : AppColors.safeGreen),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stick Battery: ${sensorData.batteryPercent}% (${sensorData.batteryVoltage.toStringAsFixed(2)}V)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sensorData.isSimulated
                        ? AppColors.warningOrange.withValues(alpha: 0.15)
                        : AppColors.safeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sensorData.isSimulated
                          ? AppColors.warningOrange
                          : AppColors.safeGreen,
                    ),
                  ),
                  child: Text(
                    sensorData.isSimulated ? 'SIMULATED' : 'PHYSICAL ESP32',
                    style: TextStyle(
                      color: sensorData.isSimulated
                          ? AppColors.warningOrange
                          : AppColors.safeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Ultrasonic Obstacle Section
            _buildObstacleRow(context),

            const SizedBox(height: 16),

            // 2. Surface Hazard Section
            _buildSurfaceRow(context),

            const SizedBox(height: 16),

            // 3. Fall Monitor & MPU6050 Accelerometer
            _buildFallRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildObstacleRow(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (sensorData.obstacleSeverity) {
      case ObstacleSeverity.clear:
        statusColor = AppColors.safeGreen;
        statusText = 'Clear Path (${sensorData.distanceCm.toInt()} cm)';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case ObstacleSeverity.warning:
        statusColor = AppColors.warningOrange;
        statusText = 'Obstacle Ahead (${sensorData.distanceCm.toInt()} cm)';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case ObstacleSeverity.danger:
        statusColor = AppColors.emergencyRed;
        statusText = 'DANGER: Very Close! (${sensorData.distanceCm.toInt()} cm)';
        statusIcon = Icons.dangerous_rounded;
        break;
    }

    final double progress = (sensorData.distanceCm / 200.0).clamp(0.0, 1.0);

    return Semantics(
      label: 'Obstacle distance sensor: $statusText',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Obstacle Distance (HC-SR04)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                '${sensorData.distanceCm.toInt()} cm',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceRow(BuildContext context) {
    Color surfaceColor;
    String surfaceText;
    IconData surfaceIcon;

    switch (sensorData.surfaceHazard) {
      case SurfaceHazardType.normalDry:
        surfaceColor = AppColors.safeGreen;
        surfaceText = 'Dry & Stable Surface (Moisture: ${sensorData.moistureLevelPercent.toInt()}%)';
        surfaceIcon = Icons.nature_people_rounded;
        break;
      case SurfaceHazardType.waterPuddle:
        surfaceColor = AppColors.waterHazardBlue;
        surfaceText = 'Water Puddle / Wet Ground (Moisture: ${sensorData.moistureLevelPercent.toInt()}%)';
        surfaceIcon = Icons.water_drop_rounded;
        break;
      case SurfaceHazardType.potholeOrDrop:
        surfaceColor = AppColors.emergencyRed;
        surfaceText = 'Steep Drop / Pothole Detected!';
        surfaceIcon = Icons.terrain_rounded;
        break;
      case SurfaceHazardType.mudOrSlippery:
        surfaceColor = AppColors.warningOrange;
        surfaceText = 'Muddy / Slippery Ground (Moisture: ${sensorData.moistureLevelPercent.toInt()}%)';
        surfaceIcon = Icons.waves_rounded;
        break;
    }

    return Semantics(
      label: 'Surface hazard sensor: $surfaceText',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(surfaceIcon, color: surfaceColor, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Surface Condition (Moisture / Drop)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  surfaceText,
                  style: TextStyle(
                    color: surfaceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallRow(BuildContext context) {
    final bool isFall = sensorData.fallDetected;
    final Color color = isFall ? AppColors.emergencyRed : AppColors.safeGreen;
    final IconData icon = isFall ? Icons.personal_injury_rounded : Icons.accessibility_new_rounded;
    final String text = isFall
        ? 'FALL DETECTED! (Impact Accel: ${sensorData.ax.toStringAsFixed(1)} m/s²)'
        : 'Normal Upright Orientation (Gravity: ${sensorData.ay.toStringAsFixed(1)} m/s²)';

    return Semantics(
      label: 'Fall detection monitor: $text',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fall Monitor (MPU6050 6-DOF)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getOverallStatusBorderColor() {
    if (sensorData.fallDetected || sensorData.obstacleSeverity == ObstacleSeverity.danger) {
      return AppColors.emergencyRed;
    }
    if (sensorData.obstacleSeverity == ObstacleSeverity.warning ||
        sensorData.surfaceHazard != SurfaceHazardType.normalDry) {
      return AppColors.warningOrange;
    }
    return AppColors.safeGreen;
  }

  IconData _getBatteryIcon(int percent) {
    if (percent > 80) return Icons.battery_full_rounded;
    if (percent > 50) return Icons.battery_5_bar_rounded;
    if (percent > 20) return Icons.battery_3_bar_rounded;
    return Icons.battery_alert_rounded;
  }
}
