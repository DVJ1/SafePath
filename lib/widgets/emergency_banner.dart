import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/emergency_event.dart';

class EmergencyBanner extends StatelessWidget {
  final EmergencyEvent event;
  final VoidCallback? onCancel;
  final VoidCallback? onResolve;
  final VoidCallback? onViewDetails;
  final bool isUserRole;

  const EmergencyBanner({
    super.key,
    required this.event,
    this.onCancel,
    this.onResolve,
    this.onViewDetails,
    this.isUserRole = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('hh:mm:ss a').format(event.timestamp);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF330808) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.emergencyRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.emergencyRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE EMERGENCY: ${event.typeDisplayName.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.emergencyRed,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Triggered at $timeStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.statusDisplayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lifecycle Stepper Visualizer
          _buildLifecycleStepper(context),

          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              if (onCancel != null && isUserRole) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Alarm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emergencyRed,
                      side: const BorderSide(color: AppColors.emergencyRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (onResolve != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Mark Safe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safeGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (onViewDetails != null)
                IconButton.filledTonal(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  tooltip: 'View Emergency Details & Map',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleStepper(BuildContext context) {
    final List<Map<String, dynamic>> steps = [
      {'title': 'Triggered', 'done': true},
      {
        'title': 'Dispatched',
        'done': event.status != EmergencyStatus.triggered,
      },
      {
        'title': 'Acknowledged',
        'done': event.status == EmergencyStatus.acknowledged ||
            event.status == EmergencyStatus.responding ||
            event.status == EmergencyStatus.assistanceCoordinated ||
            event.status == EmergencyStatus.resolved,
      },
      {
        'title': 'Responding',
        'done': event.status == EmergencyStatus.responding ||
            event.status == EmergencyStatus.assistanceCoordinated ||
            event.status == EmergencyStatus.resolved,
      },
    ];

    return Row(
      children: steps.map((step) {
        final bool done = step['done'] as bool;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.safeGreen : Colors.grey.withValues(alpha: 0.3),
                  border: Border.all(
                    color: done ? AppColors.safeGreenDark : Colors.grey,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                step['title'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: done ? FontWeight.bold : FontWeight.normal,
                  color: done ? AppColors.safeGreen : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
