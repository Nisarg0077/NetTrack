import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_usage_model.dart';
import '../utils/format_utils.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: Row(
        children: [
          Container(
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      FormatUtils.formatBytes(appTotal),
                      style: TextStyle(
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
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    Text(
                      '↑ ${FormatUtils.formatBytes(appUsage.txBytes)}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
