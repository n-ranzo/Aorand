// lib/widgets/buttons/glass_button.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/ui_controller.dart';

/// GlassButton - A glassmorphism-styled button for Aorandra
/// 
/// Features:
/// - Glass effect with customizable opacity
/// - Loading state with CircularProgressIndicator
/// - Disabled state handling
/// - Consistent styling via UIController and AppColors
class GlassButton extends StatelessWidget {
  // ================================
  // REQUIRED PARAMETERS
  // ================================

  final String text;

  // ================================
  // OPTIONAL PARAMETERS
  // ================================

  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
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
    this.width,
    this.height,
    this.textColor,
    this.fontSize,
  });

  // ================================
  // BUILD METHOD
  // ================================

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !isEnabled || isLoading;
    final theme = Theme.of(context); 

    return SizedBox(
      width: width,
      height: height ?? UIController.buttonHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIController.buttonRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UIController.buttonRadius),
            color: AppColors.glass(UIController.buttonOpacity),
            border: Border.all(
              color: isDisabled
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.3),
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
                    : _buildButtonText(isDisabled, theme), 
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================
  // HELPERS
  // ================================

  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          textColor ?? theme.textTheme.bodyLarge!.color!, 
        ),
      ),
    );
  }

  Widget _buildButtonText(bool isDisabled, ThemeData theme) {
    return Text(
      text,
      style: TextStyle(
        color: isDisabled
            ? theme.textTheme.bodyLarge!.color!.withOpacity(0.5)
            : (textColor ?? theme.textTheme.bodyLarge!.color), 
        fontSize: fontSize ?? UIController.buttonTextSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}