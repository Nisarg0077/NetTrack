import 'package:flutter/material.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;

/// An authentic Apple & Liquid Glass inspired modal dialog.
class GlassDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double blur;

  const GlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.blur = 24.0,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 240),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
      pageBuilder: (context, _, __) {
        return GlassDialog(
          title: title,
          content: content,
          actions: actions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = BorderRadius.circular(24);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, minWidth: 280),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: fusion.GlassSurface(
            borderRadius: r,
            elevation: 4,
            blur: blur,
            useBackdropFilter: true,
            padding: const EdgeInsets.all(22),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color:
                            isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                      child: title!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (content != null) ...[
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? const Color(0xFFD1D1D6)
                            : const Color(0xFF3C3C43),
                      ),
                      child: content!,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (actions != null && actions!.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < actions!.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          actions![i],
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An authentic Apple Liquid Glass modal bottom sheet.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double blur;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.blur = 28.0,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GlassBottomSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const r = BorderRadius.vertical(top: Radius.circular(28));

    return fusion.GlassSurface(
      borderRadius: r,
      elevation: 4,
      blur: blur,
      useBackdropFilter: true,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // Apple Grab Handle
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Flexible(child: child),
        ],
      ),
    );
  }
}
