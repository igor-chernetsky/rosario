import 'package:flutter/material.dart';

import '../data/saved_blueprints.dart';
import '../models/pattern.dart';

getOffset(int x, int y, BeadsPattern pattern) {
  double? xCoord = xrules[pattern.patternId] == null
      ? x * pattern.radius + 2 * pattern.radius
      : xrules[pattern.patternId]!(x, y, pattern);
  double? yCoord = yrules[pattern.patternId] == null
      ? y * pattern.radius + 2 * pattern.radius
      : yrules[pattern.patternId]!(x, y, pattern);
  if (xCoord == null || yCoord == null) {
    return null;
  }
  return Offset(xCoord, yCoord);
}
