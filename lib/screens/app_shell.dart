import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dashboard_screen.dart';
import 'apps_list_screen.dart';
import 'settings_screen.dart';
import 'report_screen.dart';
import 'permission_gate_screen.dart';

import '../providers/data_provider.dart';
import '../services/update_service.dart';
import '../core/widgets/adaptive_navigation.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/animated_indexed_stack.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  NavigationTab _currentTab = NavigationTab.dashboard;
  late final FocusNode _searchFocusNode = FocusNode();

  late final List<Widget> _screens = [
    const DashboardScreen(),
    AppsListScreen(searchFocusNode: _searchFocusNode),
    const ReportScreen(),
    const SettingsScreen(),
  ];

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  void _onTabSelected(NavigationTab tab) {
    if (_currentTab != tab) {
      setState(() => _currentTab = tab);
    } else if (tab == NavigationTab.apps) {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Only block if on Android and missing permission
    if (Platform.isAndroid && !provider.hasPermission) {
      return const PermissionGateScreen();
    }

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent, // Let edge-to-edge shine
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: AmbientBackground(
        child: AdaptiveNavigation(
          currentTab: _currentTab,
          onTabSelected: _onTabSelected,
          child: AnimatedIndexedStack(
            index: _currentTab.index,
            children: _screens,
          ),
        ),
      ),
    );
  }
}
