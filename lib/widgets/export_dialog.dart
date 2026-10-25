import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/app_usage_model.dart';
import '../models/export_history_item.dart';
import '../services/data_usage_service.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

enum ExportPeriodOption {
  thisWeek,
  thisMonth,
  dateRange,
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

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  Map<String, dynamic> _computePeriod(ExportPeriodOption option) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    String label;

    switch (option) {
      case ExportPeriodOption.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        end = now;
        label =
            '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
        break;
      case ExportPeriodOption.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = now;
        label = DateFormat('MMMM yyyy').format(now);
        break;
      case ExportPeriodOption.dateRange:
        start = DateTime(_dateRange.start.year, _dateRange.start.month,
            _dateRange.start.day);
        end = DateTime(_dateRange.end.year, _dateRange.end.month,
            _dateRange.end.day, 23, 59, 59);
        label =
            '${DateFormat('MMM d, yyyy').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
        break;
    }

    return {'start': start, 'end': end, 'label': label};
  }

  String _getOptionTitle(ExportPeriodOption option) {
    switch (option) {
      case ExportPeriodOption.thisWeek:
        return 'This Week';
      case ExportPeriodOption.thisMonth:
        return 'This Month';
      case ExportPeriodOption.dateRange:
        return 'Custom Date Range';
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
      final networkStats = await _dataUsageService.getGeneralNetworkStats(
          startDate: start, endDate: end);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.checkmark_alt,
                        color: Color(0xFF34C759), size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Report Exported',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.fileName} (${item.totalBytesFormatted})',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportService.shareFile(item.filePath);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.share,
                                size: 18,
                                color: isDark ? Colors.white : Colors.black),
                            const SizedBox(width: 6),
                            Text('Share',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportService.openFile(item.filePath);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.arrow_up_right_square,
                                size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Open File',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CupertinoButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 14)),
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
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final periodInfo = _computePeriod(_selectedOption);
    final String previewLabel = periodInfo['label'] as String;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xE6141722) : const Color(0xF2F2F2F7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.85,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF48484A)
                          : const Color(0xFFC7C7CC),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Export Data Report',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color:
                                isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(30, 30),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Period Section
                          Text(
                            'TIME PERIOD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0x1FFFFFFF)
                                    : const Color(0x14000000),
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              children: ExportPeriodOption.values.map((option) {
                                final isSelected = _selectedOption == option;
                                return Column(
                                  children: [
                                    ListTile(
                                      dense: true,
                                      title: Text(
                                        _getOptionTitle(option),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1C1C1E),
                                        ),
                                      ),
                                      subtitle: _buildOptionSubtitle(option),
                                      trailing: isSelected
                                          ? Icon(
                                              CupertinoIcons
                                                  .checkmark_circle_fill,
                                              color: primaryColor,
                                              size: 20)
                                          : const Icon(CupertinoIcons.circle,
                                              color: Color(0xFF8E8E93),
                                              size: 20),
                                      onTap: () {
                                        setState(() {
                                          _selectedOption = option;
                                        });
                                      },
                                    ),
                                    if (option !=
                                        ExportPeriodOption.values.last)
                                      Divider(
                                          height: 1,
                                          indent: 16,
                                          endIndent: 16,
                                          color: isDark
                                              ? const Color(0xFF38383A)
                                              : const Color(0xFFE5E5EA)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Export Format Selector
                          Text(
                            'FORMAT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoSlidingSegmentedControl<bool>(
                              groupValue: _isExcel,
                              backgroundColor: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                              children: {
                                true: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.table_badge_more_fill,
                                          size: 16,
                                          color: _isExcel
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                      const SizedBox(width: 6),
                                      Text('Excel (.xlsx)',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ],
                                  ),
                                ),
                                false: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.doc_text_fill,
                                          size: 16,
                                          color: !_isExcel
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                      const SizedBox(width: 6),
                                      Text('CSV (.csv)',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ],
                                  ),
                                ),
                              },
                              onValueChanged: (val) {
                                if (val != null) setState(() => _isExcel = val);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Options Container
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0x1FFFFFFF)
                                    : const Color(0x14000000),
                                width: 0.8,
                              ),
                            ),
                            child: CupertinoListTile(
                              title: const Text('Custom Destination Folder',
                                  style: TextStyle(fontSize: 14)),
                              subtitle: const Text(
                                  'Prompt for save directory on export',
                                  style: TextStyle(fontSize: 12)),
                              trailing: CupertinoSwitch(
                                value: _chooseSaveLocation,
                                onChanged: (val) =>
                                    setState(() => _chooseSaveLocation = val),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Summary Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(
                                  alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.info_circle_fill,
                                    color: primaryColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Exporting $previewLabel usage for ${dataProvider.appUsages.length} apps as ${_isExcel ? "Excel" : "CSV"}.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? const Color(0xFFE5E5EA)
                                          : const Color(0xFF1C1C1E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _isExporting ? null : _runExport,
                        child: _isExporting
                            ? const CupertinoActivityIndicator(
                                radius: 10, color: Colors.white)
                            : const Text('Generate & Export Report',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildOptionSubtitle(ExportPeriodOption option) {
    if (option == ExportPeriodOption.dateRange &&
        _selectedOption == ExportPeriodOption.dateRange) {
      return GestureDetector(
        onTap: _pickDateRange,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.calendar,
                  size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('MMM d').format(_dateRange.start)} – ${DateFormat('MMM d, yyyy').format(_dateRange.end)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return null;
  }
}
