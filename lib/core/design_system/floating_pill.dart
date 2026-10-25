import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// A reusable floating glass pill surface.
class FloatingPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? activeColor;
  final bool enableBlur;
  final double blur;

  const FloatingPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.onTap,
    this.isSelected = false,
    this.activeColor,
    this.enableBlur = true,
    this.blur = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = activeColor ?? theme.colorScheme.primary;

    final Color bgColor = isSelected
        ? primary
        : (isDark
            ? const Color(0xFF1E212B)
                .withValues(alpha: enableBlur ? 0.70 : 0.95)
            : Colors.white.withValues(alpha: enableBlur ? 0.80 : 0.95));

    final border = Border.all(
      color: isSelected
          ? primary.withValues(alpha: 0.9)
          : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08)),
      width: 0.85,
    );

    final shadows = [
      BoxShadow(
        color: isSelected
            ? primary.withValues(alpha: isDark ? 0.40 : 0.28)
            : Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
        blurRadius: isSelected ? 12 : 8,
        offset: const Offset(0, 3),
      ),
    ];

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: content,
      );
    }

    return content;
  }
}

/// A compact, interactive pill action button inspired by modern Apple and ChatGPT interfaces.
class FloatingActionPill extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final Color? color;
  final bool isCompact;
  final double? iconSize;

  const FloatingActionPill({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.color,
    this.isCompact = false,
    this.iconSize,
  });

  @override
  State<FloatingActionPill> createState() => _FloatingActionPillState();
}

class _FloatingActionPillState extends State<FloatingActionPill> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    Border? border;

    if (widget.isPrimary) {
      final pColor = widget.color ?? theme.colorScheme.primary;
      bg = pColor.withValues(
          alpha: _isPressed ? 0.82 : (_isHovered ? 0.95 : 1.0));
      fg = Colors.white;
      border = null;
    } else if (widget.isDestructive) {
      final dColor = theme.colorScheme.error;
      bg = dColor.withValues(
          alpha: _isPressed ? 0.20 : (_isHovered ? 0.15 : 0.10));
      fg = dColor;
      border = Border.all(
        color: dColor.withValues(alpha: 0.3),
        width: 0.8,
      );
    } else {
      bg = isDark
          ? (_isHovered ? const Color(0xFF2C2F3D) : const Color(0xFF1E212B))
              .withValues(alpha: 0.85)
          : (_isHovered ? const Color(0xFFE8E9EF) : Colors.white)
              .withValues(alpha: 0.88);
      fg = isDark ? Colors.white : const Color(0xFF1C1C1E);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: _isHovered ? 0.18 : 0.10)
            : Colors.black.withValues(alpha: _isHovered ? 0.10 : 0.06),
        width: 0.85,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.93 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: widget.label != null
                ? EdgeInsets.symmetric(
                    horizontal: widget.isCompact ? 10 : 13,
                    vertical: widget.isCompact ? 4.5 : 6.0,
                  )
                : EdgeInsets.all(widget.isCompact ? 6.0 : 7.5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: widget.iconSize ??
                      (widget.label == null
                          ? (widget.isCompact ? 16 : 18)
                          : (widget.isCompact ? 13 : 15)),
                  color: fg,
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 5.5),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.2,
                      color: fg,
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

/// A live connection & telemetry pill status badge.
class ConnectionStatusPill extends StatefulWidget {
  final String label;
  final bool isLive;
  final Color? color;
  final String? interfaceName;
  final IconData? icon;

  const ConnectionStatusPill({
    super.key,
    required this.label,
    this.isLive = true,
    this.color,
    this.interfaceName,
    this.icon,
  });

  @override
  State<ConnectionStatusPill> createState() => _ConnectionStatusPillState();
}

class _ConnectionStatusPillState extends State<ConnectionStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isLive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ConnectionStatusPill oldWidget) {
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
    final dotColor = widget.color ?? AppColors.success;

    Color bgColor;
    Color fgColor;
    Border border;

    if (widget.isLive) {
      bgColor = isDark
          ? const Color(0xFF1E212B).withValues(alpha: 0.8)
          : const Color(0xFFEDEDF2).withValues(alpha: 0.85);
      fgColor = isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06),
        width: 0.8,
      );
    } else if (widget.color != null) {
      bgColor = widget.color!.withValues(alpha: isDark ? 0.20 : 0.10);
      fgColor = widget.color!;
      border = Border.all(
        color: widget.color!.withValues(alpha: isDark ? 0.38 : 0.25),
        width: 0.8,
      );
    } else {
      bgColor = isDark
          ? const Color(0xFF1E212B).withValues(alpha: 0.8)
          : const Color(0xFFEDEDF2).withValues(alpha: 0.85);
      fgColor = isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06),
        width: 0.8,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
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
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 12, color: fgColor),
            const SizedBox(width: 4.5),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              height: 1.2,
              color: fgColor,
            ),
          ),
          if (widget.interfaceName != null &&
              widget.interfaceName!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '• ${widget.interfaceName}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
