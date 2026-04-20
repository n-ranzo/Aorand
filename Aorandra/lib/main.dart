// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/theme_controller.dart';
import "features/auth/ui/auth_gate.dart";
import 'package:aorandra/shared/services/user_manager.dart';

// ================================
// MAIN ENTRY POINT
// ================================

/// Application entry point
/// 
/// Initializes:
/// - Flutter binding
/// - GetStorage for persistent storage
/// - Supabase client for backend services
/// - ThemeController for theme management
Future<void> main() async {
  // Ensure Flutter binding is initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage for persistent key-value storage (theme preference)
  await GetStorage.init();

  // Initialize Supabase client with project credentials
  await Supabase.initialize(
    url: 'https://nlqhjqlgvmrrfrtpzcrc.supabase.co',
    anonKey: 'sb_publishable_9VHGrLgJCB7o9OfuTOBEQg_jbpSxlUr',
  );
  
  UserManager.instance.listenToProfileChanges();

  // Register ThemeController as a singleton using GetX
  Get.put(ThemeController());

  // Launch the application
  runApp(const MyApp());
}

// ================================
// APPLICATION WIDGET
// ================================

/// Root widget of the Aorandra application
/// 
/// Handles:
/// - Theme configuration (light/dark)
/// - GetX routing and state management
/// - Auth gate for authentication flow
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the registered ThemeController instance
    final controller = Get.find<ThemeController>();

    // Rebuild widget tree when theme mode changes (reactive)
    return Obx(() {
      return GetMaterialApp(
        // Hide debug banner in release mode
        debugShowCheckedModeBanner: false,

        // Application title
        title: 'Aorandra',

        // ================================
        // LIGHT THEME CONFIGURATION
        // ================================
        theme: ThemeData(
          brightness: Brightness.light,

          // Background colors
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.black12,
          dividerColor: Colors.black26,

          // Primary color scheme for light mode
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
          ),

          // Default icon colors
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),

          // App bar styling for light mode
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),

          // Default text styles for light mode
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black54),
          ),
        ),

        // ================================
        // DARK THEME CONFIGURATION
        // ================================
        darkTheme: ThemeData(
          brightness: Brightness.dark,

          // Background colors
          scaffoldBackgroundColor: Colors.black,
          cardColor: Colors.white10,
          dividerColor: Colors.white24,

          // Primary color scheme for dark mode
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
          ),

          // Default icon colors
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),

          // App bar styling for dark mode
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          // Default text styles for dark mode
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white60),
          ),
        ),

        // ================================
        // THEME MODE SELECTION
        // ================================
        // Reactive theme mode based on controller state
        themeMode: controller.flutterThemeMode,

        // ================================
        // ROOT ROUTE
        // ================================
        // AuthGate handles authentication state and routing
        home: const AuthGate(),
      );
    });
  }
}