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
  Map<String, Uint8List?> _cachedIcons = {};
  static const MethodChannel _windowsNetworkChannel = MethodChannel('com.example.dataUsageTracker/windows_network');

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
          List<installed.AppInfo> allApps = await InstalledApps.getInstalledApps(
            excludeSystemApps: false,
            withIcon: false,
          );
          _cachedAppMap = { for (var e in allApps) e.packageName : e };
        }

        List<NetworkInfo> networkStats = await UsageStats.queryNetworkUsageStats(
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

  /// Lightweight method to get total data usage for a specific period (Android)
  Future<double> getDailyTotalUsageMb(DateTime startDate, DateTime endDate) async {
    if (!Platform.isAndroid) return await _getWindowsDailyTotalUsageMb(startDate, endDate);
    try {
      List<NetworkInfo> stats = await UsageStats.queryNetworkUsageStats(
        startDate,
        endDate,
        networkType: NetworkType.all,
      );
      double totalMb = 0;
      for (var stat in stats) {
        final rx = stat.rxTotalBytesValue ?? 0;
        final tx = stat.txTotalBytesValue ?? 0;
        totalMb += (rx + tx) / (1024 * 1024);
      }
      return totalMb;
    } catch (e) {
      return 0;
    }
  }

  Future<void> updateWindowsAppUsageData() async {
    if (!Platform.isWindows) return;
    
    try {
      final activeApps = await _windowsNetworkChannel.invokeMethod('getActiveAppUsage');
      File('win_debug.log').writeAsStringSync('Channel returned: ${activeApps?.length} apps.\n', mode: FileMode.append);
      
      if (activeApps == null || (activeApps as Map).isEmpty) return;

      final currentStats = await _getCurrentWindowsStats();
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
      File('win_debug.log').writeAsStringSync('Error updating windows app usage data: $e\n', mode: FileMode.append);
      debugPrint("Error updating windows app usage data: $e");
    }
  }

  Future<List<AppUsageModel>> _getWindowsAppNetworkUsage(DateTime startDate, DateTime endDate) async {
    try {
      await updateWindowsAppUsageData();
      
      final prefs = await SharedPreferences.getInstance();
      Map<String, AppUsageModel> aggregated = {};
      
      DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
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
      File('win_debug.log').writeAsStringSync('Returning ${resultList.length} apps from _getWindowsAppNetworkUsage.\n', mode: FileMode.append);
      return resultList;
    } catch (e, stacktrace) {
      File('win_debug.log').writeAsStringSync('CRITICAL ERROR in _getWindowsAppNetworkUsage: $e\n$stacktrace\n', mode: FileMode.append);
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

  Future<double> _getWindowsDailyTotalUsageMb(DateTime startDate, DateTime endDate) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        double totalMb = 0;
        
        DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
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

  Future<Map<String, int>> _getCurrentWindowsStats() async {
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
        } catch(e) {
            debugPrint("Error running netstat: $e");
        }
      }
      return {'rx': rx, 'tx': tx};
  }

  /// Get general network stats (Fallback for Windows, or overall for Android)
  Future<List<NetworkStatsModel>> getGeneralNetworkStats({DateTime? startDate, DateTime? endDate}) async {
    List<NetworkStatsModel> stats = [];
    try {
      final interfaces = await NetworkInterface.list(
          includeLoopback: false, type: InternetAddressType.any);
      
      for (var interface in interfaces) {
        int rx = 0;
        int tx = 0;
        
        if (Platform.isWindows) {
           final current = await _getCurrentWindowsStats();
           await _updateWindowsAccumulator(current['rx'] ?? 0, current['tx'] ?? 0);
           
           if (startDate != null && endDate != null) {
                final prefs = await SharedPreferences.getInstance();
                int totalRx = 0;
                int totalTx = 0;
                
                DateTime curr = DateTime(startDate.year, startDate.month, startDate.day);
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
      double sumRecorded = 0;
      for (int i = 0; i < 24; i++) {
        int bytes = prefs.getInt('win_hour_${i}_$dayKey') ?? 0;
        double mb = bytes / (1024 * 1024);
        hourlyMb[i] = mb;
        sumRecorded += mb;
      }
      if (sumRecorded == 0) {
        double dailyTotal = await _getWindowsDailyTotalUsageMb(
          DateTime(day.year, day.month, day.day),
          DateTime(day.year, day.month, day.day, 23, 59, 59),
        );
        if (dailyTotal > 0) {
          final weights = [
            0.5, 0.3, 0.2, 0.2, 0.3, 0.5, 1.2, 2.0, 3.0, 4.0, 4.5, 4.0,
            4.2, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 8.0, 9.5, 8.5, 5.5, 2.5
          ];
          double totalWeight = weights.reduce((a, b) => a + b);
          for (int i = 0; i < 24; i++) {
            hourlyMb[i] = dailyTotal * (weights[i] / totalWeight);
          }
        }
      }
      return hourlyMb;
    }

    try {
      for (int i = 0; i < 24; i++) {
        DateTime start = DateTime(day.year, day.month, day.day, i, 0, 0);
        DateTime end = DateTime(day.year, day.month, day.day, i, 59, 59);
        if (end.isAfter(DateTime.now())) {
          end = DateTime.now();
        }
        if (start.isAfter(end)) {
          hourlyMb[i] = 0.0;
        } else {
          hourlyMb[i] = await getDailyTotalUsageMb(start, end);
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
}


