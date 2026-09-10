import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
      systemNavigationBarColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: LayoutBuilder(
        builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          // Desktop / Tablet Layout
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            body: Row(
              children: [
                _buildDesktopSidebar(context, isDark, provider),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121214) : const Color(0xFFFFFFFF),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      border: Border(
                        left: BorderSide(
                          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      child: _screens[_currentIndex],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Edge-to-Edge Layout with Floating Capsule + Quick Search Island
          return Scaffold(
            extendBody: true,
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            body: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentIndex),
                    child: _screens[_currentIndex],
                  ),
                ),
                // Bottom Scroll Edge Fade Effect
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 110,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7)).withValues(alpha: 0.0),
                            (isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7)).withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Floating Liquid Glass Navigation
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFloatingPill(context, isDark),
                ),
              ],
            ),
          );
        }
      },
      ),
    );
  }

  // --- Floating Capsule + Quick Search Island ---
  Widget _buildFloatingPill(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: RepaintBoundary(
              child: Row(
                children: [
                  // Main Liquid Glass Capsule
                  Expanded(
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: isDark
                            ? const Color(0x991C1C1E)
                            : const Color(0xB8FFFFFF),
                        border: Border.all(
                          color: isDark
                              ? const Color(0x33FFFFFF)
                              : const Color(0x80FFFFFF),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 28,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final tabWidth = constraints.maxWidth / 4;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Smooth Sliding Pill Indicator
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    left: tabWidth * _currentIndex + (tabWidth * 0.08),
                                    top: 6,
                                    bottom: 6,
                                    width: tabWidth * 0.84,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? primaryColor.withValues(alpha: 0.22)
                                            : primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(
                                          color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Navigation Items
                                  Positioned.fill(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildPillItem(
                                            0,
                                            CupertinoIcons.square_grid_2x2,
                                            CupertinoIcons.square_grid_2x2_fill,
                                            'Dashboard',
                                            primaryColor,
                                            isDark,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildPillItem(
                                            1,
                                            CupertinoIcons.app_badge,
                                            CupertinoIcons.app_badge_fill,
                                            'Apps',
                                            primaryColor,
                                            isDark,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildPillItem(
                                            2,
                                            CupertinoIcons.chart_bar_square,
                                            CupertinoIcons.chart_bar_alt_fill,
                                            'Report',
                                            primaryColor,
                                            isDark,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildPillItem(
                                            3,
                                            CupertinoIcons.gear_alt,
                                            CupertinoIcons.gear_alt_fill,
                                            'Settings',
                                            primaryColor,
                                            isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Quick Search Island (Circular Action Bubble)
                  GestureDetector(
                    onTap: () {
                      if (_currentIndex != 1) {
                        setState(() => _currentIndex = 1);
                      }
                      // Focus the search bar after a tiny delay to ensure screen is active
                      Future.delayed(const Duration(milliseconds: 50), () {
                        _searchFocusNode.requestFocus();
                      });
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == 1
                            ? primaryColor
                            : (isDark ? const Color(0x991C1C1E) : const Color(0xB8FFFFFF)),
                        border: Border.all(
                          color: _currentIndex == 1
                              ? primaryColor
                              : (isDark ? const Color(0x33FFFFFF) : const Color(0x80FFFFFF)),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _currentIndex == 1
                                ? primaryColor.withValues(alpha: isDark ? 0.4 : 0.25)
                                : Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 28,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.search,
                              size: 22,
                              color: _currentIndex == 1
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                            ),
                          ),
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
  }

  Widget _buildPillItem(
    int index,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
    Color primaryColor,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    final inactiveColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? primaryColor : inactiveColor,
              size: 21,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: isSelected ? primaryColor : inactiveColor,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.visible),
          ),
        ],
      ),
    );
  }

  // --- Desktop Sidebar ---
  Widget _buildDesktopSidebar(BuildContext context, bool isDark, DataProvider provider) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: 260,
      color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Brand Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, const Color(0xFF5856D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(CupertinoIcons.waveform_path_badge_plus, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NetTrack',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759), // Apple Green
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Realtime Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Sidebar Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
                ),
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildSidebarItem(0, CupertinoIcons.square_grid_2x2, CupertinoIcons.square_grid_2x2_fill, 'Dashboard', isDark, primaryColor),
                  _buildSidebarItem(1, CupertinoIcons.app_badge, CupertinoIcons.app_badge_fill, 'Applications', isDark, primaryColor, badge: '${provider.appUsages.length}'),
                  _buildSidebarItem(2, CupertinoIcons.chart_bar_square, CupertinoIcons.chart_bar_alt_fill, 'Analytics & Report', isDark, primaryColor),
                  _buildSidebarItem(3, CupertinoIcons.gear_alt, CupertinoIcons.gear_alt_fill, 'Settings', isDark, primaryColor),
                ],
              ),
            ),

            // Bottom Real-time Telemetry Mini Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.antenna_radiowaves_left_right, color: primaryColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Interface',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                            ),
                          ),
                          Text(
                            provider.networkStats.isNotEmpty
                                ? provider.networkStats.first.interfaceName
                                : 'Wi-Fi / Ethernet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
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
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
    bool isDark,
    Color primaryColor, {
    String? badge,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? primaryColor.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? iconFilled : iconOutlined,
                  color: isSelected ? primaryColor : (isDark ? const Color(0xFF98989D) : const Color(0xFF636366)),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                      color: isSelected
                          ? primaryColor
                          : (isDark ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E)),
                    ),
                  ),
                ),
                if (badge != null && badge.isNotEmpty && badge != '0')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.2)
                          : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

