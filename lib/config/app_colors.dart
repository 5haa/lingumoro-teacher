import 'package:flutter/material.dart';

class AppColors {
  // Primary blue theme colors
  static const Color primary = Color(0xFF2196F3); // Material Blue 500
  static const Color primaryLight = Color(0xFF64B5F6); // Material Blue 300
  static const Color primaryDark = Color(0xFF1976D2); // Material Blue 700
  
  // Accent colors
  static const Color accent = Color(0xFF42A5F5); // Material Blue 400
  
  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  
  // Other colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
}

