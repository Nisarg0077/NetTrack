import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  // TODO: Replace with your actual GitHub username and repository name
  static const String _githubOwner = 'YOUR_USERNAME';
  static const String _githubRepo = 'YOUR_REPO';
  static const String _apiUrl = 'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateMessage = false}) async {
    if (_githubOwner == 'YOUR_USERNAME') {
      if (showNoUpdateMessage) {
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
        final String releaseUrl = data['html_url'];

        // Extract version number from tag (e.g., 'v1.0.1' -> '1.0.1')
        final latestVersion = latestVersionTag.replaceAll('v', '').replaceAll('V', '');

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => UpdateDialog(
                latestVersion: latestVersion,
                releaseNotes: releaseNotes,
                releaseUrl: releaseUrl,
              ),
            );
          }
        } else if (showNoUpdateMessage) {
          if (context.mounted) {
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
