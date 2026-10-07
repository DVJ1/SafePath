import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/stick_sensor_data.dart';

class HardwareStatusBadge extends StatelessWidget {
  final StickSensorData sensorData;
  final String ipAddress;
  final VoidCallback onTap;

  const HardwareStatusBadge({
    super.key,
    required this.sensorData,
    required this.ipAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String statusTitle;
    IconData statusIcon;

    if (!sensorData.isConnected && !sensorData.isSimulated) {
      badgeColor = AppColors.emergencyRed;
      statusTitle = 'Stick Disconnected';
      statusIcon = Icons.wifi_off_rounded;
    } else if (sensorData.isSimulated) {
      badgeColor = AppColors.warningAmber;
      statusTitle = 'Stick Simulator Active';
      statusIcon = Icons.science_rounded;
    } else {
      badgeColor = AppColors.safeGreen;
      statusTitle = 'Stick Connected ($ipAddress)';
      statusIcon = Icons.wifi_rounded;
    }

    return Semantics(
      label: 'Smart stick hardware status: $statusTitle. Tap to configure ESP32 settings.',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badgeColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor,
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(statusIcon, size: 18, color: badgeColor),
                const SizedBox(width: 6),
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.tune_rounded, size: 16, color: badgeColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
