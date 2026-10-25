import 'dart:io';
import 'package:flutter/foundation.dart';

abstract class PlatformService {
  static bool get isDesktop => isWindows || isLinux || isMacOS;
  static bool get isMobile => isAndroid || isIOS;

  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWeb => kIsWeb;

  /// Retrieves the current platform name for display purposes
  static String get platformName {
    if (isWeb) return 'Web';
    if (isWindows) return 'Windows Desktop (x64)';
    if (isAndroid) return 'Android OS';
    if (isLinux) return 'Linux OS';
    if (isMacOS) return 'macOS';
    if (isIOS) return 'iOS';
    return 'Unknown OS';
  }
}
