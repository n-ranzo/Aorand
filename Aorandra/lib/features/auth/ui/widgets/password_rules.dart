import 'package:flutter/material.dart';

class PasswordRules extends StatelessWidget {
  final String password;

  const PasswordRules({
    super.key,
    required this.password,
  });

  bool hasUppercase(String value) {
    return RegExp(r'[A-Z]').hasMatch(value);
  }

  bool hasLowercase(String value) {
    return RegExp(r'[a-z]').hasMatch(value);
  }

  bool hasNumber(String value) {
    return RegExp(r'[0-9]').hasMatch(value);
  }

  bool hasSymbol(String value) {
    return RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(value);
  }

  bool hasMinLength(String value) {
    return value.length >= 8;
  }

  Widget rule(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel,
            color: valid ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: valid ? Colors.green : Colors.red,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        rule(
          "Minimum 8 characters",
          hasMinLength(password),
        ),

        rule(
          "At least one numeral (0-9)",
          hasNumber(password),
        ),

        rule(
          "At least one symbol (!@#\$%^&*)",
          hasSymbol(password),
        ),

        rule(
          "At least one uppercase letter",
          hasUppercase(password),
        ),

        rule(
          "At least one lowercase letter",
          hasLowercase(password),
        ),

      ],
    );
  }
}