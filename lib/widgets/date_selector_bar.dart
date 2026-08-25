import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    String customDateLabel = 'Custom Date';
    if (selectedRange == DateRange.custom && dataProvider.selectedDate != null) {
      customDateLabel = DateFormat('MMM d, yyyy').format(dataProvider.selectedDate!);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPill(
            context: context,
            label: 'Today',
            isSelected: selectedRange == DateRange.today,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.today),
          ),
          const SizedBox(width: 8),
          _buildPill(
            context: context,
            label: 'Yesterday',
            isSelected: selectedRange == DateRange.yesterday,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.yesterday),
          ),
          const SizedBox(width: 8),
          _buildPill(
            context: context,
            label: '2 Days Ago',
            isSelected: selectedRange == DateRange.twoDaysAgo,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.twoDaysAgo),
          ),
          const SizedBox(width: 8),
          _buildPill(
            context: context,
            label: 'This Week',
            isSelected: selectedRange == DateRange.thisWeek,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.thisWeek),
          ),
          const SizedBox(width: 8),
          _buildPill(
            context: context,
            label: 'Last Week',
            isSelected: selectedRange == DateRange.lastWeek,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.lastWeek),
          ),
          const SizedBox(width: 8),
          _buildPill(
            context: context,
            label: 'This Month',
            isSelected: selectedRange == DateRange.thisMonth,
            isDark: isDark,
            onTap: () => dataProvider.setDateRange(DateRange.thisMonth),
          ),
          const SizedBox(width: 8),
          _buildPill(
            context: context,
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

  Widget _buildPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0x2EFFFFFF) : const Color(0x1A000000)),
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

