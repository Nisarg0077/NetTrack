import 'package:flutter/material.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;

/// Modern Fusion Liquid Glass ambient optical backdrop.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return fusion.FusionAmbientBackground(
      enabled: true,
      intensity: 1.0,
      child: child,
    );
  }
}

