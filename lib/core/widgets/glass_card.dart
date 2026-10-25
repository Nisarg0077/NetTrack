import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// An authentic Apple Liquid Glass card surface with optical backdrop blur,
/// specular hairline highlights, soft layered depth shadows, and hardware-adaptive fallback.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool enableBlur;
  final BoxBorder? border;
  final bool showRefraction;
  final Color? tintColor;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.enableBlur = true,
    this.border,
    this.showRefraction = true,
    this.tintColor,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.width,
    this.height,
    this.blur = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? AppRadii.card;

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    } catch (_) {}

    final bool isEfficiency = themeProvider?.isEfficiencyMode ?? false;
    final bool isUltra = themeProvider?.isUltraMode ?? false;
    final bool shouldBlur = enableBlur && !isEfficiency;

    final effectiveBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: isUltra ? 0.16 : 0.10)
              : Colors.black.withValues(alpha: 0.07),
          width: 0.85,
        );

    final effectiveShadows = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.06),
            blurRadius: isUltra ? 26 : 18,
            spreadRadius: -2,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ];

    final Color effectiveTint =
        color ?? tintColor ?? (isDark ? const Color(0xFF141722) : Colors.white);

    // If blur is disabled (e.g. efficiency mode), render high-performance tinted container
    if (!shouldBlur) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? effectiveTint.withValues(alpha: 0.90)
              : effectiveTint.withValues(alpha: 0.95),
          borderRadius: r,
          border: effectiveBorder,
          boxShadow: effectiveShadows,
        ),
        child: ClipRRect(
          borderRadius: r,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      );
    }

    // Optical Liquid Glass with BackdropFilter
    final double effectiveSigma =
        isUltra ? blur : (blur * 0.75).clamp(12.0, 24.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
              sigmaX: effectiveSigma, sigmaY: effectiveSigma),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        effectiveTint.withValues(alpha: 0.65),
                        effectiveTint.withValues(alpha: 0.48),
                      ]
                    : [
                        effectiveTint.withValues(alpha: 0.85),
                        effectiveTint.withValues(alpha: 0.72),
                      ],
              ),
              border: effectiveBorder,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
