// lib/widgets/buttons/glass_button.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui_controller.dart';

/// =======================================================
/// GlassButton
/// A reusable glassmorphism button used across the app
///
/// Features:
/// - Glass effect (blur + opacity)
/// - Active / inactive visual state (for Follow button)
/// - Loading indicator support
/// - Disabled state handling
/// - Fully customizable size
/// =======================================================
class GlassButton extends StatelessWidget {

  // ================================
  // REQUIRED
  // ================================
  final String text;

  // ================================
  // OPTIONAL
  // ================================
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  /// 🔥 IMPORTANT: controls active state (Follow / Following)
  final bool isActive;

  final double? width;
  final double? height;
  final Color? textColor;
  final double? fontSize;

  // ================================
  // CONSTRUCTOR
  // ================================
  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.isActive = false, // 👈 default
    this.width,
    this.height,
    this.textColor,
    this.fontSize,
  });

  // ================================
  // BUILD
  // ================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isDisabled = !isEnabled || isLoading;

    return SizedBox(
      width: width,
      height: height ?? UIController.buttonHeight,

      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIController.buttonRadius),

        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(UIController.buttonRadius),

            /// 🎯 BACKGROUND (changes when active)
            color: isActive
                ? Colors.white.withOpacity(0.15) // Following
                : AppColors.glass(UIController.buttonOpacity), // Follow

            /// 🎯 BORDER
            border: Border.all(
              color: isActive
                  ? Colors.white.withOpacity(0.6)
                  : (isDisabled
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.3)),
              width: 1.2,
            ),
          ),

          child: Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.transparent,

              child: Center(
                child: isLoading
                    ? _buildLoadingIndicator(theme)
                    : _buildText(theme, isDisabled),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================
  // LOADING
  // ================================
  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          textColor ?? theme.textTheme.bodyLarge!.color!,
        ),
      ),
    );
  }

  // ================================
  // TEXT
  // ================================
  Widget _buildText(ThemeData theme, bool isDisabled) {
    return Text(
      text,
      style: TextStyle(
        /// 🎯 TEXT COLOR changes when active
        color: isActive
            ? Colors.white
            : (isDisabled
                ? theme.textTheme.bodyLarge!.color!.withOpacity(0.5)
                : (textColor ??
                    theme.textTheme.bodyLarge!.color)),

        fontSize: fontSize ?? UIController.buttonTextSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}