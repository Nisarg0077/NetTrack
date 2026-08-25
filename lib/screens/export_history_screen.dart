import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/export_history_item.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';

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

  void _showActionSheet(BuildContext context, ExportHistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExcel = item.format == '.xlsx';
    final Color accentColor = isExcel ? const Color(0xFF34C759) : const Color(0xFF007AFF);

    showDialog(
      context: context,
      builder: (dialogCtx) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xE61C1C1E) : const Color(0xF2FFFFFF),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark ? const Color(0x2EFFFFFF) : const Color(0x24000000),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              isExcel ? CupertinoIcons.table_badge_more_fill : CupertinoIcons.doc_text_fill,
                              color: accentColor,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.fileName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.format.toUpperCase().replaceAll(".", "")} • ${item.totalBytesFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Actions
                        _buildActionRow(
                          icon: CupertinoIcons.arrow_up_right_square,
                          title: 'Open File',
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            _exportService.openFile(item.filePath);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildActionRow(
                          icon: CupertinoIcons.share,
                          title: 'Share File',
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            _exportService.shareFile(item.filePath);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildActionRow(
                          icon: CupertinoIcons.trash,
                          title: 'Delete Record',
                          color: const Color(0xFFFF3B30),
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            _deleteItem(item.id);
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(14),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
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
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E).withValues(alpha: 0.6) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF8E8E93)),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xE61C1C1E) : const Color(0xF2FFFFFF),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark ? const Color(0x2EFFFFFF) : const Color(0x24000000),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(CupertinoIcons.trash_fill, color: Color(0xFFFF3B30), size: 26),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Clear Export History?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This will clear the history list. Files saved on disk will remain untouched.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(14),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CupertinoButton(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(14),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  _clearAll();
                                },
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Export History'),
            backgroundColor: isDark
                ? const Color(0x99000000)
                : const Color(0x99F2F2F7),
            border: null,
            trailing: _history.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.trash, size: 20, color: CupertinoColors.destructiveRed),
                    onPressed: () => _showClearAllDialog(context),
                  )
                : null,
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            )
          else if (_history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.archivebox,
                        size: 48,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Exported Reports Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Exported CSV or Excel files will appear here.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _history[index];
                    final isExcel = item.format == '.xlsx';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _exportService.openFile(item.filePath),
                          onLongPress: () => _showActionSheet(context, item),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isExcel
                                        ? const Color(0xFF34C759).withValues(alpha: isDark ? 0.2 : 0.12)
                                        : const Color(0xFF007AFF).withValues(alpha: isDark ? 0.2 : 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isExcel ? CupertinoIcons.table_badge_more_fill : CupertinoIcons.doc_text_fill,
                                    color: isExcel ? const Color(0xFF34C759) : const Color(0xFF007AFF),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.fileName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.format.toUpperCase().replaceAll(".", "")} • ${item.totalBytesFormatted}  •  ${item.dateRangeLabel}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('MMM d, yyyy  h:mm a').format(item.generatedAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Icon(CupertinoIcons.ellipsis, size: 20, color: Color(0xFF8E8E93)),
                                  onPressed: () => _showActionSheet(context, item),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
