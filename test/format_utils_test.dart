import 'package:flutter_test/flutter_test.dart';
import 'package:net_track/utils/format_utils.dart';

void main() {
  group('FormatUtils Tests', () {
    test('formats 0 bytes correctly', () {
      expect(FormatUtils.formatBytes(0), '0 B');
      expect(FormatUtils.formatBytes(-50), '0 B');
    });

    test('formats bytes without scaling', () {
      expect(FormatUtils.formatBytes(512), '512.00 B');
    });

    test('formats kilobytes correctly', () {
      expect(FormatUtils.formatBytes(1024), '1.00 KB');
      expect(FormatUtils.formatBytes(2048), '2.00 KB');
      expect(FormatUtils.formatBytes(1536), '1.50 KB');
    });

    test('formats megabytes correctly', () {
      expect(FormatUtils.formatBytes(1024 * 1024), '1.00 MB');
      expect(FormatUtils.formatBytes((2.5 * 1024 * 1024).toInt()), '2.50 MB');
    });

    test('formats gigabytes correctly', () {
      expect(FormatUtils.formatBytes(1024 * 1024 * 1024), '1.00 GB');
      expect(FormatUtils.formatBytes((4.75 * 1024 * 1024 * 1024).toInt()),
          '4.75 GB');
    });

    test('respects decimals parameter', () {
      expect(FormatUtils.formatBytes(1536, decimals: 1), '1.5 KB');
      expect(FormatUtils.formatBytes(1536, decimals: 0), '2 KB');
    });

    test('formats speed correctly', () {
      expect(FormatUtils.formatSpeed(0), '0 B/s');
      expect(FormatUtils.formatSpeed(1024), '1.0 KB/s');
      expect(FormatUtils.formatSpeed(5 * 1024 * 1024), '5.0 MB/s');
    });
  });
}
