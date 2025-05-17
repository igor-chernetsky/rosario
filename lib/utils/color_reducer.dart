import 'package:flutter/material.dart';
import 'dart:math';

class ColorReductionResult {
  final List<Color> reducedColors;
  final Map<Color, Color> colorMapping;

  ColorReductionResult(this.reducedColors, this.colorMapping);
}

class LabColor {
  final double l;
  final double a;
  final double b;

  LabColor(this.l, this.a, this.b);

  double distanceTo(LabColor other) {
    return sqrt(pow(l - other.l, 2) + pow(a - other.a, 2) + pow(b - other.b, 2));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabColor &&
          runtimeType == other.runtimeType &&
          l == other.l &&
          a == other.a &&
          b == other.b;

  @override
  int get hashCode => Object.hash(l, a, b);
}

ColorReductionResult reduceColorsWithMapping(List<Color> colors, int targetCount) {
  if (targetCount <= 0 || colors.isEmpty) {
    return ColorReductionResult([], {});
  }
  
  if (colors.length <= targetCount) {
    // Return original colors with identity mapping
    Map<Color, Color> mapping = {
      for (var color in colors) color: color
    };
    return ColorReductionResult(List.from(colors), mapping);
  }

  // Convert colors to LAB color space
  List<LabColor> labColors = colors.map((c) => rgbToLab(c)).toList();

  // Cluster colors and get mapping
  var clusteringResult = _kMeansClusteringWithMapping(labColors, targetCount);
  List<LabColor> centroids = clusteringResult.centroids;
  Map<LabColor, LabColor> labMapping = clusteringResult.mapping;

  // Convert centroids back to RGB
  List<Color> resultColors = centroids.map((lab) => labToRgb(lab)).toList();

  // Create the color mapping from original colors to reduced colors
  Map<Color, Color> colorMapping = {};
  for (int i = 0; i < colors.length; i++) {
    Color originalColor = colors[i];
    LabColor mappedLab = labMapping[labColors[i]]!;
    Color mappedColor = labToRgb(mappedLab);
    colorMapping[originalColor] = mappedColor;
  }

  return ColorReductionResult(resultColors, colorMapping);
}

class ClusteringResult {
  final List<LabColor> centroids;
  final Map<LabColor, LabColor> mapping;

