import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/export_dialog.dart';
import '../widgets/usage_chart.dart';
import '../widgets/app_usage_tile.dart';
import 'dart:io';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Report',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ExportDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).fetchData();
            },
          )
        ],
      ),
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
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DateSelectorBar(),
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
                                        child: UsageChart(weeklyTrend: dataProvider.weeklyTrend),
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
                              child: UsageChart(weeklyTrend: dataProvider.weeklyTrend),
                            ),
                          ],
                          const SizedBox(height: 24),
                          
                          // Always show top apps now that Windows is supported
                          ...[
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
                          ],
                          const SizedBox(height: 24),
                          ...[
                            Text('Network Interfaces', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            if (dataProvider.networkStats.isEmpty)
                              const Center(child: Text("No network interfaces found."))
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
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
                          ]
                        ],
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'export_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const ExportDialog(),
          );
        },
        icon: const Icon(Icons.download_rounded),
        label: const Text('Export'),
      ),
    );
  }
}
