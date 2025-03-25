import 'package:flutter/material.dart';
import 'package:rosario/utils/colors_utils.dart';

import '../models/pattern.dart';
import '../utils/canvas_utils.dart';

class PatternPainter extends CustomPainter {
  BeadsPattern pattern;
  Color color;
  bool isEditing;
  bool showNumbers;
  int rotation;

  PatternPainter(
      {required this.pattern,
      required this.color,
      required this.isEditing,
      required this.showNumbers,
      required this.rotation});

  drawText(String text, double x, double y, Canvas canvas, TextStyle? style) {
    bool isDark = getColorLight(color) < 400;
    final textSpan = TextSpan(
      text: text,
      style: style ??
          TextStyle(
              fontWeight: FontWeight.bold,
              color: isEditing && isDark ? Colors.white : Colors.black),
    );
    final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center);
    final offset = Offset(x, y);
    textPainter.layout(
      minWidth: 0,
      maxWidth: 30,
    );
    textPainter.paint(canvas, offset);
  }

  drawCircleText(int x, int y, Offset c, Canvas canvas, double tripRadius,
      double halfRadius) {
    if (!showNumbers) {
      return;
    }
    bool isDark = getColorLight(pattern.matrix?[y][x] ?? Colors.white) < 400;
    drawText(
        '${x + 1}\n${y + 1}',
        c.dx - tripRadius,
        c.dy - halfRadius,
        canvas,
        TextStyle(
            fontWeight: FontWeight.bold,
            height: 01,
            fontSize: 9,
            color: isDark ? Colors.white : Colors.black));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint()..color = Colors.transparent);
    if (isEditing) {
      final backPaint = Paint()..color = color;
      canvas.drawRect(
          Rect.fromLTRB(
              pattern.radius + 10,
              0,
              pattern.width * pattern.radius + pattern.radius + 15,
              pattern.radius),
          backPaint);
      canvas.drawRect(
          Rect.fromLTRB(0, pattern.radius + 10, pattern.radius,
              pattern.height * pattern.radius + pattern.radius + 15),
          backPaint);
    }
    for (int x = 0; x < pattern.width; x++) {
      drawText((x + 1).toString(), x * pattern.radius + pattern.radius + 15, 0,
          canvas, null);
      for (int y = 0; y < pattern.height; y++) {
        if (x == 0) {
          drawText((y + 1).toString(), 2,
              y * pattern.radius + pattern.radius + 11, canvas, null);
        }
        final c = getOffset(x, y, pattern, false);
        double halfRadius = pattern.radius / 2.5;
        double tripRadius = pattern.radius / 3.5;
        if (pattern.matrix?[y][x] != null && c != null) {
          final paint = Paint()..color = pattern.matrix?[y][x] ?? Colors.white;
          canvas.drawCircle(c, 9, paint);
          drawCircleText(x, y, c, canvas, tripRadius, halfRadius);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
