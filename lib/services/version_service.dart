import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo {
  final String currentVersion;
  final String latestVersion;
  final bool isUpdateAvailable;
  final String? updateUrl;
  final String? releaseNotes;

  VersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.isUpdateAvailable,
    this.updateUrl,
    this.releaseNotes,
  });
}

class VersionService {
  // Google Play Store API for version checking
  static const String _versionCheckUrl = 'https://play.google.com/store/apps/details?id=com.blackcross.sagrada';
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.blackcross.sagrada';
  static const String _playStoreReviewUrl = 'https://play.google.com/store/apps/details?id=com.blackcross.sagrada&showAllReviews=true';

  /// Get current app version from package info
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Check if a new version is available
  static Future<VersionInfo> checkForUpdates() async {
    try {
      final currentVersion = await getCurrentVersion();
      
      // For now, we'll simulate a version check since Google Play Store
      // doesn't provide a public API for version checking
      // In production, you might want to use a custom API or Firebase Remote Config
      final latestVersion = await _getLatestVersionFromPlayStore();
      
      final isUpdateAvailable = _isVersionNewer(latestVersion, currentVersion);
      
      return VersionInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        isUpdateAvailable: isUpdateAvailable,
        updateUrl: _playStoreUrl,
        releaseNotes: 'Bug fixes and performance improvements',
      );
    } catch (e) {
      // If version check fails, return current version info without update
      final currentVersion = await getCurrentVersion();
      return VersionInfo(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        isUpdateAvailable: false,
        updateUrl: _playStoreUrl,
      );
    }
  }

  /// Get latest version from Play Store (simulated for demo)
  static Future<String> _getLatestVersionFromPlayStore() async {
    try {
      // Since Google Play Store doesn't provide a public API for version checking,
      // we'll simulate a version check for demo purposes
      // In production, you might want to use:
      // - Firebase Remote Config
      // - Your own API endpoint
      // - Google Play Developer API (requires authentication)
      
      // For demo: simulate a newer version
      final currentVersion = await getCurrentVersion();
      final currentParts = _parseVersion(currentVersion);
      
      // Simulate a newer version by incrementing the patch version
      final simulatedVersion = '${currentParts[0]}.${currentParts[1]}.${currentParts[2] + 1}';
      
      return simulatedVersion;
    } catch (e) {
      print('Error fetching latest version: $e');
      // Return current version as fallback
      return await getCurrentVersion();
    }
  }

  /// Compare version strings to determine if new version is available
  static bool _isVersionNewer(String latestVersion, String currentVersion) {
    final latest = _parseVersion(latestVersion);
    final current = _parseVersion(currentVersion);
    
    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) {
        return true;
      } else if (latest[i] < current[i]) {
        return false;
      }
    }
    return false;
  }

  /// Parse version string into list of integers
  static List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  /// Open Google Play Store for update
  static Future<void> openAppStore() async {
    // This would typically use url_launcher package
    // For now, we'll just print the URL
    print('Opening Google Play Store: $_playStoreUrl');
  }

  /// Open Google Play Store for rating and review
  static Future<void> openRateAndReview() async {
    // This would typically use url_launcher package
    // For now, we'll just print the URL
    print('Opening Google Play Store for rating: $_playStoreReviewUrl');
  }
}
