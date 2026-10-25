import 'package:flutter/material.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;

/// Modern Fusion Frosted Glass Card.
class FrostedGlassCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);

    if (interactive || onTap != null) {
      return fusion.GlassCard(
        width: width,
        height: height,
        padding: padding,
        margin: EdgeInsets.zero,
        borderRadius: r,
        blur: blur,
        tint: color,
        interactive: interactive,
        onTap: onTap,
        useBackdropFilter: true,
        showHighlight: true,
        child: child,
      );
    }

    return fusion.GlassSurface(
      width: width,
      height: height,
      padding: padding,
      borderRadius: r,
      blur: blur,
      tint: color,
      useBackdropFilter: true,
      showHighlight: true,
      child: child,
    );
  }
}

