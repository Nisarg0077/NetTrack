import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart' as installed;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models/app_usage_model.dart';
import '../models/network_stats_model.dart';

class DataUsageService {
  Map<String, installed.AppInfo>? _cachedAppMap;
  final Map<String, Uint8List?> _cachedIcons = {};

  static final Map<String, double> _hourlyCacheMb = {};
  static final Map<String, double> _dailyCacheMb = {};
  static final Map<String, ({DateTime timestamp, List<double> trend})>
      _appTrendCache = {};
  static final Map<String, double> _appHistoricalDayCache = {};

  static const MethodChannel _windowsNetworkChannel =
      MethodChannel('com.example.dataUsageTracker/windows_network');

  /// Check if usage permissions are granted (Android only)
  Future<bool> checkUsagePermission() async {
    if (Platform.isAndroid) {
      return await UsageStats.checkUsagePermission() ?? false;
    }
    return true; // Not required on Windows/other platforms in this context
  }

  /// Prompt for usage permission (Android only)
  Future<void> grantUsagePermission() async {
    if (Platform.isAndroid) {
      await UsageStats.grantUsagePermission();
    }
  }

  /// Get per-app network usage (Android only)
  Future<List<AppUsageModel>> getAppNetworkUsage(
      DateTime startDate, DateTime endDate) async {
    if (!Platform.isAndroid) {
      return await _getWindowsAppNetworkUsage(startDate, endDate);
    }

    int retries = 3;
    while (retries > 0) {
      try {
        if (_cachedAppMap == null) {
          // Fetch WITHOUT icons first for speed!
          List<installed.AppInfo> allApps =
              await InstalledApps.getInstalledApps(
            excludeSystemApps: false,
            withIcon: false,
          );
          _cachedAppMap = {for (var e in allApps) e.packageName: e};
        }

        List<NetworkInfo> networkStats =
            await UsageStats.queryNetworkUsageStats(
          startDate,
          endDate,
          networkType: NetworkType.all,
        );

        List<AppUsageModel> appUsages = [];
        for (var stat in networkStats) {
          final packageName = stat.packageName ?? 'Unknown';
          if (packageName == 'Unknown') continue;

          final rx = stat.rxTotalBytesValue ?? 0;
          final tx = stat.txTotalBytesValue ?? 0;

          if (rx == 0 && tx == 0) continue;

          String appName = packageName;

          if (_cachedAppMap!.containsKey(packageName)) {
            appName = _cachedAppMap![packageName]!.name;
          }

          appUsages.add(
            AppUsageModel(
              packageName: packageName,
              appName: appName,
              appIcon: _cachedIcons[packageName],
              txBytes: tx,
              rxBytes: rx,
            ),
          );
        }

        // Group by package name
        Map<String, AppUsageModel> aggregated = {};
        for (var usage in appUsages) {
          if (aggregated.containsKey(usage.packageName)) {
            final existing = aggregated[usage.packageName]!;
            aggregated[usage.packageName] = existing.copyWith(
              txBytes: existing.txBytes + usage.txBytes,
              rxBytes: existing.rxBytes + usage.rxBytes,
            );
          } else {
            aggregated[usage.packageName] = usage;
          }
        }

        var resultList = aggregated.values.toList();
        resultList.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));

        // Fetch icons ONLY for the top 12 apps concurrently to save massive loading time
        final topCount = resultList.length < 12 ? resultList.length : 12;
        await Future.wait(List.generate(topCount, (i) async {
          final pkg = resultList[i].packageName;
          if (_cachedIcons[pkg] == null) {
            try {
              final info = await InstalledApps.getAppInfo(pkg);
              if (info != null && info.icon != null) {
                _cachedIcons[pkg] = info.icon;
                resultList[i] = resultList[i].copyWith(appIcon: info.icon);
              }
            } catch (e) {
              // Ignore
            }
          }
        }));

        return resultList;
      } catch (e) {
        debugPrint("Error fetching network usage (retry $retries): $e");
        retries--;
        if (retries == 0) return [];
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
    return [];
  }

  /// Ultra lightweight method to get total raw bytes for a specific period (Android)
  Future<int> getDailyTotalUsageBytes(
      DateTime startDate, DateTime endDate) async {
    if (!Platform.isAndroid) {
      double mb = await _getWindowsDailyTotalUsageMb(startDate, endDate);
      return (mb * 1024 * 1024).toInt();
    }

    try {
      List<NetworkInfo> stats = await UsageStats.queryNetworkUsageStats(
        startDate,
        endDate,
        networkType: NetworkType.all,
      );
      int totalBytes = 0;
      for (var stat in stats) {
        final rx = stat.rxTotalBytesValue ?? 0;
        final tx = stat.txTotalBytesValue ?? 0;
        totalBytes += (rx + tx);
      }
      return totalBytes;
    } catch (e) {
      return 0;
    }
  }

