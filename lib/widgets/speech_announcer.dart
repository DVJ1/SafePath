import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SpeechAnnouncer extends StatelessWidget {
  final String text;
  final bool isSpeaking;
  final VoidCallback onRepeat;

  const SpeechAnnouncer({
    super.key,
    required this.text,
    this.isSpeaking = false,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Voice guidance announcement: $text. Double tap to hear again.',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRepeat,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSpeaking ? AppColors.highContrastCyan : AppColors.primaryBlueLight.withValues(alpha: 0.3),
                width: isSpeaking ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSpeaking ? Icons.volume_up_rounded : Icons.record_voice_over_rounded,
                  color: isSpeaking ? AppColors.highContrastCyan : AppColors.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.replay_rounded, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
