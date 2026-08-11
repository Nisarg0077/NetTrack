import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'apps_list_screen.dart';
import 'settings_screen.dart';
import 'report_screen.dart';
import '../providers/data_provider.dart';
import '../services/update_service.dart';
import 'permission_gate_screen.dart';
import 'dart:io';
import 'dart:ui';
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AppsListScreen(),
    const ReportScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    
    // Only block if on Android and missing permission
    if (Platform.isAndroid && !provider.hasPermission) {
      return const PermissionGateScreen();
    }

    // Responsive layout
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // Desktop / Tablet layout
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: Text('Apps'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.table_chart_outlined),
                      selectedIcon: Icon(Icons.table_chart),
                      label: Text('Report'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          );
        } else {
          // Mobile layout
          return Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentIndex),
                    child: _screens[_currentIndex],
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: SafeArea(
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final tabWidth = constraints.maxWidth / 4;
                              return Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    left: tabWidth * _currentIndex + (tabWidth * 0.1),
                                    top: 8,
                                    bottom: 8,
                                    width: tabWidth * 0.8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Row(
                                      children: [
                                        Expanded(child: _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard')),
                                        Expanded(child: _buildNavItem(1, Icons.list_alt_outlined, Icons.list_alt, 'Apps')),
                                        Expanded(child: _buildNavItem(2, Icons.table_chart_outlined, Icons.table_chart, 'Report')),
                                        Expanded(child: _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Settings')),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final inactiveColor = theme.iconTheme.color?.withValues(alpha: 0.7) ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent, // Background handled by slider
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: isSelected ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(iconOutlined, color: inactiveColor, size: 24),
                  ),
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(iconFilled, color: primaryColor, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : inactiveColor,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.visible),
            ),
          ],
        ),
      ),
    );
  }
}
