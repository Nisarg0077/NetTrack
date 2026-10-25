import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../platform/platform_service.dart';
import '../design_system/glass_navigation_bar.dart';
import 'glass_surface.dart';

enum NavigationTab { dashboard, apps, reports, settings }

class AdaptiveNavigation extends StatelessWidget {
  final Widget child;
  final NavigationTab currentTab;
  final ValueChanged<NavigationTab> onTabSelected;

  const AdaptiveNavigation({
    super.key,
    required this.child,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = PlatformService.isDesktop;
        final bool isLandscapeMobile = !isDesktop &&
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 550;
        final bool isTablet = !isDesktop &&
            constraints.maxWidth >= 768 &&
            constraints.maxHeight >= 550;

        final bool showSidebar = isDesktop || isLandscapeMobile || isTablet;

        if (showSidebar) {
          // Compact rail for landscape mobile or narrow desktop/tablet (< 860)
          final bool isCompact =
              isLandscapeMobile || constraints.maxWidth < 860;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                _buildSidebar(
                  context,
                  isCompact: isCompact,
                  isLandscapeMobile: isLandscapeMobile,
                ),
                Expanded(child: child),
              ],
            ),
          );
        } else {
          // Mobile Portrait: Floating Stadium Dock Navigation
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: child,
            extendBody: true,
            bottomNavigationBar: _buildBottomNav(context),
          );
        }
      },
    );
  }

  Widget _buildSidebar(
    BuildContext context, {
    required bool isCompact,
    bool isLandscapeMobile = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: isCompact ? 76 : 256,
        child: GlassSurface(
          borderRadius: BorderRadius.zero,
          blur: 24,
          enableBlur: true,
          forceBlur: true,
          tintColor: isDark ? const Color(0xFF0E1119) : const Color(0xFFF4F6FC),
          border: Border(
            right: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.85,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, sidebarConstraints) {
              final double availableHeight = sidebarConstraints.maxHeight;
              final bool canShowBottomCard =
                  !isCompact && availableHeight >= 520;
              final bool canShowHeaders =
                  !isCompact && availableHeight >= 420;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Spacing / Safe Area
                  SizedBox(
                    height: isLandscapeMobile
                        ? 12
                        : (isCompact ? 20 : 26),
                  ),

                  // Branding Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 18,
                      vertical: isLandscapeMobile ? 2 : 6,
                    ),
                    child: isCompact
                        ? Center(
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(CupertinoIcons.speedometer,
                                  color: Colors.white, size: 20),
                            ),
                          )
                        : Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF007AFF),
                                      Color(0xFF5856D6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF007AFF)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(CupertinoIcons.speedometer,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NetTrack',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1C1C1E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF34C759),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Network Monitor',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF8E8E93)
                                              : const Color(0xFF6E6E73),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  SizedBox(height: isLandscapeMobile ? 8 : 16),

                  // Middle Scrollable Section to completely prevent any RenderFlex overflow
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (canShowHeaders)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, bottom: 8, top: 4),
                              child: Text(
                                'OVERVIEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          _buildSidebarItem(
                            context,
                            icon: CupertinoIcons.gauge,
                            activeIcon: CupertinoIcons.speedometer,
                            label: 'Overview',
                            tab: NavigationTab.dashboard,
                            isCompact: isCompact,
                          ),
                          const SizedBox(height: 2),
                          _buildSidebarItem(
                            context,
                            icon: CupertinoIcons.square_grid_2x2,
                            activeIcon: CupertinoIcons.square_grid_2x2_fill,
                            label: 'Applications',
                            tab: NavigationTab.apps,
                            isCompact: isCompact,
                            showBadge: true,
                          ),

                          if (canShowHeaders) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, bottom: 8),
                              child: Text(
                                'ANALYTICS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ],
                          _buildSidebarItem(
                            context,
                            icon: CupertinoIcons.chart_bar,
                            activeIcon: CupertinoIcons.chart_bar_alt_fill,
                            label: 'Reports',
                            tab: NavigationTab.reports,
                            isCompact: isCompact,
                          ),

                          if (canShowHeaders) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, bottom: 8),
                              child: Text(
                                'SYSTEM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ],
                          _buildSidebarItem(
                            context,
                            icon: CupertinoIcons.gear,
                            activeIcon: CupertinoIcons.gear_alt_fill,
                            label: 'Settings',
                            tab: NavigationTab.settings,
                            isCompact: isCompact,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Network Inspector Card (only when enough height)
                  if (canShowBottomCard)
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Consumer<DataProvider>(
                        builder: (context, provider, child) {
                          final activeInterface = provider
                                  .networkStats.isNotEmpty
                              ? provider.networkStats.first.interfaceName
                              : (Platform.isAndroid
                                  ? 'Cellular / Wi-Fi'
                                  : 'Active Adapter');
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF222226)
                                      .withValues(alpha: 0.9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.25 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: primaryColor
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(CupertinoIcons.wifi,
                                          color: primaryColor, size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activeInterface.isEmpty
                                                ? 'Ethernet'
                                                : activeInterface,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1C1C1E),
                                            ),
                                          ),
                                          Text(
                                            'Online & Monitoring',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w500,
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
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (isCompact) const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required NavigationTab tab,
    required bool isCompact,
    bool showBadge = false,
  }) {
    final isSelected = currentTab == tab;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final iconColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B));
    final textColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onTabSelected(tab),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
                vertical: 9, horizontal: isCompact ? 0 : 12),
            alignment: isCompact ? Alignment.center : Alignment.centerLeft,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF0066D6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF007AFF)
                            .withValues(alpha: isDark ? 0.35 : 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isCompact
                ? Icon(isSelected ? activeIcon : icon,
                    color: iconColor, size: 20)
                : Row(
                    children: [
                      Icon(isSelected ? activeIcon : icon,
                          color: iconColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (showBadge)
                        Consumer<DataProvider>(
                            builder: (context, provider, child) {
                          if (provider.activeAppsCount == 0) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : (isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFE5E5EA)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${provider.activeAppsCount}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFFA1A1AA)
                                        : const Color(0xFF71717A)),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final activeCount = Provider.of<DataProvider>(context).activeAppsCount;

    return GlassNavigationBar(
      currentIndex: currentTab.index,
      onItemSelected: (index) => onTabSelected(NavigationTab.values[index]),
      items: [
        const GlassNavigationItem(
          icon: CupertinoIcons.gauge,
          activeIcon: CupertinoIcons.speedometer,
          label: 'Overview',
        ),
        GlassNavigationItem(
          icon: CupertinoIcons.square_grid_2x2,
          activeIcon: CupertinoIcons.square_grid_2x2_fill,
          label: 'Apps',
          badgeCount: activeCount > 0 ? activeCount : null,
        ),
        const GlassNavigationItem(
          icon: CupertinoIcons.chart_bar,
          activeIcon: CupertinoIcons.chart_bar_alt_fill,
          label: 'Reports',
        ),
        const GlassNavigationItem(
          icon: CupertinoIcons.gear,
          activeIcon: CupertinoIcons.gear_alt_fill,
          label: 'Settings',
        ),
      ],
    );
  }
}
