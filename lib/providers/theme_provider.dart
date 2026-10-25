import 'package:flutter/material.dart';
import '../services/settings_service.dart';

enum GraphicsTier {
  ultra, // Frosted Glass: Authentic optical blur, specular hairline rims, depth shadows
  smooth, // Smooth Acrylic: Balanced 60/120Hz performance, lightweight blur
  efficiency, // Battery Saver: Flat tinted acrylic, zero blur passes, lowest power draw
}

class ThemeProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  ThemeMode _themeMode = ThemeMode.system;
  String _performanceMode = 'smooth'; // 'ultra', 'smooth', or 'efficiency'
  bool _reduceMotion = false;

  ThemeMode get themeMode => _themeMode;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  String get performanceMode => _performanceMode;
  bool get isSmoothMode => _performanceMode == 'smooth';
  bool get isUltraMode => _performanceMode == 'ultra';
  bool get isEfficiencyMode =>
      _performanceMode == 'efficiency' || _performanceMode == 'battery_saver';
  GraphicsTier get graphicsTier {
    if (isUltraMode) return GraphicsTier.ultra;
    if (isEfficiencyMode) return GraphicsTier.efficiency;
    return GraphicsTier.smooth;
  }

  bool get reduceMotion => _reduceMotion;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final modeStr = await _settingsService.getThemeMode();
    _themeMode = switch (modeStr) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    _performanceMode = await _settingsService.getPerformanceMode();
    _reduceMotion = await _settingsService.isReduceMotion();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final modeStr = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await _settingsService.setThemeMode(modeStr);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      final isCurrentDark = WidgetsBinding
              .instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
      await setThemeMode(isCurrentDark ? ThemeMode.light : ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> setPerformanceMode(String mode) async {
    if (_performanceMode == mode) return;
    _performanceMode = mode;
    await _settingsService.setPerformanceMode(mode);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool reduce) async {
    if (_reduceMotion == reduce) return;
    _reduceMotion = reduce;
    await _settingsService.setReduceMotion(reduce);
    notifyListeners();
  }
}
