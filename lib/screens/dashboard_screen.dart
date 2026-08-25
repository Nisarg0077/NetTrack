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
import 'dart:io';

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.errorMessage != null && dataProvider.appUsages.isEmpty && dataProvider.networkStats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 36, color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dataProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      onPressed: () => dataProvider.fetchData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty && dataProvider.networkStats.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          // Calculate total usage
          int totalRx = 0;
          int totalTx = 0;
          if (Platform.isWindows) {
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

          // Get top 5 apps
          final topApps = dataProvider.appUsages.take(5).toList();

          return Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  CupertinoSliverNavigationBar(
                    largeTitle: const Text('Overview'),
                    backgroundColor: isDark
                        ? const Color(0x99000000)
                        : const Color(0x99F2F2F7),
                    border: null,
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
                      onPressed: () {
                        Provider.of<DataProvider>(context, listen: false).fetchData();
                      },
                    ),
                  ),

                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      await dataProvider.fetchData();
                    },
                  ),

                  SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 768;

                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, isDesktop ? 40 : 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const DateSelectorBar(),
                              const SizedBox(height: 16),

                              if (dataProvider.isUpdateAvailable)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => UpdateDialog(
                                            latestVersion: dataProvider.updateLatestVersion ?? '',
                                            releaseNotes: dataProvider.updateReleaseNotes ?? '',
                                            releaseUrl: dataProvider.updateReleaseUrl ?? '',
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.2),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(CupertinoIcons.arrow_down_circle_fill, color: theme.colorScheme.primary, size: 22),
                                            const SizedBox(width: 12),
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
                                            Icon(CupertinoIcons.chevron_right, color: theme.colorScheme.primary, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: DailySummaryCard(
                                        totalBytes: totalBytes,
                                        txBytes: totalTx,
                                        rxBytes: totalRx,
                                        activeAppsCount: dataProvider.activeAppsCount,
                                        peakHour: dataProvider.peakHour,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 7,
                                      child: SizedBox(
                                        height: 380,
                                        child: UsageChart(
                                          dailyTrend: dataProvider.dailyTrend,
                                          weeklyTrend: dataProvider.weeklyTrend,
                                          monthlyTrend: dataProvider.monthlyTrend,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                DailySummaryCard(
                                  totalBytes: totalBytes,
                                  txBytes: totalTx,
                                  rxBytes: totalRx,
                                  activeAppsCount: dataProvider.activeAppsCount,
                                  peakHour: dataProvider.peakHour,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 270,
                                  child: UsageChart(
                                    dailyTrend: dataProvider.dailyTrend,
                                    weeklyTrend: dataProvider.weeklyTrend,
                                    monthlyTrend: dataProvider.monthlyTrend,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 28),

                              // Top Apps Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Top Data Hungry Apps',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'Top ${topApps.length}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              if (topApps.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "No network activity recorded for this timeframe.",
                                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13.5),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: topApps.length,
                                  itemBuilder: (context, index) {
                                    return AppUsageTile(
                                      appUsage: topApps[index],
                                      totalDeviceBytes: totalBytes,
                                    );
                                  },
                                ),

                              const SizedBox(height: 28),

                              // Network Interfaces Section
                              Text(
                                'Hardware Interfaces',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 14),

                              if (dataProvider.networkStats.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "No local network adapters detected.",
                                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13.5),
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 420,
                                    mainAxisExtent: 84,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: dataProvider.networkStats.length,
                                  itemBuilder: (context, index) {
                                    final stat = dataProvider.networkStats[index];
                                    final isWifi = stat.interfaceName.toLowerCase().contains('wi-fi') ||
                                        stat.interfaceName.toLowerCase().contains('wlan') ||
                                        stat.interfaceName.toLowerCase().contains('wireless');

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                                          width: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isWifi ? CupertinoIcons.wifi : CupertinoIcons.bolt_horizontal_circle,
                                              size: 20,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  stat.interfaceName,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Tx: ${FormatUtils.formatBytes(stat.txBytes)}  •  Rx: ${FormatUtils.formatBytes(stat.rxBytes)}",
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (dataProvider.isLoading && (dataProvider.appUsages.isNotEmpty || dataProvider.networkStats.isNotEmpty))
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }
}
