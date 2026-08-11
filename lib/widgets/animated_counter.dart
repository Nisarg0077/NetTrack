import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final Duration duration;
  final String Function(double) formatBuilder;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    required this.formatBuilder,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, currentValue, child) {
        return Text(
          formatBuilder(currentValue),
          style: style,
        );
      },
    );
  }
}
