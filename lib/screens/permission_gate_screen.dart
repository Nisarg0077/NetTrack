import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/glass_card.dart';

class PermissionGateScreen extends StatelessWidget {
  const PermissionGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassCard(
                  borderRadius: BorderRadius.circular(28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Luminous Shield Icon
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF007AFF),
                                    Color(0xFF5856D6)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'Usage Access Required',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'NetTrack measures per-app Wi-Fi and mobile data telemetry locally on your device.\n\nPlease grant Usage Access in System Settings to view your real-time analytics.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.45,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Modern Primary Action Button
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: () {
                            Provider.of<DataProvider>(context, listen: false)
                                .requestPermission();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.gear_alt_fill,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Open System Settings',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        onPressed: () {
                          Provider.of<DataProvider>(context, listen: false)
                              .fetchData();
                        },
                        child: Text(
                          'I Already Granted Access',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6E6E73),
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
    );
  }
}
