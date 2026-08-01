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
    this.prefixText,
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

  /// Optional prefix text.
  final String? prefixText;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
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
            style: GoogleFonts.inter(fontSize: 15, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hintText,
              prefixText: prefixText,
              hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: enabled
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                  : colorScheme.onSurface.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}
