import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ThemeProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDarkMode = await _settingsService.isDarkMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settingsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
