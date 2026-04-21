// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../../../../core/ui/ui_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../core/utils/glass_container.dart';
import 'package:aorandra/features/home/ui/home_screen.dart';
import 'forgot_password.dart';
import 'signup_screen.dart';

// ================================
// LOGIN SCREEN
// ================================

/// LoginScreen - Handles user authentication with email/username and password
/// 
/// Features:
/// - Login with email or username (username lookup via Supabase)
/// - Password visibility toggle
/// - Real-time validation and error handling
/// - Theme-aware UI (light/dark mode support)
/// - Glassmorphism UI elements
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ================================
  // SERVICES & CONTROLLERS
  // ================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ================================
  // CONTROLLERS
  // ================================

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ================================
  // STATE VARIABLES
  // ================================

  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ================================
  // LIFECYCLE METHODS
  // ================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================================
  // VALIDATION METHODS
  // ================================

  /// Validate non-empty input
  String? _validateInput(String value) {
    if (value.trim().isEmpty) return 'Required';
    return null;
  }

  /// Validate password requirements
  String? _validatePassword(String value) {
    if (value.trim().isEmpty) return 'Password required';
    if (value.trim().length < 6) return 'Too short';
    return null;
  }

  // ================================
  // AUTHENTICATION LOGIC
  // ================================

  /// Handle user login with email or username
  Future<void> _login() async {
  final input = _emailController.text.trim().toLowerCase();
  final password = _passwordController.text.trim();

  // ================= VALIDATION =================
  setState(() {
    _emailError = _validateInput(input);
    _passwordError = _validatePassword(password);
  });

  if (_emailError != null || _passwordError != null) return;

  String emailToUse = input;

  try {
    setState(() => _isLoading = true);

    // ================= USERNAME LOGIN =================
    // إذا المستخدم كتب username بدل email
    if (!input.contains('@')) {
      final result = await _supabase
          .from('profiles') 
          .select('email')
          .eq('username', input)
          .maybeSingle(); 

      if (result == null) {
        setState(() {
          _emailError = 'User not found';
          _isLoading = false;
        });
        return;
      }

      emailToUse = (result['email'] as String).trim().toLowerCase();
    }

    // ================= AUTH LOGIN =================
    await _supabase.auth.signInWithPassword(
      email: emailToUse,
      password: password,
    );

    if (!mounted) return;

    // ================= NAVIGATION =================
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );

  } on AuthException catch (e) {
    setState(() {
      if (e.message.toLowerCase().contains('invalid login')) {
        _passwordError = 'Wrong email or password';
      } else {
        _passwordError = e.message;
      }
    });

  } catch (_) {
    setState(() {
      _passwordError = 'Something went wrong';
    });

  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  // ================================
  // UI BUILDERS - INPUTS
  // ================================

  /// Build themed input field with glass container
  /// 
  /// Supports:
  /// - Password visibility toggle
  /// - Error state styling
  /// - Theme-aware colors (light/dark mode)
  Widget _buildInput({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? error,
    bool isPassword = false,
    VoidCallback? togglePassword,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);

    return GlassContainer(
      height: UIController.inputHeight,
      radius: UIController.inputRadius,
      border: Border.all(
        color: error != null
            ? Colors.red
            : theme.dividerColor.withOpacity(0.2),
        width: 1.5,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,

        // Theme-aware text color for light/dark mode
        style: TextStyle(
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 16,
          height: 1.0,
        ),

        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,

          // Theme-aware hint color
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 16,
            height: 1.0,
          ),

          // Theme-aware icon color
          prefixIcon: Icon(
            icon,
            color: theme.iconTheme.color,
            size: UIController.iconSize,
          ),

          prefixIconConstraints: const BoxConstraints(
            minWidth: 50,
            minHeight: 50,
          ),

          suffixIcon: isPassword
              ? IconButton(
                  onPressed: togglePassword,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: theme.iconTheme.color?.withOpacity(0.7),
                  ),
                )
              : null,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  /// Build error message row with icon
  Widget _errorText(String text) {
    return Row(
      children: [
        const Icon(Icons.error, color: Colors.red, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.red),
        ),
      ],
    );
  }

  // ================================
  // MAIN BUILD METHOD
  // ================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.05,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: UIController.topSpacing),

                    // App Title
                    GlassContainer(
                      height: UIController.topBottomHeight,
                      radius: UIController.topBottomRadius,
                      child: Center(
                        child: Text(
                          'Aorandra',
                          style: TextStyle(
                            fontFamily: 'PacificoFont',
                            fontSize: UIController.titleFontSize,
                            letterSpacing:
                                UIController.titleLetterSpacing,
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Email Input
                    _buildInput(
                      controller: _emailController,
                      icon: Icons.person,
                      hint: 'Username or Email',
                      error: _emailError,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 8),
                    if (_emailError != null) _errorText(_emailError!),

                    const SizedBox(height: UIController.inputSpacing),

                    // Password Input
                    _buildInput(
                      controller: _passwordController,
                      icon: Icons.lock,
                      hint: 'Password',
                      error: _passwordError,
                      isPassword: true,
                      togglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 8),
                    if (_passwordError != null)
                      _errorText(_passwordError!),

                    const SizedBox(height: 10),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Login Button
                    SizedBox(
                      width: 160,
                      child: GlassContainer(
                        height: UIController.buttonHeight,
                        radius: UIController.buttonRadius,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _login,
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const GlassButton(text: 'Login'),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Create Account Button
                    GlassContainer(
                      height: UIController.topBottomHeight,
                      radius: UIController.topBottomRadius,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: UIController.bottomSpacing),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}