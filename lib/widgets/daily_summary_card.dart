import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/format_utils.dart';
import 'animated_counter.dart';
import 'frosted_glass_card.dart';

class DailySummaryCard extends StatelessWidget {
  final int totalBytes;
  final int txBytes;
  final int rxBytes;
  final int activeAppsCount;
  final int peakHour;

  const DailySummaryCard({
    super.key,
    required this.totalBytes,
    required this.txBytes,
    required this.rxBytes,
    required this.activeAppsCount,
    required this.peakHour,
  });

  String _formatPeakHour(int hour) {
    if (hour < 0 || hour >= 24) return 'N/A';
    final start = hour.toString().padLeft(2, '0');
    final end = ((hour + 1) % 24).toString().padLeft(2, '0');
    return '$start:00 - $end:00';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return FrostedGlassCard(
      padding: const EdgeInsets.all(22.0),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.chart_pie_fill, color: primaryColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Network Activity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.app_fill, size: 13, color: primaryColor),
                    const SizedBox(width: 5),
                    Text(
                      '$activeAppsCount Active Apps',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Center Radial Indicator + Total Counter
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: totalBytes == 0 ? 0 : rxBytes / totalBytes,
                    ),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 14,
                        backgroundColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : primaryColor.withValues(alpha: 0.1),
                        color: primaryColor,
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL USAGE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedCounter(
                      value: totalBytes.toDouble(),
                      duration: const Duration(milliseconds: 700),
                      formatBuilder: (value) => FormatUtils.formatBytes(value.toInt()),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Stat Pills
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  context,
                  'Downloaded',
                  rxBytes,
                  CupertinoIcons.arrow_down_circle_fill,
                  const Color(0xFF34C759), // Apple System Green
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge(
                  context,
                  'Uploaded',
                  txBytes,
                  CupertinoIcons.arrow_up_circle_fill,
                  const Color(0xFFFF9500), // Apple System Orange
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPeakBadge(
                  context,
                  _formatPeakHour(peakHour),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context,
    String label,
    int bytes,
    IconData icon,
    Color accentColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.6)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: bytes.toDouble(),
            duration: const Duration(milliseconds: 600),
            formatBuilder: (value) => FormatUtils.formatBytes(value.toInt(), decimals: 1),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakBadge(BuildContext context, String peakText, bool isDark) {
    const color = Color(0xFFFF3B30); // Apple System Red
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.6)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.flame_fill, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            peakText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: -0.2),
          ),
          const SizedBox(height: 2),
          Text(
            'Peak Usage',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    );
  }
}

