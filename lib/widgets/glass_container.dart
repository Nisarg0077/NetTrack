import 'package:flutter/material.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;

/// Modern Fusion Frosted Glass Container.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blurRadius;
  final double saturation;
  final Color? color;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final bool interactive;
  final double shaderIntensity;
  final double fluidViscosity;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blurRadius = 24.0,
    this.saturation = 1.4,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.border,
    this.shadows,
    this.interactive = false,
    this.shaderIntensity = 1.0,
    this.fluidViscosity = 0.85,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (interactive || onTap != null) {
      return fusion.GlassCard(
        width: width,
        height: height,
        borderRadius: borderRadius,
        blur: blurRadius,
        tint: color,
        interactive: interactive,
        onTap: onTap,
        useBackdropFilter: true,
        child: child,
      );
    }

    return fusion.GlassSurface(
      width: width,
      height: height,
      borderRadius: borderRadius,
      blur: blurRadius,
      tint: color,
      useBackdropFilter: true,
      child: child,
    );
  }
}

