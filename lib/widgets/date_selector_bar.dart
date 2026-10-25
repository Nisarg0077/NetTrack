import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../services/settings_service.dart';
import '../core/design_system/floating_pill.dart';

class DateSelectorBar extends StatelessWidget {
  const DateSelectorBar({super.key});

  Future<void> _pickDate(
      BuildContext context, DataProvider dataProvider) async {
    final firstDate = await SettingsService().getAppInstallationDate();
    final now = DateTime.now();
    final initialDate = dataProvider.selectedDate ?? now;

    if (!context.mounted) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dataProvider.setCustomDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final selectedRange = dataProvider.selectedRange;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String customDateLabel = 'Custom Date';
    if (selectedRange == DateRange.custom &&
        dataProvider.selectedDate != null) {
      customDateLabel =
          DateFormat('MMM d, yyyy').format(dataProvider.selectedDate!);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildItem(
            label: 'Today',
            isSelected: selectedRange == DateRange.today,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.today),
          ),
          const SizedBox(width: 8),
          _buildItem(
            label: 'Yesterday',
            isSelected: selectedRange == DateRange.yesterday,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.yesterday),
          ),
          const SizedBox(width: 8),
          _buildItem(
            label: '2 Days Ago',
            isSelected: selectedRange == DateRange.twoDaysAgo,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.twoDaysAgo),
          ),
          const SizedBox(width: 8),
          _buildItem(
            label: 'This Week',
            isSelected: selectedRange == DateRange.thisWeek,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.thisWeek),
          ),
          const SizedBox(width: 8),
          _buildItem(
            label: 'Last Week',
            isSelected: selectedRange == DateRange.lastWeek,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.lastWeek),
          ),
          const SizedBox(width: 8),
          _buildItem(
            label: 'This Month',
            isSelected: selectedRange == DateRange.thisMonth,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.thisMonth),
          ),
          const SizedBox(width: 8),
          _buildItem(
            label: customDateLabel,
            icon: CupertinoIcons.calendar,
            isSelected: selectedRange == DateRange.custom,
            isDark: isDark,
            onTap: () => _pickDate(context, dataProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return FloatingPill(
      isSelected: isSelected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13.5,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6E6E73)),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: -0.2,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFFE5E5EA)
                      : const Color(0xFF1C1C1E)),
            ),
          ),
        ],
      ),
    );
  }
}
