import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../models/app_usage_model.dart';
import '../models/export_history_item.dart';
import '../services/settings_service.dart';
import '../utils/format_utils.dart';

class ExportService {
  /// Backward compatibility with existing CSV export
  Future<String?> exportToCsv(List<AppUsageModel> usages) async {
    final item = await exportReport(
      usages: usages,
      reportTypeLabel: 'Usage Report',
      dateRangeLabel: 'Current Period',
      isExcel: false,
      saveToCustomLocation: false,
    );
    return item?.filePath;
  }

  /// New flexible report export supporting professional .xlsx and enhanced .csv
  Future<ExportHistoryItem?> exportReport({
    required List<AppUsageModel> usages,
    required String reportTypeLabel,
    required String dateRangeLabel,
    required bool isExcel,
    required bool saveToCustomLocation,
    int? systemTotalRx,
    int? systemTotalTx,
  }) async {
    try {
      int appsTotalRx = 0;
      int appsTotalTx = 0;
      for (var usage in usages) {
        appsTotalRx += usage.rxBytes;
        appsTotalTx += usage.txBytes;
      }
      final totalRx = systemTotalRx ?? appsTotalRx;
      final totalTx = systemTotalTx ?? appsTotalTx;
      final totalCombined = totalRx + totalTx;
      final now = DateTime.now();
      final timestampStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      List<int>? bytes;
      String extension = isExcel ? 'xlsx' : 'csv';
      String fileName =
          'NetTrack_Report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.$extension';

      if (isExcel) {
        bytes = _generateExcelBytes(
          usages: usages,
          reportTypeLabel: reportTypeLabel,
          dateRangeLabel: dateRangeLabel,
          timestampStr: timestampStr,
          totalRx: totalRx,
          totalTx: totalTx,
          totalCombined: totalCombined,
        );
      } else {
        String csvData = _generateCsvString(
          usages: usages,
          reportTypeLabel: reportTypeLabel,
          dateRangeLabel: dateRangeLabel,
          timestampStr: timestampStr,
          totalRx: totalRx,
          totalTx: totalTx,
          totalCombined: totalCombined,
        );
        bytes = csvData.codeUnits;
      }

      if (bytes == null || bytes.isEmpty) return null;

      String? savePath;
      if (saveToCustomLocation) {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save NetTrack Report',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extension],
        );
      }

      if (savePath == null) {
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Documents');
          if (!await directory.exists()) {
            directory = Directory('/storage/emulated/0/Download');
          }
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
        directory ??= await getTemporaryDirectory();
        savePath = '${directory.path}/$fileName';
      }

      final file = File(savePath);
      await file.writeAsBytes(bytes);

      final item = ExportHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: file.uri.pathSegments.last,
        filePath: file.path,
        format: isExcel ? '.xlsx' : '.csv',
        dateRangeLabel: dateRangeLabel,
        generatedAt: now,
        totalBytesFormatted: FormatUtils.formatBytes(totalCombined),
      );

