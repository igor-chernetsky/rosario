import 'dart:io';
import 'package:image/image.dart' as fimg;

import 'package:flutter/material.dart';
import 'package:rosario/data/saved_blueprints.dart';
import 'package:rosario/models/pattern.dart';
import 'package:rosario/utils/color_reducer.dart';

class ImageBreakDetails {
  int horizontal;
  int vertical;
  double radius;
  String patternId;
  double module;
  int width;
  int height;
  int dx;
  int dy;

  ImageBreakDetails(
      {required this.horizontal,
      required this.vertical,
      required this.radius,
      required this.height,
      required this.width,
      required this.module,
      this.dx = 0,
      this.dy = 0,
      this.patternId = 'Square Stitch'});

  change(int delta) {
    return getImgSizing(width, height, horizontal + delta, module, patternId);
  }
}

getImgSizing(int width, int height, int amount, double module, patternId) {
  double radius =
      width / (patternId != 'Brick Stitch' ? amount : (amount + 0.5));
  int vertical =
      (height / (patternId != 'Peyote Stitch' ? radius : (radius + 0.5)))
          .floor();
  return ImageBreakDetails(
      width: width,
      height: height,
      module: module,
      horizontal: amount,
      vertical: vertical,
      patternId: patternId,
      radius: radius * module);
}

int colorCompare(Color c1, Color c2) {
  int c1amount = 256 * 256 * c1.red + 256 * c1.blue + c1.green;
  int c2amount = 256 * 256 * c2.red + 256 * c2.blue + c2.green;
  if (c1amount == c2amount) {
    return 0;
  }
  return c1amount > c2amount ? 1 : -1;
}

int getColorDelta(Color c1, Color c2) {
  return (c1.blue - c2.blue).abs() +
      (c1.red - c2.red).abs() +
      (c1.green - c2.green).abs();
}

getAvarageColor(fimg.Image bitmap, int sx, int sy, int size) {
  double red = 0;
  double green = 0;
  double blue = 0;
  double count = 0;
  for (int y = sy; y < bitmap.height && y < sy + size; y++) {
    for (int x = sx; x < bitmap.width && x < sx + size; x++) {
      if (bitmap.width > x && bitmap.height > y && x > 0 && y > 0) {
        fimg.Pixel pixel = bitmap.getPixel(x, y);
        red = red + pixel.r;
        green = green + pixel.g;
        blue = blue + pixel.b;
        count = count + 1;
      }
    }
  }
  if (count == 0) {
    return null;
  }
  int rf = red ~/ count;
  int gf = green ~/ count;
  int bf = blue ~/ count;
  return Color.fromRGBO(rf, gf, bf, 1);
}

BeadsPattern breakImage(
    ImageBreakDetails details, File file, double dx, double dy) {
  List<List<Color?>> matrix = [];
  List<Color> usedColors = [];
  fimg.Image? bitmap = fimg.decodeImage(file.readAsBytesSync())!;

  if (details.horizontal > 0) {
    double imgRad = (bitmap.width / details.horizontal);

    for (int y = 0; y < details.vertical; y++) {
      List<Color?> column = [];
      for (int x = 0; x < details.horizontal; x++) {
        double ix = xrules[details.patternId] == null
            ? (x * imgRad)
            : xrules[details.patternId]!(
                x,
                y,
                BeadsPattern(
                    width: details.horizontal,
                    height: details.vertical,
                    radius: imgRad,
                    patternId: details.patternId),
                true);
        double iy = yrules[details.patternId] == null
            ? (y * imgRad)
            : yrules[details.patternId]!(
                x,
                y,
                BeadsPattern(
                    width: details.horizontal,
                    height: details.vertical,
                    radius: imgRad,
                    patternId: details.patternId),
                true);
        Color? avrgColor = getAvarageColor(bitmap, ix.floor() + dx.floor(),
            iy.floor() + dy.floor(), imgRad.floor());
        if (avrgColor != null && !usedColors.contains(avrgColor)) {
          usedColors.add(avrgColor);
        }
        column.add(avrgColor);
      }
      matrix.add(column);
    }
    ColorReductionResult reductionResult =
        reduceColorsWithMapping(usedColors, 12);

    usedColors = reductionResult.reducedColors;

    for (int i = 0; i < matrix.length; i++) {
      for (int j = 0; j < matrix[i].length; j++) {
        if (reductionResult.colorMapping[matrix[i][j]] != null) {
          matrix[i][j] = reductionResult.colorMapping[matrix[i][j]];
        }
      }
    }
  }

  return BeadsPattern(
      width: details.horizontal,
      height: details.vertical,
      patternId: details.patternId,
      matrix: matrix,
      colors: usedColors);
}
