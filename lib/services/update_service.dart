import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../widgets/update_dialog.dart';
import '../core/widgets/app_toast.dart';

class UpdateService {
  // The GitHub repository details for checking releases
  static const String _githubOwner = 'Nisarg0077';
  static const String _githubRepo = 'NetTrack';
  static const String _apiUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

  static Future<void> checkForUpdates(BuildContext context,
      {bool showNoUpdateMessage = false}) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    if (_githubOwner == 'YOUR_USERNAME') {
      if (showNoUpdateMessage && context.mounted) {
        AppToast.warning(
          context,
          'Configuration Required',
          subtitle: 'Please configure your GitHub repo in UpdateService.',
        );
      }
      return;
    }

    if (showNoUpdateMessage && context.mounted) {
      dataProvider.setCheckingUpdate(true);
      AppToast.info(
        context,
        'Checking for updates...',
        subtitle: 'Connecting to GitHub release server',
        icon: CupertinoIcons.arrow_2_circlepath,
      );
    }

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersionTag = data['tag_name'];
        final String releaseNotes =
            data['body'] ?? 'No release notes provided.';

        // Extract version number from tag (e.g., 'v1.0.1' -> '1.0.1')
        final latestVersion =
            latestVersionTag.replaceAll('v', '').replaceAll('V', '');

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          // Check for platform-specific asset
          final List assets = data['assets'] ?? [];
          final requiredExtension = Platform.isWindows ? '.msix' : '.apk';
          String? directDownloadUrl;

          for (var asset in assets) {
            final name = (asset['name'] as String).toLowerCase();
            if (name.endsWith(requiredExtension)) {
              directDownloadUrl = asset['browser_download_url'];
              break;
            }
          }

          if (directDownloadUrl != null) {
            // Update available for this platform!
            if (context.mounted) {
              dataProvider.setCheckingUpdate(false);
              dataProvider.setUpdateAvailable(
                true,
                version: latestVersion,
                notes: releaseNotes,
                url: directDownloadUrl,
              );

              if (showNoUpdateMessage) {
                AppToast.info(
                  context,
                  'Update available: v$latestVersion',
                  subtitle: 'Opening release changelog...',
                  icon: CupertinoIcons.arrow_down_circle_fill,
                );

                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => UpdateDialog(
                    latestVersion: latestVersion,
                    currentVersion: currentVersion,
                    releaseNotes: releaseNotes,
                    releaseUrl: directDownloadUrl!,
                  ),
                );
              }
            }
            return;
          }
        }

        // If we reach here, either version is not newer, or no platform asset found
        if (context.mounted) {
          dataProvider.setCheckingUpdate(false);
          dataProvider.setUpdateAvailable(false);
          if (showNoUpdateMessage) {
            AppToast.success(
              context,
              'NetTrack is Up to Date',
              subtitle: 'You are running the latest version (v$currentVersion)',
              icon: CupertinoIcons.checkmark_seal_fill,
            );
          }
        }
      } else {
        if (context.mounted) {
          dataProvider.setCheckingUpdate(false);
          if (showNoUpdateMessage) {
            final isRateLimit = response.statusCode == 403;
            if (isRateLimit) {
              AppToast.warning(
                context,
                'GitHub API Rate Limited',
                subtitle:
                    'Hourly request limit reached. Please try again later.',
                icon: CupertinoIcons.exclamationmark_triangle_fill,
              );
            } else {
              AppToast.error(
                context,
                'Update Check Failed',
                subtitle: 'Server returned HTTP ${response.statusCode}',
                icon: CupertinoIcons.exclamationmark_circle_fill,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (context.mounted) {
        dataProvider.setCheckingUpdate(false);
        if (showNoUpdateMessage) {
          AppToast.error(
            context,
            'Unable to Check for Updates',
            subtitle: 'Please check your internet connection and try again.',
            icon: CupertinoIcons.wifi_slash,
          );
        }
      }
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    List<int> currentParts =
        currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts =
        latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad lists to be same length
    while (currentParts.length < latestParts.length) {
      currentParts.add(0);
    }
    while (latestParts.length < currentParts.length) {
      latestParts.add(0);
    }

    for (int i = 0; i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }

    return false; // They are equal
  }
}
