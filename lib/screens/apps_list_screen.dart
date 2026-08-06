import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/app_usage_tile.dart';
import '../widgets/export_dialog.dart';

class AppsListScreen extends StatefulWidget {
  const AppsListScreen({super.key});

  @override
  State<AppsListScreen> createState() => _AppsListScreenState();
}

class _AppsListScreenState extends State<AppsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Apps Usage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Report',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ExportDialog(),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
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

          final filteredApps = dataProvider.appUsages.where((app) {
            return app.appName.toLowerCase().contains(_searchQuery) ||
                   app.packageName.toLowerCase().contains(_searchQuery);
          }).toList();

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
            child: ListView.builder(
              itemCount: filteredApps.length,
              itemBuilder: (context, index) {
                return AppUsageTile(
                  appUsage: filteredApps[index],
                  totalDeviceBytes: totalBytes,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
