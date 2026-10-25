import 'package:flutter/material.dart';
import '../utils/format_utils.dart';
import 'frosted_glass_card.dart';

class TotalUsageCard extends StatelessWidget {
  final int totalBytes;
  final int txBytes;
  final int rxBytes;

  const TotalUsageCard({
    super.key,
    required this.totalBytes,
    required this.txBytes,
    required this.rxBytes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedGlassCard(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          Text('Total Network Usage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              )),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                        begin: 0,
                        end: totalBytes == 0 ? 0 : rxBytes / totalBytes),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        color: theme.colorScheme.primary,
                        strokeCap: StrokeCap.round,
                      );
                    }),
              ),
              TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: totalBytes.toDouble()),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      FormatUtils.formatBytes(value.toInt()),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    );
                  }),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, 'Downloaded', rxBytes,
                  Icons.download_rounded, const Color(0xFF10B981)),
              _buildStatItem(context, 'Uploaded', txBytes, Icons.upload_rounded,
                  const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int bytes,
      IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: bytes.toDouble()),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(FormatUtils.formatBytes(value.toInt()),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16));
            }),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                )),
      ],
    );
  }
}
