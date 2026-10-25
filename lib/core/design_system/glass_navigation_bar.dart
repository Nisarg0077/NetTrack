import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;

/// A tab item descriptor for [GlassNavigationBar].
class GlassNavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;

  const GlassNavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// A floating, pill-shaped Liquid Glass navigation bar for mobile touch interaction.
class GlassNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final List<GlassNavigationItem> items;
  final double blur;

  const GlassNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.items,
    this.blur = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final r = BorderRadius.circular(32);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: fusion.GlassSurface(
          height: 62,
          borderRadius: r,
          elevation: 3,
          blur: blur,
          useBackdropFilter: true,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = constraints.maxWidth / items.length;
              final double activePillLeft = currentIndex * itemWidth;

              return Stack(
                children: [
                  // Smooth horizontally gliding indicator pill
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: activePillLeft + 3,
                    top: 2,
                    bottom: 2,
                    width: itemWidth - 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.22)
                            : primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? primaryColor.withValues(alpha: 0.45)
                              : primaryColor.withValues(alpha: 0.32),
                          width: 0.85,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(
                                alpha: isDark ? 0.35 : 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab items on top of sliding indicator
                  Row(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        Expanded(
                          child: _buildItem(
                            context,
                            index: i,
                            item: items[i],
                            isSelected: currentIndex == i,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required GlassNavigationItem item,
    required bool isSelected,
    required bool isDark,
    required Color primaryColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onItemSelected(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.14 : 1.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 19,
                    color: isSelected
                        ? (isDark ? Colors.white : primaryColor)
                        : (isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6E6E73)),
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Positioned(
                    top: -3,
                    right: -9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                ? const Color(0xFF3A3D4A)
                                : const Color(0xFFE5E5EA)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2.5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
                color: isSelected
                    ? (isDark ? Colors.white : primaryColor)
                    : (isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73)),
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
