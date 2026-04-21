import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/ui/ui_controller.dart';
import '../../../../core/utils/glass_container.dart';
import '../../../../shared/widgets/glass_button.dart';
import 'widgets/password_rules.dart';
import 'login_screen.dart';
import '../data/otp_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final supabase = Supabase.instance.client;

  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());

  final TextEditingController passwordController = TextEditingController();

  String password = "";
  bool obscurePassword = true;
  bool isLoading = false;
  bool isVerifying = false;
  bool isVerified = false;

  int seconds = 30;
  Timer? timer;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    for (var c in otpControllers) {
      c.dispose();
    }
    passwordController.dispose();
    timer?.cancel();
    super.dispose();
  }

  String get otp => otpControllers.map((c) => c.text).join();

  // ================= TIMER =================

  void startTimer() {
    canResend = false;
    seconds = 30;

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
        setState(() {
          canResend = true;
        });
      } else {
        setState(() {
          seconds--;
        });
      }
    });
  }

  // ================= RESEND OTP =================

  Future<void> resendCode() async {
    try {
      await OtpService().sendOtp(widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code sent again")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error sending code"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= OTP BOX =================

  Widget _otpBox(int index) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 48,
      height: 58,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.white24
                : Colors.black12,
            width: 1.4,
          ),
        ),
        child: TextField(
          controller: otpControllers[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              FocusScope.of(context).nextFocus();
            }
            if (value.isEmpty && index > 0) {
              FocusScope.of(context).previousFocus();
            }
          },
        ),
      ),
    );
  }

  Widget _otpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) => _otpBox(index)),
    );
  }

  // ================= VERIFY OTP =================

  Future<void> verifyOtp() async {
    try {
      setState(() => isVerifying = true);

      final enteredCode = otp.trim();

      final isValid = await OtpService().verifyOtp(widget.email, enteredCode);

      if (!isValid) {
        throw Exception("Invalid or expired code");
      }

      if (!mounted) return;

      setState(() {
        isVerified = true;
        isVerifying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code verified")),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isVerifying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid or expired code"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= PASSWORD INPUT =================

  Widget _passwordInput() {
    final theme = Theme.of(context);

    return GlassContainer(
      height: UIController.inputHeight,
      radius: UIController.inputRadius,
      border: Border.all(
        color: theme.dividerColor.withOpacity(0.2),
        width: 1.2,
      ),
      child: TextField(
        controller: passwordController,
        obscureText: obscurePassword,
        enabled: isVerified,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 16,
        ),
        onChanged: (value) {
          setState(() {
            password = value;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: isVerified ? "New Password" : "Verify code first",
          hintStyle: TextStyle(
            color: theme.brightness == Brightness.dark
                ? Colors.white60
                : Colors.black54,
            fontSize: 16,
          ),
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          prefixIcon: Icon(
            Icons.lock,
            color: theme.iconTheme.color,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  // ================= RESET PASSWORD =================

 Future<void> resetPassword() async {
  final newPassword = passwordController.text.trim();

  // Ensure OTP is verified before proceeding
  if (!isVerified) return;

  // Basic password validation
  if (newPassword.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password too short")),
    );
    return;
  }

  try {
    setState(() => isLoading = true);

    // Edge Function endpoint
    const url =
        'https://nlqhjqlgvmrrfrtpzcrc.supabase.co/functions/v1/reset_password';

    // Send POST request to Edge Function
    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': widget.email.toLowerCase(),
        'password': newPassword,
      }),
    );

    // Debug response
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    // Parse response
    final data = jsonDecode(res.body);

    // Handle failure response
    if (data == null || data['success'] != true) {
      throw Exception(data['error'] ?? "Reset failed");
    }

    // Clear OTP after successful reset
    await OtpService().clearOtp(widget.email);

    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password updated successfully")),
    );

    // Navigate back to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}
  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: theme.iconTheme.color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Choose a new password",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the verification code you received",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),
                _otpRow(),
                const SizedBox(height: 15),
                Center(
                  child: GestureDetector(
                    onTap: canResend
                        ? () async {
                            await resendCode();
                            startTimer();
                          }
                        : null,
                    child: Text(
                      canResend ? "Resend Code" : "Resend in $seconds s",
                      style: TextStyle(
                        color: canResend
                            ? Colors.orange
                            : theme.brightness == Brightness.dark
                                ? Colors.white38
                                : Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 120,
                    child: GlassContainer(
                      height: UIController.buttonHeight,
                      radius: UIController.buttonRadius,
                      child: GestureDetector(
                        onTap: isVerifying ? null : verifyOtp,
                        child: Center(
                          child: isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Verify",
                                  style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _passwordInput(),
                const SizedBox(height: 20),
                PasswordRules(password: password),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 120,
                    child: GlassContainer(
                      height: UIController.buttonHeight,
                      radius: UIController.buttonRadius,
                      child: GestureDetector(
                        onTap: (!isVerified || isLoading)
                            ? null
                            : resetPassword,
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const GlassButton(text: "Next"),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}