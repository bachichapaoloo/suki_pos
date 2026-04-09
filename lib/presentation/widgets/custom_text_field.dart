import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable text form field with consistent styling.
class CustomTextField extends StatelessWidget {
  /// Creates a [CustomTextField].
  const CustomTextField({
    required this.label,
    required this.controller,
    super.key,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  /// The label text for the field.
  final String label;

  /// The controller for the text field.
  final TextEditingController controller;

  /// Optional validator function.
  final String? Function(String?)? validator;

  /// The type of keyboard to display.
  final TextInputType? keyboardType;

  /// Whether to obscure the text.
  final bool obscureText;

  /// Optional icon to display before the text.
  final Widget? prefixIcon;

  /// Optional icon to display after the text.
  final Widget? suffixIcon;

  /// Optional hint text.
  final String? hintText;

  /// Whether the field is enabled.
  final bool enabled;

  /// The maximum number of lines.
  final int? maxLines;

  /// The action to take when the user submits the field.
  final TextInputAction? textInputAction;

  /// Callback when the field is submitted.
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            maxLines: maxLines,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: enabled
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
