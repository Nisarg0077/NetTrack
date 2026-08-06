import 'dart:typed_data';

class AppUsageModel {
  final String packageName;
  final String appName;
  final Uint8List? appIcon;
  final int txBytes; // Bytes sent
  final int rxBytes; // Bytes received
  final int totalBytes;

  AppUsageModel({
    required this.packageName,
    required this.appName,
    this.appIcon,
    required this.txBytes,
    required this.rxBytes,
  }) : totalBytes = txBytes + rxBytes;

  // Add copyWith if needed
  AppUsageModel copyWith({
    String? packageName,
    String? appName,
    Uint8List? appIcon,
    int? txBytes,
    int? rxBytes,
  }) {
    return AppUsageModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      appIcon: appIcon ?? this.appIcon,
      txBytes: txBytes ?? this.txBytes,
      rxBytes: rxBytes ?? this.rxBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'txBytes': txBytes,
      'rxBytes': rxBytes,
    };
  }

  factory AppUsageModel.fromJson(Map<String, dynamic> json) {
    return AppUsageModel(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      txBytes: json['txBytes'] as int,
      rxBytes: json['rxBytes'] as int,
    );
  }
}
