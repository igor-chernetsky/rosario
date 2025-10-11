import 'package:flutter/material.dart';
import 'package:rosario/screens/edit.dart';

import '../data/saved_blueprints.dart';
import '../models/pattern.dart';

class Blueprints extends StatelessWidget {
  const Blueprints({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        childAspectRatio: 0.9,
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: savedBlueprints.map((pattern) {
          BeadsPattern item = BeadsPattern(
              width: pattern.width,
              height: pattern.height,
              patternId: pattern.patternId,
              xdelta: pattern.xdelta,
              ydelta: pattern.ydelta);
          return InkWell(
            onTap: () => Navigator.of(context)
                .pushNamed(EditPatternScreen.routeName, arguments: item),
            child: Card(
              child: Column(
                children: [
                  Image.asset(
                    'assets/img/${item.patternId}.png',
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.fitHeight,
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      item.patternId,
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
