import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../models/app_usage_model.dart';
import '../utils/format_utils.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/export_dialog.dart';
import 'app_detail_screen.dart';

// Design System
import '../core/widgets/glass_card.dart';
import '../core/design_system/glass_toolbar.dart';
import '../core/design_system/floating_pill.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/platform/platform_service.dart';

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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.errorMessage != null &&
              dataProvider.appUsages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle_fill,
                          size: 36, color: theme.colorScheme.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(dataProvider.errorMessage!,
                          textAlign: TextAlign.center),
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

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          // Total bytes calculation for percentage
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

          // Filter apps
          List<AppUsageModel> filteredApps =
              dataProvider.appUsages.where((app) {
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
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverGlassToolbarDelegate(
                  height: MediaQuery.of(context).padding.top +
                      (PlatformService.isDesktop ? 152.0 : 166.0),
                  child: SafeArea(
                    bottom: false,
                    child: GlassToolbar(
                      useSafeArea: false,
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      title: 'Detailed Report',
                      statusWidget: ConnectionStatusPill(
                        label: '${filteredApps.length} Records',
                        color: const Color(0xFF5856D6),
                        isLive: false,
                      ),
                      actions: [
                        FloatingActionPill(
                          icon: CupertinoIcons.share,
                          label: 'Export',
                          isPrimary: true,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const ExportDialog(),
                            );
                          },
                        ),
                        FloatingActionPill(
                          icon: CupertinoIcons.arrow_clockwise,
                          label: 'Refresh',
                          onPressed: () => dataProvider.fetchData(),
                        ),
                      ],
                      bottom: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 2, 14, 6),
                            child: DateSelectorBar(),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? const Color(0xFF1E212B)
                                        : Colors.white)
                                    .withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 0.85,
                                ),
                              ),
                              child: Center(
                                child: CupertinoSearchTextField(
                                  placeholder: 'Filter report by app name...',
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      10, 0, 10, 0),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1C1C1E),
                                    fontSize: 13.5,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value.toLowerCase();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    PlatformService.isDesktop ? AppSpacing.xl : AppSpacing.md,
                    0,
                    PlatformService.isDesktop ? AppSpacing.xl : AppSpacing.md,
                    PlatformService.isDesktop ? 60.0 : 120.0,
                  ),
                  child: filteredApps.isEmpty
                      ? GlassCard(
                          enableBlur: true,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: Text(
                                "No matching app telemetry records found.",
                                style: TextStyle(
                                    color: Color(0xFF8E8E93), fontSize: 13.5),
                              ),
                            ),
                          ),
                        )
                      : GlassCard(
                          enableBlur: true,
                          padding: EdgeInsets.zero,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    sortColumnIndex: _sortColumnIndex,
                                    sortAscending: _isAscending,
                                    headingRowColor: WidgetStateProperty.all(
                                      isDark
                                          ? const Color(0xFF252834)
                                          : const Color(0xFFF3F5FA),
                                    ),
                                    headingTextStyle: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
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
                                          : (app.totalBytes / totalBytes * 100)
                                              .clamp(0.0, 100.0);

                                      return DataRow(
                                        onSelectChanged: (_) {
                                          Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) =>
                                                  AppDetailScreen(
                                                appUsage: app,
                                                heroTagPrefix: 'report_',
                                              ),
                                            ),
                                          );
                                        },
                                        cells: [
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (app.appIcon != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      child: Image.memory(
                                                        app.appIcon!,
                                                        width: 24,
                                                        height: 24,
                                                        fit: BoxFit.cover,
                                                        gaplessPlayback: true,
                                                        cacheWidth: 48,
                                                        cacheHeight: 48,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: Icon(
                                                      Platform.isWindows
                                                          ? CupertinoIcons
                                                              .desktopcomputer
                                                          : CupertinoIcons
                                                              .device_phone_portrait,
                                                      size: 20,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 160),
                                                  child: Text(
                                                    app.appName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(
                                            FormatUtils.formatBytes(
                                                app.rxBytes),
                                            style: GoogleFonts.jetBrainsMono(
                                                fontSize: 12),
                                          )),
                                          DataCell(Text(
                                            FormatUtils.formatBytes(
                                                app.txBytes),
                                            style: GoogleFonts.jetBrainsMono(
                                                fontSize: 12),
                                          )),
                                          DataCell(Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                      .lightTextSecondary,
                                            ),
                                          )),
                                          DataCell(Text(
                                            FormatUtils.formatBytes(
                                                app.totalBytes),
                                            style: GoogleFonts.jetBrainsMono(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                              color: primaryColor,
                                            ),
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
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
