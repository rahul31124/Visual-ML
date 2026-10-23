import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../src/rust/api/neural_net.dart';

class LossLandscape3DWidget extends StatefulWidget {
  final LossLandscape3D? landscape;
  final List<DataPoint>? scatterPoints;
  final bool isLossLandscapeMode;
  final bool showPin;
  final VoidCallback? onEditTap;

  const LossLandscape3DWidget({
    super.key,
    this.landscape,
    this.scatterPoints,
    this.isLossLandscapeMode = false,
    this.showPin = false,
    this.onEditTap,
  });

  @override
  State<LossLandscape3DWidget> createState() => _LossLandscape3DWidgetState();
}

class _LossLandscape3DWidgetState extends State<LossLandscape3DWidget> {
  double _rotX = 0.52;
  double _rotY = 0.72;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotY += details.delta.dx * 0.012;
          _rotX = (_rotX - details.delta.dy * 0.012).clamp(0.15, 1.35);
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              CustomPaint(
                painter: _Landscape3DPainter(
                  landscape: widget.landscape,
                  scatterPoints: widget.scatterPoints,
                  rotX: _rotX,
                  rotY: _rotY,
                  isLossLandscapeMode: widget.isLossLandscapeMode,
                  showPin: widget.showPin,
                ),
                child: Container(),
              ),

