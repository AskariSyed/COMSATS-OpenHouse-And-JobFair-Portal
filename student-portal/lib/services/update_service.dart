import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/screens/update_dialog.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context, {GlobalKey<NavigatorState>? navigatorKey}) async {
    // Only check for updates on mobile platforms (Android)
    if (kIsWeb) return;

    try {
      // 1. Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 2. Fetch remote version info ALWAYS from the designated student frontend subdomain
      // Because the backend API server (api.jfair.tech) does not host the Flutter web files.
      final String versionUrl = 'https://student.jfair.tech/version.json';
      
      final response = await http.get(
        Uri.parse(versionUrl),
        headers: {
          "Cache-Control": "no-cache",
          "Pragma": "no-cache",
        },
      ).timeout(const Duration(seconds: 10));    

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        final String latestVersion = decoded['latest_version'] ?? '1.0.0';
        final int remoteBuildNumber = decoded['build_number'] ?? 0;
        final bool forceUpdate = decoded['force_update'] ?? false;
        final String whatsNew = decoded['whats_new'] ?? 'A new version is available!';
        
        // APK Url should be parsed directly since it is absolute in version.json
        String apkUrl = decoded['apk_url'] ?? '';

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

        if (updateAvailable) {
          // Identify a mounted context to show the dialog correctly
          BuildContext? dialogContext;
          if (context.mounted) {
            dialogContext = context;
          } else if (navigatorKey?.currentContext != null) {
            dialogContext = navigatorKey!.currentContext;
          }

          if (dialogContext != null) {
            showDialog(
              context: dialogContext,
              barrierDismissible: !forceUpdate,
              builder: (ctx) => PopScope(
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
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error checking for updates: $e");
      }
    }
  }
}
