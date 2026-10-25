import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fusion_ui/fusion_ui.dart' as fusion;

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// A modern, liquid-glass styled update dialog that showcases
/// version differences and an elegantly formatted changelog.
class UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String? currentVersion;
  final String releaseNotes;
  final String releaseUrl;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    this.currentVersion,
    required this.releaseNotes,
    required this.releaseUrl,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  String _installedVersion = '';

  @override
  void initState() {
    super.initState();
    if (widget.currentVersion != null && widget.currentVersion!.isNotEmpty) {
      _installedVersion = widget.currentVersion!;
    } else {
      _loadInstalledVersion();
    }
  }

  Future<void> _loadInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _installedVersion = info.version;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _installedVersion = '1.1.0';
        });
      }
    }
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(widget.releaseUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch ${widget.releaseUrl}');
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
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: fusion.GlassSurface(
              borderRadius: BorderRadius.circular(28),
              blur: 32,
              elevation: 6,
              useBackdropFilter: true,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sparkling Gradient Badge
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
                          color: const Color(0xFF007AFF).withValues(alpha: 0.38),
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

                  // Header Title
                  Text(
                    'Software Update',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Version Migration Pills
                  _buildVersionPills(isDark),
                  const SizedBox(height: 18),

                  // Changelog Section Header
                  Row(
                    children: [
                      const Icon(CupertinoIcons.doc_plaintext,
                          size: 13, color: Color(0xFF007AFF)),
                      const SizedBox(width: 6),
                      Text(
                        "WHAT'S NEW IN THIS RELEASE",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      _buildPlatformBadge(isDark),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scrollable Formatted Changelog Box
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1C1E26) : const Color(0xFFF2F2F7))
                          .withValues(alpha: isDark ? 0.75 : 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: _buildChangelogContent(isDark, primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (Later & Download)
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                                Color(0xFF0055D6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007AFF)
                                    .withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CupertinoButton(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () {
                              _launchUrl();
                              Navigator.of(context).pop();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.arrow_down_circle_fill,
                                    size: 17, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Download & Install',
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
    );
  }

  Widget _buildVersionPills(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_installedVersion.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Text(
              'v$_installedVersion',
              style: AppTypography.mono(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.arrow_right,
              size: 12, color: Color(0xFF007AFF)),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF007AFF).withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'v${widget.latestVersion}',
                style: AppTypography.mono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformBadge(bool isDark) {
    final String label = Platform.isWindows
        ? '.MSIX'
        : (Platform.isAndroid ? '.APK' : 'Package');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
        ),
      ),
    );
  }

  Widget _buildChangelogContent(bool isDark, Color primaryColor) {
    final rawNotes = widget.releaseNotes.trim();

    if (rawNotes.isEmpty || rawNotes == 'No release notes provided.') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            Icon(CupertinoIcons.sparkles,
                size: 26, color: primaryColor.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(
              'Maintenance & Performance Update',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This release brings stability improvements, updated UI consistency, and engine refinements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
      );
    }

    final lines = rawNotes.split('\n');
    final List<Widget> items = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Section Headings (e.g. "## What's Changed", "### Highlights")
      if (trimmed.startsWith('#')) {
        final heading = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        items.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              heading,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF0A84FF)
                    : const Color(0xFF007AFF),
              ),
            ),
          ),
        );
      }
      // Bullet items (e.g. "* Added feature by @author in https://...")
      else if (trimmed.startsWith('*') ||
          trimmed.startsWith('-') ||
          trimmed.startsWith('•')) {
        String bulletText = trimmed.replaceFirst(RegExp(r'^[\*\-•]\s*'), '');

        // Remove PR URL link fragments at end like "in https://github.com/..."
        bulletText = bulletText.replaceAll(RegExp(r'\s+in\s+https://\S+'), '');

        // Extract author if present (e.g. "by @someone")
        String? author;
        final authorMatch = RegExp(r'by\s+(@\w+)').firstMatch(bulletText);
        if (authorMatch != null) {
          author = authorMatch.group(1);
          bulletText = bulletText.replaceAll(RegExp(r'\s+by\s+@\w+'), '');
        }

        // Clean up markdown bold markers like "**Title**: description"
        bulletText = bulletText.replaceAll('**', '');

        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark
                            ? const Color(0xFFE5E5EA)
                            : const Color(0xFF2C2C2E),
                      ),
                      children: [
                        TextSpan(text: bulletText),
                        if (author != null) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: author,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Full changelog link line
      else if (trimmed.toLowerCase().contains('full changelog')) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(CupertinoIcons.link, size: 11, color: Color(0xFF007AFF)),
                const SizedBox(width: 4),
                Text(
                  'Full release notes available on GitHub',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // General text line
      else {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              trimmed.replaceAll('**', ''),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFF2C2C2E),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}
