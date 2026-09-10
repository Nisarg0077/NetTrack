import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/theme_provider.dart';
import '../providers/data_provider.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../services/desktop_startup_service.dart';
import '../widgets/update_dialog.dart';
import 'export_history_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

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
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPackageInfo();
    _checkBackgroundService();
    _checkStartupState();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = info;
        });
      }
    } catch (e) {
      debugPrint('Error loading PackageInfo: $e');
    }
  }

  Future<void> _checkStartupState() async {
    if (Platform.isWindows || Platform.isLinux) {
      bool isEnabled = await DesktopStartupService.isEnabled();
      if (mounted) {
        setState(() {
          _runAtStartup = isEnabled;
        });
      }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Settings'),
            backgroundColor: isDark
                ? const Color(0x99000000)
                : const Color(0x99F2F2F7),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  CupertinoListSection.insetGrouped(
                    backgroundColor: Colors.transparent,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                        width: 0.8,
                      ),
                    ),
                    header: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                      ),
                    ),
                    children: [
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.moon_fill,
                          const Color(0xFF5856D6), // Purple
                        ),
                        title: Text(
                          'Dark Theme',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Toggle dark/light interface',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: CupertinoSwitch(
                          value: themeProvider.isDarkMode,
                          onChanged: (bool value) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ),
                      if (Platform.isWindows || Platform.isLinux)
                        CupertinoListTile(
                          leading: _buildLeadingIcon(
                            CupertinoIcons.power,
                            const Color(0xFF007AFF), // Blue
                          ),
                          title: Text(
                            'Run at Startup',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Launch NetTrack on system boot',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                            ),
                          ),
                          trailing: CupertinoSwitch(
                            value: _runAtStartup,
                            onChanged: (bool value) async {
                              try {
                                if (value) {
                                  await DesktopStartupService.enable();
                                } else {
                                  await DesktopStartupService.disable();
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
                        ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    backgroundColor: Colors.transparent,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                        width: 0.8,
                      ),
                    ),
                    header: Text(
                      'MONITORING & PERMISSIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                      ),
                    ),
                    children: [
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.waveform_path_ecg,
                          const Color(0xFF34C759), // Green
                        ),
                        title: Text(
                          'Background Tracking',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Live traffic monitoring in background',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: CupertinoSwitch(
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
                      ),
                      if (Platform.isAndroid)
                        CupertinoListTile(
                          leading: _buildLeadingIcon(
                            CupertinoIcons.battery_100,
                            const Color(0xFFFF9500), // Orange
                          ),
                          title: Text(
                            'Battery Optimization',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Allow background tracking',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                            ),
                          ),
                          trailing: const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey, size: 16),
                          onTap: () async {
                            final status = await Permission.ignoreBatteryOptimizations.status;
                            if (!status.isGranted) {
                                final result = await Permission.ignoreBatteryOptimizations.request();
                                if (result.isGranted && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Battery optimizations ignored!')),
                                    );
                                }
                            } else {
                                if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Battery optimizations are already ignored!')),
                                    );
                                }
                            }
                          },
                        ),
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.lock_shield_fill,
                          dataProvider.hasPermission ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                        ),
                        title: Text(
                          'Usage Access Permission',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          dataProvider.hasPermission ? 'Granted & active' : 'Permission required',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: dataProvider.hasPermission
                            ? const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Color(0xFF34C759), size: 20)
                            : const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Color(0xFFFF3B30), size: 20),
                        onTap: () {
                          if (!dataProvider.hasPermission) {
                            dataProvider.requestPermission();
                          }
                        },
                      ),
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.timer,
                          const Color(0xFF00C7BE), // Teal
                        ),
                        title: Text(
                          'Polling Interval',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '$_refreshInterval seconds',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF8E8E93)),
                        onTap: () {
                          _showRefreshIntervalActionSheet(context);
                        },
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    backgroundColor: Colors.transparent,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                        width: 0.8,
                      ),
                    ),
                    header: Text(
                      'DATA & UPDATES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                      ),
                    ),
                    children: [
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.archivebox_fill,
                          const Color(0xFFFF9500), // Orange
                        ),
                        title: Text(
                          'Export History',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Manage generated telemetry reports',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF8E8E93)),
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (context) => const ExportHistoryScreen()),
                          );
                        },
                      ),
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.arrow_down_circle_fill,
                          const Color(0xFF007AFF), // Blue
                        ),
                        title: Text(
                          'Software Updates',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          dataProvider.isUpdateAvailable 
                              ? 'Update ${dataProvider.updateLatestVersion} ready to install'
                              : 'NetTrack is up to date',
                          style: TextStyle(
                            color: dataProvider.isUpdateAvailable 
                                ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)) 
                                : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
                            fontWeight: dataProvider.isUpdateAvailable ? FontWeight.w600 : null,
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF8E8E93)),
                        onTap: () {
                          if (dataProvider.isUpdateAvailable && dataProvider.updateReleaseUrl != null) {
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
                  CupertinoListSection.insetGrouped(
                    backgroundColor: Colors.transparent,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                        width: 0.8,
                      ),
                    ),
                    header: Text(
                      'ABOUT & SYSTEM INFO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                      ),
                    ),
                    children: [
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.info_circle_fill,
                          const Color(0xFF007AFF), // Blue
                        ),
                        title: Text(
                          'Version',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Installed application release',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'v${_packageInfo?.version ?? '1.0.4'} (${_packageInfo?.buildNumber ?? '1'})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                            ),
                          ),
                        ),
                      ),
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          Platform.isWindows ? CupertinoIcons.device_laptop : CupertinoIcons.device_phone_portrait,
                          const Color(0xFF5856D6), // Purple
                        ),
                        title: Text(
                          'Platform',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          Platform.isWindows ? 'Windows Desktop (x64)' : (Platform.isAndroid ? 'Android OS' : (Platform.isLinux ? 'Linux OS' : 'macOS / iOS')),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: Text(
                          Platform.operatingSystem.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                      ),
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.chevron_left_slash_chevron_right,
                          const Color(0xFF34C759), // Green
                        ),
                        title: Text(
                          'Source Code',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'github.com/Nisarg0077/NetTrack',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.arrow_up_right, size: 14, color: Color(0xFF8E8E93)),
                        onTap: () async {
                          final uri = Uri.parse('https://github.com/Nisarg0077/NetTrack');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.doc_plaintext,
                          const Color(0xFFFF9500), // Orange
                        ),
                        title: Text(
                          'Third-Party Licenses',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Open source legal notices',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF8E8E93)),
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'NetTrack',
                            applicationVersion: 'v${_packageInfo?.version ?? '1.0.4'}',
                            applicationIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(CupertinoIcons.waveform_path_ecg, color: Colors.white, size: 28),
                              ),
                            ),
                          );
                        },
                      ),
                      CupertinoListTile(
                        leading: _buildLeadingIcon(
                          CupertinoIcons.shield_lefthalf_fill,
                          const Color(0xFF00C7BE), // Teal
                        ),
                        title: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '100% on-device telemetry • No tracking',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.checkmark_shield_fill, size: 16, color: Color(0xFF34C759)),
                      ),
                    ],
                  ),
                  // Footer Branding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(CupertinoIcons.waveform_path_ecg, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'NetTrack',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version ${_packageInfo?.version ?? '1.0.4'} (Build ${_packageInfo?.buildNumber ?? '1'})',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crafted with Modern Design System',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF636366) : const Color(0xFFA1A1A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  void _showRefreshIntervalActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final options = [
      {
        'seconds': 30,
        'title': '30 Seconds',
        'subtitle': 'Fast • Live updates (higher battery usage)',
        'icon': CupertinoIcons.bolt_fill,
        'color': const Color(0xFFFF9500),
      },
      {
        'seconds': 60,
        'title': '1 Minute (Recommended)',
        'subtitle': 'Optimal balance of accuracy & power',
        'icon': CupertinoIcons.sparkles,
        'color': const Color(0xFF007AFF),
      },
      {
        'seconds': 300,
        'title': '5 Minutes',
        'subtitle': 'Low Power • Conserves system resources',
        'icon': CupertinoIcons.battery_100,
        'color': const Color(0xFF34C759),
      },
      {
        'seconds': 0,
        'title': 'Manual Only',
        'subtitle': 'Auto-refresh paused • Pull to refresh',
        'icon': CupertinoIcons.pause_circle_fill,
        'color': const Color(0xFF8E8E93),
      },
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: SingleChildScrollView(
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xE61C1C1E) : const Color(0xF2FFFFFF),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: isDark ? const Color(0x2EFFFFFF) : const Color(0x24000000),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Icon Badge
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00C7BE),
                                      primaryColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C7BE).withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(CupertinoIcons.timer, color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Polling Interval',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose how often NetTrack measures data usage',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Options List
                              ...options.map((opt) {
                                final int sec = opt['seconds'] as int;
                                final bool isSelected = _refreshInterval == sec;
                                final Color optColor = opt['color'] as Color;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        _updateInterval(sec, dialogCtx);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.1)
                                              : (isDark ? const Color(0xFF2C2C2E).withValues(alpha: 0.6) : const Color(0xFFF2F2F7)),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : (isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000)),
                                            width: isSelected ? 1.4 : 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: optColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(opt['icon'] as IconData, color: optColor, size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    opt['title'] as String,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                      color: isSelected
                                                          ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                                                          : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    opt['subtitle'] as String,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                CupertinoIcons.checkmark_alt_circle_fill,
                                                color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                              // Cancel Button
                              SizedBox(
                                width: double.infinity,
                                child: CupertinoButton(
                                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                  borderRadius: BorderRadius.circular(14),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateInterval(int seconds, BuildContext context) async {
    await _settingsService.setRefreshInterval(seconds);
    setState(() {
      _refreshInterval = seconds;
    });
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
       Provider.of<DataProvider>(context, listen: false).restartAutoRefresh(); 
    }
  }
}
