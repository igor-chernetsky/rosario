import 'package:flutter/material.dart';

import '../data/saved_blueprints.dart';
import '../models/pattern.dart';

Offset? getOffset(int x, int y, BeadsPattern pattern, bool? noOffset) {
  double startOffset =
      noOffset == true ? pattern.radius / 2 : 2 * pattern.radius;
  double? xCoord = xrules[pattern.patternId] == null
      ? x * pattern.radius + startOffset
      : xrules[pattern.patternId]!(x, y, pattern, noOffset);
  double? yCoord = yrules[pattern.patternId] == null
      ? y * pattern.radius + startOffset
      : yrules[pattern.patternId]!(x, y, pattern, noOffset);
  if (xCoord == null || yCoord == null) {
    return null;
  }
  return Offset(xCoord, yCoord);
}
