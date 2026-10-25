import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/widgets/ambient_background.dart';
import '../core/widgets/glass_card.dart';
import '../core/design_system/glass_toolbar.dart';
import '../core/design_system/floating_pill.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/platform/platform_service.dart';

class _PackageLicenseData {
  final String packageName;
  final List<String> licenseTexts;

  _PackageLicenseData({
    required this.packageName,
    required this.licenseTexts,
  });
}

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  final List<_PackageLicenseData> _allPackages = [];
  List<_PackageLicenseData> _filteredPackages = [];
  bool _isLoading = true;
  String _searchQuery = '';
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadLicenses();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {}
  }

  Future<void> _loadLicenses() async {
    final Map<String, List<String>> packageMap = {};

    try {
      await for (final entry in LicenseRegistry.licenses) {
        final text = entry.paragraphs.map((p) => p.text).join('\n\n');
        for (final package in entry.packages) {
          packageMap.putIfAbsent(package, () => []).add(text);
        }
      }
    } catch (e) {
      debugPrint('Error reading licenses: $e');
    }

    final sorted = packageMap.entries
        .map((e) => _PackageLicenseData(
              packageName: e.key,
              licenseTexts: e.value,
            ))
        .toList()
      ..sort((a, b) => a.packageName
          .toLowerCase()
          .compareTo(b.packageName.toLowerCase()));

    if (mounted) {
      setState(() {
        _allPackages.addAll(sorted);
        _filteredPackages = sorted;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _searchQuery = q;
      if (q.isEmpty) {
        _filteredPackages = _allPackages;
      } else {
        _filteredPackages = _allPackages
            .where((p) => p.packageName.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  void _showLicenseDetail(BuildContext context, _PackageLicenseData package) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: GlassCard(
                borderRadius: BorderRadius.circular(20),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modal Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.doc_text_fill,
                              color: Color(0xFF007AFF),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.packageName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                  ),
                                ),
                                Text(
                                  '${package.licenseTexts.length} ${package.licenseTexts.length == 1 ? 'Notice' : 'Notices'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6E6E73),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(28, 28),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6E6E73),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // License Content Body
                    Expanded(
                      child: SelectionArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < package.licenseTexts.length; i++) ...[
                                if (i > 0) ...[
                                  const SizedBox(height: 16),
                                  Divider(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.08),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.black : Colors.white)
                                        .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.04),
                                    ),
                                  ),
                                  child: Text(
                                    package.licenseTexts[i],
                                    style: AppTypography.mono(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                      color: isDark
                                          ? const Color(0xFFD1D1D6)
                                          : const Color(0xFF3A3A3C),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Modal Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 0.8,
                          ),
                        ),
                      ),
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final isDesktop = PlatformService.isDesktop;

    final appVersion = _packageInfo != null
        ? 'v${_packageInfo!.version} (${_packageInfo!.buildNumber})'
        : 'v1.1.0';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B0E) : const Color(0xFFE8EEF5),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverGlassToolbarDelegate(
                height: MediaQuery.of(context).padding.top +
                    (isDesktop ? 104.0 : 118.0),
                child: SafeArea(
                  bottom: false,
                  child: GlassToolbar(
                    useSafeArea: false,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    leading: FloatingActionPill(
                      icon: CupertinoIcons.chevron_left,
                      isCompact: true,
                      iconSize: 17,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    title: 'Third-Party Licenses',
                    statusWidget: ConnectionStatusPill(
                      label: '${_allPackages.length} Packages',
                      color: const Color(0xFFFF9500),
                      isLive: false,
                    ),
                    bottom: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF1E212B)
                                  : Colors.white)
                              .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 0.85,
                          ),
                        ),
                        child: Center(
                          child: CupertinoSearchTextField(
                            placeholder: 'Search open-source packages...',
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10, 0, 10, 0),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                              fontSize: 13.5,
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main Content Area
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Brand Hero Card
                        GlassCard(
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
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
                                child: const Center(
                                  child: Icon(
                                    CupertinoIcons.speedometer,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'NetTrack',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.4,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1C1C1E),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryColor
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            appVersion,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'NetTrack is built with Flutter and incredible open-source libraries. Tap any library below to view its legal license and copyright terms.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.4,
                                        color: isDark
                                            ? const Color(0xFF8E8E93)
                                            : const Color(0xFF6E6E73),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'OPEN SOURCE PACKAGES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6E6E73),
                              ),
                            ),
                            Text(
                              '${_filteredPackages.length} ${_filteredPackages.length == 1 ? 'Package' : 'Packages'}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6E6E73),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48.0),
                            child: Center(
                              child: CupertinoActivityIndicator(radius: 14),
                            ),
                          )
                        else if (_filteredPackages.isEmpty)
                          GlassCard(
                            borderRadius: BorderRadius.circular(16),
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    CupertinoIcons.search,
                                    size: 32,
                                    color: isDark
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6E6E73),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No packages found matching "$_searchQuery"',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF8E8E93)
                                          : const Color(0xFF6E6E73),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GlassCard(
                            borderRadius: BorderRadius.circular(18),
                            padding: EdgeInsets.zero,
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredPackages.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 56,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              itemBuilder: (context, index) {
                                final pkg = _filteredPackages[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showLicenseDetail(context, pkg),
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0
                                          ? const Radius.circular(18)
                                          : Radius.zero,
                                      bottom: index ==
                                              _filteredPackages.length - 1
                                          ? const Radius.circular(18)
                                          : Radius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                  .withValues(alpha: 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              CupertinoIcons.doc_plaintext,
                                              size: 16,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              pkg.packageName,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.2,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1C1C1E),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                  .withValues(alpha: 0.06),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${pkg.licenseTexts.length} ${pkg.licenseTexts.length == 1 ? 'license' : 'licenses'}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? const Color(0xFF8E8E93)
                                                    : const Color(0xFF6E6E73),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            CupertinoIcons.chevron_right,
                                            size: 14,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
