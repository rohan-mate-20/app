import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import '../widgets/app_update_dialog.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForced;
  final String currentVersion;
  final String latestVersion;
  final String? releaseNotes;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.isForced,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotes,
  });
}

class AppUpdateService {
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 1;

  static const String _prefDismissedKey = 'kmart_app_update_dismissed_at';
  static const Duration _dismissCooldown = Duration(hours: 24);

  /// Check whether an update is available from remote settings
  static Future<AppUpdateInfo> checkForUpdate() async {
    try {
      final supabase = SupabaseService.client;

      // 1. Try fetching from 'app_settings' table
      final response = await supabase
          .from('app_settings')
          .select()
          .eq('key', 'customer_app_version')
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response != null) {
        final val = response['value'];
        final Map<String, dynamic> data = val is Map<String, dynamic>
            ? val
            : Map<String, dynamic>.from(response);

        final latestVer = data['latest_version']?.toString() ?? currentVersion;
        final minVer = data['min_version']?.toString();
        final notes = data['release_notes']?.toString();
        final isForced = data['force_update'] == true ||
            (minVer != null && _isVersionGreater(minVer, currentVersion));

        final hasUpdate = _isVersionGreater(latestVer, currentVersion);

        return AppUpdateInfo(
          hasUpdate: hasUpdate,
          isForced: isForced,
          currentVersion: currentVersion,
          latestVersion: latestVer,
          releaseNotes: notes,
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] remote version check error (safe fallback): $e');
    }

    return const AppUpdateInfo(
      hasUpdate: false,
      isForced: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
    );
  }

  /// Compares semantic versions (e.g., '1.0.1' > '1.0.0')
  static bool _isVersionGreater(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final len = parts1.length > parts2.length ? parts1.length : parts2.length;
      for (int i = 0; i < len; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        if (p1 > p2) return true;
        if (p1 < p2) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Prompts the update dialog if an update is available and cooldown has elapsed
  static Future<void> checkAndPromptUpdate(
    BuildContext context, {
    bool forceCheck = false,
  }) async {
    if (!context.mounted) return;

    // Check cooldown for non-forced checks
    if (!forceCheck) {
      final prefs = await SharedPreferences.getInstance();
      final lastDismissed = prefs.getInt(_prefDismissedKey) ?? 0;
      final diff = DateTime.now().millisecondsSinceEpoch - lastDismissed;
      if (diff < _dismissCooldown.inMilliseconds) {
        return; // User recently tapped "Not Now"
      }
    }

    final info = await checkForUpdate();
    if (!info.hasUpdate || !context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: !info.isForced,
      builder: (ctx) => AppUpdateDialog(
        currentVersion: info.currentVersion,
        latestVersion: info.latestVersion,
        releaseNotes: info.releaseNotes,
        isForced: info.isForced,
        onDismissed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_prefDismissedKey, DateTime.now().millisecondsSinceEpoch);
        },
      ),
    );
  }

  /// Manually show update popup (can be called from Profile / Help / Settings)
  static void showUpdatePrompt(
    BuildContext context, {
    String? latestVersion,
    String? releaseNotes,
    bool isForced = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (ctx) => AppUpdateDialog(
        currentVersion: currentVersion,
        latestVersion: latestVersion ?? '1.0.1',
        releaseNotes: releaseNotes,
        isForced: isForced,
      ),
    );
  }
}
