import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  // The GitHub repository details for checking releases
  static const String _githubOwner = 'Nisarg0077';
  static const String _githubRepo = 'NetTrack';
  static const String _apiUrl = 'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateMessage = false}) async {
    if (_githubOwner == 'YOUR_USERNAME') {
      if (showNoUpdateMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please configure your GitHub repo in UpdateService first.')),
        );
      }
      return;
    }

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersionTag = data['tag_name'];
        final String releaseNotes = data['body'] ?? 'No release notes provided.';
        
        // Extract version number from tag (e.g., 'v1.0.1' -> '1.0.1')
        final latestVersion = latestVersionTag.replaceAll('v', '').replaceAll('V', '');

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
              Provider.of<DataProvider>(context, listen: false).setUpdateAvailable(
                true,
                version: latestVersion,
                notes: releaseNotes,
                url: directDownloadUrl,
              );
              
              if (showNoUpdateMessage) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => UpdateDialog(
                    latestVersion: latestVersion,
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
          Provider.of<DataProvider>(context, listen: false).setUpdateAvailable(false);
          if (showNoUpdateMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App is up to date.')),
            );
          }
        }
      } else {
        if (showNoUpdateMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to check for updates: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (showNoUpdateMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error checking for updates.')),
        );
      }
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    List<int> currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

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
