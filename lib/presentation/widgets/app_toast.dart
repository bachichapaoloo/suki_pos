import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:suki_pos/core/services/feedback_service.dart';

/// Centralized notification service leveraging `toastification` with modern aesthetics.
class AppToast {
  AppToast._();

  /// Show a modern success toast notification.
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    FeedbackService.success();
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(
        title ?? 'Success',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      description: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
      ),
      alignment: isDesktop ? Alignment.topRight : Alignment.topCenter,
      autoCloseDuration: duration,
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
      ),
    );
  }

  /// Show a modern error toast notification.
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    FeedbackService.error();
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(
        title ?? 'Action Failed',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      description: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
      ),
      alignment: isDesktop ? Alignment.topRight : Alignment.topCenter,
      autoCloseDuration: duration,
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error_rounded, color: Color(0xFFDC2626), size: 20),
      ),
    );
  }

  /// Show a modern warning toast notification.
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    FeedbackService.warning();
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flat,
      title: Text(
        title ?? 'Notice',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      description: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
      ),
      alignment: isDesktop ? Alignment.topRight : Alignment.topCenter,
      autoCloseDuration: duration,
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.warning_rounded, color: Color(0xFFD97706), size: 20),
      ),
    );
  }

  /// Show a modern info toast notification.
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    FeedbackService.tap();
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(
        title ?? 'Information',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      description: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
      ),
      alignment: isDesktop ? Alignment.topRight : Alignment.topCenter,
      autoCloseDuration: duration,
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.info_rounded, color: Color(0xFF0284C7), size: 20),
      ),
    );
  }
}
