import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/version_provider.dart';
import '../widgets/update_dialog.dart';
import '../services/version_service.dart';

class SettingsScreen extends ConsumerWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionState = ref.watch(versionCheckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Information'),
              subtitle: Text('Version: ${versionState.versionInfo?.currentVersion ?? 'Unknown'}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showAppInfo(context, ref),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('Check for Updates'),
              subtitle: versionState.isLoading
                  ? const Text('Checking...')
                  : versionState.error != null
                      ? Text('Error: ${versionState.error}')
                      : versionState.versionInfo?.isUpdateAvailable == true
                          ? const Text('Update available!')
                          : const Text('You\'re up to date'),
              trailing: versionState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios),
              onTap: versionState.isLoading ? null : () => _checkForUpdates(context, ref),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_rate),
              title: const Text('Rate and Review'),
              subtitle: const Text('Rate our app on Google Play Store'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _openRateAndReview(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Name: Rosario'),
            const SizedBox(height: 8),
            Text('Version: ${ref.read(versionCheckProvider).versionInfo?.currentVersion ?? 'Unknown'}'),
            const SizedBox(height: 8),
            const Text('Description: Beads pattern application'),
            const SizedBox(height: 8),
            const Text('© 2024 Your Company'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    await ref.read(versionCheckProvider.notifier).checkForUpdates();
    
    final versionState = ref.read(versionCheckProvider);
    if (versionState.versionInfo != null && versionState.versionInfo!.isUpdateAvailable) {
      showUpdateDialogIfNeeded(
        context,
        versionState.versionInfo!,
        onDismiss: () => Navigator.of(context).pop(),
      );
    } else if (versionState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking for updates: ${versionState.error}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'re using the latest version!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openRateAndReview(BuildContext context) async {
    try {
      const url = 'https://play.google.com/store/apps/details?id=com.blackcross.sagrada&showAllReviews=true';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context, 'Could not open Google Play Store');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error opening Google Play Store: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
