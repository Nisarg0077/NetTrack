import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'data_usage_service.dart';
import 'settings_service.dart';

const notificationChannelId = 'nettrack_foreground';
const notificationId = 888;

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid) return; // Only relevant for Android

  final service = FlutterBackgroundService();

  if (Platform.isAndroid) {
    const platform = MethodChannel('com.example.net_track/channel');
    try {
      await platform.invokeMethod('createNotificationChannel');
    } catch (e) {
      debugPrint("Failed to create channel: $e");
    }
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true, // Auto start on boot
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'NetTrack Tracker',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: notificationId,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final dataService = DataUsageService();
  final settingsService = SettingsService();

  // Bring to foreground
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer? bgTimer;
  int currentInterval = -1;

  Future<void> performBackgroundWork() async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        try {
          // Fetch usage for today
          final now = DateTime.now();
          final startDate = DateTime(now.year, now.month, now.day);
          
          final usages = await dataService.getAppNetworkUsage(startDate, now);
          
          int totalRx = 0;
          int totalTx = 0;
          for (var app in usages) {
            totalRx += app.rxBytes;
            totalTx += app.txBytes;
          }
          final totalBytes = totalRx + totalTx;
          
          String formatBytes(int bytes) {
            if (bytes < 1024) return '$bytes B';
            if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
            if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
            return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
          }

          service.setForegroundNotificationInfo(
            title: 'NetTrack - Today\'s Usage',
            content: 'Total: ${formatBytes(totalBytes)}',
          );
        } catch (e) {
          debugPrint("Background error: $e");
        }
      }
    }
  }

  void scheduleTimer() async {
    int interval = await settingsService.getRefreshInterval();
    if (interval < 60) interval = 60; // 60s minimum

    currentInterval = interval;
    bgTimer = Timer.periodic(Duration(seconds: currentInterval), (timer) async {
      await performBackgroundWork();

      // Check if interval changed
      int newInterval = await settingsService.getRefreshInterval();
      if (newInterval < 60) newInterval = 60;
      
      if (newInterval != currentInterval) {
        bgTimer?.cancel();
        scheduleTimer();
      }
    });
  }

  // Initial work and start timer
  await performBackgroundWork();
  scheduleTimer();
}
