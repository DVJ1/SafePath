import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/user_profile.dart';

class ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback? onDelete;
  final bool isManageMode;

  const ContactCard({
    super.key,
    required this.contact,
    this.onDelete,
    this.isManageMode = false,
  });

  Future<void> _callContact(BuildContext context) async {
    final cleanNumber = contact.phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot launch phone dialer for ${contact.phoneNumber}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Call dialer error: $e');
    }
  }

  Future<void> _smsContact(BuildContext context) async {
    final cleanNumber = contact.phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('sms:$cleanNumber?body=SafePath Emergency Notice');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('SMS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: contact.isPrimary ? AppColors.primaryBlue : Colors.grey.withValues(alpha: 0.3),
          width: contact.isPrimary ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Contact Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: contact.isPrimary ? AppColors.primaryBlue : Colors.grey.shade700,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Contact Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          contact.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.isPrimary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${contact.relationship} • ${contact.phoneNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons (Call / SMS / Delete)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  onPressed: () => _callContact(context),
                  icon: const Icon(Icons.call_rounded, color: AppColors.safeGreen),
                  tooltip: 'Call ${contact.name}',
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: () => _smsContact(context),
                  icon: const Icon(Icons.message_rounded, color: AppColors.primaryBlue),
                  tooltip: 'SMS ${contact.name}',
                ),
                if (isManageMode && onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.emergencyRed),
                    tooltip: 'Delete Contact',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
