import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_surface.dart';
import '../../utils/format_utils.dart';
import '../theme/app_colors.dart';
import '../platform/platform_service.dart';

class SpeedIndicator extends StatelessWidget {
  final double downloadSpeed;
  final double uploadSpeed;
  final String interfaceName;
  final bool isConnected;

  const SpeedIndicator({
    super.key,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.interfaceName,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final isMobile = PlatformService.isMobile;

    if (isMobile) {
      // ----------------------------------------------------
      // Authentic Liquid Glass Dynamic Floating Capsule
      // ----------------------------------------------------
      final r = BorderRadius.circular(28);
      return GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 22,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              if (isConnected && (downloadSpeed > 10240 || uploadSpeed > 10240))
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: -1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: r,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xE0121520),
                            const Color(0xC70B0D14),
                          ]
                        : [
                            const Color(0xF2FFFFFF),
                            const Color(0xDCF0F2F7),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.85,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Dynamic Activity Bubble
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isConnected
                                  ? [
                                      const Color(0xFF34C759),
                                      const Color(0xFF30B350)
                                    ]
                                  : [
                                      const Color(0xFFFF3B30),
                                      const Color(0xFFD70015)
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isConnected
                                        ? const Color(0xFF34C759)
                                        : const Color(0xFFFF3B30))
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.waveform_path_ecg,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Island Label & Connection
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                interfaceName.isEmpty
                                    ? 'Cellular / Wi-Fi'
                                    : interfaceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isConnected
                                          ? const Color(0xFF34C759)
                                          : const Color(0xFFFF3B30),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isConnected
                                                  ? const Color(0xFF34C759)
                                                  : const Color(0xFFFF3B30))
                                              .withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isConnected
                                        ? 'Live Telemetry • Active'
                                        : 'Offline',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF8E8E93)
                                          : const Color(0xFF6E6E73),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Realtime Rates (Mini Island Badges)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildIslandBadge(CupertinoIcons.arrow_down,
                                downloadSpeed, const Color(0xFF34C759), isDark),
                            const SizedBox(width: 8),
                            _buildIslandBadge(CupertinoIcons.arrow_up,
                                uploadSpeed, const Color(0xFFFF9500), isDark),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Activity Progress Track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value:
                            ((downloadSpeed + uploadSpeed) / (12 * 1024 * 1024))
                                .clamp(0.04, 1.0),
                        minHeight: 3.0,
                        backgroundColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF34C759)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // Desktop Telemetry Capsule (Windows & Linux)
    // ----------------------------------------------------
    return GlassSurface(
      enableBlur: true,
      forceBlur: true,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Desktop Adapter Symbol
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.desktopcomputer,
                    color: primaryColor,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Network Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interfaceName.isEmpty ? 'System Network' : interfaceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppColors.success
                                : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isConnected
                              ? 'Realtime Stream • Active'
                              : 'Disconnected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Desktop Throughput Badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniSpeedItem(
                    context,
                    CupertinoIcons.arrow_down,
                    downloadSpeed,
                    AppColors.success,
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniSpeedItem(
                    context,
                    CupertinoIcons.arrow_up,
                    uploadSpeed,
                    AppColors.warning,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Activity Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ((downloadSpeed + uploadSpeed) / (12 * 1024 * 1024))
                  .clamp(0.04, 1.0),
              minHeight: 2.0,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                primaryColor.withValues(alpha: isDark ? 0.8 : 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIslandBadge(IconData icon, double speed, Color color,
      [bool isDark = true]) {
    final formatted =
        '${FormatUtils.formatBytes(speed.toInt(), decimals: 1)}/s';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E212B).withValues(alpha: 0.8)
            : const Color(0xFFE8E9EF).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            formatted,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSpeedItem(
    BuildContext context,
    IconData icon,
    double speed,
    Color iconColor,
    bool isDark,
  ) {
    final formatted =
        '${FormatUtils.formatBytes(speed.toInt(), decimals: 1)}/s';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2E).withValues(alpha: 0.5)
            : const Color(0xFFE5E5EA).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            formatted,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }
}
