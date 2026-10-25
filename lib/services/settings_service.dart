import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_usage_model.dart';
import '../models/network_stats_model.dart';
import '../models/export_history_item.dart';

class SettingsService {
  static const String _themeKey = 'isDarkMode';
  static const String _themeModeKey = 'themeMode'; // 'system', 'light', 'dark'
  static const String _refreshIntervalKey = 'refreshInterval';

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
    if (mode == 'dark') {
      await prefs.setBool(_themeKey, true);
    } else if (mode == 'light') {
      await prefs.setBool(_themeKey, false);
    }
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_themeModeKey);
    if (mode != null) return mode;
    // Check backwards compatibility
    if (prefs.containsKey(_themeKey)) {
      final isDark = prefs.getBool(_themeKey) ?? false;
      return isDark ? 'dark' : 'light';
    }
    return 'system'; // Default system theme
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    await prefs.setString(_themeModeKey, isDark ? 'dark' : 'light');
  }

  Future<bool> isDarkMode() async {
    final mode = await getThemeMode();
    return mode == 'dark';
  }

  Future<void> setRefreshInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refreshIntervalKey, seconds);
  }

  Future<int> getRefreshInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_refreshIntervalKey) ?? 60; // Default 60s
  }

  static const String _performanceModeKey =
      'performanceMode'; // 'smooth' or 'ultra'
  static const String _reduceMotionKey = 'reduceMotion';

  Future<void> setPerformanceMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_performanceModeKey, mode);
  }

  Future<String> getPerformanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_performanceModeKey) ?? 'smooth';
  }

  Future<void> setReduceMotion(bool reduce) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, reduce);
  }

  Future<bool> isReduceMotion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reduceMotionKey) ?? false;
  }

  static const String _cachedAppUsagesKey = 'cachedAppUsages';
  static const String _cachedNetworkStatsKey = 'cachedNetworkStats';

  Future<void> saveCachedAppUsages(List<AppUsageModel> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(apps.map((e) => e.toJson()).toList());
    await prefs.setString(_cachedAppUsagesKey, jsonString);
  }

  Future<List<AppUsageModel>> getCachedAppUsages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_cachedAppUsagesKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((e) => AppUsageModel.fromJson(e)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> saveCachedNetworkStats(List<NetworkStatsModel> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(stats.map((e) => e.toJson()).toList());
    await prefs.setString(_cachedNetworkStatsKey, jsonString);
  }

  Future<List<NetworkStatsModel>> getCachedNetworkStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_cachedNetworkStatsKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((e) => NetworkStatsModel.fromJson(e)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  static const String _exportHistoryKey = 'exportHistory';
  static const String _installDateKey = 'appInstallDate';

  Future<DateTime> getAppInstallationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateStr = prefs.getString(_installDateKey);
    if (dateStr != null) {
      return DateTime.tryParse(dateStr) ?? DateTime(2025, 1, 1);
    } else {
      final defaultDate = DateTime(2025, 1, 1);
      await prefs.setString(_installDateKey, defaultDate.toIso8601String());
      return defaultDate;
    }
  }

  Future<void> saveExportHistoryItem(ExportHistoryItem item) async {
    final history = await getExportHistory();
    history.insert(0, item);
    // Keep top 30 exports
    if (history.length > 30) {
      history.removeRange(30, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
        jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_exportHistoryKey, jsonString);
  }

  Future<List<ExportHistoryItem>> getExportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_exportHistoryKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((e) => ExportHistoryItem.fromJson(e)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> deleteExportHistoryItem(String id) async {
    final history = await getExportHistory();
    history.removeWhere((item) => item.id == id);
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
        jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_exportHistoryKey, jsonString);
  }

  Future<void> clearExportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exportHistoryKey);
  }
}
