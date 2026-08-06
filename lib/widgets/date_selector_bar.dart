import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../services/settings_service.dart';

class DateSelectorBar extends StatelessWidget {
  const DateSelectorBar({super.key});

  Future<void> _pickDate(BuildContext context, DataProvider dataProvider) async {
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

    String customDateLabel = 'Pick Date...';
    if (selectedRange == DateRange.custom && dataProvider.selectedDate != null) {
      customDateLabel = DateFormat('MMM d, yyyy').format(dataProvider.selectedDate!);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            context: context,
            label: 'Today',
            isSelected: selectedRange == DateRange.today,
            onTap: () => dataProvider.setDateRange(DateRange.today),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'Yesterday',
            isSelected: selectedRange == DateRange.yesterday,
            onTap: () => dataProvider.setDateRange(DateRange.yesterday),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: '2 Days Ago',
            isSelected: selectedRange == DateRange.twoDaysAgo,
            onTap: () => dataProvider.setDateRange(DateRange.twoDaysAgo),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'This Week',
            isSelected: selectedRange == DateRange.thisWeek,
            onTap: () => dataProvider.setDateRange(DateRange.thisWeek),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'Last Week',
            isSelected: selectedRange == DateRange.lastWeek,
            onTap: () => dataProvider.setDateRange(DateRange.lastWeek),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'This Month',
            isSelected: selectedRange == DateRange.thisMonth,
            onTap: () => dataProvider.setDateRange(DateRange.thisMonth),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: selectedRange == DateRange.custom
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            label: Text(
              customDateLabel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selectedRange == DateRange.custom
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            backgroundColor: selectedRange == DateRange.custom
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            side: BorderSide(
              color: selectedRange == DateRange.custom
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => _pickDate(context, dataProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.dividerColor.withValues(alpha: 0.2),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
