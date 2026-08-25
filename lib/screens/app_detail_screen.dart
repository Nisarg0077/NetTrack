import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../models/app_usage_model.dart';
import '../services/data_usage_service.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/usage_chart.dart';
import '../widgets/animated_counter.dart';
import '../utils/format_utils.dart';

class AppDetailScreen extends StatefulWidget {
  final AppUsageModel appUsage;

  const AppDetailScreen({super.key, required this.appUsage});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  List<double> _sevenDayTrend = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrend();
  }

  Future<void> _fetchTrend() async {
    final service = DataUsageService();
    final trend = await service.getApp7DayTrend(widget.appUsage.packageName);
    if (mounted) {
      setState(() {
        _sevenDayTrend = trend;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final appTotal = widget.appUsage.rxBytes + widget.appUsage.txBytes;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(widget.appUsage.appName),
            backgroundColor: isDark
                ? const Color(0x99000000)
                : const Color(0x99F2F2F7),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Hero Card
                  Center(
                    child: Column(
                      children: [
                        Hero(
                          tag: 'app_icon_${widget.appUsage.packageName}',
                          child: Container(
                            width: 80,
                            height: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark ? const Color(0x2EFFFFFF) : const Color(0x1A000000),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: widget.appUsage.appIcon != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(widget.appUsage.appIcon!, fit: BoxFit.cover),
                                  )
                                : (Platform.isWindows 
                                    ? Icon(CupertinoIcons.desktopcomputer, size: 48, color: primaryColor)
                                    : Icon(CupertinoIcons.device_phone_portrait, size: 48, color: primaryColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.appUsage.packageName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Total Usage: ${FormatUtils.formatBytes(appTotal)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Stat Badges Row
                  Row(
                    children: [
                      Expanded(
                        child: FrostedGlassCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 20,
                          child: Column(
                            children: [
                              const Icon(CupertinoIcons.arrow_down_circle_fill, color: Color(0xFF34C759), size: 28),
                              const SizedBox(height: 8),
                              AnimatedCounter(
                                value: widget.appUsage.rxBytes.toDouble(),
                                formatBuilder: (v) => FormatUtils.formatBytes(v.toInt()),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Downloaded',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FrostedGlassCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 20,
                          child: Column(
                            children: [
                              const Icon(CupertinoIcons.arrow_up_circle_fill, color: Color(0xFFFF9500), size: 28),
                              const SizedBox(height: 8),
                              AnimatedCounter(
                                value: widget.appUsage.txBytes.toDouble(),
                                formatBuilder: (v) => FormatUtils.formatBytes(v.toInt()),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Uploaded',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 7-Day Trend Header
                  Text(
                    '7-Day Historical Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 280,
                    child: _isLoading
                        ? const Center(child: CupertinoActivityIndicator(radius: 14))
                        : UsageChart(
                            dailyTrend: _sevenDayTrend,
                            weeklyTrend: _sevenDayTrend,
                            monthlyTrend: _sevenDayTrend,
                            showFilters: false,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