              Positioned(
                bottom: 4,
                left: 6,
                child: InkWell(
                  onTap: widget.onEditTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                    ),
                    child: const Center(
                      child: Icon(Icons.edit_outlined, size: 13, color: Color(0xFF1E293B)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Landscape3DPainter extends CustomPainter {
  final LossLandscape3D? landscape;
  final List<DataPoint>? scatterPoints;
  final double rotX;
  final double rotY;
  final bool isLossLandscapeMode;
  final bool showPin;

  _Landscape3DPainter({
    required this.landscape,
    this.scatterPoints,
    required this.rotX,
    required this.rotY,
    this.isLossLandscapeMode = false,
    this.showPin = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 + 10;

    final transform = v64.Matrix4.identity()
      ..rotateX(rotX)
      ..rotateY(rotY);

    final double scale = (size.width * 0.44).clamp(55.0, 110.0);

    _draw3DGridBox(canvas, transform, centerX, centerY, scale);

    if (landscape != null && landscape!.lossGrid.isNotEmpty) {
      final int gridDim = landscape!.gridSize.toInt();
      final List<List<Offset>> projected = List.generate(
        gridDim,
        (_) => List.filled(gridDim, Offset.zero),
      );

      double minLoss = double.infinity;
      double maxLoss = -double.infinity;
      for (final l in landscape!.lossGrid) {
        if (l < minLoss) minLoss = l;
        if (l > maxLoss) maxLoss = l;
      }
      if (maxLoss - minLoss < 0.001) maxLoss = minLoss + 1.0;

      for (int r = 0; r < gridDim; r++) {
        final double normY = (r / (gridDim - 1) - 0.5) * 1.8;
        for (int c = 0; c < gridDim; c++) {
          final double normX = (c / (gridDim - 1) - 0.5) * 1.8;
          final int idx = r * gridDim + c;
          final double loss = landscape!.lossGrid[idx];
          final double normLoss = ((loss - minLoss) / (maxLoss - minLoss)).clamp(0.0, 1.0);
          final double zVal = (normLoss - 0.5) * 1.2;

          final vec = v64.Vector3(normX, -zVal, normY);
          final projectedVec = transform.transformed3(vec);

          projected[r][c] = Offset(centerX + projectedVec.x * scale, centerY + projectedVec.y * scale);
        }
      }

      final quadPaint = Paint()..style = PaintingStyle.fill;
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0xFF64748B).withValues(alpha: 0.25);

      for (int r = 0; r < gridDim - 1; r++) {
        for (int c = 0; c < gridDim - 1; c++) {
          final p00 = projected[r][c];
          final p10 = projected[r + 1][c];
          final p11 = projected[r + 1][c + 1];
          final p01 = projected[r][c + 1];

          final int idx = r * gridDim + c;
          final double loss = landscape!.lossGrid[idx];
          final double normLoss = ((loss - minLoss) / (maxLoss - minLoss)).clamp(0.0, 1.0);

          final Color quadColor = isLossLandscapeMode
              ? Color.lerp(
                  const Color(0xFF7F1D1D).withValues(alpha: 0.85),
                  const Color(0xFFEF4444).withValues(alpha: 0.85),
                  normLoss,
                )!
              : Color.lerp(
                  const Color(0xFF0284C7).withValues(alpha: 0.75),
                  const Color(0xFFEC4899).withValues(alpha: 0.85),
                  normLoss,
                )!;

          quadPaint.color = quadColor;

          final path = Path()
            ..moveTo(p00.dx, p00.dy)
            ..lineTo(p10.dx, p10.dy)
            ..lineTo(p11.dx, p11.dy)
            ..lineTo(p01.dx, p01.dy)
            ..close();

          canvas.drawPath(path, quadPaint);
          canvas.drawPath(path, linePaint);
        }
      }

      if (showPin || isLossLandscapeMode) {
        final pinBottom = transform.transformed3(v64.Vector3(0.0, 0.7, 0.0));
        final pinTop = transform.transformed3(v64.Vector3(0.0, -0.7, 0.0));
        final pinPaint = Paint()
          ..color = const Color(0xFF0F172A)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(centerX + pinBottom.x * scale, centerY + pinBottom.y * scale),
          Offset(centerX + pinTop.x * scale, centerY + pinTop.y * scale),
          pinPaint,
        );
      }
    }

    if (scatterPoints != null && scatterPoints!.isNotEmpty) {
      final blueDot = Paint()..color = const Color(0xFF0284C7);
      final pinkDot = Paint()..color = const Color(0xFFEC4899);

      for (int i = 0; i < scatterPoints!.length; i++) {
        final p = scatterPoints![i];
        if (p.x.length < 2) continue;
        final normX = (p.x[0] / 2.0).clamp(-1.0, 1.0) * 0.9;
        final normY = (p.x[1] / 2.0).clamp(-1.0, 1.0) * 0.9;
        final isClassOne = p.y.isNotEmpty && p.y[0] >= 0.5;
        final normZ = isClassOne ? 0.35 : -0.35;

        final vec = v64.Vector3(normX, -normZ, normY);
        final proj = transform.transformed3(vec);

        final dotCenter = Offset(centerX + proj.x * scale, centerY + proj.y * scale);
        canvas.drawCircle(dotCenter, 2.5, isClassOne ? blueDot : pinkDot);
      }
    }
  }

  void _draw3DGridBox(Canvas canvas, v64.Matrix4 transform, double cx, double cy, double scale) {
    final gridLinePaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const int divisions = 4;
    for (int i = 0; i <= divisions; i++) {
      final t = (i / divisions - 0.5) * 1.8;

      final p1 = transform.transformed3(v64.Vector3(-0.9, 0.7, t));
      final p2 = transform.transformed3(v64.Vector3(0.9, 0.7, t));
      canvas.drawLine(Offset(cx + p1.x * scale, cy + p1.y * scale), Offset(cx + p2.x * scale, cy + p2.y * scale), gridLinePaint);

      final p3 = transform.transformed3(v64.Vector3(t, 0.7, -0.9));
      final p4 = transform.transformed3(v64.Vector3(t, 0.7, 0.9));
      canvas.drawLine(Offset(cx + p3.x * scale, cy + p3.y * scale), Offset(cx + p4.x * scale, cy + p4.y * scale), gridLinePaint);

      final p5 = transform.transformed3(v64.Vector3(-0.9, t, -0.9));
      final p6 = transform.transformed3(v64.Vector3(0.9, t, -0.9));
      canvas.drawLine(Offset(cx + p5.x * scale, cy + p5.y * scale), Offset(cx + p6.x * scale, cy + p6.y * scale), gridLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Landscape3DPainter oldDelegate) =>
      oldDelegate.landscape != landscape ||
      oldDelegate.scatterPoints != scatterPoints ||
      oldDelegate.rotX != rotX ||
      oldDelegate.rotY != rotY;
}
