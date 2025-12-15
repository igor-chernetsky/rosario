import 'package:flutter/material.dart';
import 'package:rosario/data/saved_patterns.dart';
import 'package:rosario/screens/image_import.dart';
import 'package:rosario/widgets/pattern_filter.dart';
import 'package:rosario/widgets/import_from_file_tile.dart';

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
        
        // Patterns grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              childAspectRatio: 0.9,
              crossAxisCount: 2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pushNamed(ImageImport.routeName),
                  child: Card(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 8),
                          height: 134,
                          child: Icon(
                            Icons.add_a_photo,
                            color: Theme.of(context).primaryColor,
                            size: 60,
                          ),
                        ),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Import from image',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const ImportFromFileTile(),
                ...filteredItems.map((pattern) {
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Image.asset(
                              'assets/img/${item.name?.replaceAll(' ', '')}.png',
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          Container(
                            height: 50,
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              item.name ?? item.patternId,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList()
              ],
            ),
          ),
        ),
      ],
    );
  }
}









