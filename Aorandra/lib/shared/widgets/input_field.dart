import 'package:flutter/material.dart';
import 'package:aorandra/core/ui/ui_controller.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool isPassword;
  final Function(String)? onChanged;

  const InputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.isPassword = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      onChanged: onChanged,

      // يجعل النص في منتصف الحقل
      textAlignVertical: TextAlignVertical.center,

      style: const TextStyle(
        color: Colors.white,
        fontSize: UIController.textSize,
      ),

      decoration: InputDecoration(
        border: InputBorder.none,

        // الأيقونة
        prefixIcon: Icon(
          icon,
          color: Colors.white,
          size: UIController.iconSize,
        ),

        // حل مشكلة رفع النص
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),

        hintText: hint,

        hintStyle: const TextStyle(
          color: Colors.white54,
          fontSize: UIController.hintSize,
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIController.inputHorizontalPadding,
        ),
      ),
    );
  }
}