import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../core/widgets/glass_card.dart';
import '../core/theme/app_spacing.dart';

class UsageChart extends StatefulWidget {
  final List<double> dailyTrend;
  final List<double> weeklyTrend;
  final List<double> monthlyTrend;
  final bool showFilters;
  final bool enableBlur;

  const UsageChart({
    super.key,
    required this.dailyTrend,
    required this.weeklyTrend,
    required this.monthlyTrend,
    this.showFilters = true,
    this.enableBlur = true,
  });

  @override
  State<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends State<UsageChart> {
  int _selectedFilter = 1; // 0 = Daily, 1 = Weekly, 2 = Monthly

  String _formatUsage(double mb) {
    if (mb < 1024) return '${mb.toStringAsFixed(0)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    List<double> currentTrend = [];
    if (_selectedFilter == 0) {
      currentTrend = widget.dailyTrend;
    } else if (_selectedFilter == 1) {
      currentTrend = widget.weeklyTrend;
    } else {
      currentTrend = widget.monthlyTrend;
    }

    if (currentTrend.isEmpty) {
      return GlassCard(
        enableBlur: widget.enableBlur,
        child: const Center(child: CupertinoActivityIndicator(radius: 12)),
      );
    }

    double maxY = 10;
    for (var val in currentTrend) {
      if (val > maxY) maxY = val;
    }
    // Add 30% padding to top for modern breathing room
    maxY = maxY * 1.3;
    double interval = maxY / 4;
    if (interval == 0) interval = 1;

    List<FlSpot> spots = [];
    for (int i = 0; i < currentTrend.length; i++) {
      spots.add(FlSpot(i.toDouble(), currentTrend[i]));
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return GlassCard(
      enableBlur: widget.enableBlur,
      padding:
          const EdgeInsets.only(right: 20.0, left: 8.0, top: 20, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CupertinoIcons.waveform_path,
                            color: primaryColor, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Usage Trends',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showFilters)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterChip(0, '1D'),
                        _buildFilterChip(1, '1W'),
                        _buildFilterChip(2, '1M'),
                      ],
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        String label = '';
                        if (_selectedFilter == 1) {
                          int value = touchedSpot.x.toInt();
                          DateTime date = DateTime.now()
                              .subtract(Duration(days: 6 - value));
                          label = DateFormat('MMM d, EEE').format(date);
                        } else if (_selectedFilter == 0) {
                          label = '${touchedSpot.x.toInt()}:00';
                        } else {
                          int value = touchedSpot.x.toInt();
                          DateTime date = DateTime.now()
                              .subtract(Duration(days: 29 - value));
                          label = DateFormat('MMM d').format(date);
                        }
                        return LineTooltipItem(
                          '${_formatUsage(touchedSpot.y)}\n',
                          TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          children: [
                            TextSpan(
                              text: label,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.8),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [8, 8], // Modern larger dash
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: _selectedFilter == 0
                          ? 6
                          : (_selectedFilter == 2 ? 7 : 1),
                      getTitlesWidget: (value, meta) {
                        if (_selectedFilter == 1) {
                          if (value >= 0 && value < 7) {
                            DateTime date = DateTime.now()
                                .subtract(Duration(days: 6 - value.toInt()));
                            String dayName = DateFormat('E').format(date);
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(dayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  )),
                            );
                          }
                        } else if (_selectedFilter == 0) {
                          if (value >= 0 && value < 24) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text('${value.toInt()}:00',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  )),
                            );
                          }
                        } else if (_selectedFilter == 2) {
                          if (value >= 0 && value < 30) {
                            DateTime date = DateTime.now()
                                .subtract(Duration(days: 29 - value.toInt()));
                            String label = DateFormat('MMM d').format(date);
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  )),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == maxY) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            _formatUsage(value),
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: currentTrend.isEmpty
                    ? 6
                    : (currentTrend.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: primaryColor,
                    barWidth: 6, // Thicker line for modern look
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: surfaceColor,
                          strokeWidth: 3,
                          strokeColor: primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.4),
                          primaryColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}
