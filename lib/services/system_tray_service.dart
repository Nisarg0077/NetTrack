import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class SystemTrayService with TrayListener, WindowListener {
  static final SystemTrayService _instance = SystemTrayService._internal();

  factory SystemTrayService() {
    return _instance;
  }

  SystemTrayService._internal();
  int _iconToggle = 0;

  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isLinux) return;

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // Set prevent close so we can intercept the X button and hide instead
      await windowManager.setPreventClose(true);
    });
    
    windowManager.addListener(this);
    trayManager.addListener(this);

    await _initTray();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows ? 'windows/runner/resources/app_icon.ico' : 'assets/icon.png',
    );
    try {
      await trayManager.setToolTip('NetTrack - Loading...');
    } catch (e) {
      debugPrint('ToolTip not supported on this platform: $e');
    }

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_app',
          label: 'Show App',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit NetTrack',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  String _formatShort(String usage) {
      if (usage.contains('GB')) {
          final val = double.tryParse(usage.split(' ')[0]) ?? 0;
          return '${val.toStringAsFixed(1)}G';
      } else if (usage.contains('MB')) {
          final val = double.tryParse(usage.split(' ')[0]) ?? 0;
          if (val >= 100) return '${val.toStringAsFixed(0)}M';
          return '${val.toStringAsFixed(1)}M';
      } else if (usage.contains('KB')) {
          final val = double.tryParse(usage.split(' ')[0]) ?? 0;
          return '${val.toStringAsFixed(0)}K';
      }
      return usage.split(' ')[0];
  }

  Future<void> updateTrayUsage(String usageText) async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    
    // Update Tooltip
    try {
      await trayManager.setToolTip('NetTrack: $usageText');
    } catch (e) {
      // Ignore on Linux
    }
    
    // Dynamically generate high quality icon using Flutter Canvas
    try {
        final shortText = _formatShort(usageText);
        
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        const size = Size(128, 128);
        
        double fSize = 110;
        if (shortText.length > 2) fSize = 85;
        if (shortText.length > 3) fSize = 65;
        if (shortText.length > 4) fSize = 50;

        // Draw text with antialiasing
        final textPainter = TextPainter(
          text: TextSpan(
            text: shortText,
            style: TextStyle(
              color: Colors.white,
              fontSize: fSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              shadows: const [
                Shadow(offset: Offset(0, 2), blurRadius: 8.0, color: Colors.black87),
                Shadow(offset: Offset(2, 2), blurRadius: 4.0, color: Colors.black54),
                Shadow(offset: Offset(-1, -1), blurRadius: 2.0, color: Colors.black54),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        final textOffset = Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        );
        textPainter.paint(canvas, textOffset);
        
        final picture = recorder.endRecording();
        final uiImage = await picture.toImage(size.width.toInt(), size.height.toInt());
        final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
            final tempDir = await getTemporaryDirectory();
            // Alternate filenames to force Linux/AppIndicator to reload the cached icon
            _iconToggle = (_iconToggle + 1) % 2;
            
            // Build a dynamic menu showing the usage
            Menu menu = Menu(
              items: [
                MenuItem(key: 'usage_info', label: 'Usage: $usageText', disabled: true),
                MenuItem.separator(),
                MenuItem(key: 'show_app', label: 'Open NetTrack'),
                MenuItem(key: 'exit_app', label: 'Exit'),
              ],
            );

            if (Platform.isWindows) {
                // Convert pristine PNG to ICO using image package
                final imgImage = img.decodePng(byteData.buffer.asUint8List());
                if (imgImage != null) {
                    final icoBytes = img.encodeIco(imgImage);
                    final file = File('${tempDir.path}/nettrack_tray_$_iconToggle.ico');
                    await file.writeAsBytes(icoBytes);
                    await trayManager.setIcon(file.path);
                    await trayManager.setContextMenu(menu);
                }
            } else {
                // Save directly as PNG for Linux for sharper rendering
                final file = File('${tempDir.path}/nettrack_tray_$_iconToggle.png');
                await file.writeAsBytes(byteData.buffer.asUint8List());
                await trayManager.setIcon(file.path);
                await trayManager.setContextMenu(menu);
            }
        }
    } catch (e) {
        debugPrint('Failed to generate dynamic tray icon: $e');
    }
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isLinux) {
      trayManager.popUpContextMenu();
    } else {
      windowManager.show();
      windowManager.focus();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_app') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
      exit(0);
    }
  }
}
