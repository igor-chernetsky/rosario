import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/version_provider.dart';
import '../widgets/update_dialog.dart';
import '../services/version_service.dart';
import '../services/platform_helper.dart';
import '../services/user_prefs_service.dart';
import '../services/subscription_service.dart';

class SettingsScreen extends ConsumerWidget {
  static const String routeName = '/settings';

  /// High-contrast snackbar text on colored backgrounds (blue/red).
  static const TextStyle _snackbarOnColorText =
      TextStyle(color: Colors.white, fontWeight: FontWeight.w500);

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionState = ref.watch(versionCheckProvider);

    return Scaffold(
      appBar: AppBar(
        title: _SettingsTitleTapDetector(
          onActivateSubscription: (ctx) async {
            await UserPrefsService.setSubscribed(true);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Subscription activated',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
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
              subtitle: Text(
                  'Version: ${versionState.versionInfo?.currentVersion ?? 'Unknown'}'),
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
              onTap: versionState.isLoading
                  ? null
                  : () => _checkForUpdates(context, ref),
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
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.card_membership),
                  title: const Text('Manage Subscription'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showSubscriptionDialog(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Subscription is just to support the author. For now, subscribed users will have almost the same functionality, just access to all Community patterns, while for free users this access will be limited.',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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
            Text(
                'Version: ${ref.read(versionCheckProvider).versionInfo?.currentVersion ?? 'Unknown'}'),
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
    if (versionState.versionInfo != null &&
        versionState.versionInfo!.isUpdateAvailable) {
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
        SnackBar(
          content: const Text(
            'You\'re using the latest version!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openRateAndReview(BuildContext context) async {
    try {
      const url =
          'https://play.google.com/store/apps/details?id=com.blackcross.sagrada&showAllReviews=true';
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

  /// Shows the subscription dialog. Can be called from other screens (e.g. to gate premium features on iOS).
  static Future<void> showSubscriptionDialog(BuildContext context) async {
    final subscriptionService = SubscriptionService();
    await subscriptionService.initialize();

    final isSubscribed = await UserPrefsService.isSubscribed();
    final product = subscriptionService.getProduct();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isSubscribed ? 'Subscription Active' : 'Subscribe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSubscribed)
                const Text(
                    'You have an active subscription. Thank you for your support!')
              else ...[
                const Text(
                    'Subscribe to support the author and get access to all Community patterns.'),
                if (isIOS) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Enable Import from image: create patterns from your photos.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
                if (product == null && isIOS) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Product not loaded. Set up In-App Purchase in App Store Connect (product ID: ${SubscriptionService.subscriptionProductId}), or tap Restore if you already purchased.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
                if (product != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Price: ${product.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              if (!isSubscribed)
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    await Future<void>.delayed(const Duration(milliseconds: 150));
                    try {
                      final success =
                          await subscriptionService.purchaseSubscription();
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Processing subscription…',
                              style: _snackbarOnColorText,
                            ),
                            backgroundColor: Color(0xFF0D47A1),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to start purchase. Please try again.',
                              style: _snackbarOnColorText,
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: _snackbarOnColorText,
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Subscribe'),
                ),
              if (isSubscribed)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final String url = isIOS
                          ? 'https://apps.apple.com/account/subscriptions'
                          : 'https://play.google.com/store/account/subscriptions';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not open subscription management',
                              style: _snackbarOnColorText,
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not open subscription management',
                              style: _snackbarOnColorText,
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Manage Subscription'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await subscriptionService.restorePurchases();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Restoring purchases…',
                          style: _snackbarOnColorText,
                        ),
                        backgroundColor: Color(0xFF0D47A1),
                      ),
                    );
                  }
                },
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                subscriptionService.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSubscriptionDialog(BuildContext context) async {
    await SettingsScreen.showSubscriptionDialog(context);
  }
}

/// Hidden shortcut: 10 taps on the Settings title activate subscription (works in prod).
class _SettingsTitleTapDetector extends StatefulWidget {
  final void Function(BuildContext context) onActivateSubscription;

  const _SettingsTitleTapDetector({required this.onActivateSubscription});

  @override
  State<_SettingsTitleTapDetector> createState() =>
      _SettingsTitleTapDetectorState();
}

class _SettingsTitleTapDetectorState extends State<_SettingsTitleTapDetector> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _tapCount++;
          if (_tapCount >= 10) {
            _tapCount = 0;
            widget.onActivateSubscription(context);
          }
        });
      },
      child: const Text('Settings'),
    );
  }
}
