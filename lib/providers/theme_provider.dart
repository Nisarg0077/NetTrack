import 'package:flutter/material.dart';
import '../services/settings_service.dart';

enum GraphicsTier {
  ultra, // Frosted Glass: Authentic optical blur, specular hairline rims, depth shadows
  smooth, // Smooth Acrylic: Balanced 60/120Hz performance, lightweight blur
  efficiency, // Battery Saver: Flat tinted acrylic, zero blur passes, lowest power draw
}

class ThemeProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  bool _isDarkMode = false;
  String _performanceMode = 'smooth'; // 'ultra', 'smooth', or 'efficiency'
  bool _reduceMotion = false;

  bool get isDarkMode => _isDarkMode;
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
    _isDarkMode = await _settingsService.isDarkMode();
    _performanceMode = await _settingsService.getPerformanceMode();
    _reduceMotion = await _settingsService.isReduceMotion();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settingsService.setDarkMode(_isDarkMode);
    notifyListeners();
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
