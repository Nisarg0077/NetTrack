import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class UsageChart extends StatelessWidget {
  final List<double> weeklyTrend;
  
  const UsageChart({super.key, required this.weeklyTrend});

  String _formatUsage(double mb) {
    if (mb < 1024) return '${mb.toStringAsFixed(0)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    if (weeklyTrend.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    double maxY = 10;
    for (var val in weeklyTrend) {
      if (val > maxY) maxY = val;
    }
    // Add 20% padding to top
    maxY = maxY * 1.2;
    double interval = maxY / 4;
    if (interval == 0) interval = 1;

    List<FlSpot> spots = [];
    for (int i = 0; i < weeklyTrend.length; i++) {
      spots.add(FlSpot(i.toDouble(), weeklyTrend[i]));
    }
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Card(
      elevation: 4,
      shadowColor: primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.only(right: 22.0, left: 8.0, top: 32, bottom: 16),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => primaryColor,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    return LineTooltipItem(
                      _formatUsage(touchedSpot.y),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < 7) {
                      DateTime date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                      String dayName = DateFormat('E').format(date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          dayName, 
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          )
                        ),
                      );
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
                          color: Theme.of(context).textTheme.bodySmall?.color,
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
            maxX: 6,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: primaryColor,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: surfaceColor,
                      strokeWidth: 2.5,
                      strokeColor: primaryColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.3),
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
    );
  }
}
