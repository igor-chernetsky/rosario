import 'package:flutter/material.dart';

class BeadsPattern {
  String? name;
  String? id;
  String patternId;
  int width;
  int height;
  List<List<Color?>>? matrix;
  double radius;
  int xdelta;
  int ydelta;
  List<Color>? colors;
  Map<String, dynamic>? rowsPattern;
  Map<String, dynamic>? columnsPattern;

  BeadsPattern(
      {this.name,
      required this.width,
      required this.height,
      required this.patternId,
      this.id,
      this.matrix,
      this.colors,
      this.rowsPattern,
      this.columnsPattern,
      this.radius = 20,
      this.xdelta = 1,
      this.ydelta = 1}) {
    if (matrix == null) {
      matrix = [];
      for (var y = 0; y < height; y++) {
        List<Color?> row = [];
        for (var x = 0; x < width; x++) {
          row.add(Colors.white);
        }
        matrix!.add(row);
      }
    }
    colors ??= [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green
    ];
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
        'patternId': patternId,
        'width': width,
        'height': height,
        'colors': colors?.map((col) => col.value.toString()).toList(),
        'matrix': matrix
            ?.map((e) => e.map((col) => col?.value.toString()).toList())
            .toList(),
        'rowsPattern': rowsPattern,
        'columnsPattern': columnsPattern
      };
}
