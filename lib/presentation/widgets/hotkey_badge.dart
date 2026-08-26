import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A stylish badge displaying keyboard shortcut keys (e.g. `[F1]`, `[ESC]`, `[F4]`).
class HotkeyBadge extends StatelessWidget {
  const HotkeyBadge({
    super.key,
    required this.label,
    this.isLight = false,
    this.fontSize = 11,
  });

  final String label;
  final bool isLight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withOpacity(0.2) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLight ? Colors.white.withOpacity(0.4) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
        boxShadow: isLight
            ? null
            : [
                const BoxShadow(
                  color: Color(0x0F000000),
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: isLight ? Colors.white : const Color(0xFF475569),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
