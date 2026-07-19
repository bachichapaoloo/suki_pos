import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _primaryBlue = Color(0xFF4A6B97); // Same as store icon
  static const Color _darkBlue = Color(0xFF1E293B); // Darker blue for text
  static const Color _bgGrey = Color(0xFFF8FAFC);
  static const Color _dotEmpty = Color(0xFFCBD5E1);
  static const Color _dotFilled = Color(0xFF94A3B8);

  String _pin = '';
  bool _isSuccess = false;

  void _onDigitPressed(String digit) {
    if (_pin.length < 6) {
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        _pin += digit;
      });
      // Auto-submit on 6th digit
      if (_pin.length == 6) {
        _onEnterPressed();
      }
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
    if (_pin.length == 6) {
      context.read<AuthBloc>().add(LoginEvent(_pin));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          final navigator = Navigator.of(context);
          unawaited(HapticFeedback.mediumImpact());
          setState(() {
            _isSuccess = true;
          });
          await Future<void>.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            unawaited(navigator.pushReplacementNamed('/pos'));
          }
        } else if (state is AuthError) {
          unawaited(HapticFeedback.vibrate());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _pin = '';
          });
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout() {
    return Container(
      color: _bgGrey,
      child: SafeArea(
        child: _isSuccess ? _buildSuccessView() : _buildLoginContent(isDesktop: false),
      ),
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)], // Soft blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: _isSuccess
            ? _buildSuccessView()
            : Container(
                width: 550,
                height: 820,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.05),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: _buildLoginContent(isDesktop: true),
              ),
      ),
    );
  }

  Widget _buildLoginContent({required bool isDesktop}) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isDesktop ? 48 : 0),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 40,
                ),
              ).animate().fade().scale(),
              const SizedBox(height: 24),
              Text(
                'SukiPOS',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _darkBlue,
                ),
              ).animate().fade().slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF475569),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fade().slideY(begin: 0.2),
              const SizedBox(height: 48),
              _buildPinDots().animate().fade().scale(),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildPinPad(isDesktop: isDesktop),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (index) {
          bool isFilled = index < _pin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? _dotFilled : _dotEmpty,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPinPad({required bool isDesktop}) {
    const bgColor = Color(0xFFEEEEEE);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isDesktop
            ? const BorderRadius.vertical(bottom: Radius.circular(32))
            : const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPadRow(['1', '2', '3'], isDesktop),
          _buildPadRow(['4', '5', '6'], isDesktop),
          _buildPadRow(['7', '8', '9'], isDesktop),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.fingerprint, () {}, isDesktop),
                _buildNumberButton('0', isDesktop),
                _buildActionButton(Icons.backspace_outlined, _onDeletePressed, isDesktop),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildPadRow(List<String> numbers, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: numbers.map((n) => _buildNumberButton(n, isDesktop)).toList(),
      ),
    );
  }

  Widget _buildNumberButton(String number, bool isDesktop) {
    return InkWell(
      onTap: () => _onDigitPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isDesktop ? Colors.white : Colors.white,
          shape: BoxShape.circle,
          boxShadow: isDesktop
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, bool isDesktop) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(
            icon,
            size: 32,
            color: _darkBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 64,
            ),
          ).animate().scale(
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 24),
          Text(
            'Success',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ).animate().fade().slideY(),
        ],
      ),
    );
  }
}
