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
    this.borderRadius = 22.0,
    this.padding = const EdgeInsets.all(20.0),
    this.blur = 20.0,
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
        ? const Color(0xB31C1C1E) // 70% Apple dark glass
        : const Color(0xD9FFFFFF); // 85% Apple light glass

    final defaultBorder = Border.all(
      color: isDark 
          ? const Color(0x2EFFFFFF) 
          : const Color(0x1A000000),
      width: 0.8,
    );

    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
        blurRadius: 20,
        offset: const Offset(0, 6),
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
      child: RepaintBoundary(child: child),
    );
  }
}
