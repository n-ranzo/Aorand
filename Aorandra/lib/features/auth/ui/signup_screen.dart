// lib/screens/auth/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/ui/ui_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../core/utils/glass_container.dart';
import 'widgets/password_rules.dart';
import 'package:aorandra/features/home/ui/home_screen.dart';

// ================================
// SIGNUP SCREEN
// ================================

/// SignupScreen - Handles new user registration with Supabase
/// 
/// Features:
/// - Username, email, and password validation
/// - Username uniqueness check via Supabase
/// - User creation with Supabase Auth
/// - Profile data insertion into users table
/// - Theme-aware UI (light/dark mode support)
/// - Glassmorphism UI elements
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ================================
  // SERVICES & CONTROLLERS
  // ================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ================================
  // CONTROLLERS
  // ================================

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // ================================
  // STATE VARIABLES
  // ================================

  String _password = '';
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ================================
  // LIFECYCLE METHODS
  // ================================

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================================
  // VALIDATION METHODS
  // ================================

  /// Validate username requirements
  String? _validateUsername(String value) {
    final username = value.trim().toLowerCase();

    if (username.isEmpty) return 'Username required';
    if (username.length < 3) return 'Minimum 3 characters';
    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(username)) {
      return 'Only lowercase letters, numbers, . and _';
    }
    return null;
  }

  /// Validate email format
  String? _validateEmail(String email) {
    final value = email.trim();

    if (value.isEmpty) return 'Email required';

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$');

    if (!emailRegex.hasMatch(value)) return 'Invalid email';

    return null;
  }

  /// Validate password strength requirements
  String? _validatePassword(String value) {
    if (value.length < 8) return 'Min 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Uppercase required';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Lowercase required';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Number required';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(value)) {
      return 'Symbol required';
    }
    return null;
  }

  // ================================
  // REGISTRATION LOGIC
  // ================================

  /// Handle user registration with Supabase
  Future<void> _register() async {
  final username = _usernameController.text.trim().toLowerCase();
  final email = _emailController.text.trim().toLowerCase();
  final pass = _passwordController.text.trim();

  final name = _nameController.text.trim();

  // ================= VALIDATION =================
  setState(() {
    _usernameError = _validateUsername(username);
    _emailError = _validateEmail(email);
    _passwordError = _validatePassword(pass);
  });

  if (_usernameError != null ||
      _emailError != null ||
      _passwordError != null) {
    return;
  }

  try {
    setState(() => _isLoading = true);

    // ================= CHECK USERNAME =================
    final usernameCheck = await _supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    if (usernameCheck != null) {
      setState(() {
        _usernameError = 'Username already taken';
      });
      return;
    }

    // ================= SIGN UP (مرة واحدة فقط) =================
    await _supabase.auth.signUp(
  email: email,
  password: pass,
  data: {
    'username': username,
    'name': name, 
  },
);

    if (!mounted) return;

    // ================= NAVIGATION =================
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  } on AuthException catch (e) {
    if (!mounted) return;

    if (e.message.toLowerCase().contains('already registered')) {
      setState(() {
        _emailError = 'Email already in use';
      });
    } else {
      _showError(e.message);
    }
  } on PostgrestException catch (e) {
    if (!mounted) return;
    _showError(e.message);
  } catch (e) {
    if (!mounted) return;
    _showError('Something went wrong');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  /// Display error message in SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
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

        // Theme-aware text color for light/dark mode
        style: TextStyle(
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),

        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,

          // Theme-aware hint color
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),

          // Theme-aware icon color
          prefixIcon: Icon(
            icon,
            color: theme.iconTheme.color,
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

          contentPadding:
              const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// Build error message row with icon
  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ================================
  // UI BUILDERS - HEADER & TITLE
  // ================================

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: theme.iconTheme.color,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Create Account',
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildErrors() {
    return Column(
      children: [
        if (_usernameError != null) _errorText(_usernameError!),
        if (_emailError != null) _errorText(_emailError!),
        if (_passwordError != null) _errorText(_passwordError!),
      ],
    );
  }

  // ================================
  // MAIN BUILD METHOD
  // ================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: Container(
        // Theme-aware background color (replaces gradient)
        color: theme.scaffoldBackgroundColor,

        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Back button header
                    _buildHeader(context),

                    const Spacer(),

                    Column(
                      children: [
                        // Screen title
                        _buildTitle(context),

                        const SizedBox(height: 25),

                        // Username Input
                        _buildInput(
                          controller: _usernameController,
                          icon: Icons.person,
                          hint: 'Username',
                          error: _usernameError,
                          onChanged: (_) {
                            setState(() {
                              _usernameError = _validateUsername(
                                _usernameController.text,
                              );
                            });
                          },
                        ),

                        const SizedBox(height: UIController.inputSpacing),

                        // Email Input
                        _buildInput(
                          controller: _emailController,
                          icon: Icons.email,
                          hint: 'Email',
                          error: _emailError,
                          onChanged: (_) {
                            setState(() {
                              _emailError = _validateEmail(
                                _emailController.text,
                              );
                            });
                          },
                        ),

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
                          onChanged: (value) {
                            setState(() {
                              _password = value;
                              _passwordError = _validatePassword(value);
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        // Error messages
                        _buildErrors(),

                        const SizedBox(height: 10),

                        // Password rules widget
                        PasswordRules(password: _password),

                        const SizedBox(height: 25),

                        // Sign Up Button
                        SizedBox(
                          width: 160,
                          child: GlassContainer(
                            height: UIController.buttonHeight,
                            radius: UIController.buttonRadius,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _register,
                              child: _isLoading
                                  ? Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    )
                                  : const GlassButton(text: 'Sign Up'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
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