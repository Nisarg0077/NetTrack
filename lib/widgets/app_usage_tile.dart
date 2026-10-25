import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/app_usage_model.dart';
import '../utils/format_utils.dart';
import '../screens/app_detail_screen.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_typography.dart';

class AppUsageTile extends StatelessWidget {
  final AppUsageModel appUsage;
  final int totalDeviceBytes;
  final String heroTagPrefix;
  final bool isFirst;
  final bool isLast;

  static final TextStyle _monoTotalBase = AppTypography.mono(
    fontWeight: FontWeight.w700,
    fontSize: 14,
  );
  static final TextStyle _monoStatBase = AppTypography.mono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  final bool useCardBackground;

  const AppUsageTile({
    super.key,
    required this.appUsage,
    required this.totalDeviceBytes,
    this.heroTagPrefix = '',
    this.isFirst = false,
    this.isLast = false,
    this.useCardBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final appTotal = appUsage.rxBytes + appUsage.txBytes;
    final percentage = totalDeviceBytes == 0
        ? 0.0
        : (appTotal / totalDeviceBytes).clamp(0.0, 1.0);
    final statColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: useCardBackground
              ? (isDark ? AppColors.darkSurfaceElevated : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(22) : Radius.zero,
            bottom: isLast ? const Radius.circular(22) : Radius.zero,
          ),
          border: useCardBackground
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.85,
                )
              : null,
          boxShadow: (useCardBackground && isLast)
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.vertical(
                  top: isFirst ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => AppDetailScreen(
                        appUsage: appUsage,
                        heroTagPrefix: heroTagPrefix,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag:
                            '${heroTagPrefix}app_icon_${appUsage.packageName}_${appUsage.appName}',
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.radiusMd,
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF2F2F7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.25 : 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: appUsage.appIcon != null
                              ? ClipRRect(
                                  borderRadius: AppRadii.radiusMd,
                                  child: Image.memory(
                                    appUsage.appIcon!,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    cacheWidth: 100,
                                    cacheHeight: 100,
                                  ),
                                )
                              : (Platform.isWindows
                                  ? Icon(CupertinoIcons.desktopcomputer,
                                      color: primaryColor, size: 24)
                                  : Icon(CupertinoIcons.app_fill,
                                      color: primaryColor, size: 24)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    appUsage.appName,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.5,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      FormatUtils.formatBytes(appTotal),
                                      style: _monoTotalBase.copyWith(
                                        color: primaryColor,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 13,
                                      color: isDark
                                          ? const Color(0xFF636366)
                                          : const Color(0xFFC7C7CC),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.arrow_down,
                                        size: 12, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      FormatUtils.formatBytes(appUsage.rxBytes),
                                      style: _monoStatBase.copyWith(
                                          color: statColor),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Icon(CupertinoIcons.arrow_up,
                                        size: 12, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      FormatUtils.formatBytes(appUsage.txBytes),
                                      style: _monoStatBase.copyWith(
                                          color: statColor),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 3,
                                backgroundColor: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E5EA),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
