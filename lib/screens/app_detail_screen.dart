import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import '../models/app_usage_model.dart';
import '../services/data_usage_service.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/usage_chart.dart';
import '../widgets/animated_counter.dart';
import '../utils/format_utils.dart';

class AppDetailScreen extends StatefulWidget {
  final AppUsageModel appUsage;

  const AppDetailScreen({super.key, required this.appUsage});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  List<double> _sevenDayTrend = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrend();
  }

  Future<void> _fetchTrend() async {
    final service = DataUsageService();
    final trend = await service.getApp7DayTrend(widget.appUsage.packageName);
    if (mounted) {
      setState(() {
        _sevenDayTrend = trend;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.appUsage.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Hero(
                tag: 'app_icon_${widget.appUsage.packageName}',
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: widget.appUsage.appIcon != null
                        ? Image.memory(widget.appUsage.appIcon!, width: 80, height: 80)
                        : (Platform.isWindows 
                            ? const Icon(Icons.window, size: 80, color: Colors.blue)
                            : const Icon(Icons.android, size: 80, color: Colors.green)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.appUsage.packageName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: FrostedGlassCard(
                      child: Column(
                        children: [
                          const Icon(Icons.download_rounded, color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          AnimatedCounter(
                            value: widget.appUsage.rxBytes.toDouble(),
                            formatBuilder: (v) => FormatUtils.formatBytes(v.toInt()),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text('Downloaded', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FrostedGlassCard(
                      child: Column(
                        children: [
                          const Icon(Icons.upload_rounded, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          AnimatedCounter(
                            value: widget.appUsage.txBytes.toDouble(),
                            formatBuilder: (v) => FormatUtils.formatBytes(v.toInt()),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text('Uploaded', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Text(
                '7-Day Trend',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 300,
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : UsageChart(
                        dailyTrend: _sevenDayTrend, // Passing 7-day trend to dailyTrend just for display
                        weeklyTrend: _sevenDayTrend,
                        monthlyTrend: _sevenDayTrend,
                        showFilters: false,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
