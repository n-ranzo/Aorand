import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aorandra/core/theme/theme_controller.dart';

final ThemeController themeController = Get.find<ThemeController>();

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {

  @override
  Widget build(BuildContext context) {
    return Obx(() {

      final theme = Theme.of(context);

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        appBar: AppBar(
          title: const Text("Appearance"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),

        body: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: theme.dividerColor),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  "Appearance",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _themeButton(context, "System", AppThemeMode.system),
                    _themeButton(context, "Light", AppThemeMode.light),
                    _themeButton(context, "Dark", AppThemeMode.dark),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _themeButton(BuildContext context, String title, AppThemeMode mode) {
    final theme = Theme.of(context);

    final selected =
        themeController.themeMode.value == mode;

    IconData icon;

    if (mode == AppThemeMode.system) {
      icon = Icons.brightness_auto;
    } else if (mode == AppThemeMode.dark) {
      icon = Icons.dark_mode;
    } else {
      icon = Icons.light_mode;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          themeController.setTheme(mode);
        },
        child: Column(
          children: [

            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 90,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.redAccent.withOpacity(0.2)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? Colors.redAccent
                      : theme.dividerColor,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 30,
                  color: selected
                      ? Colors.redAccent
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 4),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
                color: selected
                    ? Colors.redAccent
                    : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}