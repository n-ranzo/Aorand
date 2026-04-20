// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {

  // ================================
  // BRAND / PRIMARY (ثابتة)
  // ================================

  static const Color darkRed = Color.fromARGB(255, 4, 5, 26);
  static const Color midRed = Color.fromARGB(255, 0, 0, 0);
  static const Color brightRed = Color.fromARGB(255, 11, 10, 26);

  static const Color accent = Colors.redAccent;

  // ================================
  // DARK MODE
  // ================================

  static const Color darkBackground = Color(0xFF0E0E0E);
  static const Color darkCard = Colors.white10;
  static const Color darkBorder = Colors.white24;

  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;

  static const Color darkIconPrimary = Colors.white;
  static const Color darkIconSecondary = Colors.white54;

  // ================================
  // LIGHT MODE
  // ================================

  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCard = Colors.black12;
  static const Color lightBorder = Colors.black26;

  static const Color lightTextPrimary = Colors.black;
  static const Color lightTextSecondary = Colors.black54;

  static const Color lightIconPrimary = Colors.black;
  static const Color lightIconSecondary = Colors.black54;

  // ================================
  // MAIN GRADIENT (Dark)
  // ================================

  static const List<Color> mainGradient = [
    Color.fromARGB(255, 4, 5, 26),
    Color.fromARGB(255, 3, 0, 12),
    Color.fromARGB(255, 0, 0, 0),
  ];

  // ================================
  // GLASS SYSTEM
  // ================================

  static const Color glassBase = Color(0xFFFFFFFF);

  static Color glass([double opacity = 0.08]) {
    return glassBase.withOpacity(opacity);
  }

  static Color glassBorder([double opacity = 0.15]) {
    return glassBase.withOpacity(opacity);
  }

  // ================================
  // BUTTON
  // ================================

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF460000),
      Color(0xFF000000),
    ],
  );

  // ================================
  // SHADOW
  // ================================

  static Color shadow([double opacity = 0.3]) {
    return Colors.black.withOpacity(opacity);
  }
}