import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/export_history_item.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import 'dart:ui';

class ExportHistoryScreen extends StatefulWidget {
  const ExportHistoryScreen({super.key});

  @override
  State<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends State<ExportHistoryScreen> {
  final SettingsService _settingsService = SettingsService();
  final ExportService _exportService = ExportService();
  List<ExportHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final items = await _settingsService.getExportHistory();
    setState(() {
      _history = items;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(String id) async {
    await _settingsService.deleteExportHistoryItem(id);
    await _loadHistory();
  }

  Future<void> _clearAll() async {
    await _settingsService.clearExportHistory();
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Export History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Export History?'),
                    content: const Text(
                        'This will clear the history list. The generated files on disk will not be deleted.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearAll();
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 64,
                          color: theme.disabledColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No Exported Reports Yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Exported reports will appear here for easy access.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  itemCount: _history.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final isExcel = item.format == '.xlsx';

                    return Card(
                      elevation: 2,
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isExcel
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isExcel
                                  ? Icons.table_chart_rounded
                                  : Icons.description_rounded,
                              color: isExcel
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6),
                            ),
                          ),
                          title: Text(
                            item.fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${item.format.toUpperCase().replaceAll(".", "")} • ${item.totalBytesFormatted}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.dateRangeLabel} • Created ${DateFormat('MMM d, yyyy HH:mm').format(item.generatedAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.disabledColor,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (val) {
                              if (val == 'open') {
                                _exportService.openFile(item.filePath);
                              } else if (val == 'share') {
                                _exportService.shareFile(item.filePath);
                              } else if (val == 'delete') {
                                _deleteItem(item.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'open',
                                child: Row(
                                  children: [
                                    Icon(Icons.open_in_new_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Open File'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete from History',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _exportService.openFile(item.filePath),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
