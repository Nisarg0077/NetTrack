import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_usage_model.dart';
import '../utils/format_utils.dart';
import '../screens/app_detail_screen.dart';

class AppUsageTile extends StatelessWidget {
  final AppUsageModel appUsage;
  final int totalDeviceBytes;

  const AppUsageTile({
    super.key,
    required this.appUsage,
    required this.totalDeviceBytes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    
    final appTotal = appUsage.rxBytes + appUsage.txBytes;
    final percentage = totalDeviceBytes == 0 ? 0.0 : (appTotal / totalDeviceBytes).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => AppDetailScreen(appUsage: appUsage),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'app_icon_${appUsage.packageName}',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                        width: 0.8,
                      ),
                    ),
                    child: appUsage.appIcon != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              appUsage.appIcon!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              cacheWidth: 92,
                              cacheHeight: 92,
                            ),
                          )
                        : (Platform.isWindows 
                            ? Icon(CupertinoIcons.desktopcomputer, color: primaryColor, size: 24) 
                            : Icon(CupertinoIcons.device_phone_portrait, color: primaryColor, size: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appUsage.appName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            FormatUtils.formatBytes(appTotal),
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: percentage),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.arrow_down, size: 11, color: const Color(0xFF34C759)),
                              const SizedBox(width: 3),
                              Text(
                                FormatUtils.formatBytes(appUsage.rxBytes),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(CupertinoIcons.arrow_up, size: 11, color: const Color(0xFFFF9500)),
                              const SizedBox(width: 3),
                              Text(
                                FormatUtils.formatBytes(appUsage.txBytes),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

