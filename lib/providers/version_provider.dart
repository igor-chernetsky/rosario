import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/version_service.dart';

/// Provider for version checking state
final versionCheckProvider = StateNotifierProvider<VersionCheckNotifier, VersionCheckState>((ref) {
  return VersionCheckNotifier();
});

/// State for version checking
class VersionCheckState {
  final bool isLoading;
  final VersionInfo? versionInfo;
  final String? error;
  final bool hasChecked;

  const VersionCheckState({
    this.isLoading = false,
    this.versionInfo,
    this.error,
    this.hasChecked = false,
  });

  VersionCheckState copyWith({
    bool? isLoading,
    VersionInfo? versionInfo,
    String? error,
    bool? hasChecked,
  }) {
    return VersionCheckState(
      isLoading: isLoading ?? this.isLoading,
      versionInfo: versionInfo ?? this.versionInfo,
      error: error ?? this.error,
      hasChecked: hasChecked ?? this.hasChecked,
    );
  }
}

/// Notifier for version checking
class VersionCheckNotifier extends StateNotifier<VersionCheckState> {
  VersionCheckNotifier() : super(const VersionCheckState());

  /// Check for updates
  Future<void> checkForUpdates() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final versionInfo = await VersionService.checkForUpdates();
      state = state.copyWith(
        isLoading: false,
        versionInfo: versionInfo,
        hasChecked: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasChecked: true,
      );
    }
  }

  /// Reset the state
  void reset() {
    state = const VersionCheckState();
  }

  /// Get current version info without checking for updates
  Future<VersionInfo> getCurrentVersionInfo() async {
    final currentVersion = await VersionService.getCurrentVersion();
    return VersionInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      isUpdateAvailable: false,
    );
  }
}

