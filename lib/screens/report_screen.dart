import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/data_provider.dart';
import '../models/app_usage_model.dart';
import '../utils/format_utils.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/export_dialog.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _searchQuery = '';
  int _sortColumnIndex = 4; // Sort by Total by default
  bool _isAscending = false;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.errorMessage != null && dataProvider.appUsages.isEmpty) {
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
                    Text(dataProvider.errorMessage!, textAlign: TextAlign.center),
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

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          // Total bytes calculation for percentage
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

          // Filter apps
          List<AppUsageModel> filteredApps = dataProvider.appUsages.where((app) {
            return app.appName.toLowerCase().contains(_searchQuery) ||
                   app.packageName.toLowerCase().contains(_searchQuery);
          }).toList();

          // Sort apps
          filteredApps.sort((a, b) {
            int result;
            switch (_sortColumnIndex) {
              case 0:
                result = a.appName.compareTo(b.appName);
                break;
              case 1:
                result = a.rxBytes.compareTo(b.rxBytes);
                break;
              case 2:
                result = a.txBytes.compareTo(b.txBytes);
                break;
              case 3: // % uses Total
              case 4:
                result = a.totalBytes.compareTo(b.totalBytes);
                break;
              default:
                result = 0;
                break;
            }
            return _isAscending ? result : -result;
          });

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Detailed Report'),
                backgroundColor: isDark
                    ? const Color(0x99000000)
                    : const Color(0x99F2F2F7),
                border: null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.share, size: 20),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ExportDialog(),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
                      onPressed: () {
                        Provider.of<DataProvider>(context, listen: false).fetchData();
                      },
                    ),
                  ],
                ),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await dataProvider.fetchData();
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DateSelectorBar(),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                            width: 0.8,
                          ),
                        ),
                        child: CupertinoSearchTextField(
                          placeholder: 'Filter report by app name...',
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontSize: 14,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  child: filteredApps.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                              width: 0.8,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "No matching app telemetry records found.",
                              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13.5),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: DataTable(
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _isAscending,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                                ),
                                headingTextStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                ),
                                columns: [
                                  DataColumn(
                                    label: const Text('App'),
                                    onSort: _onSort,
                                  ),
                                  DataColumn(
                                    label: const Text('Download'),
                                    numeric: true,
                                    onSort: _onSort,
                                  ),
                                  DataColumn(
                                    label: const Text('Upload'),
                                    numeric: true,
                                    onSort: _onSort,
                                  ),
                                  DataColumn(
                                    label: const Text('Share'),
                                    numeric: true,
                                    onSort: _onSort,
                                  ),
                                  DataColumn(
                                    label: const Text('Total Usage'),
                                    numeric: true,
                                    onSort: _onSort,
                                  ),
                                ],
                                rows: filteredApps.map((app) {
                                  final percentage = totalBytes == 0
                                      ? 0.0
                                      : (app.totalBytes / totalBytes * 100).clamp(0.0, 100.0);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (app.appIcon != null)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.memory(
                                                    app.appIcon!,
                                                    width: 24,
                                                    height: 24,
                                                  ),
                                                ),
                                              )
                                            else
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8.0),
                                                child: Icon(
                                                  Platform.isWindows
                                                      ? CupertinoIcons.desktopcomputer
                                                      : CupertinoIcons.device_phone_portrait,
                                                  size: 20,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 160),
                                              child: Text(
                                                app.appName,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(
                                        FormatUtils.formatBytes(app.rxBytes),
                                        style: const TextStyle(fontSize: 12.5),
                                      )),
                                      DataCell(Text(
                                        FormatUtils.formatBytes(app.txBytes),
                                        style: const TextStyle(fontSize: 12.5),
                                      )),
                                      DataCell(Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                        ),
                                      )),
                                      DataCell(Text(
                                        FormatUtils.formatBytes(app.totalBytes),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: primaryColor,
                                        ),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
