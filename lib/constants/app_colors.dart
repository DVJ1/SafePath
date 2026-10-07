import 'package:flutter/material.dart';

/// Accessible, High-Contrast Color Palette for SafePath
/// Designed for both visually impaired individuals (high contrast / distinct cues)
/// and caregivers (modern, clean, and intuitive emergency UI).
class AppColors {
  // Brand Primary
  static const Color primaryBlue = Color(0xFF0F52BA); // Sapphire Blue
  static const Color primaryBlueDark = Color(0xFF0A387E);
  static const Color primaryBlueLight = Color(0xFF4B89EC);

  // High-Contrast Dark & Light Surfaces
  static const Color darkBackground = Color(0xFF12151B);
  static const Color darkSurface = Color(0xFF1C222E);
  static const Color darkCard = Color(0xFF242C3C);
  static const Color darkBorder = Color(0xFF3B4860);

  static const Color lightBackground = Color(0xFFF6F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFD0D7DE);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0A0D14);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFBAC5D5);

  // Emergency & Status Accents
  static const Color emergencyRed = Color(0xFFD32F2F); // High-contrast Crimson
  static const Color emergencyRedGlow = Color(0xFFFF5252);
  static const Color warningOrange = Color(0xFFE65100); // Deep safety amber
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color safeGreen = Color(0xFF10B981); // Emerald safe green
  static const Color safeGreenDark = Color(0xFF047857);
  static const Color infoBlue = Color(0xFF0284C7);
  static const Color purpleAccent = Color(0xFF8B5CF6);

  // Sensor Alert Colors
  static const Color obstacleWarning = Color(0xFFEA580C);
  static const Color waterHazardBlue = Color(0xFF0284C7);
  static const Color fallHazardRed = Color(0xFFDC2626);

  // Accessible High Contrast Accents
  static const Color highContrastYellow = Color(0xFFFFEB3B);
  static const Color highContrastCyan = Color(0xFF00E5FF);
}