  ClusteringResult(this.centroids, this.mapping);
}

ClusteringResult _kMeansClusteringWithMapping(List<LabColor> colors, int k, {int maxIterations = 100}) {
  if (colors.isEmpty || k <= 0) return ClusteringResult([], {});
  if (colors.length <= k) {
    Map<LabColor, LabColor> mapping = {
      for (var color in colors) color: color
    };
    return ClusteringResult(List.from(colors), mapping);
  }

  // Initialize centroids using the farthest point method
  List<LabColor> centroids = [colors.first];
  
  while (centroids.length < k) {
    LabColor farthest = colors.first;
    double maxDistance = 0;
    
    for (var color in colors) {
      double minDistance = double.infinity;
      for (var centroid in centroids) {
        double distance = color.distanceTo(centroid);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      
      if (minDistance > maxDistance) {
        maxDistance = minDistance;
        farthest = color;
      }
    }
    
    centroids.add(farthest);
  }

  Map<LabColor, LabColor> mapping = {};
  
  // K-means iterations
  for (int i = 0; i < maxIterations; i++) {
    // Assign each color to nearest centroid
    Map<LabColor, List<LabColor>> clusters = {
      for (var centroid in centroids) centroid: []
    };
    
    for (var color in colors) {
      LabColor nearestCentroid = centroids.first;
      double minDistance = double.infinity;
      
      for (var centroid in centroids) {
        double distance = color.distanceTo(centroid);
        if (distance < minDistance) {
          minDistance = distance;
          nearestCentroid = centroid;
        }
      }
      
      clusters[nearestCentroid]!.add(color);
      mapping[color] = nearestCentroid;
    }
    
    // Update centroids
    bool centroidsChanged = false;
    List<LabColor> newCentroids = [];
    
    for (var centroid in centroids) {
      List<LabColor> cluster = clusters[centroid]!;
      if (cluster.isEmpty) {
        newCentroids.add(centroid);
        continue;
      }
      
      double lSum = 0, aSum = 0, bSum = 0;
      for (var color in cluster) {
        lSum += color.l;
        aSum += color.a;
        bSum += color.b;
      }
      
      LabColor newCentroid = LabColor(
        lSum / cluster.length,
        aSum / cluster.length,
        bSum / cluster.length,
      );
      
      if (newCentroid.distanceTo(centroid) > 1.0) {
        centroidsChanged = true;
      }
      
      newCentroids.add(newCentroid);
    }
    
    centroids = newCentroids;
    if (!centroidsChanged) break;
  }

  // Final mapping update
  mapping = {};
  for (var color in colors) {
    LabColor nearestCentroid = centroids.first;
    double minDistance = double.infinity;
    
    for (var centroid in centroids) {
      double distance = color.distanceTo(centroid);
      if (distance < minDistance) {
        minDistance = distance;
        nearestCentroid = centroid;
      }
    }
    
    mapping[color] = nearestCentroid;
  }

  return ClusteringResult(centroids, mapping);
}

LabColor rgbToLab(Color color) {
  // Convert RGB to XYZ
  double r = color.red / 255.0;
  double g = color.green / 255.0;
  double b = color.blue / 255.0;

  r = r > 0.04045 ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
  g = g > 0.04045 ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
  b = b > 0.04045 ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92;

  r *= 100;
  g *= 100;
  b *= 100;

  // Observer = 2°, Illuminant = D65
  double x = r * 0.4124 + g * 0.3576 + b * 0.1805;
  double y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  double z = r * 0.0193 + g * 0.1192 + b * 0.9505;

  // Convert XYZ to LAB
  x /= 95.047;
  y /= 100.0;
  z /= 108.883;

  x = x > 0.008856 ? pow(x, 1/3) : (7.787 * x) + (16 / 116);
  y = y > 0.008856 ? pow(y, 1/3) : (7.787 * y) + (16 / 116);
  z = z > 0.008856 ? pow(z, 1/3) : (7.787 * z) + (16 / 116);

  double l = (116 * y) - 16;
  double a = 500 * (x - y);
  double labB = 200 * (y - z);

  return LabColor(l, a, labB);
}

Color labToRgb(LabColor lab) {
  // Convert LAB to XYZ
  double y = (lab.l + 16) / 116;
  double x = lab.a / 500 + y;
  double z = y - lab.b / 200;

  double x3 = pow(x, 3);
  double y3 = pow(y, 3);
  double z3 = pow(z, 3);

  x = x3 > 0.008856 ? x3 : (x - 16/116) / 7.787;
  y = y3 > 0.008856 ? y3 : (y - 16/116) / 7.787;
  z = z3 > 0.008856 ? z3 : (z - 16/116) / 7.787;

  // Observer = 2°, Illuminant = D65
  x *= 95.047;
  y *= 100.0;
  z *= 108.883;

  // Convert XYZ to RGB
  x /= 100;
  y /= 100;
  z /= 100;

  double r = x * 3.2406 + y * -1.5372 + z * -0.4986;
  double g = x * -0.9689 + y * 1.8758 + z * 0.0415;
  double b = x * 0.0557 + y * -0.2040 + z * 1.0570;

  r = r > 0.0031308 ? 1.055 * pow(r, 1/2.4) - 0.055 : 12.92 * r;
  g = g > 0.0031308 ? 1.055 * pow(g, 1/2.4) - 0.055 : 12.92 * g;
  b = b > 0.0031308 ? 1.055 * pow(b, 1/2.4) - 0.055 : 12.92 * b;

  return Color.fromRGBO(
    (r * 255).clamp(0, 255).round(),
    (g * 255).clamp(0, 255).round(),
    (b * 255).clamp(0, 255).round(),
    1.0,
  );
}
