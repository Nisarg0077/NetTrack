import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../providers/data_provider.dart';
import '../models/app_usage_model.dart';
import '../widgets/app_usage_tile.dart';
import '../utils/format_utils.dart';
import 'app_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// Design System
import '../core/widgets/glass_card.dart';
import '../core/design_system/glass_toolbar.dart';
import '../core/design_system/floating_pill.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/platform/platform_service.dart';

class AppsListScreen extends StatefulWidget {
  final FocusNode? searchFocusNode;

  const AppsListScreen({super.key, this.searchFocusNode});

  @override
  State<AppsListScreen> createState() => _AppsListScreenState();
}

class _AppsListScreenState extends State<AppsListScreen> {
  String _searchQuery = '';
  int _sortBy = 0; // 0: Total, 1: Download, 2: Upload, 3: A-Z
  int _filterBy = 0; // 0: All, 1: User, 2: System
  bool _animateItems = true;
  Timer? _debounceTimer;

  List<AppUsageModel>? _cachedFilteredApps;
  List<AppUsageModel>? _lastSourceApps;
  String _lastSearch = '';
  int _lastSort = 0;
  int _lastFilter = 0;
  int _cachedTotalBytes = 0;

  @override
  void initState() {
    super.initState();
    _disableAnimationsAfterDelay();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _disableAnimationsAfterDelay() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _animateItems = false);
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.toLowerCase().trim();
          _cachedFilteredApps = null;
        });
      }
    });
  }

  void _onFilterSortChanged() {
    _cachedFilteredApps = null;
    setState(() {
      _animateItems = true;
    });
    _disableAnimationsAfterDelay();
  }

  List<AppUsageModel> _getFilteredApps(List<AppUsageModel> sourceApps) {
    if (identical(_lastSourceApps, sourceApps) &&
        _lastSearch == _searchQuery &&
        _lastSort == _sortBy &&
        _lastFilter == _filterBy &&
        _cachedFilteredApps != null) {
      return _cachedFilteredApps!;
    }

    _lastSourceApps = sourceApps;
    _lastSearch = _searchQuery;
    _lastSort = _sortBy;
    _lastFilter = _filterBy;

    int totalBytes = 0;
    for (var app in sourceApps) {
      totalBytes += app.totalBytes;
    }
    _cachedTotalBytes = totalBytes;

    var filtered = sourceApps.where((app) {
      bool matchesSearch = _searchQuery.isEmpty ||
          app.appName.toLowerCase().contains(_searchQuery) ||
          app.packageName.toLowerCase().contains(_searchQuery);
      if (!matchesSearch) return false;

      bool isSystem = app.packageName.startsWith('com.android') ||
          app.packageName.startsWith('android');
      if (_filterBy == 1 && isSystem) return false;
      if (_filterBy == 2 && !isSystem) return false;

      return true;
    }).toList();

    if (_sortBy == 0) {
      filtered.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    } else if (_sortBy == 1) {
      filtered.sort((a, b) => b.rxBytes.compareTo(a.rxBytes));
    } else if (_sortBy == 2) {
      filtered.sort((a, b) => b.txBytes.compareTo(a.txBytes));
    } else if (_sortBy == 3) {
      filtered.sort((a, b) => a.appName.compareTo(b.appName));
    }

    _cachedFilteredApps = filtered;
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.errorMessage != null &&
              dataProvider.appUsages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle_fill,
                          size: 36, color: theme.colorScheme.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(dataProvider.errorMessage!,
                          textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      CupertinoButton.filled(
                        onPressed: () => dataProvider.fetchData(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          final filteredApps = _getFilteredApps(dataProvider.appUsages);
          final totalBytes = _cachedTotalBytes;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverGlassToolbarDelegate(
                  height: MediaQuery.of(context).padding.top +
                      (PlatformService.isDesktop ? 144.0 : 158.0),
                  child: SafeArea(
                    bottom: false,
                    child: GlassToolbar(
                      useSafeArea: false,
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      title: 'Applications',
                      statusWidget: ConnectionStatusPill(
                        label: '${filteredApps.length} Apps',
                        color: const Color(0xFF007AFF),
                        isLive: false,
                      ),
                      actions: [
                        FloatingActionPill(
                          icon: CupertinoIcons.arrow_clockwise,
                          label: 'Refresh',
                          isPrimary: true,
                          onPressed: () => dataProvider.fetchData(),
                        ),
                      ],
                      bottom: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? const Color(0xFF1E212B)
                                        : Colors.white)
                                    .withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 0.85,
                                ),
                              ),
                              child: Center(
                                child: CupertinoSearchTextField(
                                  focusNode: widget.searchFocusNode,
                                  placeholder: 'Search installed apps...',
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      10, 0, 10, 0),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1C1C1E),
                                    fontSize: 13.5,
                                  ),
                                  onChanged: _onSearchChanged,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 34,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  _buildPillChip(0, 'Total', _sortBy == 0,
                                      isDark, primaryColor, (idx) {
                                    _sortBy = idx;
                                    _onFilterSortChanged();
                                  }),
                                  const SizedBox(width: AppSpacing.xs),
                                  _buildPillChip(1, '↓ Download', _sortBy == 1,
                                      isDark, primaryColor, (idx) {
                                    _sortBy = idx;
                                    _onFilterSortChanged();
                                  }),
                                  const SizedBox(width: AppSpacing.xs),
                                  _buildPillChip(2, '↑ Upload', _sortBy == 2,
                                      isDark, primaryColor, (idx) {
                                    _sortBy = idx;
                                    _onFilterSortChanged();
                                  }),
                                  const SizedBox(width: AppSpacing.xs),
                                  _buildPillChip(3, 'A-Z', _sortBy == 3, isDark,
                                      primaryColor, (idx) {
                                    _sortBy = idx;
                                    _onFilterSortChanged();
                                  }),
                                  const SizedBox(width: AppSpacing.md),
                                  Container(
                                    width: 1,
                                    height: 16,
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  _buildPillChip(0, 'All', _filterBy == 0,
                                      isDark, primaryColor, (idx) {
                                    _filterBy = idx;
                                    _onFilterSortChanged();
                                  }),
                                  const SizedBox(width: AppSpacing.xs),
                                  _buildPillChip(1, 'User', _filterBy == 1,
                                      isDark, primaryColor, (idx) {
                                    _filterBy = idx;
                                    _onFilterSortChanged();
                                  }),
                                  const SizedBox(width: AppSpacing.xs),
                                  _buildPillChip(2, 'System', _filterBy == 2,
                                      isDark, primaryColor, (idx) {
                                    _filterBy = idx;
                                    _onFilterSortChanged();
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
              if (filteredApps.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(36.0),
                    child: Center(
                      child: Text(
                        "No apps matching criteria found.",
                        style:
                            TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                      ),
                    ),
                  ),
                )
              else if (PlatformService.isDesktop)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                  sliver: SliverToBoxAdapter(
                    child: _buildDesktopAppsTable(
                        context, filteredApps, totalBytes, isDark, theme),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, 110),
                  sliver: SliverList.separated(
                    itemCount: filteredApps.length,
                    separatorBuilder: (_, __) => Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : Colors.white,
                        border: Border(
                          left: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 0.85,
                          ),
                          right: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 0.85,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 78),
                      child: Container(
                        height: 0.8,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final childTile = AppUsageTile(
                        appUsage: filteredApps[index],
                        totalDeviceBytes: totalBytes,
                        isFirst: index == 0,
                        isLast: index == filteredApps.length - 1,
                        useCardBackground: true,
                      );

                      if (!_animateItems || index > 12) return childTile;

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 250),
                        child: SlideAnimation(
                          verticalOffset: 20.0,
                          child: FadeInAnimation(
                            child: childTile,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPillChip(
    int index,
    String label,
    bool isSelected,
    bool isDark,
    Color primaryColor,
    ValueChanged<int> onSelect,
  ) {
    return FloatingPill(
      isSelected: isSelected,
      onTap: () => onSelect(index),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: -0.2,
          color: isSelected
              ? Colors.white
              : (isDark ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E)),
        ),
      ),
    );
  }

  Widget _buildDesktopAppsTable(
    BuildContext context,
    List<AppUsageModel> apps,
    int totalBytes,
    bool isDark,
    ThemeData theme,
  ) {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.04),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'APPLICATION / PROCESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'PACKAGE IDENTIFIER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DOWNLOAD',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'UPLOAD',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'BANDWIDTH SHARE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL USAGE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apps.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            itemBuilder: (context, index) {
              final app = apps[index];
              final double percent = totalBytes > 0
                  ? (app.totalBytes / totalBytes).clamp(0.0, 1.0)
                  : 0.0;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => AppDetailScreen(
                          appUsage: app,
                          heroTagPrefix: 'apps_table_',
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 11),
                    child: Row(
                      children: [
                        // App Name + Icon
                        Expanded(
                          flex: 4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (app.appIcon != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    app.appIcon!,
                                    width: 26,
                                    height: 26,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  ),
                                )
                              else
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007AFF)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(CupertinoIcons.app_fill,
                                      color: Color(0xFF007AFF), size: 14),
                                ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  app.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Package Identifier
                        Expanded(
                          flex: 4,
                          child: Text(
                            app.packageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                            ),
                          ),
                        ),
                        // Download
                        Expanded(
                          flex: 2,
                          child: Text(
                            FormatUtils.formatBytes(app.rxBytes),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFE4E4E7)
                                  : const Color(0xFF27272A),
                            ),
                          ),
                        ),
                        // Upload
                        Expanded(
                          flex: 2,
                          child: Text(
                            FormatUtils.formatBytes(app.txBytes),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFE4E4E7)
                                  : const Color(0xFF27272A),
                            ),
                          ),
                        ),
                        // Bandwidth Share
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 38,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.08),
                                    valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF007AFF)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '${(percent * 100).toStringAsFixed(1)}%',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6E6E73),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Total
                        Expanded(
                          flex: 2,
                          child: Text(
                            FormatUtils.formatBytes(app.totalBytes),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 14, color: Color(0xFF8E8E93)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.02),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${apps.length} process entries monitored',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF8E8E93),
                  ),
                ),
                Text(
                  'Cumulative Traffic: ${FormatUtils.formatBytes(totalBytes)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
    );
  }
}
