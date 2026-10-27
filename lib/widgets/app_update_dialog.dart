import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/platform_launcher_service.dart';

class AppUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String? releaseNotes;
  final bool isForced;
  final VoidCallback? onDismissed;

  const AppUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotes,
    this.isForced = false,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForced,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Icon Graphic
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 38,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Version Badge Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v$latestVersion • Google Play Store',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              const Text(
                'Update Available! 🚀',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                releaseNotes ??
                    'A newer and faster version of K MART is available on Google Play Store with latest festival offers, smoother cart, and improved tracking.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Primary "Update App" Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PlatformLauncherService.openPlayStore();
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text(
                    'Update App',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // Secondary "Not Now" Button
              if (!isForced) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismissed?.call();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Not Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
