import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/utils/responsive_layout.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';

/// The login page of the application where users enter their PIN.
class LoginPage extends StatefulWidget {
  /// Creates a [LoginPage].
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _pin = '';
  bool _isSuccess = false;

  void _onDigitPressed(String digit) {
    if (_pin.length < 12) {
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        _pin += digit;
      });
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onEnterPressed() {
    if (_pin.isNotEmpty) {
      context.read<AuthBloc>().add(LoginEvent(_pin));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSuccess) {
      return _buildSuccessView(colorScheme);
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          final navigator = Navigator.of(context);
          unawaited(HapticFeedback.mediumImpact());
          setState(() {
            _isSuccess = true;
          });
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) {
            unawaited(navigator.pushReplacementNamed('/pos'));
          }
        } else if (state is AuthError) {
          unawaited(HapticFeedback.vibrate());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _pin = '';
          });
        }
      },
      child: Scaffold(
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
            _buildPinDisplay(colorScheme),
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
                      _buildPinDisplay(colorScheme),
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
                      _buildPinDisplay(colorScheme),
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
            'Enter your PIN to access SukiPOS',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 600.ms),
          context.watch<AuthBloc>().state is AuthLoading
              ? Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.primary,
                    ),
                  ),
                ).animate().fadeIn()
              : const SizedBox(height: 56),
        ],
      ),
    );
  }

  // ================= PIN DISPLAY =================
  Widget _buildPinDisplay(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _pin.isEmpty ? 'Enter PIN' : '• ' * _pin.length,
        style: GoogleFonts.poppins(
          fontSize: 24,
          letterSpacing: 8,
          fontWeight: FontWeight.bold,
          color: _pin.isEmpty ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : colorScheme.primary,
        ),
      ),
    ).animate(target: _pin.isNotEmpty ? 1 : 0).shimmer();
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
              _buildDeleteButton(colorScheme, buttonSize),
              _buildNumberButton('0', colorScheme, buttonSize),
              _buildEnterButton(colorScheme, buttonSize),
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
        children: digits.map((d) => _buildNumberButton(d, colorScheme, buttonSize)).toList(),
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
              color: colorScheme.error.withValues(alpha: 0.7),
              size: buttonSize * 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnterButton(ColorScheme colorScheme, double buttonSize) {
    final isLoading = context.watch<AuthBloc>().state is AuthLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : _onEnterPressed,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.login_rounded,
              color: Colors.white,
              size: 32,
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
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).then().shake(duration: 400.ms),
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
