import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// An authentic Apple-grade Frosted Glass Card with optical backdrop blur,
/// specular hairline highlights, soft layered depth shadows, and interactive spring feedback.
class FrostedGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final double shaderIntensity; // Kept for compatibility
  final double fluidViscosity; // Kept for compatibility
  final bool interactive;
  final VoidCallback? onTap;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.padding = const EdgeInsets.all(20.0),
    this.blur = 20.0,
    this.color,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
    this.shaderIntensity = 0.45,
    this.fluidViscosity = 0.85,
    this.interactive = false,
    this.onTap,
  });

  @override
  State<FrostedGlassCard> createState() => _FrostedGlassCardState();
}

class _FrostedGlassCardState extends State<FrostedGlassCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = BorderRadius.circular(widget.borderRadius);

    final Color tint =
        widget.color ?? (isDark ? const Color(0xFF141722) : Colors.white);

    // Apple Specular Edge Rim (Crisp hairline reflection)
    final effectiveBorder = widget.border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: _isHovered ? 0.18 : 0.10)
              : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.06),
          width: 0.85,
        );

    // Apple Layered Depth Ambient Shadows
    final effectiveShadows = widget.boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.05),
            blurRadius: _isHovered ? 28 : 18,
            spreadRadius: -2,
            offset: Offset(0, _isHovered ? 10 : 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ];

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        tint.withValues(alpha: 0.65),
                        tint.withValues(alpha: 0.50),
                      ]
                    : [
                        tint.withValues(alpha: 0.85),
                        tint.withValues(alpha: 0.72),
                      ],
              ),
              border: effectiveBorder,
            ),
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.interactive || widget.onTap != null) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor:
            widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.985 : (_isHovered ? 1.008 : 1.0),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
