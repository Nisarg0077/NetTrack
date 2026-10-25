import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/update_dialog.dart';
import '../widgets/usage_chart.dart';
import '../widgets/app_usage_tile.dart';
import '../utils/format_utils.dart';
import 'app_detail_screen.dart';

// Design System Primitives
import '../core/widgets/glass_card.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/design_system/glass_toolbar.dart';
import '../core/design_system/floating_pill.dart';
import '../core/platform/platform_service.dart';
import '../core/widgets/app_toast.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isDesktop = PlatformService.isDesktop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverGlassToolbarDelegate(
              height: MediaQuery.of(context).padding.top +
                  (isDesktop ? 104.0 : 118.0),
              child: SafeArea(
                bottom: false,
                child: GlassToolbar(
                  useSafeArea: false,
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  title: 'Overview',
                  statusWidget: Consumer<DataProvider>(
                    builder: (context, provider, _) {
                      final activeInterface = provider.networkStats.isNotEmpty
                          ? provider.networkStats.first.interfaceName
                          : (Platform.isAndroid ? 'Cellular / Wi-Fi' : '');
                      return ConnectionStatusPill(
                        label: 'Live Telemetry',
                        isLive: true,
                        interfaceName: activeInterface,
                      );
                    },
                  ),
                  actions: [
                    FloatingActionPill(
                      icon: CupertinoIcons.arrow_clockwise,
                      label: 'Refresh',
                      isPrimary: true,
                      onPressed: () {
                        Provider.of<DataProvider>(context, listen: false)
                            .fetchData();
                        AppToast.info(
                          context,
                          'Telemetry refreshed',
                          icon: CupertinoIcons.arrow_clockwise,
                        );
                      },
                    ),
                  ],
                  bottom: const Padding(
                    padding: EdgeInsets.fromLTRB(14, 2, 14, 8),
                    child: DateSelectorBar(),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                if (dataProvider.errorMessage != null &&
                    dataProvider.appUsages.isEmpty &&
                    dataProvider.networkStats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: GlassCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.exclamationmark_triangle_fill,
                                size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              dataProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            CupertinoButton.filled(
                              onPressed: () => dataProvider.fetchData(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (dataProvider.isLoading &&
                    dataProvider.appUsages.isEmpty &&
                    dataProvider.networkStats.isEmpty) {
                  return const SizedBox(
                    height: 400,
                    child:
                        Center(child: CupertinoActivityIndicator(radius: 14)),
                  );
                }

                int totalRx = 0;
                int totalTx = 0;
                if (Platform.isWindows || Platform.isLinux) {
                  for (var stat in dataProvider.networkStats) {
                    totalRx += stat.rxBytes;
                    totalTx += stat.txBytes;
                  }
                } else {
                  for (var app in dataProvider.appUsages) {
                    totalRx += app.rxBytes;
                    totalTx += app.txBytes;
                  }
                }
                final totalBytes = totalRx + totalTx;
                final topApps = dataProvider.appUsages.take(5).toList();
                final activeInterface = dataProvider.networkStats.isNotEmpty
                    ? dataProvider.networkStats.first.interfaceName
                    : (Platform.isAndroid ? 'Cellular / Wi-Fi' : 'Unknown');

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscapeMobile = !PlatformService.isDesktop &&
                        constraints.maxWidth > constraints.maxHeight &&
                        constraints.maxHeight < 550;
                    final isDesktop = PlatformService.isDesktop ||
                        (constraints.maxWidth >= 768 &&
                            constraints.maxHeight >= 550);
                    final double bottomPadding =
                        (isDesktop || isLandscapeMobile)
                            ? AppSpacing.xxl
                            : 110;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, bottomPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          if (dataProvider.isUpdateAvailable)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: GlassCard(
                                padding: EdgeInsets.zero,
                                borderRadius: BorderRadius.circular(16),
                                color: isDark
                                    ? const Color(0xFF1E212B)
                                    : Colors.white,
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => UpdateDialog(
                                        latestVersion:
                                            dataProvider.updateLatestVersion ??
                                                '',
                                        releaseNotes:
                                            dataProvider.updateReleaseNotes ??
                                                '',
                                        releaseUrl:
                                            dataProvider.updateReleaseUrl ?? '',
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(
                                            CupertinoIcons
                                                .arrow_down_circle_fill,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            'Update ${dataProvider.updateLatestVersion} is available! Tap to install.',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.5,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        Icon(CupertinoIcons.chevron_right,
                                            color: theme.colorScheme.primary,
                                            size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (isDesktop) ...[
                            _buildDesktopTelemetryRibbon(
                              dataProvider: dataProvider,
                              totalBytes: totalBytes,
                              totalRx: totalRx,
                              totalTx: totalTx,
                              activeInterface: activeInterface,
                              isDark: isDark,
                              theme: theme,
                              isNarrow: constraints.maxWidth < 960,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (constraints.maxWidth < 960) ...[
                              _buildWaveformCard(
                                  context, dataProvider, isDark, theme),
                              const SizedBox(height: AppSpacing.md),
                              _buildDesktopTopAppsCard(
                                  context, topApps, totalBytes, isDark, theme),
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Pane (flex 6): Bandwidth Activity Trend Waveform
                                  Expanded(
                                    flex: 6,
                                    child: _buildWaveformCard(
                                        context, dataProvider, isDark, theme),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  // Right Pane (flex 5): Top Bandwidth Consumers
                                  Expanded(
                                    flex: 5,
                                    child: _buildDesktopTopAppsCard(context,
                                        topApps, totalBytes, isDark, theme),
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            // Mobile Adaptive Layout
                            DailySummaryCard(
                              totalBytes: totalBytes,
                              txBytes: totalTx,
                              rxBytes: totalRx,
                              activeAppsCount: dataProvider.activeAppsCount,
                              peakHour: dataProvider.peakHour,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 280,
                              child: UsageChart(
                                dailyTrend: dataProvider.dailyTrend,
                                weeklyTrend: dataProvider.weeklyTrend,
                                monthlyTrend: dataProvider.monthlyTrend,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _buildTopAppsSection(
                                context, topApps, totalBytes, isDark, theme),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppsSection(
    BuildContext context,
    List<dynamic> topApps,
    int totalBytes,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Data Hungry Apps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Top ${topApps.length}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6E6E73),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (topApps.isEmpty)
          const GlassCard(
            enableBlur: true,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  "No network activity recorded for this timeframe.",
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13.5),
                ),
              ),
            ),
          )
        else
          GlassCard(
            padding: EdgeInsets.zero,
            enableBlur: true,
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topApps.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return AppUsageTile(
                  appUsage: topApps[index],
                  totalDeviceBytes: totalBytes,
                  heroTagPrefix: 'dashboard_',
                  isFirst: index == 0,
                  isLast: index == topApps.length - 1,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWaveformCard(
    BuildContext context,
    DataProvider dataProvider,
    bool isDark,
    ThemeData theme,
  ) {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bandwidth Activity Waveform',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (dataProvider.peakHour >= 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Peak: ${dataProvider.peakHour}:00 - ${(dataProvider.peakHour + 1) % 24}:00',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 330,
            child: UsageChart(
              dailyTrend: dataProvider.dailyTrend,
              weeklyTrend: dataProvider.weeklyTrend,
              monthlyTrend: dataProvider.monthlyTrend,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTelemetryRibbon({
    required DataProvider dataProvider,
    required int totalBytes,
    required int totalRx,
    required int totalTx,
    required String activeInterface,
    required bool isDark,
    required ThemeData theme,
    bool isNarrow = false,
  }) {
    final bool isToday = dataProvider.selectedRange == DateRange.today;

    final card1 = _buildKpiCard(
      icon: CupertinoIcons.arrow_down_circle_fill,
      iconColor: const Color(0xFF007AFF),
      title: isToday
          ? FormatUtils.formatSpeed(dataProvider.currentDownloadSpeed)
          : FormatUtils.formatBytes(totalRx),
      subtitle: isToday ? 'Live Download Rate' : 'Total Downloaded',
      isDark: isDark,
      isMono: true,
    );

    final card2 = _buildKpiCard(
      icon: CupertinoIcons.arrow_up_circle_fill,
      iconColor: const Color(0xFF5856D6),
      title: isToday
          ? FormatUtils.formatSpeed(dataProvider.currentUploadSpeed)
          : FormatUtils.formatBytes(totalTx),
      subtitle: isToday ? 'Live Upload Rate' : 'Total Uploaded',
      isDark: isDark,
      isMono: true,
    );

    final card3 = _buildKpiCard(
      icon: CupertinoIcons.chart_pie_fill,
      iconColor: const Color(0xFF34C759),
      title: FormatUtils.formatBytes(totalBytes),
      subtitle:
          '↓ ${FormatUtils.formatBytes(totalRx)}  •  ↑ ${FormatUtils.formatBytes(totalTx)}',
      isDark: isDark,
      isMono: true,
    );

    final card4 = _buildKpiCard(
      icon: CupertinoIcons.waveform_path_ecg,
      iconColor: const Color(0xFFFF9500),
      title: activeInterface.isEmpty ? 'Ethernet' : activeInterface,
      subtitle: dataProvider.peakHour >= 0
          ? '${dataProvider.activeAppsCount} Active Apps • Peak: ${dataProvider.peakHour}:00'
          : '${dataProvider.activeAppsCount} Active Apps',
      isDark: isDark,
      isMono: false,
    );

    if (isNarrow) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: card2),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: card3),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: card4),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: card1),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: card2),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: card3),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: card4),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isMono,
  }) {
    return GlassCard(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isMono
                      ? AppTypography.mono(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1C1E),
                        )
                      : TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopAppsCard(
    BuildContext context,
    List<dynamic> topApps,
    int totalBytes,
    bool isDark,
    ThemeData theme,
  ) {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.flame_fill,
                      size: 16, color: Color(0xFFFF9500)),
                  const SizedBox(width: 8),
                  Text(
                    'Top Bandwidth Consumers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Top ${topApps.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (topApps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  "No network activity recorded for this timeframe.",
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topApps.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final app = topApps[index];
                final double percent = totalBytes > 0
                    ? (app.totalBytes / totalBytes).clamp(0.0, 1.0)
                    : 0.0;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => AppDetailScreen(
                          appUsage: app,
                          heroTagPrefix: 'dashboard_desktop_',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: Row(
                      children: [
                        // App Icon
                        if (app.appIcon != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              app.appIcon!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          )
                        else
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(CupertinoIcons.app_fill,
                                color: Color(0xFF007AFF), size: 18),
                          ),
                        const SizedBox(width: 12),
                        // App Name & Down/Up Breakdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '↓ ${FormatUtils.formatBytes(app.rxBytes)}  •  ↑ ${FormatUtils.formatBytes(app.txBytes)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6E6E73),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Percentage & Total
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              FormatUtils.formatBytes(app.totalBytes),
                              style: AppTypography.mono(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 4,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      backgroundColor:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.08),
                                      valueColor: const AlwaysStoppedAnimation(
                                          Color(0xFF007AFF)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(percent * 100).toStringAsFixed(1)}%',
                                  style: AppTypography.mono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6E6E73),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 14, color: Color(0xFF8E8E93)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
