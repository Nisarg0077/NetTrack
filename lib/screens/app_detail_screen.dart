import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/app_usage_model.dart';
import '../providers/data_provider.dart';
import '../services/data_usage_service.dart';
import '../widgets/usage_chart.dart';
import '../widgets/animated_counter.dart';
import '../utils/format_utils.dart';

// Design System
import '../core/platform/platform_service.dart';
import '../core/widgets/glass_card.dart';
import '../core/design_system/glass_toolbar.dart';
import '../core/design_system/floating_pill.dart';
import '../core/widgets/ambient_background.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_spacing.dart';

class AppDetailScreen extends StatefulWidget {
  final AppUsageModel appUsage;
  final String heroTagPrefix;

  const AppDetailScreen(
      {super.key, required this.appUsage, this.heroTagPrefix = ''});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  List<double> _sevenDayTrend = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay fetching until route transition completes smoothly
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _fetchTrend();
        }
      });
    });
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

    // Calculate download / upload distribution ratios
    final double rxRatio = appTotal > 0
        ? (widget.appUsage.rxBytes / appTotal).clamp(0.0, 1.0)
        : 0.5;
    final int rxPercent = (rxRatio * 100).round();
    final int txPercent = 100 - rxPercent;

    // Calculate 7-day stats (Peak and Daily Average)
    double peakMb = 0.0;
    double sumMb = 0.0;
    for (var val in _sevenDayTrend) {
      if (val > peakMb) peakMb = val;
      sumMb += val;
    }
    final double avgMb =
        _sevenDayTrend.isNotEmpty ? (sumMb / _sevenDayTrend.length) : 0.0;

    // Check share of total device bandwidth from DataProvider
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    int deviceTotal = 0;
    for (var a in dataProvider.appUsages) {
      deviceTotal += a.totalBytes;
    }
    final double deviceShare =
        deviceTotal > 0 ? ((appTotal / deviceTotal) * 100) : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverGlassToolbarDelegate(
                height: MediaQuery.of(context).padding.top +
                    (PlatformService.isDesktop ? 54.0 : 62.0),
                child: SafeArea(
                  bottom: false,
                  child: GlassToolbar(
                    useSafeArea: false,
                    margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                    leading: FloatingActionPill(
                      icon: CupertinoIcons.chevron_left,
                      isCompact: true,
                      iconSize: 17,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    title: widget.appUsage.appName,
                    titleWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.appUsage.appIcon != null)
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.35 : 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                widget.appUsage.appIcon!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                cacheWidth: 48,
                                cacheHeight: 48,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            widget.appUsage.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: PlatformService.isDesktop ? 16 : 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ConnectionStatusPill(
                        label: FormatUtils.formatBytes(appTotal),
                        color: primaryColor,
                        isLive: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 768;

                  if (isDesktop) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                          AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column (flex 5): Identity, Traffic Split, and Rates
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildIdentitySection(context, isDark,
                                        primaryColor, appTotal, deviceShare),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildTrafficSplitCard(
                                        rxPercent, txPercent, isDark),
                                    const SizedBox(height: AppSpacing.md),
                                    _buildStatBadgesRow(
                                        rxPercent, txPercent, isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              // Right Column (flex 7): 7-Day Trend Chart & History Stats
                              Expanded(
                                flex: 7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTrendHeader(theme, primaryColor,
                                        isDark, peakMb, avgMb),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildChartContainer(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Mobile iOS Layout
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIdentitySection(context, isDark, primaryColor,
                            appTotal, deviceShare),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTrafficSplitCard(rxPercent, txPercent, isDark),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatBadgesRow(rxPercent, txPercent, isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTrendHeader(
                            theme, primaryColor, isDark, peakMb, avgMb),
                        const SizedBox(height: AppSpacing.sm),
                        _buildChartContainer(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitySection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    int appTotal,
    double deviceShare,
  ) {
    return Center(
      child: Column(
        children: [
          Hero(
            tag:
                '${widget.heroTagPrefix}app_icon_${widget.appUsage.packageName}_${widget.appUsage.appName}',
            child: Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: AppRadii.radiusLg,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.appUsage.appIcon != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        widget.appUsage.appIcon!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        cacheWidth: 168,
                        cacheHeight: 168,
                      ),
                    )
                  : (Platform.isWindows
                      ? Icon(CupertinoIcons.desktopcomputer,
                          size: 48, color: primaryColor)
                      : Icon(CupertinoIcons.device_phone_portrait,
                          size: 48, color: primaryColor)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: widget.appUsage.packageName));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Package name copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.appUsage.packageName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.doc_on_clipboard,
                  size: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Total: ${FormatUtils.formatBytes(appTotal)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              if (deviceShare > 0.05)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${deviceShare.toStringAsFixed(1)}% of total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE5E5EA)
                          : const Color(0xFF3A3A3C),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficSplitCard(int rxPercent, int txPercent, bool isDark) {
    return GlassCard(
      enableBlur: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRAFFIC SPLIT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                '$rxPercent% Down • $txPercent% Up',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, rxPercent),
                    child: Container(color: const Color(0xFF34C759)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: math.max(1, txPercent),
                    child: Container(color: const Color(0xFFFF9500)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadgesRow(int rxPercent, int txPercent, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            enableBlur: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.arrow_down_circle_fill,
                        color: Color(0xFF34C759), size: 24),
                    SizedBox(width: 6),
                    Text(
                      'Downloaded',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedCounter(
                  value: widget.appUsage.rxBytes.toDouble(),
                  formatBuilder: (v) => FormatUtils.formatBytes(v.toInt()),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$rxPercent% of app traffic',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GlassCard(
            enableBlur: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.arrow_up_circle_fill,
                        color: Color(0xFFFF9500), size: 24),
                    SizedBox(width: 6),
                    Text(
                      'Uploaded',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedCounter(
                  value: widget.appUsage.txBytes.toDouble(),
                  formatBuilder: (v) => FormatUtils.formatBytes(v.toInt()),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$txPercent% of app traffic',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendHeader(
    ThemeData theme,
    Color primaryColor,
    bool isDark,
    double peakMb,
    double avgMb,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '7-Day Trend',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        if (!_isLoading && _sevenDayTrend.isNotEmpty)
          Row(
            children: [
              if (peakMb > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Peak: ${peakMb < 1024 ? "${peakMb.toStringAsFixed(0)} MB" : "${(peakMb / 1024).toStringAsFixed(1)} GB"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Avg: ${avgMb < 1024 ? "${avgMb.toStringAsFixed(0)} MB/d" : "${(avgMb / 1024).toStringAsFixed(1)} GB/d"}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE5E5EA)
                        : const Color(0xFF3A3A3C),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChartContainer() {
    return SizedBox(
      height: 300,
      child: _isLoading
          ? const GlassCard(
              enableBlur: true,
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            )
          : UsageChart(
              dailyTrend: _sevenDayTrend,
              weeklyTrend: _sevenDayTrend,
              monthlyTrend: _sevenDayTrend,
              showFilters: false,
              enableBlur: true,
            ),
    );
  }
}
