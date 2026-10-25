import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DesktopStartupService {
  static const String taskName = 'NetTrack';
  static const String regKeyName = 'NetTrack';

  /// Initializes the startup configuration on desktop platforms
  static Future<void> init() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final isMsix = Platform.resolvedExecutable.contains('WindowsApps');

      launchAtStartup.setup(
        appName:
            packageInfo.appName.isNotEmpty ? packageInfo.appName : 'NetTrack',
        appPath: Platform.resolvedExecutable,
        packageName: isMsix ? 'Nisarg0077.NetTrack' : null,
      );
    } catch (e) {
      debugPrint('DesktopStartupService setup error: $e');
    }
  }

  /// Checks if NetTrack is configured to run at startup
  static Future<bool> isEnabled() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return false;
    }

    // 1. Check Task Scheduler & Registry (Windows only)
    if (Platform.isWindows) {
      try {
        final taskResult =
            await Process.run('schtasks', ['/query', '/tn', taskName]);
        if (taskResult.exitCode == 0) {
          return true;
        }
      } catch (_) {}

      try {
        final regResult = await Process.run('reg', [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          regKeyName,
        ]);
        if (regResult.exitCode == 0) {
          return true;
        }

        final regFallback = await Process.run('reg', [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          'net_track',
        ]);
        if (regFallback.exitCode == 0) {
          return true;
        }
      } catch (_) {}
    }

    // 2. Check launch_at_startup plugin (Handles Linux/MacOS natively)
    try {
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Enables startup via Task Scheduler/Registry (Windows) and Plugins
  static Future<bool> enable() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return false;
    }
    final exePath = Platform.resolvedExecutable;
    bool success = false;

    if (Platform.isWindows) {
      // 1. Create Task Scheduler task with highest available privileges
      try {
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

      // 2. Add to Windows Registry
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
    }

    // 3. Call launchAtStartup plugin for Linux / MacOS / MSIX compatibility
    try {
      await launchAtStartup.enable();
      success = true;
    } catch (_) {}

    return success;
  }

  /// Disables startup across Task Scheduler, Registry, and Shortcuts
  static Future<bool> disable() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return false;
    }

    if (Platform.isWindows) {
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
    }

    // 3. Disable via launchAtStartup plugin
    try {
      await launchAtStartup.disable();
    } catch (_) {}

    return true;
  }
}
