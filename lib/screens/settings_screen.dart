import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fusion_ui/fusion_ui.dart';

import '../providers/theme_provider.dart';
import '../providers/data_provider.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../services/desktop_startup_service.dart';
import '../widgets/update_dialog.dart';
import 'export_history_screen.dart';
import 'licenses_screen.dart';

import '../core/design_system/glass_toolbar.dart';
import '../core/design_system/floating_pill.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/platform/platform_service.dart';
import '../core/widgets/app_toast.dart';

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
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (mounted) {
        setState(() {
          _isBackgroundServiceRunning = isRunning;
        });
      }
    } catch (e) {
      debugPrint("Background service check failed: $e");
    }
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverGlassToolbarDelegate(
              height: MediaQuery.of(context).padding.top +
                  (PlatformService.isDesktop ? 54.0 : 64.0),
              child: SafeArea(
                bottom: false,
                child: GlassToolbar(
                  useSafeArea: false,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  title: 'Settings',
                  statusWidget: ConnectionStatusPill(
                    label: PlatformService.platformName,
                    color: const Color(0xFF34C759),
                    isLive: false,
                  ),
                  actions: [
                    FloatingActionPill(
                      icon: themeProvider.isSystemMode
                          ? CupertinoIcons.circle_righthalf_fill
                          : (isDark
                              ? CupertinoIcons.sun_max_fill
                              : CupertinoIcons.moon_fill),
                      label: themeProvider.isSystemMode
                          ? 'Auto'
                          : (isDark ? 'Light' : 'Dark'),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 768;
                final horizontalPadding =
                    isDesktop ? AppSpacing.xl : AppSpacing.md;
                final bottomPadding = isDesktop ? 60.0 : 120.0;

                if (isDesktop) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding,
                        AppSpacing.sm, horizontalPadding, bottomPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column (System Preferences & Performance)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildPreferencesSection(
                                          themeProvider, isDark),
                                      const SizedBox(height: AppSpacing.xl),
                                      _buildPerformanceSection(
                                          themeProvider, isDark),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xl),
                                // Right Column (Monitoring, Data & About)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildMonitoringSection(
                                          dataProvider, isDark),
                                      const SizedBox(height: AppSpacing.xl),
                                      _buildDataUpdatesSection(
                                          dataProvider, isDark),
                                      const SizedBox(height: AppSpacing.xl),
                                      _buildAboutSection(isDark),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _buildBrandingFooter(isDark),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Mobile Inset Grouped layout
                return Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, AppSpacing.sm,
                      horizontalPadding, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPreferencesSection(themeProvider, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildPerformanceSection(themeProvider, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildMonitoringSection(dataProvider, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildDataUpdatesSection(dataProvider, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildAboutSection(isDark),
                      _buildBrandingFooter(isDark),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(ThemeProvider themeProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('PREFERENCES', isDark),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: themeProvider.isSystemMode
                    ? CupertinoIcons.circle_righthalf_fill
                    : (isDark
                        ? CupertinoIcons.moon_fill
                        : CupertinoIcons.sun_max_fill),
                iconColor: themeProvider.isSystemMode
                    ? const Color(0xFF007AFF)
                    : (isDark
                        ? const Color(0xFF5856D6)
                        : const Color(0xFFFF9500)),
                title: 'Theme Mode',
                subtitle: switch (themeProvider.themeMode) {
                  ThemeMode.system => 'System Default • Follows device appearance',
                  ThemeMode.dark => 'Dark Theme • Permanent obsidian glass',
                  ThemeMode.light => 'Light Theme • Crisp porcelain acrylic',
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        switch (themeProvider.themeMode) {
                          ThemeMode.system => 'System (Auto)',
                          ThemeMode.dark => 'Dark',
                          ThemeMode.light => 'Light',
                        },
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF0A84FF)
                              : const Color(0xFF007AFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 14, color: CupertinoColors.systemGrey),
                  ],
                ),
                onTap: () => _showThemeModeDialog(context, themeProvider),
                isDark: isDark,
              ),
              if (Platform.isWindows || Platform.isLinux) ...[
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  icon: CupertinoIcons.power,
                  iconColor: const Color(0xFF007AFF),
                  title: 'Run at Startup',
                  subtitle: 'Launch NetTrack on system boot',
                  trailing: FusionSwitch(
                    value: _runAtStartup,
                    onChanged: (bool value) async {
                      try {
                        if (value) {
                          await DesktopStartupService.enable();
                        } else {
                          await DesktopStartupService.disable();
                        }
                        if (!mounted) return;
                        setState(() {
                          _runAtStartup = value;
                        });
                        AppToast.success(
                          context,
                          value
                              ? 'Run at startup enabled'
                              : 'Run at startup disabled',
                          icon: CupertinoIcons.power,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        AppToast.error(
                          context,
                          'Could not change startup settings: $e',
                        );
                      }
                    },
                  ),
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(ThemeProvider themeProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('PERFORMANCE & GRAPHICS', isDark),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: CupertinoIcons.sparkles,
                iconColor: const Color(0xFF007AFF),
                title: 'Graphics Engine Tier',
                subtitle: themeProvider.isUltraMode
                    ? 'Frosted Glass • Optical blur & specular reflections'
                    : (themeProvider.isEfficiencyMode
                        ? 'Battery Saver • Zero blur passes, minimal GPU load'
                        : 'Smooth Acrylic • 60/120 FPS balanced rendering'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      themeProvider.isUltraMode
                          ? 'Ultra'
                          : (themeProvider.isEfficiencyMode
                              ? 'Efficiency'
                              : 'Smooth'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isUltraMode
                            ? const Color(0xFF007AFF)
                            : (themeProvider.isEfficiencyMode
                                ? const Color(0xFFFF9500)
                                : const Color(0xFF34C759)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 14, color: CupertinoColors.systemGrey),
                  ],
                ),
                onTap: () => _showGraphicsTierDialog(context, themeProvider),
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: CupertinoIcons.slowmo,
                iconColor: const Color(0xFFFF9500),
                title: 'Reduce Motion',
                subtitle: 'Pause heavy animations to save battery & CPU',
                trailing: FusionSwitch(
                  value: themeProvider.reduceMotion,
                  onChanged: (bool value) {
                    themeProvider.setReduceMotion(value);
                    AppToast.info(
                      context,
                      value
                          ? 'Reduce motion enabled'
                          : 'Reduce motion disabled',
                      icon: CupertinoIcons.slowmo,
                    );
                  },
                ),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonitoringSection(DataProvider dataProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('MONITORING & PERMISSIONS', isDark),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              if (Platform.isAndroid || Platform.isIOS) ...[
                _buildSettingsTile(
                  icon: CupertinoIcons.waveform_path_ecg,
                  iconColor: const Color(0xFF34C759),
                  title: 'Background Tracking',
                  subtitle: 'Live traffic monitoring in background',
                  trailing: FusionSwitch(
                    value: _isBackgroundServiceRunning,
                    onChanged: (bool value) async {
                      final service = FlutterBackgroundService();
                      if (value) {
                        await service.startService();
                      } else {
                        service.invoke("stopService");
                      }
                      if (!mounted) return;
                      setState(() {
                        _isBackgroundServiceRunning = value;
                      });
                      AppToast.info(
                        context,
                        value
                            ? 'Background tracking active'
                            : 'Background tracking stopped',
                        icon: CupertinoIcons.waveform_path_ecg,
                      );
                    },
                  ),
                  isDark: isDark,
                ),
                const Divider(height: 1, indent: 56),
              ],
              if (Platform.isAndroid) ...[
                _buildSettingsTile(
                  icon: CupertinoIcons.battery_charging,
                  iconColor: const Color(0xFFFF9500),
                  title: 'Battery Optimization',
                  subtitle: 'Allow background tracking',
                  trailing: const Icon(CupertinoIcons.chevron_right,
                      size: 16, color: CupertinoColors.systemGrey),
                  onTap: () async {
                    final status =
                        await Permission.ignoreBatteryOptimizations.status;
                    if (!status.isGranted) {
                      final result =
                          await Permission.ignoreBatteryOptimizations.request();
                      if (result.isGranted && mounted) {
                        AppToast.success(
                          context,
                          'Battery optimizations ignored',
                          icon: CupertinoIcons.battery_charging,
                        );
                      }
                    } else {
                      if (mounted) {
                        AppToast.info(
                          context,
                          'Battery optimizations already ignored',
                          icon: CupertinoIcons.battery_charging,
                        );
                      }
                    }
                  },
                  isDark: isDark,
                ),
                const Divider(height: 1, indent: 56),
              ],
              _buildSettingsTile(
                icon: CupertinoIcons.lock_shield_fill,
                iconColor: dataProvider.hasPermission
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
                title: 'Usage Access Permission',
                subtitle: dataProvider.hasPermission
                    ? 'Granted & active'
                    : 'Permission required',
                trailing: dataProvider.hasPermission
                    ? const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                        color: Color(0xFF34C759), size: 20)
                    : const Icon(CupertinoIcons.exclamationmark_circle_fill,
                        color: Color(0xFFFF3B30), size: 20),
                onTap: () {
                  if (!dataProvider.hasPermission) {
                    dataProvider.requestPermission();
                  }
                },
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: CupertinoIcons.timer,
                iconColor: const Color(0xFF00C7BE),
                title: 'Polling Interval',
                subtitle: '$_refreshInterval seconds',
                trailing: const Icon(CupertinoIcons.chevron_right,
                    size: 16, color: CupertinoColors.systemGrey),
                onTap: () => _showRefreshIntervalActionSheet(context),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataUpdatesSection(DataProvider dataProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('DATA & UPDATES', isDark),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: CupertinoIcons.archivebox_fill,
                iconColor: const Color(0xFFFF9500),
                title: 'Export History',
                subtitle: 'Manage generated telemetry reports',
                trailing: const Icon(CupertinoIcons.chevron_right,
                    size: 16, color: CupertinoColors.systemGrey),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const ExportHistoryScreen()),
                  );
                },
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: CupertinoIcons.arrow_down_circle_fill,
                iconColor: const Color(0xFF007AFF),
                title: 'Software Updates',
                subtitle: dataProvider.isUpdateAvailable
                    ? 'Update ${dataProvider.updateLatestVersion} ready to install'
                    : (dataProvider.isCheckingUpdate
                        ? 'Checking for latest release...'
                        : 'NetTrack is up to date • Tap to check'),
                trailing: dataProvider.isCheckingUpdate
                    ? const CupertinoActivityIndicator(radius: 8)
                    : (dataProvider.isUpdateAvailable
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'v${dataProvider.updateLatestVersion}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Icon(CupertinoIcons.chevron_right,
                            size: 16, color: CupertinoColors.systemGrey)),
                onTap: () {
                  if (dataProvider.isCheckingUpdate) return;
                  if (dataProvider.isUpdateAvailable &&
                      dataProvider.updateReleaseUrl != null) {
                    showDialog(
                      context: context,
                      builder: (context) => UpdateDialog(
                        latestVersion: dataProvider.updateLatestVersion ?? '',
                        currentVersion: _packageInfo?.version,
                        releaseNotes: dataProvider.updateReleaseNotes ?? '',
                        releaseUrl: dataProvider.updateReleaseUrl ?? '',
                      ),
                    );
                  } else {
                    UpdateService.checkForUpdates(context,
                        showNoUpdateMessage: true);
                  }
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('ABOUT & SYSTEM INFO', isDark),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: CupertinoIcons.info_circle_fill,
                iconColor: const Color(0xFF007AFF),
                title: 'Version',
                subtitle: 'Installed application release',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${_packageInfo?.version ?? '1.0.4'} (${_packageInfo?.buildNumber ?? '1'})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF0A84FF)
                          : const Color(0xFF007AFF),
                    ),
                  ),
                ),
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: Platform.isWindows
                    ? CupertinoIcons.device_laptop
                    : CupertinoIcons.device_phone_portrait,
                iconColor: const Color(0xFF5856D6),
                title: 'Platform',
                subtitle: Platform.isWindows
                    ? 'Windows Desktop (x64)'
                    : (Platform.isAndroid
                        ? 'Android OS'
                        : (Platform.isLinux ? 'Linux OS' : PlatformService.platformName)),
                trailing: Text(
                  Platform.operatingSystem.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: CupertinoIcons.chevron_left_slash_chevron_right,
                iconColor: const Color(0xFF34C759),
                title: 'Source Code',
                subtitle: 'github.com/Nisarg0077/NetTrack',
                trailing: const Icon(CupertinoIcons.arrow_up_right,
                    size: 14, color: CupertinoColors.systemGrey),
                onTap: () async {
                  final uri =
                      Uri.parse('https://github.com/Nisarg0077/NetTrack');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: CupertinoIcons.doc_text_search,
                iconColor: const Color(0xFFFF9500),
                title: 'Third-Party Licenses',
                subtitle: 'Open source legal notices & copyright terms',
                trailing: const Icon(CupertinoIcons.chevron_right,
                    size: 16, color: CupertinoColors.systemGrey),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const LicensesScreen()),
                  );
                },
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: CupertinoIcons.shield_lefthalf_fill,
                iconColor: const Color(0xFF00C7BE),
                title: 'Privacy Policy',
                subtitle: '100% on-device telemetry • No tracking',
                trailing: const Icon(CupertinoIcons.checkmark_shield_fill,
                    size: 16, color: Color(0xFF34C759)),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
              child: Icon(CupertinoIcons.waveform_path_ecg,
                  color: Colors.white, size: 22),
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
            'Crafted with Fusion-ui',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF636366) : const Color(0xFFA1A1A6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
          16), // Match container if it's the only one, otherwise splash might leak
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Center(child: trailing),
            ],
          ],
        ),
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
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: GlassSurface(
                      borderRadius: BorderRadius.circular(26),
                      blur: 28,
                      elevation: 4,
                      useBackdropFilter: true,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                      color: const Color(0xFF00C7BE)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(CupertinoIcons.timer,
                                      color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Polling Interval',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose how often NetTrack measures data usage',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6E6E73),
                                ),
                              ),
                              const SizedBox(height: 18),
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
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor.withValues(
                                                  alpha: isDark ? 0.18 : 0.1)
                                              : (isDark
                                                  ? const Color(0xFF2C2C2E)
                                                      .withValues(alpha: 0.6)
                                                  : const Color(0xFFF2F2F7)),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : (isDark
                                                    ? const Color(0x1AFFFFFF)
                                                    : const Color(0x14000000)),
                                            width: isSelected ? 1.4 : 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: optColor.withValues(
                                                    alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                  opt['icon'] as IconData,
                                                  color: optColor,
                                                  size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    opt['title'] as String,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      color: isSelected
                                                          ? (isDark
                                                              ? const Color(
                                                                  0xFF0A84FF)
                                                              : const Color(
                                                                  0xFF007AFF))
                                                          : (isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF1C1C1E)),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    opt['subtitle'] as String,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF8E8E93)
                                                          : const Color(
                                                              0xFF6E6E73),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                CupertinoIcons
                                                    .checkmark_alt_circle_fill,
                                                color: isDark
                                                    ? const Color(0xFF0A84FF)
                                                    : const Color(0xFF007AFF),
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
                              SizedBox(
                                width: double.infinity,
                                child: CupertinoButton(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFE5E5EA),
                                  borderRadius: BorderRadius.circular(14),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1C1C1E),
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
      final intervalText = seconds == 0 ? 'Manual only' : '$seconds seconds';
      AppToast.success(
        context,
        'Polling interval set to $intervalText',
        icon: CupertinoIcons.timer,
      );
    }
  }

  void _showThemeModeDialog(
      BuildContext context, ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final modes = [
      {
        'mode': ThemeMode.system,
        'title': 'System Default',
        'subtitle': 'Automatically matches device system appearance',
        'icon': CupertinoIcons.circle_righthalf_fill,
        'color': const Color(0xFF007AFF),
      },
      {
        'mode': ThemeMode.light,
        'title': 'Light Theme',
        'subtitle': 'Crisp porcelain acrylic with high-contrast elements',
        'icon': CupertinoIcons.sun_max_fill,
        'color': const Color(0xFFFF9500),
      },
      {
        'mode': ThemeMode.dark,
        'title': 'Dark Theme',
        'subtitle': 'Deep obsidian glass with illuminated neon accents',
        'icon': CupertinoIcons.moon_fill,
        'color': const Color(0xFF5856D6),
      },
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Center(
          child: SingleChildScrollView(
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassSurface(
                  borderRadius: BorderRadius.circular(26),
                  blur: 28,
                  elevation: 4,
                  useBackdropFilter: true,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF)
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(CupertinoIcons.circle_righthalf_fill,
                              color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Theme Appearance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how NetTrack renders its interface',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...modes.map((opt) {
                        final mode = opt['mode'] as ThemeMode;
                        final isSelected = themeProvider.themeMode == mode;
                        final Color optColor = opt['color'] as Color;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                themeProvider.setThemeMode(mode);
                                Navigator.pop(dialogCtx);
                                AppToast.success(
                                  context,
                                  'Theme set to ${opt['title']}',
                                  icon: opt['icon'] as IconData,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withValues(
                                          alpha: isDark ? 0.18 : 0.1)
                                      : (isDark
                                          ? const Color(0xFF2C2C2E)
                                              .withValues(alpha: 0.6)
                                          : const Color(0xFFF2F2F7)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark
                                            ? const Color(0x1AFFFFFF)
                                            : const Color(0x14000000)),
                                    width: isSelected ? 1.4 : 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color:
                                            optColor.withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        opt['icon'] as IconData,
                                        color: optColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            opt['title'] as String,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? (isDark
                                                      ? const Color(0xFF0A84FF)
                                                      : const Color(0xFF007AFF))
                                                  : (isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF1C1C1E)),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            opt['subtitle'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? const Color(0xFF8E8E93)
                                                  : const Color(0xFF6E6E73),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        CupertinoIcons
                                            .checkmark_alt_circle_fill,
                                        color: isDark
                                            ? const Color(0xFF0A84FF)
                                            : const Color(0xFF007AFF),
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
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
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
        );
      },
    );
  }

  void _showGraphicsTierDialog(
      BuildContext context, ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final tiers = [
      {
        'tier': 'ultra',
        'title': 'Frosted Glass (High Fidelity)',
        'badge': 'Fusion Glass',
        'subtitle':
            'Authentic optical backdrop diffusion, crisp specular hairline rims, and depth shadows. Hardware accelerated.',
        'icon': CupertinoIcons.sparkles,
        'color': const Color(0xFF007AFF),
      },
      {
        'tier': 'smooth',
        'title': 'Smooth Acrylic (Default)',
        'badge': 'Balanced',
        'subtitle':
            'Silky 60/120 FPS performance with lightweight acrylic diffusion. Perfectly balanced for all modern hardware.',
        'icon': CupertinoIcons.layers_alt_fill,
        'color': const Color(0xFF34C759),
      },
      {
        'tier': 'efficiency',
        'title': 'Battery Saver / Low-End',
        'badge': 'Max Battery',
        'subtitle':
            'Zero GPU backdrop filter overhead. Tinted acrylic with specular rim for budget devices and extended battery life.',
        'icon': CupertinoIcons.battery_100,
        'color': const Color(0xFFFF9500),
      },
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Center(
          child: SingleChildScrollView(
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassSurface(
                  borderRadius: BorderRadius.circular(26),
                  blur: 28,
                  elevation: 4,
                  useBackdropFilter: true,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF007AFF)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(CupertinoIcons.sparkles,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Graphics Engine Tier',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select rendering fidelity optimized for your hardware',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ...tiers.map((opt) {
                            final String mode = opt['tier'] as String;
                            final bool isSelected =
                                themeProvider.performanceMode == mode;
                            final Color optColor = opt['color'] as Color;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    themeProvider.setPerformanceMode(mode);
                                    Navigator.of(dialogCtx).pop();
                                    AppToast.success(
                                      context,
                                      'Graphics engine set to ${opt['badge']}',
                                      icon: CupertinoIcons.sparkles,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? optColor.withValues(
                                              alpha: isDark ? 0.18 : 0.1)
                                          : (isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.04)
                                              : Colors.black
                                                  .withValues(alpha: 0.03)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? optColor.withValues(alpha: 0.6)
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : Colors.black
                                                    .withValues(alpha: 0.06)),
                                        width: isSelected ? 1.5 : 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: optColor.withValues(
                                                alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(opt['icon'] as IconData,
                                              size: 18, color: optColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    opt['title'] as String,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF1C1C1E),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  if (isSelected)
                                                    Icon(
                                                        CupertinoIcons
                                                            .checkmark_circle_fill,
                                                        color: optColor,
                                                        size: 18),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                opt['subtitle'] as String,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 1.35,
                                                  color: isDark
                                                      ? const Color(0xFF8E8E93)
                                                      : const Color(0xFF6E6E73),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
      },
    );
  }
}
