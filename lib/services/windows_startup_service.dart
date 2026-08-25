import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WindowsStartupService {
  static const String taskName = 'NetTrack';
  static const String regKeyName = 'NetTrack';

  /// Initializes the startup configuration on Windows launch
  static Future<void> init() async {
    if (!Platform.isWindows) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final isMsix = Platform.resolvedExecutable.contains('WindowsApps');
      
      launchAtStartup.setup(
        appName: packageInfo.appName.isNotEmpty ? packageInfo.appName : 'NetTrack',
        appPath: Platform.resolvedExecutable,
        packageName: isMsix ? 'Nisarg0077.NetTrack' : null,
      );
    } catch (e) {
      debugPrint('WindowsStartupService setup error: $e');
    }
  }

  /// Checks if NetTrack is configured to run at startup
  static Future<bool> isEnabled() async {
    if (!Platform.isWindows) return false;

    // 1. Check Task Scheduler
    try {
      final taskResult = await Process.run('schtasks', ['/query', '/tn', taskName]);
      if (taskResult.exitCode == 0) return true;
    } catch (_) {}

    // 2. Check Windows Registry (HKCU\Software\Microsoft\Windows\CurrentVersion\Run)
    try {
      final regResult = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        regKeyName,
      ]);
      if (regResult.exitCode == 0) return true;

      // Also check fallback lowercase name
      final regFallback = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        'net_track',
      ]);
      if (regFallback.exitCode == 0) return true;
    } catch (_) {}

    // 3. Check launch_at_startup plugin
    try {
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Enables startup via Task Scheduler (bypasses UAC restrictions) + Registry
  static Future<bool> enable() async {
    if (!Platform.isWindows) return false;
    final exePath = Platform.resolvedExecutable;
    bool success = false;

    // 1. Create Task Scheduler task with highest available privileges (Runs on user login)
    try {
      // First attempt with /rl HIGHEST (for administrator executables)
      var result = await Process.run('schtasks', [
        '/create',
        '/tn',
        taskName,
        '/tr',
        '"$exePath"',
        '/sc',
        'ONLOGON',
        '/rl',
        'HIGHEST',
        '/f',
      ]);

      if (result.exitCode != 0) {
        // Fallback without /rl HIGHEST
        result = await Process.run('schtasks', [
          '/create',
          '/tn',
          taskName,
          '/tr',
          '"$exePath"',
          '/sc',
          'ONLOGON',
          '/f',
        ]);
      }

      if (result.exitCode == 0) {
        success = true;
      }
    } catch (e) {
      debugPrint('Task Scheduler creation error: $e');
    }

    // 2. Add to Windows Registry with quoted path (handles spaces like "C:\Program Files\...")
    try {
      final regResult = await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        regKeyName,
        '/t',
        'REG_SZ',
        '/d',
        '"$exePath"',
        '/f',
      ]);
      if (regResult.exitCode == 0) {
        success = true;
      }
    } catch (e) {
      debugPrint('Registry add error: $e');
    }

    // 3. Also call launchAtStartup plugin for MSIX / shortcut compatibility
    try {
      await launchAtStartup.enable();
      success = true;
    } catch (_) {}

    return success;
  }

  /// Disables startup across Task Scheduler, Registry, and Shortcuts
  static Future<bool> disable() async {
    if (!Platform.isWindows) return false;

    // 1. Delete Task Scheduler task
    try {
      await Process.run('schtasks', ['/delete', '/tn', taskName, '/f']);
    } catch (_) {}

    // 2. Delete Registry entries
    try {
      await Process.run('reg', [
        'delete',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        regKeyName,
        '/f',
      ]);
      await Process.run('reg', [
        'delete',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        'net_track',
        '/f',
      ]);
      await Process.run('reg', [
        'delete',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        'net_track (Debug)',
        '/f',
      ]);
    } catch (_) {}

    // 3. Disable via launchAtStartup plugin
    try {
      await launchAtStartup.disable();
    } catch (_) {}

    return true;
  }
}
