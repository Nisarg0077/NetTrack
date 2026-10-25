import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/format_utils.dart';

class StickySummaryDelegate extends SliverPersistentHeaderDelegate {
  final int totalBytes;
  final int txBytes;
  final int rxBytes;
  final int activeAppsCount;
  final int peakHour;
  final double expandedHeight;
  final double collapsedHeight;

  StickySummaryDelegate({
    required this.totalBytes,
    required this.txBytes,
    required this.rxBytes,
    required this.activeAppsCount,
    required this.peakHour,
    this.expandedHeight = 380,
    this.collapsedHeight =
        kToolbarHeight + 32, // Accommodate standard app bar plus some padding
  });

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant StickySummaryDelegate oldDelegate) {
    return totalBytes != oldDelegate.totalBytes ||
        txBytes != oldDelegate.txBytes ||
        rxBytes != oldDelegate.rxBytes ||
        activeAppsCount != oldDelegate.activeAppsCount ||
        peakHour != oldDelegate.peakHour;
  }

  String _formatPeakHour(int hour) {
    if (hour < 0 || hour >= 24) return 'N/A';
    final start = hour.toString().padLeft(2, '0');
    final end = ((hour + 1) % 24).toString().padLeft(2, '0');
    return '$start:00 - $end:00';
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 0.0 means fully expanded, 1.0 means fully collapsed
    final shrinkPercentage =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: shrinkPercentage * 15,
          sigmaY: shrinkPercentage * 15,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Color.lerp(
                    theme.scaffoldBackgroundColor,
                    const Color(0xFF1E293B).withValues(alpha: 0.85),
                    shrinkPercentage)
                : Color.lerp(theme.scaffoldBackgroundColor,
                    Colors.white.withValues(alpha: 0.85), shrinkPercentage),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor
                    .withValues(alpha: shrinkPercentage * 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fully Expanded State (Fades out)
                Opacity(
                  opacity: (1 - shrinkPercentage * 2).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF0F172A)
                                ]
                              : [
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  Colors.white
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Usage Summary',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$activeAppsCount Apps Used',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(flex: 1),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: totalBytes == 0
                                          ? 0
                                          : rxBytes / totalBytes,
                                    ),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 10,
                                        backgroundColor: theme
                                            .colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        color: theme.colorScheme.primary,
                                        strokeCap: StrokeCap.round,
                                      );
                                    },
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'TOTAL',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      FormatUtils.formatBytes(totalBytes),
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(flex: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildExpandedStatItem(
                                    context,
                                    'Downloaded',
                                    rxBytes,
                                    Icons.download_rounded,
                                    const Color(0xFF10B981)),
                                _buildExpandedStatItem(
                                    context,
                                    'Uploaded',
                                    txBytes,
                                    Icons.upload_rounded,
                                    const Color(0xFFF59E0B)),
                                _buildExpandedPeakItem(
                                    context, _formatPeakHour(peakHour)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Collapsed State (Fades in)
                Opacity(
                  opacity: ((shrinkPercentage - 0.5) * 2).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Usage',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                FormatUtils.formatBytes(totalBytes),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCollapsedStat(
                                  context,
                                  rxBytes,
                                  Icons.download_rounded,
                                  const Color(0xFF10B981)),
                              const SizedBox(width: 16),
                              _buildCollapsedStat(
                                  context,
                                  txBytes,
                                  Icons.upload_rounded,
                                  const Color(0xFFF59E0B)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedStatItem(BuildContext context, String label, int bytes,
      IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              FormatUtils.formatBytes(bytes),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7)),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedPeakItem(BuildContext context, String peakText) {
    const color = Color(0xFFEF4444);
    return Expanded(
      child: Column(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              peakText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Peak Usage',
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7)),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedStat(
      BuildContext context, int bytes, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          FormatUtils.formatBytes(bytes),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
