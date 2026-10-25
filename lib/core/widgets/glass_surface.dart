import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../theme/app_radii.dart';

/// Authentic Apple macOS / iOS Frosted Glass Surface.
///
/// Hardware-adaptive multi-tier rendering:
///   - Tier A (Frosted Glass - High Fidelity): Optical backdrop blur (24px), crisp specular rim, deep layered shadow.
///   - Tier B (Smooth Acrylic - Balanced): Silky 60/120 FPS diffusion (16px blur) with specular edge rim.
///   - Tier C (Battery Saver / Low-End): Zero-shader tinted acrylic squircle with specular rim.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final Color? tintColor;
  final bool enableBlur;
  final bool forceBlur;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final bool showRefraction;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 24.0,
    this.opacity = 0.65,
    this.borderRadius,
    this.border,
    this.tintColor,
    this.enableBlur = true,
    this.forceBlur = false,
    this.padding,
    this.boxShadow,
    this.showRefraction = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadii.radiusMd;

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    } catch (_) {}

    final bool isEfficiency = themeProvider?.isEfficiencyMode ?? false;
    final bool isUltra = themeProvider?.isUltraMode ?? false;

    Widget innerChild = child;
    if (padding != null) {
      innerChild = Padding(padding: padding!, child: child);
    }

    // Apple layered ambient & depth shadows
    final effectiveShadows = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.06),
            blurRadius: isUltra ? 24 : 16,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ];

    // Apple Specular Edge Rim (Crisp hairline reflection)
    final effectiveBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: isUltra ? 0.14 : 0.10)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.85,
        );

    // Zero GPU blur shader passes when blur is disabled or efficiency mode is active:
    if ((!enableBlur || isEfficiency) && !forceBlur) {
      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? (tintColor ?? const Color(0xE615171E))
              : (tintColor ?? const Color(0xF5FFFFFF)),
          borderRadius: radius,
          border: effectiveBorder,
          boxShadow: effectiveShadows,
        ),
        child: innerChild,
      );
    }

    // Tiers A & B: Optical Backdrop Blur Diffusion
    final double effectiveSigma = isUltra ? blur : 16.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
              sigmaX: effectiveSigma, sigmaY: effectiveSigma),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        (tintColor ?? const Color(0xFF1E212B))
                            .withValues(alpha: isUltra ? 0.50 : 0.60),
                        (tintColor ?? const Color(0xFF12141A))
                            .withValues(alpha: isUltra ? 0.62 : 0.72),
                      ]
                    : [
                        (tintColor ?? Colors.white)
                            .withValues(alpha: isUltra ? 0.78 : 0.85),
                        (tintColor ?? const Color(0xFFEFF1F5))
                            .withValues(alpha: isUltra ? 0.60 : 0.70),
                      ],
              ),
              border: effectiveBorder,
            ),
            child: innerChild,
          ),
        ),
      ),
    );
  }
}
