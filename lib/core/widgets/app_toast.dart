import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;

/// A modern, high-performance floating glass toast notification system.
class AppToast {
  static OverlayEntry? _currentEntry;

  /// Shows a success toast with an emerald badge icon.
  static void success(
    BuildContext context,
    String message, {
    String? subtitle,
    IconData icon = CupertinoIcons.checkmark_circle_fill,
    Color iconColor = const Color(0xFF34C759),
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
    );
  }

  /// Shows an info toast with a sapphire or custom icon.
  static void info(
    BuildContext context,
    String message, {
    String? subtitle,
    IconData icon = CupertinoIcons.info_circle_fill,
    Color iconColor = const Color(0xFF007AFF),
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
    );
  }

  /// Shows a warning toast with an amber badge icon.
  static void warning(
    BuildContext context,
    String message, {
    String? subtitle,
    IconData icon = CupertinoIcons.exclamationmark_triangle_fill,
    Color iconColor = const Color(0xFFFF9500),
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
    );
  }

  /// Shows an error toast with a danger badge icon.
  static void error(
    BuildContext context,
    String message, {
    String? subtitle,
    IconData icon = CupertinoIcons.exclamationmark_circle_fill,
    Color iconColor = const Color(0xFFFF3B30),
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
    );
  }

  /// Core toast presenter with smooth slide-down entrance and spring physics.
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    // Dismiss existing toast if still showing
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.of(context);

    HapticFeedback.selectionClick();

    late final OverlayEntry entry;
    final animationKey = GlobalKey<_ToastOverlayWidgetState>();

    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlayWidget(
        key: animationKey,
        message: message,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        onDismissed: () {
          if (entry.mounted && _currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // Auto dismiss after specified duration
    Future.delayed(duration, () {
      if (entry.mounted && _currentEntry == entry) {
        animationKey.currentState?.dismiss();
      }
    });
  }
}

class _ToastOverlayWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onDismissed;

  const _ToastOverlayWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.onDismissed,
  });

  @override
  State<_ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<_ToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();
  }

  void dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 14,
      left: 18,
      right: 18,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: GestureDetector(
              onTap: dismiss,
              behavior: HitTestBehavior.opaque,
              child: fusion.GlassSurface(
                borderRadius: BorderRadius.circular(28),
                blur: 28,
                elevation: 4,
                useBackdropFilter: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (widget.iconColor ?? theme.colorScheme.primary)
                                .withValues(alpha: isDark ? 0.20 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              widget.icon,
                              size: 16,
                              color: widget.iconColor ??
                                  theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.subtitle != null &&
                                widget.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 1.5),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6E6E73),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
