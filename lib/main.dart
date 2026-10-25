import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/data_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_shell.dart';
import 'services/desktop_startup_service.dart';
import 'services/background_service.dart';
import 'services/system_tray_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fusion_ui/fusion_ui.dart';
import 'core/theme/app_typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set transparent system bar on Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  if (Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 700),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await SystemTrayService().init();
    await DesktopStartupService.init();

    // Ensure it's enabled if user turned it on previously
    bool isStartupEnabled = await DesktopStartupService.isEnabled();
    if (isStartupEnabled) {
      try {
        await DesktopStartupService.enable();
      } catch (e) {
        debugPrint('Failed to set startup task: $e');
      }
    }
  }

  await initializeBackgroundService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const NetTrackApp(),
    ),
  );
}

class NetTrackApp extends StatelessWidget {
  const NetTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        final effectQuality = switch (themeProvider.performanceMode) {
          'ultra' => FusionEffectQuality.high,
          'efficiency' || 'battery_saver' => FusionEffectQuality.minimal,
          _ => FusionEffectQuality.balanced,
        };

        final fusionLight = FusionThemeData.light(
          primary: const Color(0xFF007AFF),
          accent: const Color(0xFF5856D6),
          effectQuality: effectQuality,
          reducedMotion: themeProvider.reduceMotion,
        );

        final fusionDark = FusionThemeData.dark(
          primary: const Color(0xFF0A84FF),
          accent: const Color(0xFF5E5CE6),
          effectQuality: effectQuality,
          reducedMotion: themeProvider.reduceMotion,
        );

        final currentFusionTheme = isDark ? fusionDark : fusionLight;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor:
                isDark ? const Color(0xFF000000) : const Color(0xFFE8EEF5),
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: MaterialApp(
            title: 'NetTrack',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              extensions: [fusionLight],
              brightness: Brightness.light,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF007AFF), // System Blue
                onPrimary: Colors.white,
                secondary: Color(0xFF5856D6), // System Purple / Indigo
                onSecondary: Colors.white,
                surface: Color(0xFFFFFFFF),
                onSurface: Color(0xFF1C1C1E),
                surfaceContainerHighest: Color(0xFFDFE5EF),
                error: Color(0xFFFF3B30), // System Red
                onError: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: const Color(0x0A000000),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
              ),
              cupertinoOverrideTheme: CupertinoThemeData(
                brightness: Brightness.light,
                primaryColor: const Color(0xFF007AFF),
                barBackgroundColor: const Color(0xCCF2F2F7),
                scaffoldBackgroundColor: const Color(0xFFF2F2F7),
                textTheme: CupertinoTextThemeData(
                  primaryColor: const Color(0xFF1C1C1E),
                  textStyle: AppTypography.primary(color: const Color(0xFF1C1C1E)),
                ),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                },
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0x14000000), width: 0.8),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFE5E5EA),
                thickness: 0.8,
                space: 1,
              ),
              textTheme: AppTypography.lightTextTheme(ThemeData.light().textTheme),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              extensions: [fusionDark],
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF0A84FF), // Dark System Blue
                onPrimary: Colors.white,
                secondary: Color(0xFF5E5CE6), // Dark Indigo
                onSecondary: Colors.white,
                surface: Color(0xFF1C1C1E), // Dark Neutral Surface
                onSurface: Color(0xFFF2F2F7),
                surfaceContainerHighest: Color(0xFF2C2C2E),
                error: Color(0xFFFF453A),
                onError: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: const Color(0x14FFFFFF),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: Brightness.light,
                ),
              ),
              cupertinoOverrideTheme: CupertinoThemeData(
                brightness: Brightness.dark,
                primaryColor: const Color(0xFF0A84FF),
                barBackgroundColor: const Color(0xCC1C1C1E),
                scaffoldBackgroundColor: const Color(0xFF010101),
                textTheme: CupertinoTextThemeData(
                  primaryColor: Colors.white,
                  textStyle: AppTypography.primary(color: Colors.white),
                ),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                },
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1C1C1E),
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0x1FFFFFFF), width: 0.8),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFF2C2C2E),
                thickness: 0.8,
                space: 1,
              ),
              textTheme: AppTypography.darkTextTheme(ThemeData.dark().textTheme),
            ),
            builder: (context, child) {
              return FusionTheme(
                data: currentFusionTheme,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const AppShell(),
          ),
        );
      },
    );
  }
}
