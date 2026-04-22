// lib/theme/inputs.dart — Glass text fields with a consistent look.
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Standard text field style consistent with the glass design.
InputDecoration glassInputDecoration({
  String? hintText,
  String? labelText,
  IconData? prefixIcon,
  Widget? suffixIcon,
  bool dense = false,
}) {
  const radius = AppRadii.md;
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    hintStyle: const TextStyle(color: Bk.textDim, fontSize: 14),
    labelStyle: const TextStyle(color: Bk.textSec, fontSize: 13),
    filled: true,
    fillColor: Bk.glassDefault,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: Bk.textSec, size: 18),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    suffixIcon: suffixIcon,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: dense ? 12 : 16,
    ),
    isDense: dense,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: Bk.glassBorder, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: Bk.glassBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: Bk.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: Bk.danger, width: 1),
    ),
  );
}

class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.textInputAction,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText, labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText, autofocus, enabled;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      textInputAction: textInputAction,
      validator: validator,
      enabled: enabled,
      style: const TextStyle(color: Bk.textPri, fontSize: 15),
      cursorColor: Bk.accent,
      decoration: glassInputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
