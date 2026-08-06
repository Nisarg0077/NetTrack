class ExportHistoryItem {
  final String id;
  final String fileName;
  final String filePath;
  final String format; // '.xlsx' or '.csv'
  final String dateRangeLabel;
  final DateTime generatedAt;
  final String totalBytesFormatted;

  ExportHistoryItem({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.format,
    required this.dateRangeLabel,
    required this.generatedAt,
    required this.totalBytesFormatted,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'format': format,
      'dateRangeLabel': dateRangeLabel,
      'generatedAt': generatedAt.toIso8601String(),
      'totalBytesFormatted': totalBytesFormatted,
    };
  }

  factory ExportHistoryItem.fromJson(Map<String, dynamic> json) {
    return ExportHistoryItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      format: json['format'] as String,
      dateRangeLabel: json['dateRangeLabel'] as String,
      generatedAt: DateTime.tryParse(json['generatedAt'] as String) ?? DateTime.now(),
      totalBytesFormatted: json['totalBytesFormatted'] as String,
    );
  }
}
