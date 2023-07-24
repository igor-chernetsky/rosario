import 'package:flutter/material.dart';
import 'package:rosario/data/saved_patterns.dart';

import '../models/pattern.dart';
import '../screens/edit.dart';

class PatternsCollection extends StatefulWidget {
  const PatternsCollection({super.key});

  @override
  State<PatternsCollection> createState() => _PatternsCollectionState();
}

class _PatternsCollectionState extends State<PatternsCollection> {
  List<BeadsPattern> items = [];

  initCollection() {
    if (items.isEmpty) {
      getSavedPatters().then((value) {
        setState(() {
          items = value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    initCollection();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: items.map((pattern) {
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
                children: [
                  Image.asset(
                    'assets/img/${item.name}.png',
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.fitHeight,
                  ),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      item.name ?? item.patternId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
