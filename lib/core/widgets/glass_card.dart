import 'package:flutter/material.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// An authentic Apple Liquid Glass card surface powered by Fusion UI.
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
    return fusion.GlassCard(
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius ?? AppRadii.card,
      blur: enableBlur ? blur : 0.0,
      tint: tintColor ?? color,
      showHighlight: showRefraction,
      useBackdropFilter: enableBlur,
      child: child,
    );
  }
}

