import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient Colors
  static const Color primaryBlue = Color(0xFF00C6FF);
  static const Color primaryPurple = Color(0xFF0072FF);
  
  // Secondary / Accent Colors
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentDeepBlue = Color(0xFF0A0E21);
  
  // Backgrounds
  static const Color darkBackground = Color(0xFF0A0E21);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  
  // Design System Tokens
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentCyan, primaryBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
