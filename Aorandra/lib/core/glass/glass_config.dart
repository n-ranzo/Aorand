// lib/core/theme/glass_config.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// GlassConfig - Centralized configuration for glassmorphism effects
/// 
/// Contains all visual properties for the glass effect including
/// blur strength, border radius, colors, and shadows.
/// 
/// Modify these values to adjust the glass appearance globally
/// across the Aorandra application.
class GlassConfig {

  // ================================
  // BLUR SETTINGS
  // ================================
  
  /// Blur strength for the glass effect (sigmaX/sigmaY)
  /// Recommended range: 10-30 for optimal performance
  static const double blur = 20.0;

  // ================================
  // SHAPE & BORDER
  // ================================
  
  /// Border radius for glass containers
  static const double borderRadius = 25.0;

  // ================================
  // COLORS
  // ================================
  
  /// Background color with opacity for glass effect
  static const Color backgroundColor = Color.fromRGBO(255, 255, 255, 0.06);

  /// Border color with opacity for glass outline
  static const Color borderColor = Color.fromRGBO(255, 255, 255, 0.20);

  /// Border width for glass outline
  static const double borderWidth = 1.2;

  // ================================
  // SHADOW EFFECT
  // ================================
  
  /// Default shadow configuration for glass containers
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.20),
      blurRadius: 20.0,
      spreadRadius: 1.0,
      offset: Offset(0, 4),
    ),
  ];

  // ================================
  // PRESET CONFIGURATIONS
  // ================================
  
  /// Light glass preset (higher opacity, less blur)
  static GlassPreset get lightPreset => const GlassPreset(
        blur: 15.0,
        opacity: 0.10,
        borderOpacity: 0.25,
      );

  /// Heavy glass preset (lower opacity, more blur)
  static GlassPreset get heavyPreset => const GlassPreset(
        blur: 30.0,
        opacity: 0.04,
        borderOpacity: 0.15,
      );

  // ================================
  // UTILITY METHODS
  // ================================
  
  /// Creates a BoxDecoration with glass effect
  static BoxDecoration get decoration => BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: shadow,
      );

  /// Creates a BackdropFilter for blur effect
  static ImageFilter get blurFilter => ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
      );
}

/// Preset configuration for quick glass style switching
class GlassPreset {
  final double blur;
  final double opacity;
  final double borderOpacity;

  const GlassPreset({
    required this.blur,
    required this.opacity,
    required this.borderOpacity,
  });

  Color get backgroundColor => Colors.white.withOpacity(opacity);
  Color get borderColor => Colors.white.withOpacity(borderOpacity);
}