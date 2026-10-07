import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double minHeight;
  final double fontSize;
  final String? semanticLabel;
  final String? semanticHint;
  final bool isDestructive;
  final bool isLoading;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.minHeight = 58.0,
    this.fontSize = 18.0,
    this.semanticLabel,
    this.semanticHint,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        (isDestructive ? AppColors.emergencyRed : Theme.of(context).colorScheme.primary);
    final effectiveFg = textColor ?? Colors.white;

    return Semantics(
      label: semanticLabel ?? label,
      hint: semanticHint,
      button: true,
      enabled: !isLoading,
      child: Material(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: effectiveBg.withValues(alpha: 0.4),
        child: InkWell(
          onTap: () {
            if (!isLoading) {
              HapticFeedback.selectionClick();
              onPressed();
            }
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDestructive ? AppColors.emergencyRedGlow : Colors.white24,
                width: 1.5,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: effectiveFg, size: fontSize + 6),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: effectiveFg,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
