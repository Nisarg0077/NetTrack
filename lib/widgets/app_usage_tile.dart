import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_usage_model.dart';
import '../utils/format_utils.dart';
import 'frosted_glass_card.dart';
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
    
    final appTotal = appUsage.rxBytes + appUsage.txBytes;
    final percentage = totalDeviceBytes == 0 ? 0.0 : (appTotal / totalDeviceBytes).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppDetailScreen(appUsage: appUsage),
            ),
          );
        },
        child: FrostedGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          blur: 0,
          child: Row(
            children: [
              Hero(
                tag: 'app_icon_${appUsage.packageName}',
                child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
            ),
            child: appUsage.appIcon != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      appUsage.appIcon!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      cacheWidth: 100,
                      cacheHeight: 100,
                    ),
                  )
                : (Platform.isWindows 
                    ? const Icon(Icons.window, color: Colors.blue) 
                    : const Icon(Icons.android, color: Colors.green)),
          ),
              ),
          const SizedBox(width: 16),
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
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      FormatUtils.formatBytes(appTotal),
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '↓ ${FormatUtils.formatBytes(appUsage.rxBytes)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    Text(
                      '↑ ${FormatUtils.formatBytes(appUsage.txBytes)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
