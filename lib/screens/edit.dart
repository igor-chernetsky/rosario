import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/models/pattern.dart';
import 'package:rosario/providers/mypatterns.dart';

import '../widgets/pattern_canvas.dart';

class EditPatternScreen extends ConsumerStatefulWidget {
  static String routeName = '/edit';
  const EditPatternScreen({super.key});

  @override
  ConsumerState<EditPatternScreen> createState() => _EditPatternScreenState();
}

class _EditPatternScreenState extends ConsumerState<EditPatternScreen> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    super.dispose();
  }

  export(BuildContext context, BeadsPattern pattern) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Copy pattern data'),
              content: ElevatedButton(
                child: const Text('Copy pattern data'),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: jsonEncode(pattern.toJson())));
                },
              ));
        });
  }

  savePattern(BuildContext context, BeadsPattern pattern) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        if (pattern.name != null) {
          nameController.text = pattern.name!;
        }
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    controller: nameController,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            pattern.name = nameController.text;
                          });
                          ref
                              .read(myPatternsProvider.notifier)
                              .addPattern(pattern);
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                      OutlinedButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext contex) {
    BeadsPattern pattern =
        ModalRoute.of(context)!.settings.arguments as BeadsPattern;

    return Scaffold(
      appBar: AppBar(
          title: Text('Edit ${pattern.name ?? pattern.patternId} pattern')),
      body: PatternCanvas(
          pattern: pattern,
          export: (context, pattern) => export(contex, pattern)),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => savePattern(contex, pattern),
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}
