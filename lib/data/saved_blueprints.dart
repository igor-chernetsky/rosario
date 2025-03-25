import '../models/pattern.dart';

Map<String, Function> xrules = {
  "Brick Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    double mult = noOffset ? 0.5 : 2;
    double result =
        x * radius + (y.isEven ? mult * radius : radius * (mult + 0.5));
    return result;
  },
  "2nd Brick Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    double result = x * radius +
        (((y + 1) % 4 == 3 || (y + 1) % 4 == 0) ? 2 * radius : radius * 2.5);
    return result;
  },
  "3rd Brick Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    double result = x * radius +
        (((y + 1) % 6 == 5 || (y + 1) % 6 == 4 || (y + 1) % 6 == 0)
            ? 2 * radius
            : radius * 2.5);
    return result;
  },
  "Netting Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    double result = x * radius + (y.isEven ? 2 * radius : radius * 2.5);
    return result;
  },
};

Map<String, Function> yrules = {
  "Peyote Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    double mult = noOffset ? 0.3 : 2;
    double result =
        y * radius + (x.isEven ? mult * radius : radius * (mult + 0.5));
    return result;
  },
  "2nd Peyote Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    double result = y * radius +
        (((x + 1) % 4 == 3 || (x + 1) % 4 == 0) ? 2 * radius : radius * 2.5);
    return result;
  },
  "3rd Peyote Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    double result = y * radius +
        (((x + 1) % 6 == 5 || (x + 1) % 6 == 4 || (x + 1) % 6 == 0)
            ? 2 * radius
            : radius * 2.5);
    return result;
  },
  "Netting Stitch": (int x, int y, BeadsPattern pattern, bool noOffset) {
    double radius = pattern.radius;
    if (((y + 2) % 4 == 0 && (x + 2) % 2 != 0) ||
        (y % 4 == 0 && x.isEven) ||
        !y.isEven && x == pattern.width - 1) {
      return null;
    }
    double result = y * radius + 2 * radius;
    return result;
  },
};

List<BeadsPattern> savedBlueprints = [
  BeadsPattern(width: 8, height: 20, patternId: 'Square Stitch'),
  BeadsPattern(width: 8, height: 20, patternId: 'Brick Stitch', ydelta: 2),
  BeadsPattern(width: 8, height: 20, patternId: '2nd Brick Stitch', ydelta: 4),
  BeadsPattern(width: 8, height: 21, patternId: '3rd Brick Stitch', ydelta: 6),
  BeadsPattern(patternId: 'Peyote Stitch', width: 9, height: 20, xdelta: 2),
  BeadsPattern(patternId: '2nd Peyote Stitch', width: 8, height: 20, xdelta: 4),
  BeadsPattern(patternId: '3rd Peyote Stitch', width: 9, height: 20, xdelta: 6),
  BeadsPattern(
      width: 9, height: 21, patternId: 'Netting Stitch', xdelta: 2, ydelta: 4),
];
