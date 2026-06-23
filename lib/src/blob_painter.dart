import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BlobPainter extends CustomPainter {
  final Float32List positions;
  final ui.FragmentShader? shader;
  final double pointSize;
  final Color fallbackColor;

  BlobPainter({
    required this.positions,
    this.shader,
    required this.pointSize,
    required this.fallbackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = pointSize
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    if (shader != null) {
      paint.shader = shader;
    } else {
      paint.color = fallbackColor;
    }

    // High performance drawing of all points in a single pass
    canvas.drawRawPoints(ui.PointMode.points, positions, paint);
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) {
    return true; // We animate every frame
  }
}
