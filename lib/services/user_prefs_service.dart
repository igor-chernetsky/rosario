import 'package:android_id/android_id.dart';
import 'package:flutter/services.dart';
import 'package:rosario/main.dart';
import 'package:rosario/services/subscription_service.dart';

class UserPrefsService {
  static const _androidId = AndroidId();

  static Future<String?> getUserName() async {
    try {
      return await dbHelper.getUserName();
    } catch (_) {
      // ignore read errors, treat as no username
      return null;
    }
  }

  static Future<void> setUserName(String userName) async {
    try {
      await dbHelper.setUserName(userName);
    } catch (_) {
      // ignore write errors
    }
  }

  static Future<String> getDeviceId() async {
    try {
      final String? androidId = await _androidId.getId();
      if (androidId != null && androidId.isNotEmpty) {
        return androidId;
      }
      // Fallback if Android ID is not available (e.g., on iOS or error)
      return 'unknown-device';
    } on PlatformException catch (_) {
      // Handle platform-specific errors (e.g., on iOS)
      return 'unknown-device';
    } catch (_) {
      // Fallback for any other errors
      return 'unknown-device';
    }
  }

  static Future<bool> isSubscribed() async {
    return await SubscriptionService.isSubscribed();
  }

  static Future<void> setSubscribed(bool isSubscribed) async {
    await SubscriptionService.setSubscribed(isSubscribed);
  }
}


