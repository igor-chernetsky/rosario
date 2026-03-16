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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, left: 4, right: 4),
                          child: Image.asset(
                            'assets/img/${item.patternId}.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text(
                          item.patternId,
                          style: Theme.of(context).textTheme.titleMedium,
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
    );
  }
}
