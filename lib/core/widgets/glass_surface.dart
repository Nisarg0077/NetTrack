import 'package:flutter/material.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;
import '../theme/app_radii.dart';

/// Modern Fusion Frosted Glass Surface.
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
    return fusion.GlassSurface(
      borderRadius: borderRadius ?? AppRadii.radiusMd,
      blur: enableBlur ? blur : 0.0,
      opacity: opacity,
      tint: tintColor,
      forceBlur: forceBlur,
      padding: padding,
      showHighlight: showRefraction,
      useBackdropFilter: enableBlur,
      child: child,
    );
  }
}

