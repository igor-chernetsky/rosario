import 'package:flutter/material.dart';
import 'dart:math';

class ColorReductionResult {
  final List<Color> reducedColors;
  final Map<Color, Color> colorMapping;

  ColorReductionResult(this.reducedColors, this.colorMapping);
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

  // Convert colors to LAB color space for better perceptual difference
  List<LabColor> labColors = colors.map((c) => rgbToLab(c)).toList();

  // Cluster colors using k-means algorithm and get mapping
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

  // Initialize centroids using the farthest point method for better spread
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

  // Update mapping with final centroids
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
