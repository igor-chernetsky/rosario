import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rosario/models/pattern.dart';
import 'package:rosario/services/user_prefs_service.dart';
import 'package:share_plus/share_plus.dart';

class SharePatternButton extends StatelessWidget {
  final BeadsPattern pattern;

  const SharePatternButton({
    super.key,
    required this.pattern,
  });

  String _generateAccessToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    // 17 random characters + 's  ' = 20 characters total.
    final randomPart =
        List.generate(17, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${randomPart}s  ';
  }

  Future<void> _handleSendToCommunity(
    BuildContext context,
    BuildContext bottomSheetContext,
    TextEditingController controller,
  ) async {
    // Show loading indicator while sending pattern to community
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final name = controller.text.trim();
    if (name.isNotEmpty) {
      await UserPrefsService.setUserName(name);
    }
    final deviceId = await UserPrefsService.getDeviceId();
    final payload = {
      'id': pattern.id,
      'userName': name,
      'deviceId': deviceId,
      'patternName': pattern.name ?? '',
      'pattern': pattern.toJson(),
      'access': _generateAccessToken(),
    };
    try {
      final uri = Uri.parse(
        'https://rosario-api.vercel.app/api/records',
      );
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (!context.mounted) return;

      // Close loading indicator
      Navigator.of(context, rootNavigator: true).pop();
      // Close bottom sheet
      Navigator.of(bottomSheetContext).pop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pattern was sent and is going to be reviewed.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending pattern: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      // Close loading indicator
      Navigator.of(context, rootNavigator: true).pop();
      // Close bottom sheet
      Navigator.of(bottomSheetContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending pattern: $e'),
        ),
      );
    }
  }

  Future<void> _handleSharePatternFile(
    BuildContext context,
    BuildContext bottomSheetContext,
  ) async {
    Navigator.of(bottomSheetContext).pop();
    await _sharePatternFile(context);
  }

  Future<void> _sharePatternFile(BuildContext context) async {
    try {
      final jsonString = jsonEncode(pattern.toJson());

      final tempDir = await getTemporaryDirectory();
      final fileName = '${pattern.name ?? 'pattern'}.json';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(jsonString);

      final xFile = XFile(file.path, mimeType: 'application/json');
      await Share.shareXFiles(
        [xFile],
        subject: pattern.name ?? 'Pattern',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing pattern: $e')),
      );
    }
  }

  Future<void> _showShareOptionsSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final existingName = await UserPrefsService.getUserName();
    final TextEditingController controller =
        TextEditingController(text: existingName ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A3042),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Send To Community Section
              Text(
                'Send To Community',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'User Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Enter your name',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your pattern will be checked and added to the Rosario Pattern Collection that will be provided later.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primaryColor,
                      ),
                      icon: const Icon(Icons.public),
                      label: const Text('Send to Rosario Community'),
                      onPressed: () =>
                          _handleSendToCommunity(context, ctx, controller),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Separator
              const Divider(
                color: Colors.white24,
                thickness: 1,
              ),
              const SizedBox(height: 24),
              // Share Pattern File Section
              Text(
                'Share Pattern File',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primaryColor,
                      ),
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('Share pattern file'),
                      onPressed: () => _handleSharePatternFile(context, ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () => _showShareOptionsSheet(context),
      tooltip: 'Share',
    );
  }
}
