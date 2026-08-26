import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/presentation/widgets/hotkey_badge.dart';

/// A unified, responsive top header / app bar that provides a consistent layout,
/// typography, intelligent back navigation, breadcrumbs, and action slots
/// across small (mobile) and wide (desktop/tablet) screens without UI overflows.
class AppUnifiedHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppUnifiedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.parentHubTitle,
    this.parentHubRoute,
    this.onBackPressed,
    this.showBackButton = true,
    this.actions = const [],
    this.searchWidget,
    this.badge,
    this.leading,
    this.bottom,
    this.height = 68,
  });

  final String title;
  final String? subtitle;
  final String? parentHubTitle;
  final String? parentHubRoute;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final List<Widget> actions;
  final Widget? searchWidget;
  final Widget? badge;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double height;

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  Size get preferredSize => Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  void _handleBack(BuildContext context) {
    FeedbackService.tap();
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (parentHubRoute != null) {
      Navigator.of(context).pushReplacementNamed(parentHubRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height - 1.0, // Deduct 1.0px to perfectly accommodate the 1.0px bottom border
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 12),
                child: isDesktop
                    ? _buildDesktopHeader(context, colorScheme)
                    : _buildMobileHeader(context, colorScheme),
              ),
            ),
            if (bottom != null) bottom!,
            // Bottom 1px Divider within allocated bounds
            Container(
              height: 1.0,
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, ColorScheme colorScheme) {
    final canGoBack =
        showBackButton && (Navigator.of(context).canPop() || parentHubRoute != null || onBackPressed != null);

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ] else if (canGoBack) ...[
          // Breadcrumb / Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleBack(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 20, color: colorScheme.primary),
                    if (parentHubTitle != null) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          parentHubTitle!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    const HotkeyBadge(label: 'Esc', fontSize: 10),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 22, color: colorScheme.outlineVariant),
          const SizedBox(width: 12),
        ],

        // Title and Subtitle with flexible constraints to prevent right-edge overflow
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    badge!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Optional Search Widget
        if (searchWidget != null) ...[
          Flexible(
            flex: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: searchWidget!,
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Actions slot wrapped with mainAxisSize.min to avoid expansion overflows
        if (actions.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions.map((act) => Padding(padding: const EdgeInsets.only(left: 6.0), child: act)).toList(),
          ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context, ColorScheme colorScheme) {
    final canGoBack =
        showBackButton && (Navigator.of(context).canPop() || parentHubRoute != null || onBackPressed != null);

    return Row(
      children: [
        if (leading != null)
          leading!
        else if (canGoBack)
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.primary, size: 22),
            onPressed: () => _handleBack(context),
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            visualDensity: VisualDensity.compact,
          )
        else
          const SizedBox(width: 2),

        const SizedBox(width: 4),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    badge!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        if (actions.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions.map((act) => Padding(padding: const EdgeInsets.only(left: 2.0), child: act)).toList(),
          ),
      ],
    );
  }
}
