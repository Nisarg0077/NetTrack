import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_usage_model.dart';
import '../models/network_stats_model.dart';
import '../services/data_usage_service.dart';
import '../services/settings_service.dart';
import '../services/system_tray_service.dart';
enum DateRange { today, yesterday, twoDaysAgo, thisWeek, lastWeek, thisMonth, custom }

class DataProvider with ChangeNotifier, WidgetsBindingObserver {
  final DataUsageService _dataUsageService = DataUsageService();
  final SettingsService _settingsService = SettingsService();

  List<AppUsageModel> _appUsages = [];
  List<AppUsageModel> get appUsages => _appUsages;

  List<NetworkStatsModel> _networkStats = [];
  List<NetworkStatsModel> get networkStats => _networkStats;

  List<double> _weeklyTrend = [];
  List<double> get weeklyTrend => _weeklyTrend;

  List<double> _dailyTrend = [];
  List<double> get dailyTrend => _dailyTrend;

  List<double> _monthlyTrend = [];
  List<double> get monthlyTrend => _monthlyTrend;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  DateRange _selectedRange = DateRange.today;
  DateRange get selectedRange => _selectedRange;

  DateTime? _customStartDate;
  DateTime? get customStartDate => _customStartDate;

  DateTime? _customEndDate;
  DateTime? get customEndDate => _customEndDate;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  int _peakHour = -1;
  int get peakHour => _peakHour;

  int _activeAppsCount = 0;
  int get activeAppsCount => _activeAppsCount;

  bool _isUpdateAvailable = false;
  bool get isUpdateAvailable => _isUpdateAvailable;

  String? _updateLatestVersion;
  String? get updateLatestVersion => _updateLatestVersion;

  String? _updateReleaseNotes;
  String? get updateReleaseNotes => _updateReleaseNotes;

  String? _updateReleaseUrl;
  String? get updateReleaseUrl => _updateReleaseUrl;

  double _currentDownloadSpeed = 0; // Bytes per second
  double get currentDownloadSpeed => _currentDownloadSpeed;

  double _currentUploadSpeed = 0; // Bytes per second
  double get currentUploadSpeed => _currentUploadSpeed;

  int _lastRxBytes = 0;
  int _lastTxBytes = 0;
  DateTime? _lastFetchTime;
  
  DateTime? _lastTrendFetchTime;
  DateRange? _lastTrendRange;

  Timer? _refreshTimer;
  int _currentFetchId = 0;

  DataProvider() {
    _init();
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    
    // Load cached data
    _appUsages = await _settingsService.getCachedAppUsages();
    _networkStats = await _settingsService.getCachedNetworkStats();
    notifyListeners();

    _hasPermission = await _dataUsageService.checkUsagePermission();
    if (_hasPermission) {
      await fetchData();
      _startAutoRefresh();
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnResume();
    }
  }

  Future<void> _checkPermissionOnResume() async {
    final currentlyHasPermission = await _dataUsageService.checkUsagePermission();
    if (currentlyHasPermission != _hasPermission) {
      _hasPermission = currentlyHasPermission;
      if (_hasPermission) {
        await fetchData();
        _startAutoRefresh();
      } else {
        _refreshTimer?.cancel();
      }
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    await _dataUsageService.grantUsagePermission();
    // After returning from settings, we check again
    _hasPermission = await _dataUsageService.checkUsagePermission();
    if (_hasPermission) {
      await fetchData();
      _startAutoRefresh();
    }
    notifyListeners();
  }

  void setDateRange(DateRange range) {
    _selectedRange = range;
    if (range != DateRange.custom) {
      _customStartDate = null;
      _customEndDate = null;
    }
    _lastFetchTime = null;
    _currentDownloadSpeed = 0;
    _currentUploadSpeed = 0;
    fetchData(forceRefreshTrends: true);
  }

  void setCustomDate(DateTime date) {
    _selectedRange = DateRange.custom;
    _customStartDate = DateTime(date.year, date.month, date.day);
    _customEndDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    _selectedDate = _customStartDate;
    _lastFetchTime = null;
    _currentDownloadSpeed = 0;
    _currentUploadSpeed = 0;
    fetchData(forceRefreshTrends: true);
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    _selectedRange = DateRange.custom;
    _customStartDate = DateTime(start.year, start.month, start.day);
    _customEndDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    _selectedDate = null;
    _lastFetchTime = null;
    _currentDownloadSpeed = 0;
    _currentUploadSpeed = 0;
    fetchData(forceRefreshTrends: true);
  }

  void setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void setUpdateAvailable(bool available, {String? version, String? notes, String? url}) {
    _isUpdateAvailable = available;
    _updateLatestVersion = version;
    _updateReleaseNotes = notes;
    _updateReleaseUrl = url;
    notifyListeners();
  }

  Future<void> fetchData({bool forceRefreshTrends = false}) async {
    final int fetchId = ++_currentFetchId;
    _isLoading = true;
    notifyListeners();

    DateTime endDate = DateTime.now();
    DateTime startDate;

    switch (_selectedRange) {
      case DateRange.today:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        _selectedDate = startDate;
        break;
      case DateRange.yesterday:
        startDate = DateTime(endDate.year, endDate.month, endDate.day - 1);
        endDate = DateTime(endDate.year, endDate.month, endDate.day).subtract(const Duration(milliseconds: 1));
        _selectedDate = startDate;
        break;
      case DateRange.twoDaysAgo:
        startDate = DateTime(endDate.year, endDate.month, endDate.day - 2);
        endDate = DateTime(endDate.year, endDate.month, endDate.day - 1).subtract(const Duration(milliseconds: 1));
        _selectedDate = startDate;
        break;
      case DateRange.thisWeek:
        startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        _selectedDate = null;
        break;
      case DateRange.lastWeek:
        DateTime currentWeekStart = endDate.subtract(Duration(days: endDate.weekday - 1));
        startDate = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day - 7);
        endDate = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day).subtract(const Duration(milliseconds: 1));
        _selectedDate = null;
        break;
      case DateRange.thisMonth:
        startDate = DateTime(endDate.year, endDate.month, 1);
        _selectedDate = null;
        break;
      case DateRange.custom:
        startDate = _customStartDate ?? DateTime(endDate.year, endDate.month, endDate.day);
        endDate = _customEndDate ?? endDate;
        if (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
          _selectedDate = startDate;
        } else {
          _selectedDate = null;
        }
        break;
    }

