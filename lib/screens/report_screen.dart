import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/data_provider.dart';
import '../models/app_usage_model.dart';
import '../utils/format_utils.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/export_dialog.dart';
import 'dart:ui';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detailed Report', style: TextStyle(fontWeight: FontWeight.bold)),
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
          if (dataProvider.errorMessage != null && dataProvider.appUsages.isEmpty) {
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

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 90), // Padding for transparent app bar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: DateSelectorBar(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: filteredApps.isEmpty
                    ? const Center(child: Text("No apps found."))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  sortColumnIndex: _sortColumnIndex,
                                  sortAscending: _isAscending,
                                  columns: [
                                    DataColumn(
                                      label: const Text('App Name'),
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
                                      label: const Text('% of Total'),
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
                                                  child: Platform.isWindows
                                                      ? const Icon(Icons.window, size: 24, color: Colors.blue)
                                                      : const Icon(Icons.android, size: 24, color: Colors.green),
                                                ),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 150),
                                                child: Text(
                                                  app.appName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          )
                                        ),
                                        DataCell(Text(FormatUtils.formatBytes(app.rxBytes))),
                                        DataCell(Text(FormatUtils.formatBytes(app.txBytes))),
                                        DataCell(Text('${percentage.toStringAsFixed(1)}%')),
                                        DataCell(Text(
                                          FormatUtils.formatBytes(app.totalBytes),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
