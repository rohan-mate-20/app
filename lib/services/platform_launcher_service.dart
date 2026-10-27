import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// PlatformLauncherService handles interaction with native Android capabilities:
/// - Opening Google Play Store for app updates
/// - Safely opening the phone dialer without sensitive CALL_PHONE permissions
/// - Safely opening SMS client without sensitive SEND_SMS permissions
/// - Handling notification permissions for Android 13+
class PlatformLauncherService {
  static const MethodChannel _channel = MethodChannel('kmart/platform');

  /// Open Google Play Store on K MART's listing page
  static Future<bool> openPlayStore({String? packageName}) async {
    try {
      final success = await _channel.invokeMethod<bool>('openPlayStore', {
        'packageName': packageName ?? 'com.kmart.kmart_customer',
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[PlatformLauncherService] openPlayStore error: $e');
      return false;
    }
  }

  /// Launch the phone dialer with pre-filled phone number
  /// Safe for Google Play: does not require CALL_PHONE permission
  static Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      final success = await _channel.invokeMethod<bool>('makePhoneCall', {
        'phoneNumber': phoneNumber,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[PlatformLauncherService] makePhoneCall error: $e');
      return false;
    }
  }

  /// Open SMS composer with pre-filled message
  /// Safe for Google Play: does not require SEND_SMS permission
  static Future<bool> openSms(String phoneNumber, {String? message}) async {
    try {
      final success = await _channel.invokeMethod<bool>('openSms', {
        'phoneNumber': phoneNumber,
        'message': message ?? '',
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[PlatformLauncherService] openSms error: $e');
      return false;
    }
  }

  /// Request runtime notification permission (Android 13+ / API 33+)
  static Future<bool> requestNotificationPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return granted ?? true;
    } catch (e) {
      debugPrint('[PlatformLauncherService] requestNotificationPermission error: $e');
      return true;
    }
  }

  /// Check whether notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('checkNotificationPermission');
      return granted ?? true;
    } catch (e) {
      debugPrint('[PlatformLauncherService] checkNotificationPermission error: $e');
      return true;
    }
  }

  /// Display a native Android mobile system notification (status bar & lock screen)
  static Future<bool> showSystemNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'body': body,
        'id': id ?? (DateTime.now().millisecondsSinceEpoch % 100000),
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[PlatformLauncherService] showSystemNotification error: $e');
      return false;
    }
  }
}
