import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/screens/select_pattern.dart';

import '../providers/mypatterns.dart';

class HomeScreen extends ConsumerWidget {
  static String routeName = '/mypatterns';
  const HomeScreen({super.key});

  getEmptyState(BuildContext context) {
    return Center(
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        color: const Color(0xFF0A3042),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  height: 40.0,
                  'assets/img/rosario.png',
                ),
                const SizedBox(
                  width: 20,
                ),
                const Text(
                  'NO PATTERNS FOUND',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('ADD PATTERN'),
              onPressed: () => Navigator.of(context)
                  .pushNamed(SelectPatternScreen.routeName),
            ),
          ],
        ),
      ),
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
                  ? getEmptyState(context)
                  : ListView.builder(
                      itemBuilder: (ctx, index) => Column(
                        children: [
                          ListTile(
                            title: Text(
                              myPatterns[index].name ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor),
                            ),
                            subtitle: Text(
                              myPatterns[index].patternId,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.white),
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
