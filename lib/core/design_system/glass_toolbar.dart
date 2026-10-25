import 'package:flutter/material.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;
import '../platform/platform_service.dart';

/// A modern, adaptive Liquid Glass toolbar.
///
/// On Mobile / Android: Renders as a floating stadium capsule over the content.
/// On Desktop: Renders as a refined macOS translucent top toolbar.
class GlassToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final Widget? statusWidget;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? bottom;
  final double bottomHeight;
  final bool isFloating;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onSearchTap;
  final bool useSafeArea;

  const GlassToolbar({
    super.key,
    this.title = '',
    this.titleWidget,
    this.statusWidget,
    this.actions = const [],
    this.leading,
    this.bottom,
    this.bottomHeight = 0.0,
    this.isFloating = true,
    this.margin,
    this.onSearchTap,
    this.useSafeArea = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        (PlatformService.isDesktop ? 54.0 : 58.0) + bottomHeight,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isDesktop = PlatformService.isDesktop;

    Widget mainRow = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16,
        vertical: isDesktop ? 8 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Leading + Title + Status Pill
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: titleWidget ??
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                ),
                if (statusWidget != null) ...[
                  const SizedBox(width: 10),
                  statusWidget!,
                ],
              ],
            ),
          ),

          // Right: Action pills
          if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  actions[i],
                ],
              ],
            ),
        ],
      ),
    );

    Widget fullContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainRow,
        if (bottom != null) bottom!,
      ],
    );

    // Desktop presentation: full-width translucent macOS top bar
    if (isDesktop) {
      Widget desktopBar = fusion.GlassSurface(
        borderRadius: BorderRadius.zero,
        blur: 20,
        elevation: 0,
        useBackdropFilter: true,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.85,
              ),
            ),
          ),
          child: fullContent,
        ),
      );
      return useSafeArea
          ? SafeArea(bottom: false, child: desktopBar)
          : desktopBar;
    }

    // Mobile presentation: Floating stadium capsule
    final r = BorderRadius.circular(28);

    Widget floatingBar = Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: fusion.GlassSurface(
        borderRadius: r,
        elevation: 2,
        blur: 24,
        useBackdropFilter: true,
        padding: EdgeInsets.zero,
        child: fullContent,
      ),
    );

    return useSafeArea
        ? SafeArea(bottom: false, child: floatingBar)
        : floatingBar;
  }
}

/// Sliver persistent header delegate for [GlassToolbar].
class SliverGlassToolbarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  SliverGlassToolbarDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverGlassToolbarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
