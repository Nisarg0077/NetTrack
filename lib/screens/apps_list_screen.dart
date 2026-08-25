import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/data_provider.dart';
import '../widgets/app_usage_tile.dart';

class AppsListScreen extends StatefulWidget {
  const AppsListScreen({super.key});

  @override
  State<AppsListScreen> createState() => _AppsListScreenState();
}

class _AppsListScreenState extends State<AppsListScreen> {
  String _searchQuery = '';
  int _sortBy = 0; // 0: Total, 1: Download, 2: Upload, 3: A-Z
  int _filterBy = 0; // 0: All, 1: User, 2: System

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.errorMessage != null && dataProvider.appUsages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 36, color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    Text(dataProvider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      onPressed: () => dataProvider.fetchData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          var filteredApps = dataProvider.appUsages.where((app) {
            bool matchesSearch = app.appName.toLowerCase().contains(_searchQuery) ||
                                 app.packageName.toLowerCase().contains(_searchQuery);
            if (!matchesSearch) return false;

            bool isSystem = app.packageName.startsWith('com.android') || app.packageName.startsWith('android');
            if (_filterBy == 1 && isSystem) return false;
            if (_filterBy == 2 && !isSystem) return false;

            return true;
          }).toList();

          if (_sortBy == 0) {
            filteredApps.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
          } else if (_sortBy == 1) {
            filteredApps.sort((a, b) => b.rxBytes.compareTo(a.rxBytes));
          } else if (_sortBy == 2) {
            filteredApps.sort((a, b) => b.txBytes.compareTo(a.txBytes));
          } else if (_sortBy == 3) {
            filteredApps.sort((a, b) => a.appName.compareTo(b.appName));
          }

          int totalBytes = 0;
          for (var app in dataProvider.appUsages) {
            totalBytes += app.totalBytes;
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Applications'),
                backgroundColor: isDark
                    ? const Color(0x99000000)
                    : const Color(0x99F2F2F7),
                border: null,
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await dataProvider.fetchData();
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                            width: 0.8,
                          ),
                        ),
                        child: CupertinoSearchTextField(
                          placeholder: 'Search installed apps...',
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontSize: 14,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildPillChip(0, 'Total', _sortBy == 0, isDark, primaryColor, (idx) => setState(() => _sortBy = idx)),
                            const SizedBox(width: 6),
                            _buildPillChip(1, '↓ Download', _sortBy == 1, isDark, primaryColor, (idx) => setState(() => _sortBy = idx)),
                            const SizedBox(width: 6),
                            _buildPillChip(2, '↑ Upload', _sortBy == 2, isDark, primaryColor, (idx) => setState(() => _sortBy = idx)),
                            const SizedBox(width: 6),
                            _buildPillChip(3, 'A-Z', _sortBy == 3, isDark, primaryColor, (idx) => setState(() => _sortBy = idx)),
                            const SizedBox(width: 12),
                            Container(width: 1, height: 18, color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6)),
                            const SizedBox(width: 12),
                            _buildPillChip(0, 'All', _filterBy == 0, isDark, primaryColor, (idx) => setState(() => _filterBy = idx)),
                            const SizedBox(width: 6),
                            _buildPillChip(1, 'User', _filterBy == 1, isDark, primaryColor, (idx) => setState(() => _filterBy = idx)),
                            const SizedBox(width: 6),
                            _buildPillChip(2, 'System', _filterBy == 2, isDark, primaryColor, (idx) => setState(() => _filterBy = idx)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredApps.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(36.0),
                    child: Center(
                      child: Text(
                        "No apps matching criteria found.",
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 300),
                          child: SlideAnimation(
                            verticalOffset: 30.0,
                            child: FadeInAnimation(
                              child: AppUsageTile(
                                appUsage: filteredApps[index],
                                totalDeviceBytes: totalBytes,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredApps.length,
                    ),
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
    return GestureDetector(
      onTap: () => onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000)),
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
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
      ),
    );
  }
}
