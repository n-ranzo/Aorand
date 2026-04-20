import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aorandra/core/ui/ui_controller.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;

  final double? height;
  final double radius;
  final EdgeInsets? padding;

  final bool? isGlassEnabled;

  final Border? border;
  final List<BoxShadow>? customShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.height,
    this.radius = 30,
    this.padding,
    this.border,
    this.customShadow,
    this.isGlassEnabled,
  });

  @override
  Widget build(BuildContext context) {
    /// 🔥 ثيم
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool glassOn =
        isGlassEnabled ?? UIController.isGlassEnabled;

    /// ===============================
    /// DISABLE GLASS
    /// ===============================
    if (!glassOn) {
      return Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: UIController.topBottomHorizontalPadding,
            ),
        child: child,
      );
    }

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: UIController.topBottomHorizontalPadding,
          ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,

          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: UIController.blur,
              sigmaY: UIController.blur,
            ),

            child: Container(
              height: height,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),

                /// 🔥🔥🔥 FIX اللايت مود (تم تعديل هذا السطر فقط)
                color: isDark
                    ? Colors.white.withOpacity(
                        UIController.glassOpacity,
                      )
                    : Colors.black.withOpacity(0.05),

                /// 🔥 BORDER
                border: border ??
                    Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(
                              UIController.borderOpacity,
                            )
                          : Colors.black.withOpacity(0.15),
                      width: UIController.borderWidth,
                    ),

                /// 🔥 SHADOW
                boxShadow: customShadow ??
                    [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(
                                UIController.shadowOpacity,
                              )
                            : Colors.black.withOpacity(0.08),
                        blurRadius: UIController.shadowBlur,
                        offset: const Offset(
                          0,
                          UIController.shadowOffsetY,
                        ),
                      ),
                    ],
              ),

              child: child,
            ),
          ),
        ),
      ),
    );
  }
}