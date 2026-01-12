import 'package:flutter/material.dart';
import 'package:rosario/widgets/patterns_collection.dart';
import 'package:rosario/widgets/community_collection.dart';
import 'package:rosario/widgets/blueprints.dart';
import 'package:rosario/screens/image_import.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:rosario/models/pattern.dart';
import 'package:rosario/providers/mypatterns.dart';
import 'package:rosario/screens/home.dart';

class SelectPatternScreen extends ConsumerWidget {
  static String routeName = '/select';
  const SelectPatternScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(right: 60.0),
          child: Image.asset(
            'assets/img/rosario-logo.png',
            width: double.infinity,
            height: 40,
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOption(
            context,
            icon: Icons.collections_bookmark,
            title: 'Patterns Collection',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Patterns Collection'),
                    ),
                    body: const PatternsCollection(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.people,
            title: 'Community Collection',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Community Collection'),
                    ),
                    body: const CommunityCollection(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.architecture,
            title: 'Schemes',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Schemes'),
                    ),
                    body: const Blueprints(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.add_a_photo,
            title: 'Import from image',
            onTap: () {
              Navigator.of(context).pushNamed(ImageImport.routeName);
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.file_download,
            title: 'Import from shared file',
            onTap: () => _importPatternFromFile(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 32,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).primaryColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _importPatternFromFile(
      BuildContext context, WidgetRef ref) async {
    try {
      // Pick a JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        // User canceled the picker
        return;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Read and parse the JSON file
      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonData;

      try {
        jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        if (!context.mounted) return;
        _showError(context, 'Invalid JSON format: ${e.toString()}');
        return;
      }

      // Validate the JSON structure
      if (!_validatePatternJson(jsonData)) {
        if (!context.mounted) return;
        _showError(context,
            'Invalid pattern format. The file must contain: name, patternId, width, height, colors, and matrix.');
        return;
      }

      // Parse the pattern
      final pattern = _parsePatternFromJson(jsonData);

      // Add pattern to user patterns
      ref.read(myPatternsProvider.notifier).addPattern(pattern);

      if (!context.mounted) return;

      // Store pattern name for success message
      final patternName = pattern.name ?? 'Unnamed';

      // Navigate to home page
      Navigator.of(context).pushNamedAndRemoveUntil(
        HomeScreen.routeName,
        (route) => false,
      );

      // Show success message after navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            final rootContext =
                Navigator.of(context, rootNavigator: true).context;
            if (rootContext != null) {
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pattern "$patternName" imported successfully!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          } catch (e) {
            // If context is not available, the message will be lost
          }
        });
      });
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Error importing pattern: ${e.toString()}');
    }
  }

  bool _validatePatternJson(Map<String, dynamic> json) {
    // Check required fields
    if (!json.containsKey('patternId') || json['patternId'] == null) {
      return false;
    }
    if (!json.containsKey('width') || json['width'] == null) {
      return false;
    }
    if (!json.containsKey('height') || json['height'] == null) {
      return false;
    }
    if (!json.containsKey('colors') || json['colors'] == null) {
      return false;
    }
    if (!json.containsKey('matrix') || json['matrix'] == null) {
      return false;
    }

    // Validate types
    if (json['width'] is! int || json['height'] is! int) {
      return false;
    }
    if (json['colors'] is! List) {
      return false;
    }
    if (json['matrix'] is! List) {
      return false;
    }

    // Validate matrix structure
    final matrix = json['matrix'] as List;
    final height = json['height'] as int;
    final width = json['width'] as int;

    if (matrix.length != height) {
      return false;
    }

    for (var row in matrix) {
      if (row is! List || row.length != width) {
        return false;
      }
    }

    return true;
  }

  BeadsPattern _parsePatternFromJson(Map<String, dynamic> json) {
    // Parse matrix
    List<List<Color?>> matrix = [];
    final matrixData = json['matrix'] as List<dynamic>;

    for (var rowData in matrixData) {
      final row = (rowData as List<dynamic>)
          .map((e) => e == null ? null : Color(int.parse(e.toString())))
          .toList();
      matrix.add(row);
    }

    // Parse colors
    List<Color> colors = [];
    final colorsData = json['colors'] as List<dynamic>;
    for (var colorData in colorsData) {
      colors.add(Color(int.parse(colorData.toString())));
    }

    // Create pattern
    return BeadsPattern(
      name: json['name'] as String?,
      patternId: json['patternId'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      matrix: matrix,
      colors: colors,
      rowsPattern: json['rowsPattern'] as Map<String, dynamic>?,
      columnsPattern: json['columnsPattern'] as Map<String, dynamic>?,
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFFC62828),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
