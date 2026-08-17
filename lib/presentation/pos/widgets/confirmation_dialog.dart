import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum DialogVariant { info, warning, danger, success }

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    required this.title,
    super.key,
    this.message,
    this.body,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.variant = DialogVariant.info,
    this.showConfirm = true,
    this.showCancel = true,
    this.showCloseButton = false,
    this.showDividers = true,
    this.showIcon = true,
    this.confirmColor,
    this.isLoading = false,
    this.icon,
    this.enableKeyboardShortcuts = true,
    this.titleAlignment = TextAlign.left,
    this.contentAlignment = TextAlign.left,
    this.actionsAlignment = MainAxisAlignment.end,
    this.headerPadding = const EdgeInsets.fromLTRB(20, 16, 16, 16),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.actionsPadding = const EdgeInsets.fromLTRB(20, 14, 20, 16),
    this.width,
    this.height,
    this.minWidth = 300,
    this.maxWidth = 480,
    this.minHeight = 0,
    this.maxHeight,
    this.constraints,
  });

  // --- Semantic Named Constructors ---
  const ConfirmationDialog.danger({
    required this.title,
    super.key,
    this.message,
    this.body,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.showConfirm = true,
    this.showCancel = true,
    this.showCloseButton = false,
    this.showDividers = true,
    this.showIcon = true,
    this.confirmColor,
    this.isLoading = false,
    this.icon,
    this.enableKeyboardShortcuts = true,
    this.titleAlignment = TextAlign.left,
    this.contentAlignment = TextAlign.left,
    this.actionsAlignment = MainAxisAlignment.end,
    this.headerPadding = const EdgeInsets.fromLTRB(20, 16, 16, 16),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.actionsPadding = const EdgeInsets.fromLTRB(20, 14, 20, 16),
    this.width,
    this.height,
    this.minWidth = 300,
    this.maxWidth = 480,
    this.minHeight = 0,
    this.maxHeight,
    this.constraints,
  }) : variant = DialogVariant.danger;

  const ConfirmationDialog.warning({
    required this.title,
    super.key,
    this.message,
    this.body,
    this.confirmLabel = 'Proceed',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.showConfirm = true,
    this.showCancel = true,
    this.showCloseButton = false,
    this.showDividers = true,
    this.showIcon = true,
    this.confirmColor,
    this.isLoading = false,
    this.icon,
    this.enableKeyboardShortcuts = true,
    this.titleAlignment = TextAlign.left,
    this.contentAlignment = TextAlign.left,
    this.actionsAlignment = MainAxisAlignment.end,
    this.headerPadding = const EdgeInsets.fromLTRB(20, 16, 16, 16),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.actionsPadding = const EdgeInsets.fromLTRB(20, 14, 20, 16),
    this.width,
    this.height,
    this.minWidth = 300,
    this.maxWidth = 480,
    this.minHeight = 0,
    this.maxHeight,
    this.constraints,
  }) : variant = DialogVariant.warning;

  final String title;
  final String? message;
  final Widget? body;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final DialogVariant variant;
  final bool showConfirm;
  final bool showCancel;
  final bool showCloseButton;
  final bool showDividers;
  final bool showIcon;
  final Color? confirmColor;
  final bool isLoading;
  final IconData? icon;
  final bool enableKeyboardShortcuts;

  // Alignments
  final TextAlign titleAlignment;
  final TextAlign contentAlignment;
  final MainAxisAlignment actionsAlignment;

  // Dynamic Paddings
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;

  // Dynamic Sizing & Constraints
  final double? width;
  final double? height;
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double? maxHeight;
  final BoxConstraints? constraints;

  // --- Static Helper for Quick Invocation ---
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    DialogVariant variant = DialogVariant.info,
    bool showConfirm = true,
    bool showCancel = true,
    bool showCloseButton = false,
    bool showDividers = true,
    bool showIcon = true,
    Color? confirmColor,
    IconData? icon,
    bool barrierDismissible = false,
    bool enableKeyboardShortcuts = true,
    TextAlign titleAlignment = TextAlign.left,
    TextAlign contentAlignment = TextAlign.left,
    MainAxisAlignment actionsAlignment = MainAxisAlignment.end,
    EdgeInsetsGeometry headerPadding = const EdgeInsets.fromLTRB(20, 16, 16, 16),
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    EdgeInsetsGeometry actionsPadding = const EdgeInsets.fromLTRB(20, 14, 20, 16),
    double? width,
    double? height,
    double minWidth = 300,
    double maxWidth = 480,
    double minHeight = 0,
    double? maxHeight,
    BoxConstraints? constraints,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        message: message,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        variant: variant,
        showConfirm: showConfirm,
        showCancel: showCancel,
        showCloseButton: showCloseButton,
        showDividers: showDividers,
        showIcon: showIcon,
        confirmColor: confirmColor,
        icon: icon,
        titleAlignment: titleAlignment,
        contentAlignment: contentAlignment,
        actionsAlignment: actionsAlignment,
        headerPadding: headerPadding,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
        width: width,
        height: height,
        minWidth: minWidth,
        maxWidth: maxWidth,
        minHeight: minHeight,
        maxHeight: maxHeight,
        constraints: constraints,
        enableKeyboardShortcuts: enableKeyboardShortcuts,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  Color _resolvePrimaryColor(ColorScheme colorScheme) {
    if (confirmColor != null) return confirmColor!;
    switch (variant) {
      case DialogVariant.danger:
        return Colors.red.shade600;
      case DialogVariant.warning:
        return Colors.amber.shade800;
      case DialogVariant.success:
        return Colors.green.shade600;
      case DialogVariant.info:
        return colorScheme.primary;
    }
  }

  IconData _resolveIcon() {
    if (icon != null) return icon!;
    switch (variant) {
      case DialogVariant.danger:
        return Icons.warning_amber_rounded;
      case DialogVariant.warning:
        return Icons.error_outline_rounded;
      case DialogVariant.success:
        return Icons.check_circle_outline_rounded;
      case DialogVariant.info:
        return Icons.help_outline_rounded;
    }
  }

  Alignment _resolveAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
      default:
        return Alignment.centerLeft;
    }
  }

  void _handleConfirm(BuildContext context) {
    if (isLoading || !showConfirm) return;
    if (onConfirm != null) {
      onConfirm!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _handleCancel(BuildContext context) {
    if (isLoading) return;
    if (onCancel != null) {
      onCancel!();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryActionColor = _resolvePrimaryColor(colorScheme);

    final effectiveConstraints =
        constraints ??
        BoxConstraints(
          minWidth: width ?? minWidth,
          maxWidth: width ?? maxWidth,
          minHeight: height ?? minHeight,
          maxHeight: height ?? (maxHeight ?? MediaQuery.sizeOf(context).height * 0.85),
        );

    final isFixedHeight =
        height != null ||
        (constraints != null && constraints!.hasBoundedHeight && constraints!.minHeight == constraints!.maxHeight);

    final hasActions = showCancel || showConfirm;

    final dialogContent = Center(
      child: Dialog(
        elevation: 6,
        backgroundColor: colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: effectiveConstraints,
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              mainAxisSize: isFixedHeight ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Icon + Title + Optional Close Button)
                Padding(
                  padding: headerPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showIcon) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryActionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_resolveIcon(), color: primaryActionColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          textAlign: titleAlignment,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (showCloseButton && !isLoading) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Close',
                          color: colorScheme.onSurfaceVariant,
                          onPressed: () => _handleCancel(context),
                        ),
                      ],
                    ],
                  ),
                ),

                // Top Divider
                if (showDividers)
                  Divider(
                    indent: 12,
                    endIndent: 12,
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),

                // 2. Content Body with Dynamic Padding & Scroll Safety
                if (isFixedHeight)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: contentPadding,
                      child: _buildBodyContent(colorScheme),
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: contentPadding,
                      child: _buildBodyContent(colorScheme),
                    ),
                  ),

                // Bottom Divider
                if (hasActions && showDividers)
                  Divider(
                    indent: 12,
                    endIndent: 12,
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),

                // 3. Actions Footer (Cancel / Confirm)
                if (hasActions)
                  Padding(
                    padding: actionsPadding,
                    child: Row(
                      mainAxisAlignment: actionsAlignment,
                      children: [
                        if (showCancel) ...[
                          OutlinedButton(
                            onPressed: isLoading ? null : () => _handleCancel(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              side: BorderSide(color: colorScheme.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              cancelLabel,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (showConfirm) const SizedBox(width: 10),
                        ],
                        if (showConfirm)
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _handleConfirm(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryActionColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: primaryActionColor.withValues(alpha: 0.6),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    confirmLabel,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final guardedContent = PopScope(
      canPop: !isLoading,
      child: dialogContent,
    );

    if (!enableKeyboardShortcuts || isLoading) {
      return guardedContent;
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () => _handleConfirm(context),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () => _handleConfirm(context),
        const SingleActivator(LogicalKeyboardKey.escape): () => _handleCancel(context),
      },
      child: Focus(
        autofocus: true,
        child: guardedContent,
      ),
    );
  }

  Widget _buildBodyContent(ColorScheme colorScheme) {
    if (body != null) {
      return Align(
        alignment: _resolveAlignment(contentAlignment),
        child: body!,
      );
    }
    if (message != null) {
      return Text(
        message!,
        textAlign: contentAlignment,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
