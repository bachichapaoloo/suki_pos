import 'package:flutter/services.dart';

/// Centralized service for tactile feedback (haptics and audio chimes) across POS operations.
class FeedbackService {
  FeedbackService._();

  /// Subtle click feedback for buttons, chips, and list selections.
  static void tap() {
    HapticFeedback.selectionClick();
  }

  /// Feedback for adding an item or successful barcode scan.
  static void scan() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Feedback for completing a sale or saving master data.
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// Feedback for validation errors or warnings.
  static void warning() {
    HapticFeedback.lightImpact();
  }

  /// Feedback for transaction failure or critical error.
  static void error() {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }
}
