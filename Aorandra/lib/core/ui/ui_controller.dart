// lib/core/utils/ui_controller.dart

import 'package:flutter/material.dart';

/// UIController - Centralized UI constants and glass effect settings
/// 
/// Contains all spacing, sizing, typography, and visual effect values
/// to ensure design consistency across the Aorandra application.
/// 
/// Glass effect values are dynamically calculated based on base opacity
/// and blur settings for different component types.
class UIController {

  // ================================
  // GLOBAL TOGGLES
  // ================================
  
  /// Enable or disable glass effect globally (for performance mode)
  static bool isGlassEnabled = true;

  // ================================
  // HEADER & FOOTER
  // ================================
  
  static const double topBottomHeight = 75.0;
  static const double topBottomRadius = 35.0;
  static const double topBottomHorizontalPadding = 20.0;
  static const double topBottomOffsetY = 0.0;

  // --- Title Settings ---
  static const double titleFontSize = 26.0;
  static const double titleLetterSpacing = 1.0;
  static const double titleTopOffset = 0.0;

  // --- Spacing ---
  static const double topSpacing = 20.0;
  static const double bottomSpacing = 20.0;

  // ================================
  // INPUT FIELDS
  // ================================
  
  static const double inputHeight = 50.0;
  static const double inputRadius = 30.0;
  static const double inputSpacing = 15.0;
  static const double inputHorizontalPadding = 15.0;
  static const double inputVerticalPadding = 10.0;
  static const double inputOffsetY = 0.0;

  // --- Icon Settings ---
  static const double iconSize = 22.0;
  static const double iconOffsetX = 0.0;
  static const double iconOffsetY = 0.0;

  // --- Text Settings ---
  static const double textSize = 16.0;
  static const double hintSize = 14.0;
  static const double textOffsetX = 0.0;
  static const double textOffsetY = 0.0;
  static const double spaceBetweenIconAndText = 10.0;

  // ================================
  // BUTTONS
  // ================================
  
  static const double buttonHeight = 45.0;
  static const double buttonRadius = 25.0;
  static const double buttonWidth = 160.0;      // ✅ تم الإضافة
  static const double buttonSpacing = 25.0;     // ✅ تم الإضافة
  static const double buttonWidthFactor = 0.5;
  static const double buttonOffsetY = 0.0;
  static const double buttonTextSize = 16.0;

  // ================================
  // FOOTER
  // ================================
  
  static const double footerTextSize = 14.0;
  static const double footerOffsetY = 0.0;

  // ================================
  // GLASS EFFECT SYSTEM (Base Values)
  // ================================
  
  /// Base opacity for glass effect (default: 12%)
  static const double glassOpacity = 0.12;
  
  /// Base blur strength for glass effect (default: 20)
  static const double blur = 20.0;

  // --- Dynamic Glass Values per Component ---
  
  /// Opacity for header/footer glass (base + 3%)
  static double get topBottomOpacity => 
      (glassOpacity + 0.03).clamp(0.05, 1.0);

  /// Blur for header/footer glass (base + 5)
  static double get topBottomBlur => 
      (blur + 5.0).clamp(0.0, 100.0);

  /// Opacity for input glass (base - 2%)
  static double get inputOpacity => 
      (glassOpacity - 0.02).clamp(0.05, 1.0);

  /// Blur for input glass (same as base)
  static double get inputBlur => 
      blur.clamp(0.0, 100.0);

  /// Opacity for button glass (base + 6%)
  static double get buttonOpacity => 
      (glassOpacity + 0.06).clamp(0.05, 1.0);

  /// Blur for button glass (base - 2)
  static double get buttonBlur => 
      (blur - 2.0).clamp(0.0, 100.0);

  // ================================
  // BORDER SETTINGS
  // ================================
  
  static const double borderOpacity = 0.25;
  static const double borderWidth = 1.2;

  // ================================
  // 3D LIGHT EFFECT
  // ================================
  
  static const double lightOpacity = 0.25;
  static const double darkOpacity = 0.15;

  // ================================
  // SHADOW SETTINGS
  // ================================
  
  static const double shadowBlur = 20.0;
  static const double shadowOffsetY = 10.0;
  static const double shadowOpacity = 0.25;

  // ================================
  // ADVANCED CONTROLS
  // ================================
  
  static const double iconTextAlignmentY = 0.0;
  static const double inputShadowBoost = 1.0;

  // ================================
  // ANIMATION SETTINGS
  // ================================
  
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration animationDurationFast = Duration(milliseconds: 100);
  static const Duration animationDurationSlow = Duration(milliseconds: 400);
  static const Curve animationCurve = Curves.easeInOut;
}