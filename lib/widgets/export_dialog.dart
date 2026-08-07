import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_usage_model.dart';
import '../models/export_history_item.dart';
import '../services/data_usage_service.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

enum ExportPeriodOption {
  specificDay,
  dateRange,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  customMonth,
  thisYear,
  lastYear,
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final ExportService _exportService = ExportService();
  final DataUsageService _dataUsageService = DataUsageService();

  ExportPeriodOption _selectedOption = ExportPeriodOption.thisMonth;
  bool _isExcel = true;
  bool _chooseSaveLocation = false;
  bool _isExporting = false;

  DateTime _specificDay = DateTime.now();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  DateTime _customMonth = DateTime.now();

  Map<String, dynamic> _computePeriod(ExportPeriodOption option) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    String label;

    switch (option) {
      case ExportPeriodOption.specificDay:
        start = DateTime(_specificDay.year, _specificDay.month, _specificDay.day);
        end = DateTime(_specificDay.year, _specificDay.month, _specificDay.day, 23, 59, 59);
        label = DateFormat('MMM d, yyyy').format(start);
        break;
      case ExportPeriodOption.dateRange:
        start = DateTime(_dateRange.start.year, _dateRange.start.month, _dateRange.start.day);
        end = DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day, 23, 59, 59);
        label = '${DateFormat('MMM d, yyyy').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
        break;
      case ExportPeriodOption.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        end = now;
        label = '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
        break;
      case ExportPeriodOption.lastWeek:
        final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
        start = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day);
        final endOfLastWeek = startOfThisWeek.subtract(const Duration(milliseconds: 1));
        end = endOfLastWeek;
        label = '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
        break;
      case ExportPeriodOption.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = now;
        label = DateFormat('MMMM yyyy').format(now);
        break;
      case ExportPeriodOption.lastMonth:
        final startOfThisMonth = DateTime(now.year, now.month, 1);
        final endOfLastMonth = startOfThisMonth.subtract(const Duration(milliseconds: 1));
        start = DateTime(endOfLastMonth.year, endOfLastMonth.month, 1);
        end = endOfLastMonth;
        label = DateFormat('MMMM yyyy').format(start);
        break;
      case ExportPeriodOption.customMonth:
        start = DateTime(_customMonth.year, _customMonth.month, 1);
        final nextMonth = _customMonth.month == 12
            ? DateTime(_customMonth.year + 1, 1, 1)
            : DateTime(_customMonth.year, _customMonth.month + 1, 1);
        end = nextMonth.subtract(const Duration(milliseconds: 1));
        if (end.isAfter(now)) end = now;
        label = DateFormat('MMMM yyyy').format(start);
        break;
      case ExportPeriodOption.thisYear:
        start = DateTime(now.year, 1, 1);
        end = now;
        label = DateFormat('yyyy').format(now);
        break;
      case ExportPeriodOption.lastYear:
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        label = DateFormat('yyyy').format(start);
        break;
    }

    return {'start': start, 'end': end, 'label': label};
  }

  String _getOptionTitle(ExportPeriodOption option) {
    switch (option) {
      case ExportPeriodOption.specificDay:
        return 'Specific Day';
      case ExportPeriodOption.dateRange:
        return 'Date Range';
      case ExportPeriodOption.thisWeek:
        return 'This Week';
      case ExportPeriodOption.lastWeek:
        return 'Last Week';
      case ExportPeriodOption.thisMonth:
        return 'This Month';
      case ExportPeriodOption.lastMonth:
        return 'Last Month';
      case ExportPeriodOption.customMonth:
        return 'Custom Month';
      case ExportPeriodOption.thisYear:
        return 'This Year';
      case ExportPeriodOption.lastYear:
        return 'Last Year';
    }
  }

  Future<void> _pickSpecificDay() async {
    final firstDate = await SettingsService().getAppInstallationDate();
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDay.isBefore(firstDate) ? firstDate : _specificDay,
      firstDate: firstDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _specificDay = picked;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final firstDate = await SettingsService().getAppInstallationDate();
    if (!mounted) return;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _pickCustomMonth() async {
    final firstDate = await SettingsService().getAppInstallationDate();
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _customMonth,
      firstDate: firstDate,
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _customMonth = picked;
      });
    }
  }

  Future<void> _runExport() async {
    setState(() {
      _isExporting = true;
    });

    final period = _computePeriod(_selectedOption);
    final DateTime start = period['start'] as DateTime;
    final DateTime end = period['end'] as DateTime;
    final String label = period['label'] as String;

    final List<AppUsageModel> usages =
        await _dataUsageService.getAppNetworkUsage(start, end);

    int totalRx = 0;
    int totalTx = 0;
    if (Platform.isWindows) {
      final networkStats = await _dataUsageService.getGeneralNetworkStats(startDate: start, endDate: end);
      for (var stat in networkStats) {
        totalRx += stat.rxBytes;
        totalTx += stat.txBytes;
      }
    } else {
      for (var app in usages) {
        totalRx += app.rxBytes;
        totalTx += app.txBytes;
      }
    }

    final item = await _exportService.exportReport(
      usages: usages,
      reportTypeLabel: '${_getOptionTitle(_selectedOption)} Report',
      dateRangeLabel: label,
      isExcel: _isExcel,
      saveToCustomLocation: _chooseSaveLocation,
      systemTotalRx: totalRx,
      systemTotalTx: totalTx,
    );

    setState(() {
      _isExporting = false;
    });

    if (!mounted) return;
    Navigator.pop(context); // Close dialog

    if (item != null) {
      _showSuccessSheet(context, item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export usage report.')),
      );
    }
  }

  void _showSuccessSheet(BuildContext context, ExportHistoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Report Exported!',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.fileName} (${item.totalBytesFormatted})',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportService.shareFile(item.filePath);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open File'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportService.openFile(item.filePath);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final periodInfo = _computePeriod(_selectedOption);
    final String previewLabel = periodInfo['label'] as String;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('EXPORT CONFIGURATION',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.primary,
                        )),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Period Selector
                      Text('TIME PERIOD',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.textTheme.bodySmall?.color,
                          )),
                      const SizedBox(height: 8),
                      ...ExportPeriodOption.values.map((option) {
                        return RadioListTile<ExportPeriodOption>(
                          title: Text(_getOptionTitle(option)),
                          subtitle: _buildOptionSubtitle(option),
                          value: option,
                          // ignore: deprecated_member_use
                          groupValue: _selectedOption,
                          activeColor: theme.colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                          // ignore: deprecated_member_use
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedOption = val;
                              });
                            }
                          },
                        );
                      }),
                      const SizedBox(height: 16),

                      // Export Format Selector
                      Text('EXPORT FORMAT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.textTheme.bodySmall?.color,
                          )),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            label: Text('Excel (.xlsx)'),
                            icon: Icon(Icons.table_chart_rounded),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text('CSV (.csv)'),
                            icon: Icon(Icons.description_rounded),
                          ),
                        ],
                        selected: {_isExcel},
                        onSelectionChanged: (set) {
                          setState(() {
                            _isExcel = set.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Choose save location switch
                      SwitchListTile(
                        title: const Text('Choose Save Location'),
                        subtitle: const Text('Prompt for destination folder'),
                        value: _chooseSaveLocation,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _chooseSaveLocation = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Report Summary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      )),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Includes $previewLabel usage for ${dataProvider.appUsages.length} apps (${_isExcel ? "Excel (.xlsx)" : "CSV (.csv)"})',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : _runExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(_isExporting ? 'Generating Report...' : 'Export Report'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildOptionSubtitle(ExportPeriodOption option) {
    if (option == ExportPeriodOption.specificDay &&
        _selectedOption == ExportPeriodOption.specificDay) {
      return TextButton.icon(
        onPressed: _pickSpecificDay,
        icon: const Icon(Icons.calendar_today, size: 14),
        label: Text(DateFormat('MMM d, yyyy').format(_specificDay)),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
        ),
      );
    }
    if (option == ExportPeriodOption.dateRange &&
        _selectedOption == ExportPeriodOption.dateRange) {
      return TextButton.icon(
        onPressed: _pickDateRange,
        icon: const Icon(Icons.date_range, size: 14),
        label: Text(
            '${DateFormat('MMM d').format(_dateRange.start)} – ${DateFormat('MMM d, yyyy').format(_dateRange.end)}'),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
        ),
      );
    }
    if (option == ExportPeriodOption.customMonth &&
        _selectedOption == ExportPeriodOption.customMonth) {
      return TextButton.icon(
        onPressed: _pickCustomMonth,
        icon: const Icon(Icons.calendar_month, size: 14),
        label: Text(DateFormat('MMMM yyyy').format(_customMonth)),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
        ),
      );
    }
    return null;
  }
}
