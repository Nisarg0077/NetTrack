import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/update_dialog.dart';
import '../widgets/usage_chart.dart';
import '../widgets/app_usage_tile.dart';
import '../widgets/daily_summary_card.dart';
import 'dart:io';
import 'dart:ui';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.errorMessage != null && dataProvider.appUsages.isEmpty && dataProvider.networkStats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(dataProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dataProvider.fetchData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty && dataProvider.networkStats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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
              RefreshIndicator(
                onRefresh: () async {
                  await dataProvider.fetchData();
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 800;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          title: const Text('NetTrack', style: TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          flexibleSpace: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          actions: [

                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                Provider.of<DataProvider>(context, listen: false).fetchData();
                              },
                            ),
                          ],
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const DateSelectorBar(),
                          if (dataProvider.isUpdateAvailable)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Material(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.system_update, color: Colors.blueAccent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Update ${dataProvider.updateLatestVersion} is available! Tap to download.',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.blueAccent),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: DailySummaryCard(
                                    totalBytes: totalBytes,
                                    txBytes: totalTx,
                                    rxBytes: totalRx,
                                    activeAppsCount: dataProvider.activeAppsCount,
                                    peakHour: dataProvider.peakHour,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Data Usage Trend', style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 300,
                                        child: UsageChart(
                                          dailyTrend: dataProvider.dailyTrend,
                                          weeklyTrend: dataProvider.weeklyTrend,
                                          monthlyTrend: dataProvider.monthlyTrend,
                                        ),
                                      ),
                                    ],
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
                              const SizedBox(height: 24),
                            Text('Data Usage Trend', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: UsageChart(
                                dailyTrend: dataProvider.dailyTrend,
                                weeklyTrend: dataProvider.weeklyTrend,
                                monthlyTrend: dataProvider.monthlyTrend,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text('Top Data Hungry Apps', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          if (topApps.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text("No app usage data found for this period."),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: topApps.length,
                              itemBuilder: (context, index) {
                                return AppUsageTile(
                                  appUsage: topApps[index],
                                  totalDeviceBytes: totalBytes,
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          Text('Network Interfaces', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          if (dataProvider.networkStats.isEmpty)
                            const Center(child: Text("No network interfaces found."))
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400,
                                mainAxisExtent: 100,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: dataProvider.networkStats.length,
                              itemBuilder: (context, index) {
                                final stat = dataProvider.networkStats[index];
                                return Card(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Center(
                                      child: ListTile(
                                        leading: const Icon(Icons.network_wifi, size: 36),
                                        title: Text(stat.interfaceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text("Tx: ${stat.txBytes} B | Rx: ${stat.rxBytes} B"),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
              if (dataProvider.isLoading && (dataProvider.appUsages.isNotEmpty || dataProvider.networkStats.isNotEmpty))
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}
