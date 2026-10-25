import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/format_utils.dart';
import 'animated_counter.dart';
import '../core/widgets/glass_card.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

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

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.chart_pie_fill,
                          color: primaryColor, size: 16),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Network Activity',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.app_fill,
                        size: 13, color: primaryColor),
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
          const SizedBox(height: AppSpacing.xl),

          // Modern Network Activity Block
          const SizedBox(height: AppSpacing.sm),
          Text(
            'TOTAL USAGE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedCounter(
            value: totalBytes.toDouble(),
            duration: const Duration(milliseconds: 700),
            formatBuilder: (value) => FormatUtils.formatBytes(value.toInt()),
            style: AppTypography.mono(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0.0,
                end: totalBytes == 0 ? 0.0 : rxBytes / totalBytes,
              ),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : primaryColor.withValues(alpha: 0.1),
                  color: primaryColor,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Stat Pills
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  context,
                  'Downloaded',
                  rxBytes,
                  CupertinoIcons.arrow_down_circle_fill,
                  AppColors.success,
                  isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatBadge(
                  context,
                  'Uploaded',
                  txBytes,
                  CupertinoIcons.arrow_up_circle_fill,
                  AppColors.warning,
                  isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
            ? const Color(0xFF22222A).withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.90),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 6),
          AnimatedCounter(
            value: bytes.toDouble(),
            duration: const Duration(milliseconds: 600),
            formatBuilder: (value) =>
                FormatUtils.formatBytes(value.toInt(), decimals: 1),
            style: AppTypography.mono(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.2,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakBadge(BuildContext context, String peakText, bool isDark) {
    const color = AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF22222A).withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.90),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(CupertinoIcons.flame_fill, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              peakText,
              maxLines: 1,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: -0.2),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Peak Usage',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