  /// Lightweight method to get total data usage for a specific period (Android)
  Future<double> getDailyTotalUsageMb(
      DateTime startDate, DateTime endDate) async {
    if (!Platform.isAndroid) {
      return await _getWindowsDailyTotalUsageMb(startDate, endDate);
    }

    // Check cache for full past days
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    bool isFullDay = startDate.hour == 0 && startDate.minute == 0;
    bool isPast = startDate.isBefore(todayStart);
    String cacheKey = '${startDate.year}_${startDate.month}_${startDate.day}';

    if (isFullDay && isPast && _dailyCacheMb.containsKey(cacheKey)) {
      return _dailyCacheMb[cacheKey]!;
    }

    try {
      int totalBytes = await getDailyTotalUsageBytes(startDate, endDate);
      double totalMb = totalBytes / (1024 * 1024);

      if (isFullDay && isPast) {
        _dailyCacheMb[cacheKey] = totalMb;
      }

      return totalMb;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> _getLinuxActiveApps() async {
    Map<String, int> activeApps = {};
    if (Platform.isLinux) {
      try {
        final result = await Process.run('ss', ['-tunp']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (var line in lines) {
            final match = RegExp(r'users:\(\("([^"]+)"').firstMatch(line);
            if (match != null) {
              String appName = match.group(1)!;
              activeApps[appName] = (activeApps[appName] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        debugPrint("Error running ss: $e");
      }
    }
    return activeApps;
  }

  Future<void> updateWindowsAppUsageData() async {
    if (!Platform.isWindows && !Platform.isLinux) return;

    try {
      dynamic activeApps;
      if (Platform.isWindows) {
        activeApps =
            await _windowsNetworkChannel.invokeMethod('getActiveAppUsage');
      } else if (Platform.isLinux) {
        activeApps = await _getLinuxActiveApps();
      }

      if (activeApps == null || activeApps.isEmpty) return;

      final currentStats = await _getCurrentDesktopStats();
      final prefs = await SharedPreferences.getInstance();

      int lastRx = prefs.getInt('win_last_app_rx_total') ?? currentStats['rx']!;
      int lastTx = prefs.getInt('win_last_app_tx_total') ?? currentStats['tx']!;

      int deltaRx = currentStats['rx']! - lastRx;
      int deltaTx = currentStats['tx']! - lastTx;

      if (deltaRx < 0) deltaRx = currentStats['rx']!;
      if (deltaTx < 0) deltaTx = currentStats['tx']!;

      // ALWAYS register known apps even if delta is 0, so they show up on the UI
      List<String> knownApps = prefs.getStringList('win_known_apps') ?? [];
      bool addedNewApp = false;
      int totalConnections = 0;

      Map<String, int> validApps = {};

      for (var entry in activeApps.entries) {
        String appName = entry.key.toString();
        if (appName.toLowerCase() == 'unknown') continue;

        int connections = entry.value as int;
        validApps[appName] = connections;
        totalConnections += connections;

        if (!knownApps.contains(appName)) {
          knownApps.add(appName);
          addedNewApp = true;
        }
      }

      if (addedNewApp) {
        await prefs.setStringList('win_known_apps', knownApps);
      }

      if ((deltaRx > 0 || deltaTx > 0) && totalConnections > 0) {
        final now = DateTime.now();
        final todayKey = '${now.year}_${now.month}_${now.day}';

        for (var entry in validApps.entries) {
          String appName = entry.key;
          int connections = entry.value;

          double ratio = connections / totalConnections;
          int appRxDelta = (deltaRx * ratio).round();
          int appTxDelta = (deltaTx * ratio).round();

          String rxKey = 'win_app_rx_${appName}_$todayKey';
          String txKey = 'win_app_tx_${appName}_$todayKey';

          int currentAppRx = prefs.getInt(rxKey) ?? 0;
          int currentAppTx = prefs.getInt(txKey) ?? 0;

          await prefs.setInt(rxKey, currentAppRx + appRxDelta);
          await prefs.setInt(txKey, currentAppTx + appTxDelta);
        }
      }

      await prefs.setInt('win_last_app_rx_total', currentStats['rx']!);
      await prefs.setInt('win_last_app_tx_total', currentStats['tx']!);
    } catch (e) {
      debugPrint("Error updating windows app usage data: $e");
    }
  }

  Future<List<AppUsageModel>> _getWindowsAppNetworkUsage(
      DateTime startDate, DateTime endDate) async {
    try {
      await updateWindowsAppUsageData();

      final prefs = await SharedPreferences.getInstance();
      Map<String, AppUsageModel> aggregated = {};

      DateTime current =
          DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      List<String> appList = prefs.getStringList('win_known_apps') ?? [];

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final dayKey = '${current.year}_${current.month}_${current.day}';

        for (String appName in appList) {
          String rxKey = 'win_app_rx_${appName}_$dayKey';
          String txKey = 'win_app_tx_${appName}_$dayKey';

          int rx = prefs.getInt(rxKey) ?? 0;
          int tx = prefs.getInt(txKey) ?? 0;

          // Always include known apps so the user can see they are being tracked
          if (aggregated.containsKey(appName)) {
            var existing = aggregated[appName]!;
            aggregated[appName] = existing.copyWith(
              txBytes: existing.txBytes + tx,
              rxBytes: existing.rxBytes + rx,
            );
          } else {
            aggregated[appName] = AppUsageModel(
              packageName: appName,
              appName: appName,
              txBytes: tx,
              rxBytes: rx,
            );
          }
        }
        current = current.add(const Duration(days: 1));
      }

      var resultList = aggregated.values.toList();
      resultList.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
      debugPrint(
          'Returning ${resultList.length} apps from _getWindowsAppNetworkUsage.');
      return resultList;
    } catch (e, stacktrace) {
      debugPrint('Error in _getWindowsAppNetworkUsage: $e\n$stacktrace');
      return [];
    }
  }

  Future<void> _updateWindowsAccumulator(int currentRx, int currentTx) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';

    final totalRxKey = 'win_total_rx_$todayKey';
    final totalTxKey = 'win_total_tx_$todayKey';

    // 1. Initialize total if missing (Migrate old baseline if exists)
    if (!prefs.containsKey(totalRxKey)) {
      int initialTotalRx = 0;
      int initialTotalTx = 0;

      final oldStartRxKey = 'win_rx_$todayKey';
      final oldStartTxKey = 'win_tx_$todayKey';

      if (prefs.containsKey(oldStartRxKey)) {
        int oldStartRx = prefs.getInt(oldStartRxKey)!;
        int oldStartTx = prefs.getInt(oldStartTxKey)!;
        initialTotalRx = currentRx - oldStartRx;
        initialTotalTx = currentTx - oldStartTx;
        if (initialTotalRx < 0) initialTotalRx = currentRx;
        if (initialTotalTx < 0) initialTotalTx = currentTx;
      }
      await prefs.setInt(totalRxKey, initialTotalRx);
      await prefs.setInt(totalTxKey, initialTotalTx);
    }

    // 2. Compute deltas
    int lastRx = prefs.getInt('win_last_rx') ?? currentRx;
    int lastTx = prefs.getInt('win_last_tx') ?? currentTx;

    int deltaRx = currentRx - lastRx;
    int deltaTx = currentTx - lastTx;

    if (deltaRx < 0) deltaRx = currentRx; // Reboot occurred
    if (deltaTx < 0) deltaTx = currentTx;

    // 3. Accumulate if data changed
    if (deltaRx > 0 || deltaTx > 0) {
      int totalRx = prefs.getInt(totalRxKey) ?? 0;
      int totalTx = prefs.getInt(totalTxKey) ?? 0;

      await prefs.setInt(totalRxKey, totalRx + deltaRx);
      await prefs.setInt(totalTxKey, totalTx + deltaTx);

      final int hour = now.hour;
      final String hourKey = 'win_hour_${hour}_$todayKey';
      int hourBytes = prefs.getInt(hourKey) ?? 0;
      await prefs.setInt(hourKey, hourBytes + deltaRx + deltaTx);
    }

    // 4. Update last seen
    await prefs.setInt('win_last_rx', currentRx);
    await prefs.setInt('win_last_tx', currentTx);
  }

  Future<double> _getWindowsDailyTotalUsageMb(
      DateTime startDate, DateTime endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double totalMb = 0;

      DateTime current =
          DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final dayKey = '${current.year}_${current.month}_${current.day}';
        int rx = prefs.getInt('win_total_rx_$dayKey') ?? 0;
        int tx = prefs.getInt('win_total_tx_$dayKey') ?? 0;
        totalMb += (rx + tx) / (1024 * 1024);
        current = current.add(const Duration(days: 1));
      }
      return totalMb;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> _getCurrentDesktopStats() async {
    int rx = 0;
    int tx = 0;
    if (Platform.isWindows) {
      try {
        final result = await Process.run('netstat', ['-e']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (var line in lines) {
            final trimmed = line.trim().replaceAll(RegExp(r'\s+'), ' ');
            final parts = trimmed.split(' ');
            if (parts.length >= 3 && parts[0].toLowerCase() == 'bytes') {
              rx = int.tryParse(parts[1]) ?? 0;
              tx = int.tryParse(parts[2]) ?? 0;
              break;
            }
          }
        }
      } catch (e) {
        debugPrint("Error running netstat: $e");
      }
    } else if (Platform.isLinux) {
      try {
        final file = File('/proc/net/dev');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          for (var line in lines) {
            if (line.contains(':')) {
              final parts = line.split(':');
              final interfaceName = parts[0].trim();
              final data = parts[1].trim().split(RegExp(r'\s+'));
              if (data.length >= 9 && interfaceName != 'lo') {
                rx += int.tryParse(data[0]) ?? 0;
                tx += int.tryParse(data[8]) ?? 0;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error reading /proc/net/dev for linux stats: $e");
      }
    }
    return {'rx': rx, 'tx': tx};
  }

  /// Get general network stats (Fallback for Windows, or overall for Android)
  Future<List<NetworkStatsModel>> getGeneralNetworkStats(
      {DateTime? startDate, DateTime? endDate}) async {
    List<NetworkStatsModel> stats = [];
    try {
      final interfaces = await NetworkInterface.list(
          includeLoopback: false, type: InternetAddressType.any);

      for (var interface in interfaces) {
        int rx = 0;
        int tx = 0;

        if (Platform.isWindows || Platform.isLinux) {
          final current = await _getCurrentDesktopStats();
          await _updateWindowsAccumulator(
              current['rx'] ?? 0, current['tx'] ?? 0);

          if (startDate != null && endDate != null) {
            final prefs = await SharedPreferences.getInstance();
            int totalRx = 0;
            int totalTx = 0;

            DateTime curr =
                DateTime(startDate.year, startDate.month, startDate.day);
            final end = DateTime(endDate.year, endDate.month, endDate.day);

            while (curr.isBefore(end) || curr.isAtSameMomentAs(end)) {
              final dayKey = '${curr.year}_${curr.month}_${curr.day}';
              totalRx += prefs.getInt('win_total_rx_$dayKey') ?? 0;
              totalTx += prefs.getInt('win_total_tx_$dayKey') ?? 0;
              curr = curr.add(const Duration(days: 1));
            }
            rx = totalRx;
            tx = totalTx;
          } else {
            final prefs = await SharedPreferences.getInstance();
            final now = DateTime.now();
            final dayKey = '${now.year}_${now.month}_${now.day}';
            rx = prefs.getInt('win_total_rx_$dayKey') ?? 0;
            tx = prefs.getInt('win_total_tx_$dayKey') ?? 0;
          }
        } else if (Platform.isAndroid) {
          try {
            final file = File('/proc/net/dev');
            if (await file.exists()) {
              final lines = await file.readAsLines();
              for (var line in lines) {
                if (line.contains(interface.name)) {
                  final parts = line.split(':');
                  if (parts.length > 1) {
                    final data = parts[1].trim().split(RegExp(r'\s+'));
                    if (data.length >= 9) {
                      rx = int.tryParse(data[0]) ?? 0;
                      tx = int.tryParse(data[8]) ?? 0;
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error reading /proc/net/dev: $e");
          }
        }

        stats.add(
          NetworkStatsModel(
            interfaceName: interface.name,
            txBytes: tx,
            rxBytes: rx,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching network interfaces: $e");
    }
    return stats;
  }

  /// Get hourly data usage in MB for a specific day (0..23)
  Future<List<double>> getHourlyUsageForDay(DateTime day) async {
    List<double> hourlyMb = List.filled(24, 0.0);
    if (!Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final dayKey = '${day.year}_${day.month}_${day.day}';
      for (int i = 0; i < 24; i++) {
        int bytes = prefs.getInt('win_hour_${i}_$dayKey') ?? 0;
        double mb = bytes / (1024 * 1024);
        hourlyMb[i] = mb;
      }
      return hourlyMb;
    }

    try {
      for (int i = 0; i < 24; i++) {
        DateTime start = DateTime(day.year, day.month, day.day, i, 0, 0);
        DateTime end = DateTime(day.year, day.month, day.day, i, 59, 59);

        if (start.isAfter(DateTime.now())) {
          hourlyMb[i] = 0.0;
          continue;
        }

        String cacheKey = '${day.year}_${day.month}_${day.day}_$i';
        bool isPastHour = end.isBefore(DateTime.now()
            .subtract(const Duration(minutes: 5))); // Add 5 min buffer

        if (isPastHour && _hourlyCacheMb.containsKey(cacheKey)) {
          hourlyMb[i] = _hourlyCacheMb[cacheKey]!;
          continue;
        }

        if (end.isAfter(DateTime.now())) {
          end = DateTime.now();
        }

        double val = await getDailyTotalUsageMb(start, end);
        hourlyMb[i] = val;

        if (isPastHour) {
          _hourlyCacheMb[cacheKey] = val;
        }
      }
    } catch (e) {
      debugPrint('Error loading hourly usage: $e');
    }
    return hourlyMb;
  }

  /// Get the hour index (0..23) with peak usage
  int getPeakHourIndex(List<double> hourlyMb) {
    if (hourlyMb.isEmpty) return -1;
    int peakIndex = 0;
    double maxVal = hourlyMb[0];
    for (int i = 1; i < hourlyMb.length; i++) {
      if (hourlyMb[i] > maxVal) {
        maxVal = hourlyMb[i];
        peakIndex = i;
      }
    }
    return maxVal > 0.001 ? peakIndex : -1;
  }

  /// Get 7-day historical trend for a specific app (MB)
  Future<List<double>> getApp7DayTrend(String packageName) async {
    // 1. Check in-memory 10-minute cache first (0 IPC overhead, instant navigation)
    final cached = _appTrendCache[packageName];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp).inMinutes < 10) {
      return List<double>.from(cached.trend);
    }

    List<double> trend = List.filled(7, 0.0);
    DateTime today = DateTime.now();

    if (Platform.isAndroid) {
      for (int i = 0; i < 7; i++) {
        DateTime date = DateTime(today.year, today.month, today.day - (6 - i));
        final dayKey = '${packageName}_${date.year}_${date.month}_${date.day}';

        // Past days (i < 6) never change; check historical day cache to avoid redundant IPC calls
        if (i < 6 && _appHistoricalDayCache.containsKey(dayKey)) {
          trend[i] = _appHistoricalDayCache[dayKey]!;
          continue;
        }

        DateTime start = DateTime(date.year, date.month, date.day);
        DateTime end = DateTime(date.year, date.month, date.day, 23, 59, 59);
        if (end.isAfter(today)) end = today;

        try {
          // Query sequentially instead of parallel Future.wait to prevent
          // overflowing Android system_server Binder buffers and triggering Watchdog reboots
          List<NetworkInfo> stats = await UsageStats.queryNetworkUsageStats(
            start,
            end,
            networkType: NetworkType.all,
          );
          double totalMb = 0;
          for (var stat in stats) {
            if (stat.packageName == packageName) {
              final rx = stat.rxTotalBytesValue ?? 0;
              final tx = stat.txTotalBytesValue ?? 0;
              totalMb += (rx + tx) / (1024 * 1024);
            }
          }
          trend[i] = totalMb;
          if (i < 6) {
            _appHistoricalDayCache[dayKey] = totalMb;
          }
        } catch (e) {
          debugPrint(
              'Error querying network stats for $packageName on day $i: $e');
          trend[i] = 0.0;
        }

        // Brief yield between sequential IPC queries to let system_server drain its queue
        if (i < 6) {
          await Future.delayed(const Duration(milliseconds: 15));
        }
      }
      _appTrendCache[packageName] =
          (timestamp: DateTime.now(), trend: List<double>.from(trend));
    } else if (Platform.isWindows || Platform.isLinux) {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < 7; i++) {
        DateTime date = DateTime(today.year, today.month, today.day - (6 - i));
        final dayKey = '${date.year}_${date.month}_${date.day}';

        String rxKey = 'win_app_rx_${packageName}_$dayKey';
        String txKey = 'win_app_tx_${packageName}_$dayKey';

        int rx = prefs.getInt(rxKey) ?? 0;
        int tx = prefs.getInt(txKey) ?? 0;
        trend[i] = (rx + tx) / (1024 * 1024);
      }
      _appTrendCache[packageName] =
          (timestamp: DateTime.now(), trend: List<double>.from(trend));
    }
    return trend;
  }
}
