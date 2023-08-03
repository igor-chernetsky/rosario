import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/screens/select_pattern.dart';

import '../providers/mypatterns.dart';

class HomeScreen extends ConsumerWidget {
  static String routeName = '/mypatterns';
  const HomeScreen({super.key});

  getEmptyState() {
    return const Center(
      child: Text('No Patterns Found'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var myPatterns = ref.watch(myPatternsProvider);

    removeItem(int index) async {
      confirm(context).then((approved) {
        if (approved) {
          ref
              .read(myPatternsProvider.notifier)
              .removePattern(myPatterns[index].id!);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/img/rosario-logo.png',
          width: double.infinity,
          height: 40,
          fit: BoxFit.fitHeight,
        ),
      ),
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: myPatterns.isEmpty
                  ? getEmptyState()
                  : ListView.builder(
                      itemBuilder: (ctx, index) => Column(
                        children: [
                          ListTile(
                            title: Text(myPatterns[index].name ?? ''),
                            subtitle: Text(
                              myPatterns[index].patternId,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.grey),
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                                EditPatternScreen.routeName,
                                arguments: myPatterns[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => removeItem(index),
                            ),
                          ),
                          const Divider()
                        ],
                      ),
                      itemCount: myPatterns.length,
                    ))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(SelectPatternScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
