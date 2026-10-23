import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../src/rust/api/neural_net.dart';

class DecisionBoundaryWidget extends StatelessWidget {
  final List<double> decisionBoundary;
  final List<DataPoint> dataPoints;
  final bool showTestData;

  const DecisionBoundaryWidget({
    super.key,
    required this.decisionBoundary,
    required this.dataPoints,
    this.showTestData = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: _DecisionBoundaryPainter(
          decisionBoundary: decisionBoundary,
          dataPoints: dataPoints,
        ),
        child: Container(),
      ),
    );
  }
}

class _DecisionBoundaryPainter extends CustomPainter {
  final List<double> decisionBoundary;
  final List<DataPoint> dataPoints;

  _DecisionBoundaryPainter({
    required this.decisionBoundary,
    required this.dataPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {

    if (decisionBoundary.isNotEmpty) {
      final int gridDim = math.sqrt(decisionBoundary.length).round();
      final double cellW = size.width / gridDim;
      final double cellH = size.height / gridDim;
      final cellPaint = Paint()..style = PaintingStyle.fill;

      for (int r = 0; r < gridDim; r++) {
        for (int c = 0; c < gridDim; c++) {
          final int idx = r * gridDim + c;
          if (idx >= decisionBoundary.length) break;
          final double val = decisionBoundary[idx].clamp(0.0, 1.0);

          final Color cellColor;
          if (val < 0.5) {
            final t = val / 0.5;
            cellColor = Color.lerp(
              const Color(0xFFEC4899),
              Colors.white,
              t,
            )!;
          } else {
            final t = (val - 0.5) / 0.5;
            cellColor = Color.lerp(
              Colors.white,
              const Color(0xFF0284C7),
              t,
            )!;
          }

          cellPaint.color = cellColor;
          canvas.drawRect(
            Rect.fromLTWH(c * cellW, r * cellH, cellW + 0.5, cellH + 0.5),
            cellPaint,
          );
        }
      }
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    }

    final gridLinePaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), gridLinePaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), gridLinePaint);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white;

    for (final point in dataPoints) {
      if (point.x.length < 2) continue;
      final double rawX1 = point.x[0];
      final double rawX2 = point.x[1];
      final double label = point.y.isNotEmpty ? point.y[0] : 0.0;

      final double screenX = ((rawX1 + 2.0) / 4.0) * size.width;
      final double screenY = ((2.0 - rawX2) / 4.0) * size.height;

      final bool isClassOne = label >= 0.5;
      fillPaint.color = isClassOne
          ? const Color(0xFF0284C7)
          : const Color(0xFFEC4899);

      canvas.drawCircle(Offset(screenX, screenY), 4.0, fillPaint);
      canvas.drawCircle(Offset(screenX, screenY), 4.0, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DecisionBoundaryPainter oldDelegate) => true;
}
