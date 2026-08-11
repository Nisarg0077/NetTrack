import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import '../providers/theme_provider.dart';
import '../providers/data_provider.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'export_history_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:ui';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  int _refreshInterval = 60;
  bool _isBackgroundServiceRunning = false;
  bool _runAtStartup = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBackgroundService();
    _checkStartupState();
  }

  Future<void> _checkStartupState() async {
    if (Platform.isWindows) {
      bool isEnabled = await launchAtStartup.isEnabled();
      setState(() {
        _runAtStartup = isEnabled;
      });
    }
  }

  Future<void> _checkBackgroundService() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    setState(() {
      _isBackgroundServiceRunning = isRunning;
    });
  }

  Future<void> _loadSettings() async {
    final interval = await _settingsService.getRefreshInterval();
    setState(() {
      _refreshInterval = interval;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Material(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.only(top: 100, bottom: 100),
          children: [
            SwitchListTile(
            title: const Text('Dark Theme'),
            subtitle: const Text('Toggle dark/light mode'),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme();
            },
          ),
          if (Platform.isWindows)
            SwitchListTile(
              title: const Text('Run at Startup'),
              subtitle: const Text('Automatically launch the app when you log in'),
              value: _runAtStartup,
              onChanged: (bool value) async {
                try {
                  if (value) {
                    await launchAtStartup.enable();
                  } else {
                    await launchAtStartup.disable();
                  }
                  if (!context.mounted) return;
                  setState(() {
                    _runAtStartup = value;
                  });
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not change startup settings: $e')),
                  );
                }
              },
            ),
          SwitchListTile(
            title: const Text('Background Tracking'),
            subtitle: const Text('Track usage in real-time in background'),
            value: _isBackgroundServiceRunning,
            onChanged: (bool value) async {
              final service = FlutterBackgroundService();
              if (value) {
                await service.startService();
              } else {
                service.invoke("stopService");
              }
              setState(() {
                _isBackgroundServiceRunning = value;
              });
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Permissions'),
            subtitle: Text(dataProvider.hasPermission ? 'Granted' : 'Not Granted'),
            trailing: dataProvider.hasPermission
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.error, color: Colors.red),
            onTap: () {
              if (!dataProvider.hasPermission) {
                dataProvider.requestPermission();
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Refresh Interval'),
            subtitle: Text('$_refreshInterval seconds'),
            trailing: const Icon(Icons.timer),
            onTap: () {
              _showRefreshIntervalDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Export History'),
            subtitle: const Text('View, open, share, or delete past exported reports'),
            trailing: const Icon(Icons.history_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportHistoryScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Check for Updates'),
            subtitle: Text(
              dataProvider.isUpdateAvailable 
                  ? 'New Update Available! (${dataProvider.updateLatestVersion})'
                  : 'See if a newer version is available',
              style: TextStyle(
                color: dataProvider.isUpdateAvailable ? Colors.blueAccent : null,
                fontWeight: dataProvider.isUpdateAvailable ? FontWeight.bold : null,
              ),
            ),
            trailing: Icon(
              Icons.system_update,
              color: dataProvider.isUpdateAvailable ? Colors.blueAccent : null,
            ),
            onTap: () {
              if (dataProvider.isUpdateAvailable && dataProvider.updateReleaseUrl != null) {
                // If we already know an update is available, just show the dialog immediately
                showDialog(
                  context: context,
                  builder: (context) => UpdateDialog(
                    latestVersion: dataProvider.updateLatestVersion ?? '',
                    releaseNotes: dataProvider.updateReleaseNotes ?? '',
                    releaseUrl: dataProvider.updateReleaseUrl ?? '',
                  ),
                );
              } else {
                UpdateService.checkForUpdates(context, showNoUpdateMessage: true);
              }
            },
          ),
        ],
      ),
      ),
    );
  }

  void _showRefreshIntervalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Refresh Interval'),
          content: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                title: const Text('30 seconds (Heavy Battery)'),
                onTap: () => _updateInterval(30, context),
              ),
              ListTile(
                title: const Text('1 minute (Recommended)'),
                onTap: () => _updateInterval(60, context),
              ),
              ListTile(
                title: const Text('5 minutes'),
                onTap: () => _updateInterval(300, context),
              ),
              ListTile(
                title: const Text('Disable Auto-refresh'),
                onTap: () => _updateInterval(0, context),
              ),
            ],
          ),
          ),
        );
      }
    );
  }

  void _updateInterval(int seconds, BuildContext context) async {
    await _settingsService.setRefreshInterval(seconds);
    setState(() {
      _refreshInterval = seconds;
    });
    if (context.mounted) Navigator.pop(context);
    // Restart timer by re-initing provider (or add a method)
    if (context.mounted) {
       Provider.of<DataProvider>(context, listen: false).restartAutoRefresh(); 
    }
  }
}
