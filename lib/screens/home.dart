import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/screens/select_pattern.dart';
import 'package:rosario/screens/settings.dart';
import 'package:rosario/widgets/pattern_filter.dart';

import '../providers/mypatterns.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static String routeName = '/mypatterns';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? selectedFilter;

  // Get filtered patterns based on selected filter
  List<dynamic> getFilteredPatterns(List<dynamic> myPatterns) {
    if (selectedFilter == null) {
      return myPatterns;
    }
    return myPatterns.where((pattern) => pattern.patternId == selectedFilter).toList();
  }

  // Get unique pattern types from current patterns
  List<String> getAvailablePatternTypes(List<dynamic> myPatterns) {
    return myPatterns.map((pattern) => pattern.patternId).where((id) => id != null).cast<String>().toSet().toList();
  }

  getEmptyState(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 200,
        child: Card(
          color: const Color(0xFF0A3042),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                style: ButtonStyle(
                    iconColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).primaryColor)),
                label: Text(
                  'ADD PATTERN',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () => Navigator.of(context)
                    .pushNamed(SelectPatternScreen.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var myPatterns = ref.watch(myPatternsProvider);
    final filteredPatterns = getFilteredPatterns(myPatterns);
    final availablePatternTypes = getAvailablePatternTypes(myPatterns);

    removeItem(int index) async {
      confirm(context).then((approved) {
        if (approved) {
          // Find the original index in myPatterns
          final patternToRemove = filteredPatterns[index];
          final originalIndex = myPatterns.indexWhere((p) => p.id == patternToRemove.id);
          if (originalIndex != -1) {
            ref
                .read(myPatternsProvider.notifier)
                .removePattern(myPatterns[originalIndex].id!);
          }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed(SettingsScreen.routeName),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
          child: Column(
            children: [
              // Pattern filter (only show if there are patterns and available types)
              if (myPatterns.isNotEmpty && availablePatternTypes.isNotEmpty)
                PatternFilter(
                  selectedFilter: selectedFilter,
                  onFilterChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue;
                    });
                  },
                  availablePatterns: availablePatternTypes,
                ),
              
              // Patterns list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: myPatterns.isEmpty
                      ? getEmptyState(context)
                      : ListView.builder(
                          itemBuilder: (ctx, index) => Column(
                            children: [
                              ListTile(
                                splashColor: Theme.of(context).splashColor,
                                title: Text(
                                  filteredPatterns[index].name ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                      color: Theme.of(context).primaryColor),
                                ),
                                subtitle: Text(
                                  filteredPatterns[index].patternId,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(color: Colors.white),
                                ),
                                onTap: () => Navigator.of(context).pushNamed(
                                    EditPatternScreen.routeName,
                                    arguments: filteredPatterns[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => removeItem(index),
                                ),
                              ),
                              const Divider()
                            ],
                          ),
                          itemCount: filteredPatterns.length,
                        ),
                ),
              ),
            ],
          )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(SelectPatternScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
