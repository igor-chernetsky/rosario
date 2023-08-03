import 'package:flutter/material.dart';

import '../models/pattern.dart';
import '../utils/canvas_utils.dart';

class PatternPainter extends CustomPainter {
  BeadsPattern pattern;
  Color color;
  bool isEditing;
  int rotation;

  PatternPainter(
      {required this.pattern,
      required this.color,
      required this.isEditing,
      required this.rotation});

  drawText(String text, double x, double y, Canvas canvas) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          color:
              isEditing && color == Colors.black ? Colors.white : Colors.black),
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
          canvas);
      for (int y = 0; y < pattern.height; y++) {
        if (x == 0) {
          drawText((y + 1).toString(), 2,
              y * pattern.radius + pattern.radius + 11, canvas);
        }
        final c = getOffset(x, y, pattern);
        if (pattern.matrix?[y][x] != null && c != null) {
          final paint = Paint()..color = pattern.matrix?[y][x] ?? Colors.white;
          canvas.drawCircle(c, 9, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
