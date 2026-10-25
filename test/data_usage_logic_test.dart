import 'package:flutter_test/flutter_test.dart';
import 'package:net_track/services/data_usage_service.dart';
import 'package:net_track/models/app_usage_model.dart';

void main() {
  group('DataUsageService peak hour logic', () {
    final service = DataUsageService();

    test('returns -1 for empty hourly list', () {
      expect(service.getPeakHourIndex([]), -1);
    });

    test('returns -1 when all hourly usage is zero', () {
      expect(service.getPeakHourIndex(List.filled(24, 0.0)), -1);
    });

    test('identifies single peak hour correctly', () {
      final hours = List.filled(24, 0.0);
      hours[14] = 250.5; // Peak at 14:00 (2 PM)
      expect(service.getPeakHourIndex(hours), 14);
    });

    test('identifies first peak hour in case of equal values', () {
      final hours = List.filled(24, 10.0);
      hours[8] = 50.0;
      hours[18] = 50.0;
      expect(service.getPeakHourIndex(hours), 8);
    });
  });

  group('AppUsageModel tests', () {
    test('computes totalBytes correctly', () {
      final model = AppUsageModel(
        packageName: 'com.example.test',
        appName: 'Test App',
        rxBytes: 5000,
        txBytes: 2500,
      );
      expect(model.totalBytes, 7500);
    });

    test('copyWith preserves unmodified fields', () {
      final original = AppUsageModel(
        packageName: 'com.example.test',
        appName: 'Test App',
        rxBytes: 1000,
        txBytes: 2000,
      );

      final updated = original.copyWith(rxBytes: 3000);
      expect(updated.packageName, 'com.example.test');
      expect(updated.appName, 'Test App');
      expect(updated.rxBytes, 3000);
      expect(updated.txBytes, 2000);
      expect(updated.totalBytes, 5000);
    });
  });
}
