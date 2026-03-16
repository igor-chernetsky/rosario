import 'package:flutter/material.dart';
import 'package:rosario/data/saved_patterns.dart';
import 'package:rosario/widgets/pattern_filter.dart';

import '../models/pattern.dart';
import '../screens/edit.dart';

class PatternsCollection extends StatefulWidget {
  const PatternsCollection({super.key});

  @override
  State<PatternsCollection> createState() => _PatternsCollectionState();
}

class _PatternsCollectionState extends State<PatternsCollection> {
  List<BeadsPattern> items = [];
  String? selectedFilter;

  initCollection() {
    if (items.isEmpty) {
      getSavedPatters().then((value) {
        setState(() {
          items = value;
        });
      });
    }
  }

  // Get filtered patterns based on selected filter
  List<BeadsPattern> getFilteredPatterns() {
    if (selectedFilter == null) {
      return items;
    }
    return items.where((pattern) => pattern.patternId == selectedFilter).toList();
  }

  // Get unique pattern types from current collection
  List<String> getAvailablePatternTypes() {
    return items.map((pattern) => pattern.patternId).where((id) => id != null).cast<String>().toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    initCollection();
    
    final filteredItems = getFilteredPatterns();
    final availablePatternTypes = getAvailablePatternTypes();
    
    return Column(
      children: [
        // Filter dropdown
        PatternFilter(
          selectedFilter: selectedFilter,
          onFilterChanged: (String? newValue) {
            setState(() {
              selectedFilter = newValue;
            });
          },
          availablePatterns: availablePatternTypes,
        ),
        
        // Patterns grid: 3 columns on medium+ (e.g. iPad), 2 on phone; image fills space above title
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;
                final isMediumOrLarger = width >= 600;
                final crossAxisCount = isMediumOrLarger ? 3 : 2;
                final childAspectRatio = isMediumOrLarger ? 0.8 : 0.9;
                return GridView.count(
                  childAspectRatio: childAspectRatio,
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: filteredItems.map((pattern) {
                    BeadsPattern item = BeadsPattern(
                        width: pattern.width,
                        height: pattern.height,
                        patternId: pattern.patternId,
                        matrix: [...pattern.matrix!],
                        name: pattern.name,
                        colors: pattern.colors,
                        xdelta: pattern.xdelta,
                        ydelta: pattern.ydelta);
                    return InkWell(
                      onTap: () => Navigator.of(context)
                          .pushNamed(EditPatternScreen.routeName, arguments: item),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4, right: 4),
                                child: Image.asset(
                                  'assets/img/${item.name?.replaceAll(' ', '')}.png',
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Container(
                              height: 50,
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text(
                                item.name ?? item.patternId,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}









