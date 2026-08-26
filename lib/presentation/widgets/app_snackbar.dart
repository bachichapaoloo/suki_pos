import 'package:flutter/material.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

/// Legacy AppSnackBar class - now forwards directly to [AppToast] for modern Toastification notifications.
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message, {String? title}) {
    AppToast.showSuccess(context, message: message, title: title);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    AppToast.showError(context, message: message, title: title);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    AppToast.showInfo(context, message: message, title: title);
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    AppToast.showWarning(context, message: message, title: title);
  }
}
