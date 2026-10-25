class FormatUtils {
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = 0;
    double b = bytes.toDouble();
    while (b >= 1024 && i < suffixes.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatSpeed(double bytesPerSec, {int decimals = 1}) {
    if (bytesPerSec <= 0) return "0 B/s";
    return '${formatBytes(bytesPerSec.toInt(), decimals: decimals)}/s';
  }
}
