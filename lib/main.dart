import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/data_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_shell.dart';
import 'services/background_service.dart';
import 'services/system_tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows) {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    bool isMsix = Platform.resolvedExecutable.contains('WindowsApps');
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      packageName: isMsix ? 'Nisarg0077.NetTrack' : null,
    );
    
    // Set to true by default on first launch
    final prefs = await SharedPreferences.getInstance();
    bool hasSetStartup = prefs.getBool('has_set_startup') ?? false;
    if (!hasSetStartup) {
      try {
        await launchAtStartup.enable();
      } catch (e) {
        debugPrint('Failed to set startup task: $e');
      }
      await prefs.setBool('has_set_startup', true);
    }
  }

  await SystemTrayService().init();
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
        return MaterialApp(
          title: 'NetTrack',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5), // Indigo 600
              brightness: Brightness.light,
              surface: const Color(0xFFF8FAFC), // Slate 50
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            listTileTheme: const ListTileThemeData(
              tileColor: Colors.transparent,
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF818CF8), // Indigo 400
              brightness: Brightness.dark,
              surface: const Color(0xFF111827), // Gray 900
              primary: const Color(0xFF818CF8), // Indigo 400
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF111827),
            listTileTheme: const ListTileThemeData(
              tileColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1F2937), // Gray 800
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          home: const AppShell(),
        );
      },
    );
  }
}
