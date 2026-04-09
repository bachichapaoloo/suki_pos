import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/utils/responsive_layout.dart';

/// The login page of the application where users enter their PIN.
class LoginPage extends StatefulWidget {
  /// Creates a [LoginPage].
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _pin = '';
  final String _superuserPin = '050724';
  bool _isVerifying = false;
  bool _isSuccess = false;

  void _onDigitPressed(String digit) {
    if (_isVerifying || _isSuccess) return;
    if (_pin.length < 6) {
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        _pin += digit;
      });
      if (_pin.length == 6) {
        unawaited(_verifyPin());
      }
    }
  }

  void _onDeletePressed() {
    if (_isVerifying || _isSuccess) return;
    if (_pin.isNotEmpty) {
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);

    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (_pin == _superuserPin) {
      setState(() {
        _isSuccess = true;
        _isVerifying = false;
      });

      unawaited(HapticFeedback.mediumImpact());

      await Future<void>.delayed(const Duration(seconds: 2));

      if (mounted) {
        unawaited(Navigator.of(context).pushReplacementNamed('/pos'));
      }
    } else {
      unawaited(HapticFeedback.vibrate());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incorrect PIN. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        setState(() {
          _pin = '';
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSuccess) {
      return _buildSuccessView(colorScheme);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveLayout(
            mobile: _buildMobileLayout(colorScheme),
            tablet: _buildTabletLayout(colorScheme),
            desktop: _buildDesktopLayout(colorScheme),
          ),
        ),
      ),
    );
  }

  // ================= LAYOUTS =================

  Widget _buildMobileLayout(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Container(
        height:
            MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).top -
            MediaQuery.paddingOf(context).bottom,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: _buildHeader(colorScheme, isCompact: true),
            ),
            _buildPinIndicators(colorScheme),
            const SizedBox(height: 32),
            _buildNumberPad(colorScheme, buttonSize: 72),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(ColorScheme colorScheme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                  child: _buildHeader(colorScheme, isCompact: false),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPinIndicators(colorScheme),
                      const SizedBox(height: 48),
                      _buildNumberPad(colorScheme, buttonSize: 64),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ColorScheme colorScheme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 650),
        child: Card(
          elevation: 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.2),
                        colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                    ),
                  ),
                  child: _buildHeader(colorScheme, isCompact: false),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPinIndicators(colorScheme),
                      const SizedBox(height: 56),
                      _buildNumberPad(colorScheme, buttonSize: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(ColorScheme colorScheme, {required bool isCompact}) {
    final logoSize = isCompact ? 140.0 : 180.0;
    final titleSize = isCompact ? 24.0 : 28.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/suki_pos_logo_transparent.png',
            width: logoSize,
          ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
          const SizedBox(height: 24),
          Text(
            'Welcome Back',
            style: GoogleFonts.poppins(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Enter your 6-digit PIN to access SukiPOS',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 600.ms),
          if (_isVerifying)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }

  // ================= PIN DOTS =================
  Widget _buildPinIndicators(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pin.length;
        return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isFilled
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: 2,
                ),
                boxShadow: isFilled
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
            )
            .animate(target: isFilled ? 1 : 0)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.1, 1.1),
              curve: Curves.elasticOut,
            );
      }),
    ).animate().fadeIn(delay: 800.ms);
  }

  // ================= NUMBER PAD =================
  Widget _buildNumberPad(ColorScheme colorScheme, {double buttonSize = 80}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPadRow(['1', '2', '3'], colorScheme, buttonSize),
        _buildPadRow(['4', '5', '6'], colorScheme, buttonSize),
        _buildPadRow(['7', '8', '9'], colorScheme, buttonSize),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: buttonSize, height: buttonSize),
              _buildNumberButton('0', colorScheme, buttonSize),
              _buildDeleteButton(colorScheme, buttonSize),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1);
  }

  Widget _buildPadRow(
    List<String> digits,
    ColorScheme colorScheme,
    double buttonSize,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits
            .map((d) => _buildNumberButton(d, colorScheme, buttonSize))
            .toList(),
      ),
    );
  }

  Widget _buildNumberButton(
    String digit,
    ColorScheme colorScheme,
    double buttonSize,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              digit,
              style: GoogleFonts.poppins(
                fontSize: buttonSize * 0.35,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ColorScheme colorScheme, double buttonSize) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onDeletePressed,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: colorScheme.primary,
              size: buttonSize * 0.35,
            ),
          ),
        ),
      ),
    );
  }

  // ================= SUCCESS VIEW =================
  Widget _buildSuccessView(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: colorScheme.primary,
                    size: 80,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .shake(duration: 400.ms),
            const SizedBox(height: 40),
            Text(
              'Authorized',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              'Welcome to SukiPOS',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
