class NetworkStatsModel {
  final String interfaceName;
  final int txBytes; // Bytes sent
  final int rxBytes; // Bytes received
  final int totalBytes;

  NetworkStatsModel({
    required this.interfaceName,
    required this.txBytes,
    required this.rxBytes,
  }) : totalBytes = txBytes + rxBytes;

  NetworkStatsModel copyWith({
    String? interfaceName,
    int? txBytes,
    int? rxBytes,
  }) {
    return NetworkStatsModel(
      interfaceName: interfaceName ?? this.interfaceName,
      txBytes: txBytes ?? this.txBytes,
      rxBytes: rxBytes ?? this.rxBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interfaceName': interfaceName,
      'txBytes': txBytes,
      'rxBytes': rxBytes,
    };
  }

  factory NetworkStatsModel.fromJson(Map<String, dynamic> json) {
    return NetworkStatsModel(
      interfaceName: json['interfaceName'] as String,
      txBytes: json['txBytes'] as int,
      rxBytes: json['rxBytes'] as int,
    );
  }
}
