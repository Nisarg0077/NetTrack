import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Authentic Apple floating pill header bar.
///
/// Features:
/// - Floating stadium pill capsule with optical frosted glass blur
/// - Specular hairline highlight rim and layered floating depth shadow
/// - Crisp typography with optical tracking
/// - Action pill buttons with spring press feedback
/// - Animated pulsing live beacon status pill
class AppleTopBar extends StatelessWidget {
  final String title;
  final Widget? statusWidget;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBottomBorder;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final bool isFloating;
  final bool useSafeArea;

  const AppleTopBar({
    super.key,
    required this.title,
    this.statusWidget,
    this.actions = const [],
    this.leading,
    this.showBottomBorder = false,
    this.margin,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.isFloating = true,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = BorderRadius.circular(30);

    Widget content = Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Leading (e.g. back button) + Title + Status Pill
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                if (statusWidget != null) ...[
                  const SizedBox(width: 8),
                  statusWidget!,
                ],
              ],
            ),
          ),

          // Right: Action buttons
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

    if (!isFloating) {
      return useSafeArea ? SafeArea(bottom: false, child: content) : content;
    }

    Widget bar = Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: r,
                color:
                    isDark ? const Color(0xCC161822) : const Color(0xDDFFFFFF),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.85,
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );

    return useSafeArea ? SafeArea(bottom: false, child: bar) : bar;
  }
}

/// An Apple sticky header sliver delegate.
///
/// Features:
/// - Stays pinned gracefully at the top of a [CustomScrollView].
/// - When content scrolls underneath, smoothly transitions from transparent to an optical frosted glass blur scrim with specular bottom hairline.
/// - Covers status bar / notch area seamlessly while child content stays safely below it.
class AppleStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  final bool showBottomBorder;

  AppleStickyHeaderDelegate({
    required this.height,
    required this.child,
    this.showBottomBorder = true,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isScrolled = shrinkOffset > 2 || overlapsContent;

    return SizedBox(
      height: height,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: isScrolled ? 24.0 : 0.001,
            sigmaY: isScrolled ? 24.0 : 0.001,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isScrolled
                  ? (isDark ? const Color(0xCC0E1119) : const Color(0xCCF7F8FA))
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isScrolled && showBottomBorder
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06))
                      : Colors.transparent,
                  width: 0.85,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant AppleStickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.showBottomBorder != showBottomBorder;
  }
}

/// An Apple macOS & iOS styled floating pill action button.
class AppleBarButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const AppleBarButton({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<AppleBarButton> createState() => _AppleBarButtonState();
}

class _AppleBarButtonState extends State<AppleBarButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    Color bg;
    Border? border;

    if (widget.isPrimary) {
      bg = primaryColor.withValues(
          alpha: _isPressed ? 0.85 : (_isHovered ? 0.95 : 1.0));
      border = null;
    } else {
      bg = isDark
          ? (_isHovered ? const Color(0xFF2C2F3B) : const Color(0xFF21232C))
              .withValues(alpha: 0.90)
          : (_isHovered ? const Color(0xFFE2E4E9) : const Color(0xFFEDEDF2))
              .withValues(alpha: 0.90);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: _isHovered ? 0.20 : 0.10)
            : Colors.black.withValues(alpha: 0.06),
        width: 0.8,
      );
    }

    final textColor = widget.isPrimary
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1C1C1E));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.label != null ? 12 : 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20), // Apple Stadium Pill
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: textColor),
                if (widget.label != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An Apple status badge pill with optional live pulsing beacon dot.
class AppleStatusPill extends StatefulWidget {
  final String label;
  final bool isLive;
  final Color? color;

  const AppleStatusPill({
    super.key,
    required this.label,
    this.isLive = false,
    this.color,
  });

  @override
  State<AppleStatusPill> createState() => _AppleStatusPillState();
}

class _AppleStatusPillState extends State<AppleStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isLive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AppleStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isLive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dotColor = widget.color ?? const Color(0xFF34C759); // Apple Green

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22242D) : const Color(0xFFE8E9EF),
        borderRadius: BorderRadius.circular(20), // Apple Stadium Pill
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLive) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(
                            alpha: _pulseAnimation.value * 0.7),
                        blurRadius: 6 * _pulseAnimation.value,
                        spreadRadius: 1 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C),
            ),
          ),
        ],
      ),
    );
  }
}
