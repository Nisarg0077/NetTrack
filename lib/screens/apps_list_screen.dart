import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('All Apps Usage', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildSortChip(0, 'Total'),
                    const SizedBox(width: 8),
                    _buildSortChip(1, '↓ Download'),
                    const SizedBox(width: 8),
                    _buildSortChip(2, '↑ Upload'),
                    const SizedBox(width: 8),
                    _buildSortChip(3, 'A-Z'),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 20, color: Colors.grey),
                    const SizedBox(width: 16),
                    _buildFilterChip(0, 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'User'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'System'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          // Removed Platform.isAndroid check so Windows can also view the list.

          if (dataProvider.errorMessage != null && dataProvider.appUsages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(dataProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dataProvider.fetchData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (dataProvider.isLoading && dataProvider.appUsages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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

          if (filteredApps.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No apps found. Try adjusting your filters or search."),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await dataProvider.fetchData();
            },
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 200, 16, 100),
                itemCount: filteredApps.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: AppUsageTile(
                          appUsage: filteredApps[index],
                          totalDeviceBytes: totalBytes,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(int index, String label) {
    bool isSelected = _sortBy == index;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _sortBy = index;
        });
      },
      showCheckmark: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    bool isSelected = _filterBy == index;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _filterBy = index;
        });
      },
      showCheckmark: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
