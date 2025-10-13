import 'package:flutter/material.dart';

import '../data/saved_blueprints.dart';
import '../models/pattern.dart';

Offset? getOffset(int x, int y, BeadsPattern pattern, bool? noOffset) {
  double startOffset =
      noOffset == true ? pattern.radius / 2 : 2 * pattern.radius;

  // Determine which patternId to use for x-coordinate calculation
  String yPatternId = pattern.patternId;
  if (pattern.columnsPattern != null) {
    List<int> columns =
        List<int>.from(pattern.columnsPattern!['columns'] ?? []);
    if (columns.contains(x)) {
      yPatternId = pattern.columnsPattern!['patternId'] ?? pattern.patternId;
    }
  }

  // Determine which patternId to use for y-coordinate calculation
  String xPatternId = pattern.patternId;
  if (pattern.rowsPattern != null) {
    List<int> rows = List<int>.from(pattern.rowsPattern!['rows'] ?? []);
    if (rows.contains(y)) {
      xPatternId = pattern.rowsPattern!['patternId'] ?? pattern.patternId;
    }
  }

  double? xCoord = xrules[xPatternId] == null
      ? x * pattern.radius + startOffset
      : xrules[xPatternId]!(x, y, pattern, noOffset);
  double? yCoord = yrules[yPatternId] == null
      ? y * pattern.radius + startOffset
      : yrules[yPatternId]!(x, y, pattern, noOffset);
  if (xCoord == null || yCoord == null) {
    return null;
  }
  return Offset(xCoord, yCoord);
}
