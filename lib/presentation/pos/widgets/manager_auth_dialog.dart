import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/domain/repositories/auth/auth_repository.dart';
import 'package:suki_pos/injection_container.dart' as di;
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class ManagerAuthDialog extends StatefulWidget {
  final String actionTitle;
  final String reasonMessage;

  const ManagerAuthDialog({
    super.key,
    this.actionTitle = 'Supervisor Override Required',
    this.reasonMessage =
        'Please enter a 6-digit Manager / Admin PIN to authorize this action.',
  });

  /// Checks if the current user already has Admin/Manager permissions.
  /// If not, opens the [ManagerAuthDialog] and returns true only if authorized.
  static Future<bool> verify(
    BuildContext context, {
    String actionTitle = 'Supervisor Override Required',
    String reasonMessage =
        'Please enter a 6-digit Manager / Admin PIN to authorize this action.',
  }) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.canAdminMode) {
      return true;
    }

    final authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManagerAuthDialog(
        actionTitle: actionTitle,
        reasonMessage: reasonMessage,
      ),
    );
    return authorized ?? false;
  }

  @override
  State<ManagerAuthDialog> createState() => _ManagerAuthDialogState();
}

class _ManagerAuthDialogState extends State<ManagerAuthDialog> {
  String _pin = '';
  bool _isVerifying = false;
  String? _errorText;
  final FocusNode _keyboardFocus = FocusNode();

  static const Color _primaryBlue = Color(0xFF355C8F);
  static const Color _textDark = Color(0xFF1E293B);

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_isVerifying || _pin.length >= 6) return;
    FeedbackService.tap();
    setState(() {
      _errorText = null;
      _pin += digit;
    });
    if (_pin.length == 6) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_isVerifying || _pin.isEmpty) return;
    FeedbackService.tap();
    setState(() {
      _errorText = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClear() {
    if (_isVerifying || _pin.isEmpty) return;
    FeedbackService.tap();
    setState(() {
      _errorText = null;
      _pin = '';
    });
  }

  Future<void> _verifyPin() async {
    if (_pin.length != 6) return;
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final result = await di.sl<AuthRepository>().verifyManagerPin(_pin);
    if (!mounted) return;

    result.fold(
      (failure) {
        FeedbackService.error();
        setState(() {
          _isVerifying = false;
          _pin = '';
          _errorText = 'Invalid Manager PIN or insufficient permissions';
        });
      },
      (manager) {
        FeedbackService.success();
        AppToast.showSuccess(
          context,
          title: 'Supervisor Authorized',
          message: 'Approved by ${manager.name}',
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(false);
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
      _onDigit(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFFD97706),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.actionTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.reasonMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // 6-Dot PIN Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? _primaryBlue
                            : const Color(0xFFE2E8F0),
                        border: Border.all(
                          color: isFilled
                              ? _primaryBlue
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    );
                  }),
                ),

                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Touch Numpad
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: 10),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: 10),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionKey(
                        label: 'CLR',
                        onTap: _onClear,
                        textColor: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDigitKey('0')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildIconKey(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isVerifying
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      children: [
        Expanded(child: _buildDigitKey(digits[0])),
        const SizedBox(width: 10),
        Expanded(child: _buildDigitKey(digits[1])),
        const SizedBox(width: 10),
        Expanded(child: _buildDigitKey(digits[2])),
      ],
    );
  }

  Widget _buildDigitKey(String digit) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _onDigit(digit),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            digit,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required String label,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconKey({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF475569)),
        ),
      ),
    );
  }
}
