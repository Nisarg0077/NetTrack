import 'package:flutter/material.dart';

/// Authentic Apple Liquid Glass ambient optical backdrop.
///
/// Features:
/// - Deep obsidian canvas with restrained sapphire and indigo optical nodes.
/// - Provides the optical depth and radiant color required for physical glass refraction.
/// - Completely static rendering with 0% idle CPU and GPU battery drain.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF090B10) : const Color(0xFFF6F8FC),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Top-Left Sapphire Radiant Node (Physical illumination for glass refraction)
            Positioned(
              top: -120,
              left: -80,
              width: 520,
              height: 520,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF007AFF).withValues(alpha: 0.14),
                              const Color(0xFF0A58CA).withValues(alpha: 0.05),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFB8D5FF).withValues(alpha: 0.40),
                              const Color(0xFFD6E6FF).withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Center-Right Indigo Ambient Node (Secondary refractive depth)
            Positioned(
              top: 140,
              right: -100,
              width: 560,
              height: 560,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF5856D6).withValues(alpha: 0.12),
                              const Color(0xFF3F3B96).withValues(alpha: 0.04),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFE2DCFF).withValues(alpha: 0.35),
                              const Color(0xFFF0ECFF).withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bottom Subtle Emerald Node (Represents live network telemetry)
            Positioned(
              bottom: -150,
              left: 60,
              width: 480,
              height: 480,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF34C759).withValues(alpha: 0.06),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFD4F8DE).withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            child,
          ],
        ),
      ),
    );
  }
}
