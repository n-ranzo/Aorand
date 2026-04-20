// lib/core/theme/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // 🔥 مهم

enum AppThemeMode { system, light, dark }

class ThemeController extends GetxController {

  final box = GetStorage(); // 🔥 تخزين

  final themeMode = AppThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();

    // 🔥 تحميل الثيم المحفوظ
    final saved = box.read('theme');

    if (saved != null) {
      themeMode.value = AppThemeMode.values[saved];
    }
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  void setTheme(AppThemeMode mode) {
    themeMode.value = mode;

    // 🔥 حفظ الثيم
    box.write('theme', mode.index);
  }
}