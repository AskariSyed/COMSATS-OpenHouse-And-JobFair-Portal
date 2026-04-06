import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/screens/update_dialog.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    // Only check for updates on mobile platforms (Android)
    if (kIsWeb) return;

    try {
      // 1. Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 2. Fetch remote version info
      String baseUrl = BackendConfig.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
      if (!baseUrl.endsWith('/')) baseUrl += '/';
      final String versionUrl = '${baseUrl}student/version.json';

      final response = await http.get(Uri.parse(versionUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        final String latestVersion = decoded['latest_version'] ?? '1.0.0';
        final int remoteBuildNumber = decoded['build_number'] ?? 0;
        final bool forceUpdate = decoded['force_update'] ?? false;
        final String whatsNew = decoded['whats_new'] ?? 'A new version is available!';
        
        // Construct full APK URL if it is relative
        String apkUrl = decoded['apk_url'] ?? '';
        if (apkUrl.startsWith('/')) {
          apkUrl = '$baseUrl${apkUrl.substring(1)}';
        }

        // Compare versions (prioritize build number)
        bool updateAvailable = remoteBuildNumber > currentBuildNumber;

        // Semantic check fallback
        if (!updateAvailable && currentVersion != latestVersion) {
          final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
          final remoteParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
          
          for (int i = 0; i < 3; i++) {
            final c = i < currentParts.length ? currentParts[i] : 0;
            final r = i < remoteParts.length ? remoteParts[i] : 0;
            if (r > c) {
              updateAvailable = true;
              break;
            } else if (c > r) {
              break;
            }
          }
        }

        if (updateAvailable && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: !forceUpdate,
            builder: (context) => PopScope(
              canPop: !forceUpdate,
              child: UpdateDialog(
                latestVersion: latestVersion,
                whatsNew: whatsNew,
                apkUrl: apkUrl,
                forceUpdate: forceUpdate,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }
}