      await SettingsService().saveExportHistoryItem(item);
      return item;
    } catch (e) {
      debugPrint("Error exporting report: $e");
      return null;
    }
  }

  List<int>? _generateExcelBytes({
    required List<AppUsageModel> usages,
    required String reportTypeLabel,
    required String dateRangeLabel,
    required String timestampStr,
    required int totalRx,
    required int totalTx,
    required int totalCombined,
  }) {
    var excel = Excel.createExcel();
    String sheetName = 'Usage Report';
    Sheet sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // Set auto/default column widths
    sheet.setColumnWidth(0, 26.0); // App Name
    sheet.setColumnWidth(1, 32.0); // Package Name
    sheet.setColumnWidth(2, 18.0); // Download (MB)
    sheet.setColumnWidth(3, 18.0); // Upload (MB)
    sheet.setColumnWidth(4, 18.0); // Total Usage (MB)
    sheet.setColumnWidth(5, 16.0); // % of Total
    sheet.setColumnWidth(6, 16.0); // Usage Time (s)

    // Row 0: NetTrack Title & Timestamp
    var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue("NetTrack - $reportTypeLabel");
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#1A237E'),
    );

    var timeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));
    timeCell.value = TextCellValue("Generated: $timestampStr");
    timeCell.cellStyle = CellStyle(italic: true, fontSize: 10);

    // Row 1: Date Range
    var rangeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    rangeCell.value = TextCellValue("Period: $dateRangeLabel");
    rangeCell.cellStyle = CellStyle(bold: true, fontSize: 12);

    // Row 2: Summary Stats
    var sumCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
    final dlMb = (totalRx / (1024 * 1024)).toStringAsFixed(2);
    final ulMb = (totalTx / (1024 * 1024)).toStringAsFixed(2);
    final totMb = (totalCombined / (1024 * 1024)).toStringAsFixed(2);
    sumCell.value = TextCellValue(
        "Total Combined: $totMb MB (Download: $dlMb MB | Upload: $ulMb MB)");
    sumCell.cellStyle = CellStyle(bold: true, fontSize: 11);

    // Row 4: Table Header with Dark Blue (#1A237E) background and white text
    final headers = [
      "App Name",
      "Package Name",
      "Download (MB)",
      "Upload (MB)",
      "Total Usage (MB)",
      "% of Total",
      "Usage Time (s)"
    ];

    int headerRow = 4;
    for (int col = 0; col < headers.length; col++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
        horizontalAlign: col >= 2 ? HorizontalAlign.Right : HorizontalAlign.Left,
      );
    }

    // Rows 5..N: Data Rows with alternating backgrounds (#FFFFFF and #F5F5F5)
    for (int i = 0; i < usages.length; i++) {
      int rowIdx = 5 + i;
      final usage = usages[i];
      final rxMbVal = usage.rxBytes / (1024 * 1024);
      final txMbVal = usage.txBytes / (1024 * 1024);
      final totMbVal = usage.totalBytes / (1024 * 1024);
      final pct = totalCombined == 0 ? 0.0 : (usage.totalBytes / totalCombined) * 100.0;

      final bool isAlt = (i % 2 == 1);
      final bgColor = isAlt
          ? ExcelColor.fromHexString('#F5F5F5')
          : ExcelColor.fromHexString('#FFFFFF');

      _setCell(sheet, 0, rowIdx, TextCellValue(usage.appName), bgColor, HorizontalAlign.Left);
      _setCell(sheet, 1, rowIdx, TextCellValue(usage.packageName), bgColor, HorizontalAlign.Left);
      _setCell(sheet, 2, rowIdx, DoubleCellValue(double.parse(rxMbVal.toStringAsFixed(2))), bgColor, HorizontalAlign.Right);
      _setCell(sheet, 3, rowIdx, DoubleCellValue(double.parse(txMbVal.toStringAsFixed(2))), bgColor, HorizontalAlign.Right);
      _setCell(sheet, 4, rowIdx, DoubleCellValue(double.parse(totMbVal.toStringAsFixed(2))), bgColor, HorizontalAlign.Right);
      _setCell(sheet, 5, rowIdx, TextCellValue("${pct.toStringAsFixed(1)}%"), bgColor, HorizontalAlign.Center);
      _setCell(sheet, 6, rowIdx, IntCellValue(0), bgColor, HorizontalAlign.Right);
    }

    // Row N+1: Summary Row
    int totalRowIdx = 5 + usages.length;
    final totalBg = ExcelColor.fromHexString('#E8EAF6');
    _setCell(sheet, 0, totalRowIdx, TextCellValue("TOTAL"), totalBg, HorizontalAlign.Left, bold: true);
    _setCell(sheet, 1, totalRowIdx, TextCellValue(""), totalBg, HorizontalAlign.Left);
    _setCell(sheet, 2, totalRowIdx, DoubleCellValue(double.parse(dlMb)), totalBg, HorizontalAlign.Right, bold: true);
    _setCell(sheet, 3, totalRowIdx, DoubleCellValue(double.parse(ulMb)), totalBg, HorizontalAlign.Right, bold: true);
    _setCell(sheet, 4, totalRowIdx, DoubleCellValue(double.parse(totMb)), totalBg, HorizontalAlign.Right, bold: true);
    _setCell(sheet, 5, totalRowIdx, TextCellValue("100.0%"), totalBg, HorizontalAlign.Center, bold: true);
    _setCell(sheet, 6, totalRowIdx, TextCellValue("-"), totalBg, HorizontalAlign.Right, bold: true);

    // Row N+3: Watermark Footer
    int footerRowIdx = totalRowIdx + 2;
    var footCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: footerRowIdx));
    footCell.value = TextCellValue("Generated by NetTrack v1.0.0+1");
    footCell.cellStyle = CellStyle(italic: true, fontSize: 9);

    return excel.encode();
  }

  void _setCell(
    Sheet sheet,
    int col,
    int row,
    CellValue value,
    ExcelColor bgColor,
    HorizontalAlign align, {
    bool bold = false,
  }) {
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: 10,
      backgroundColorHex: bgColor,
      horizontalAlign: align,
    );
  }

  String _generateCsvString({
    required List<AppUsageModel> usages,
    required String reportTypeLabel,
    required String dateRangeLabel,
    required String timestampStr,
    required int totalRx,
    required int totalTx,
    required int totalCombined,
  }) {
    List<List<String>> rows = [];
    final dlMb = (totalRx / (1024 * 1024)).toStringAsFixed(2);
    final ulMb = (totalTx / (1024 * 1024)).toStringAsFixed(2);
    final totMb = (totalCombined / (1024 * 1024)).toStringAsFixed(2);

    rows.add(["NetTrack - $reportTypeLabel", "", "", "", "Generated: $timestampStr"]);
    rows.add(["Period: $dateRangeLabel"]);
    rows.add(["Total Combined: $totMb MB (Download: $dlMb MB | Upload: $ulMb MB)"]);
    rows.add([]); // Blank separator
    rows.add([
      "App Name",
      "Package Name",
      "Download (MB)",
      "Upload (MB)",
      "Total Usage (MB)",
      "% of Total",
      "Usage Time (s)"
    ]);

    for (var usage in usages) {
      final rxMbVal = (usage.rxBytes / (1024 * 1024)).toStringAsFixed(2);
      final txMbVal = (usage.txBytes / (1024 * 1024)).toStringAsFixed(2);
      final totMbVal = (usage.totalBytes / (1024 * 1024)).toStringAsFixed(2);
      final pct = totalCombined == 0
          ? 0.0
          : (usage.totalBytes / totalCombined) * 100.0;

      rows.add([
        '"${usage.appName.replaceAll('"', '""')}"',
        '"${usage.packageName.replaceAll('"', '""')}"',
        rxMbVal,
        txMbVal,
        totMbVal,
        "${pct.toStringAsFixed(1)}%",
        "0"
      ]);
    }

    rows.add(["TOTAL", "", dlMb, ulMb, totMb, "100.0%", "-"]);
    rows.add([]);
    rows.add(["Generated by NetTrack v1.0.0+1"]);

    return rows.map((row) => row.join(',')).join('\n');
  }

  Future<void> openFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint("Error opening file: $e");
    }
  }

  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'NetTrack Usage Report',
      );
    } catch (e) {
      debugPrint("Error sharing file: $e");
    }
  }
}
