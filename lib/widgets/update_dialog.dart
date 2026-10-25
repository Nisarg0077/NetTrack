import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String releaseNotes;
  final String releaseUrl;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.releaseNotes,
    required this.releaseUrl,
  });

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(releaseUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $releaseUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xE61C1C1E)
                        : const Color(0xF2FFFFFF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x2EFFFFFF)
                          : const Color(0x24000000),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.45 : 0.14),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shimmering Icon Badge
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF007AFF),
                              Color(0xFF5856D6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF)
                                  .withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(CupertinoIcons.sparkles,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Software Update',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(
                              alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Version $latestVersion is ready to install',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF0A84FF)
                                : const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                      if (releaseNotes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E).withValues(alpha: 0.7)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0x1AFFFFFF)
                                  : const Color(0x14000000),
                              width: 0.8,
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              releaseNotes,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: isDark
                                    ? const Color(0xFFE5E5EA)
                                    : const Color(0xFF3A3A3C),
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(14),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Later',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF007AFF),
                                    Color(0xFF0051D5),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CupertinoButton(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                onPressed: () {
                                  _launchUrl();
                                  Navigator.of(context).pop();
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.arrow_down_circle_fill,
                                        size: 18, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Download & Update',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
