# Version Check Feature

This document describes the version checking and update notification feature implemented in the Rosario app.

## Overview

The app now automatically checks for updates when it starts and prompts users to update when a new version is available. Users can also manually check for updates through the Settings screen.

## Features

### Automatic Version Checking
- Checks for updates 2 seconds after app startup
- Compares current app version with latest available version
- Shows update dialog if a newer version is available

### Update Dialog
- Displays current and latest version information
- Shows release notes (if available)
- Provides "Update Now" and "Later" options
- "Update Now" opens the appropriate app store

### Manual Version Check
- Settings screen with "Check for Updates" option
- Shows loading state during version check
- Displays error messages if check fails
- Shows success message if already up to date

## Implementation Details

### Files Added/Modified

1. **`lib/services/version_service.dart`**
   - Handles version checking logic
   - Compares version strings
   - Fetches latest version from API (currently simulated)
   - Manages app store URLs

2. **`lib/widgets/update_dialog.dart`**
   - Custom dialog for update notifications
   - Displays version information and release notes
   - Handles app store navigation

3. **`lib/providers/version_provider.dart`**
   - Riverpod provider for version checking state
   - Manages loading, error, and success states
   - Provides methods for manual version checking

4. **`lib/screens/settings.dart`**
   - Settings screen with version information
   - Manual update check functionality
   - App information display

5. **`lib/main.dart`**
   - Integrated version checking into app initialization
   - Added settings screen route
   - Listens for version check state changes

6. **`lib/screens/home.dart`**
   - Added settings button to app bar

### Dependencies Added

- `package_info_plus: ^4.2.0` - Get current app version
- `http: ^1.1.0` - Make HTTP requests for version checking
- `url_launcher: ^6.2.1` - Open app store URLs

## Configuration

### Google Play Store Integration
The app is now configured for the actual Google Play Store:
```dart
static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.blackcross.sagrada';
static const String _playStoreReviewUrl = 'https://play.google.com/store/apps/details?id=com.blackcross.sagrada&showAllReviews=true';
```

### Version Source
The app version is automatically read from `pubspec.yaml`:
```yaml
version: 1.1.0+22
```

## Usage

### For Users
1. **Automatic**: Update dialog appears automatically when a new version is available
2. **Manual**: Go to Settings → Check for Updates
3. **App Info**: Go to Settings → App Information to see current version
4. **Rate & Review**: Go to Settings → Rate and Review to open Google Play Store

### For Developers
1. **Testing**: Change the simulated version in `version_service.dart` to test the update flow
2. **Production**: The app is now configured with the real Google Play Store URL
3. **Customization**: Modify the update dialog appearance in `update_dialog.dart`
4. **Version Management**: Update the version in `pubspec.yaml` to change the app version

## Testing

To test the version checking feature:

1. **Simulate Update Available**: Modify `_getLatestVersionFromAPI()` in `version_service.dart` to return a higher version number
2. **Test Manual Check**: Use the Settings screen to manually trigger version checks
3. **Test Error Handling**: Disable internet connection to test error states

## Notes

- The version checking uses simulated data for demonstration purposes
- The app is now configured with the real Google Play Store URL: [https://play.google.com/store/apps/details?id=com.blackcross.sagrada](https://play.google.com/store/apps/details?id=com.blackcross.sagrada)
- Version information is automatically read from `pubspec.yaml`
- The feature gracefully handles network errors and API failures
- Rate and Review functionality opens the Google Play Store review page
