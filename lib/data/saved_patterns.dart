import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pattern.dart';

Future<BeadsPattern> readJsonFile(String filePath) async {
  var input = await rootBundle.loadString(filePath);
  var map = jsonDecode(input);
  List<List<Color?>> matrix = [];
  (map['matrix'] as List<dynamic>).forEach(
    (element) {
      matrix.add((element as List<dynamic>)
          .map((e) => e == null ? null : Color(int.parse(e)))
          .toList());
    },
  );
  return BeadsPattern(
      height: map['height'],
      width: map['width'],
      matrix: matrix,
      colors: (map['colors'] as List<dynamic>)
          .map((e) => Color(int.parse(e)))
          .toList(),
      patternId: map['patternId'],
      name: map['name']);
}

List<BeadsPattern> savedPatterns = [];

Future<List<BeadsPattern>> getSavedPatters() async {
  if (savedPatterns.isNotEmpty) {
    return savedPatterns;
  }

  final cornflower = await Future.wait([
    readJsonFile('assets/patterns/abyss.json'),
    readJsonFile('assets/patterns/blue_flower.json'),
    readJsonFile('assets/patterns/cornflower.json'),
    readJsonFile('assets/patterns/fox.json'),
    readJsonFile('assets/patterns/minion.json'),
    readJsonFile('assets/patterns/mermaid.json'),
    readJsonFile('assets/patterns/cat.json'),
    readJsonFile('assets/patterns/caramel.json'),
    readJsonFile('assets/patterns/gray_red_pattern.json'),
    readJsonFile('assets/patterns/autumn_river.json'),
    readJsonFile('assets/patterns/mint_chocolate.json'),
    readJsonFile('assets/patterns/siamese_cat.json'),
    readJsonFile('assets/patterns/watermelone_popsicle.json'),
    readJsonFile('assets/patterns/raphael_tmnt.json'),
    readJsonFile('assets/patterns/skull.json'),
  ]);

  return cornflower;
}
