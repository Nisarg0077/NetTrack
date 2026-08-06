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

  Future<void> init() async {
    if (!Platform.isWindows) return;

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
    await trayManager.setToolTip('NetTrack - Loading...');

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
    if (!Platform.isWindows) return;
    
    // Update Tooltip
    await trayManager.setToolTip('NetTrack: $usageText');
    
    // Dynamically generate high quality icon using Flutter Canvas
    try {
        final shortText = _formatShort(usageText);
        
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        const size = Size(128, 128);
        
        // Draw deep indigo background with rounded corners
        final paint = Paint()
          ..color = const Color(0xFF1F2937) // Gray 800
          ..style = PaintingStyle.fill;
        final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24));
        canvas.drawRRect(rrect, paint);
        
        // Draw vivid indigo border
        final borderPaint = Paint()
          ..color = const Color(0xFF4F46E5) // Indigo 600
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10;
        canvas.drawRRect(rrect, borderPaint);
        
        // Draw text with antialiasing
        final textPainter = TextPainter(
          text: TextSpan(
            text: shortText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
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
            // Convert pristine PNG to ICO using image package
            final imgImage = img.decodePng(byteData.buffer.asUint8List());
            if (imgImage != null) {
                final icoBytes = img.encodeIco(imgImage);
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}\\nettrack_tray.ico');
                await file.writeAsBytes(icoBytes);
                
                await trayManager.setIcon(file.path);
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
    windowManager.show();
    windowManager.focus();
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
