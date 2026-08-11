import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.padding = const EdgeInsets.all(24.0),
    this.blur = 24.0,
    this.color,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) 
        : Colors.white.withValues(alpha: 0.7);

    final defaultBorder = Border.all(
      color: isDark 
          ? Colors.white.withValues(alpha: 0.1) 
          : Colors.white.withValues(alpha: 0.8),
      width: 1,
    );

    final defaultShadow = [
      BoxShadow(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.2) 
            : theme.colorScheme.primary.withValues(alpha: 0.08),
        blurRadius: 32,
        offset: const Offset(0, 12),
      )
    ];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: _buildInnerContainer(defaultColor, defaultBorder),
              )
            : _buildInnerContainer(defaultColor, defaultBorder),
      ),
    );
  }

  Widget _buildInnerContainer(Color defaultColor, Border defaultBorder) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
      ),
      child: child,
    );
  }
}