    try {
      final newAppUsages = await _dataUsageService.getAppNetworkUsage(startDate, endDate);
      if (fetchId != _currentFetchId) return; // Stale fetch

      final newNetworkStats = await _dataUsageService.getGeneralNetworkStats(startDate: startDate, endDate: endDate);
      if (fetchId != _currentFetchId) return; // Stale fetch
      
      if (newAppUsages.isNotEmpty || newNetworkStats.isNotEmpty) {
          _appUsages = newAppUsages;
          _networkStats = newNetworkStats;
          
          _settingsService.saveCachedAppUsages(_appUsages); // Fire and forget
          _settingsService.saveCachedNetworkStats(_networkStats);
      }

      _activeAppsCount = _appUsages.where((app) => (app.rxBytes + app.txBytes) > 0).length;
      
      // Update system tray on Windows and Linux
      if (Platform.isWindows || Platform.isLinux) {
         int totalRx = 0;
         int totalTx = 0;
         for (var stat in _networkStats) {
             totalRx += stat.rxBytes;
             totalTx += stat.txBytes;
         }
         final totalBytes = totalRx + totalTx;
         
         String formatBytes(int bytes) {
            if (bytes < 1024) return '$bytes B';
            if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
            if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
            return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
         }
         
         SystemTrayService().updateTrayUsage(formatBytes(totalBytes));
      }

      // Calculate live speeds
      int totalRx = 0;
      int totalTx = 0;
      if (Platform.isWindows || Platform.isLinux) {
         for (var stat in _networkStats) {
             totalRx += stat.rxBytes;
             totalTx += stat.txBytes;
         }
      } else {
         for (var app in _appUsages) {
             totalRx += app.rxBytes;
             totalTx += app.txBytes;
         }
      }

      final now = DateTime.now();
      if (_lastFetchTime != null && _selectedRange == DateRange.today) {
          final diff = now.difference(_lastFetchTime!).inMilliseconds;
          if (diff > 0) {
              int deltaRx = totalRx - _lastRxBytes;
              int deltaTx = totalTx - _lastTxBytes;
              
              if (deltaRx < 0) deltaRx = 0;
              if (deltaTx < 0) deltaTx = 0;

              _currentDownloadSpeed = (deltaRx / diff) * 1000;
              _currentUploadSpeed = (deltaTx / diff) * 1000;
          }
      } else {
          _currentDownloadSpeed = 0;
          _currentUploadSpeed = 0;
      }
      _lastRxBytes = totalRx;
      _lastTxBytes = totalTx;
      _lastFetchTime = now;

      // Fast UI Update
      _isLoading = false;
      notifyListeners();

      bool shouldFetchTrends = forceRefreshTrends || 
                               _lastTrendFetchTime == null || 
                               _lastTrendRange != _selectedRange || 
                               now.difference(_lastTrendFetchTime!).inMinutes >= 5;

      if (shouldFetchTrends) {
        // Background loading for heavy stats
        DateTime targetDay = _selectedDate ?? startDate;
        final hourlyMb = await _dataUsageService.getHourlyUsageForDay(targetDay);
        if (fetchId != _currentFetchId) return; // Stale fetch
        
        _peakHour = _dataUsageService.getPeakHourIndex(hourlyMb);
        _dailyTrend = hourlyMb;

        // Fetch weekly trend sequentially to avoid saturating Android IPC Binder
        List<double> trend = [];
        for (int i = 6; i >= 0; i--) {
          DateTime dayStart = DateTime(endDate.year, endDate.month, endDate.day - i);
          DateTime dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
          trend.add(await _dataUsageService.getDailyTotalUsageMb(dayStart, dayEnd));
          if (fetchId != _currentFetchId) return; // Stale fetch during loop
        }
        _weeklyTrend = trend;

        // Fetch monthly trend in the background
        _fetchMonthlyTrend(endDate, fetchId);
        
        _lastTrendFetchTime = now;
        _lastTrendRange = _selectedRange;
      }
    } catch (e) {
      _errorMessage = "Failed to load usage data.";
    }
    
    if (fetchId == _currentFetchId) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _startAutoRefresh() async {
    _refreshTimer?.cancel();
    int interval = await _settingsService.getRefreshInterval();
    if (interval > 0) {
      _refreshTimer = Timer.periodic(Duration(seconds: interval), (timer) {
        if (_hasPermission) fetchData();
      });
    }
  }

  void restartAutoRefresh() {
    if (_hasPermission) {
      fetchData();
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMonthlyTrend(DateTime endDate, int fetchId) async {
    List<double> trend = [];
    for (int i = 29; i >= 0; i--) {
      DateTime dayStart = DateTime(endDate.year, endDate.month, endDate.day - i);
      DateTime dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      trend.add(await _dataUsageService.getDailyTotalUsageMb(dayStart, dayEnd));
      if (fetchId != _currentFetchId) return; // Stale fetch
    }
    _monthlyTrend = trend;
    notifyListeners();
  }
}
