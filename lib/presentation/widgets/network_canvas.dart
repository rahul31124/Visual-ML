import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NetworkCanvas extends StatefulWidget {
  final List<String> inputFeatures;
  final List<int> hiddenLayers;
  final List<List<List<double>>> weights;
  final List<List<double>> biases;
  final List<List<double>> neuronHeatmaps;
  final bool isTraining;

  const NetworkCanvas({
    super.key,
    required this.inputFeatures,
    required this.hiddenLayers,
    required this.weights,
    required this.biases,
    required this.neuronHeatmaps,
    required this.isTraining,
  });

  @override
  State<NetworkCanvas> createState() => _NetworkCanvasState();
}

class _NetworkCanvasState extends State<NetworkCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isTraining) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant NetworkCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTraining != oldWidget.isTraining) {
      if (widget.isTraining) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: widget.isTraining
          ? AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _NetworkPainter(
                    inputFeatures: widget.inputFeatures,
                    hiddenLayers: widget.hiddenLayers,
                    weights: widget.weights,
                    biases: widget.biases,
                    neuronHeatmaps: widget.neuronHeatmaps,
                    animPhase: _animController.value,
                  ),
                  child: Container(),
                );
              },
            )
          : CustomPaint(
              painter: _NetworkPainter(
                inputFeatures: widget.inputFeatures,
                hiddenLayers: widget.hiddenLayers,
                weights: widget.weights,
                biases: widget.biases,
                neuronHeatmaps: widget.neuronHeatmaps,
                animPhase: 0.0,
              ),
              child: Container(),
            ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final List<String> inputFeatures;
  final List<int> hiddenLayers;
  final List<List<List<double>>> weights;
  final List<List<double>> biases;
  final List<List<double>> neuronHeatmaps;
  final double animPhase;

  _NetworkPainter({
    required this.inputFeatures,
    required this.hiddenLayers,
    required this.weights,
    required this.biases,
    required this.neuronHeatmaps,
    required this.animPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {

    final double paddingX = 20.0;
    final double paddingTop = 8.0;
    final double paddingBottom = 48.0;
    final double availableWidth = size.width - paddingX * 2;
    final double availableHeight = size.height - paddingTop - paddingBottom;

    final int totalCols = 1 + hiddenLayers.length + 1;
    final double colSpacing = availableWidth / (totalCols - 1);

    final List<List<Offset>> nodePositions = [];

    final int inCount = inputFeatures.length;
    final List<Offset> inPositions = [];
    final double inSpacing = availableHeight / (inCount + 1);
    for (int i = 0; i < inCount; i++) {
      inPositions.add(Offset(paddingX, paddingTop + (i + 1) * inSpacing));
    }
    nodePositions.add(inPositions);

    for (int l = 0; l < hiddenLayers.length; l++) {
      final int count = hiddenLayers[l];
      final List<Offset> layerPositions = [];
      final double spacing = availableHeight / (count + 1);
      final double colX = paddingX + (l + 1) * colSpacing;
      for (int i = 0; i < count; i++) {
        layerPositions.add(Offset(colX, paddingTop + (i + 1) * spacing));
      }
      nodePositions.add(layerPositions);
    }

    final double outX = paddingX + (totalCols - 1) * colSpacing;
    nodePositions.add([Offset(outX, paddingTop + availableHeight / 2)]);

    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int l = 0; l < nodePositions.length - 1; l++) {
      final fromNodes = nodePositions[l];
      final toNodes = nodePositions[l + 1];

      final bool hasWeights = l < weights.length;
      final layerWeights = hasWeights ? weights[l] : null;

      for (int t = 0; t < toNodes.length; t++) {
        for (int f = 0; f < fromNodes.length; f++) {
          final p1 = fromNodes[f];
          final p2 = toNodes[t];

          double w = 0.5;
          if (layerWeights != null &&
              t < layerWeights.length &&
              f < layerWeights[t].length) {
            w = layerWeights[t][f];
          }

          final bool isPositive = w >= 0;
          final double absW = w.abs().clamp(0.05, 5.0);
          final double strokeWidth = (absW * 1.5).clamp(1.4, 4.8);

          final Color wireColor = isPositive
              ? const Color(0xFF0284C7).withValues(alpha: (absW / 2.0).clamp(0.4, 0.95))
              : const Color(0xFFEC4899).withValues(alpha: (absW / 2.0).clamp(0.4, 0.95));

          wirePaint.color = wireColor;
          wirePaint.strokeWidth = strokeWidth;

          final double startX = p1.dx + 16.0;
          final double endX = p2.dx - 16.0;
          final double dx = (endX - startX) * 0.5;

          final path = Path()
            ..moveTo(startX, p1.dy)
            ..cubicTo(startX + dx, p1.dy, endX - dx, p2.dy, endX, p2.dy);

          _drawDashedPath(canvas, path, wirePaint, dashLength: 4.5, dashGap: 3.5, phase: animPhase * 8.0);
        }
      }
    }

    int hiddenNeuronIndex = 0;

    for (int l = 0; l < nodePositions.length; l++) {
      final nodes = nodePositions[l];
      final bool isInput = (l == 0);
      final bool isOutput = (l == nodePositions.length - 1);
      final bool isHidden = !isInput && !isOutput;

      final double colSpacingY = availableHeight / (nodes.length + 1);
      final double boxSize = isHidden
          ? (colSpacingY * 0.72).clamp(18.0, 32.0)
          : (isOutput ? (colSpacingY * 0.65).clamp(20.0, 30.0) : (colSpacingY * 0.68).clamp(18.0, 26.0));

      for (int n = 0; n < nodes.length; n++) {
        final pos = nodes[n];
        final rect = Rect.fromCenter(center: pos, width: boxSize, height: boxSize);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(boxSize > 24 ? 5 : 3));

        if (isHidden && hiddenNeuronIndex < neuronHeatmaps.length) {
          _drawNeuronMiniHeatmap(canvas, rect, rrect, neuronHeatmaps[hiddenNeuronIndex]);
          hiddenNeuronIndex++;
        } else {
          final bgPaint = Paint()
            ..color = isInput
                ? const Color(0xFFF8FAFC)
                : (isOutput ? const Color(0xFFEC4899) : const Color(0xFFF8FAFC))
            ..style = PaintingStyle.fill;
          canvas.drawRRect(rrect, bgPaint);
        }

        final borderPaint = Paint()
          ..color = isInput
              ? const Color(0xFF64748B)
              : (isOutput ? const Color(0xFF0F2634) : const Color(0xFF1E293B))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawRRect(rrect, borderPaint);

        final nubPaint = Paint()
          ..color = const Color(0xFF1E293B)
          ..style = PaintingStyle.fill;

        if (!isOutput) {

          canvas.drawCircle(Offset(pos.dx + boxSize / 2 + 1.5, pos.dy), 2.5, nubPaint);
        }
        if (!isInput) {

          canvas.drawCircle(Offset(pos.dx - boxSize / 2 - 1.5, pos.dy), 2.5, nubPaint);
        }

        if (isInput) {
          final textSpan = TextSpan(
            text: inputFeatures[n],
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: boxSize * 0.38,
              fontWeight: FontWeight.bold,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
          );
        } else if (isOutput) {
          final textSpan = TextSpan(
            text: 'Y',
            style: TextStyle(
              color: Colors.white,
              fontSize: boxSize * 0.42,
              fontWeight: FontWeight.bold,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
          );
        }
      }
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double dashGap,
    required double phase,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = phase % (dashLength + dashGap);
      while (distance < metric.length) {
        final double end = math.min(distance + dashLength, metric.length);
        if (end > distance) {
          final extractPath = metric.extractPath(distance, end);
          canvas.drawPath(extractPath, paint);
        }
        distance += dashLength + dashGap;
      }
    }
  }

  void _drawNeuronMiniHeatmap(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    List<double> heatmapVals,
  ) {
    if (heatmapVals.isEmpty) {
      final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
      canvas.drawRRect(rrect, bgPaint);
      return;
    }

    final int gridDim = math.sqrt(heatmapVals.length).round();
    final double vTL = heatmapVals.first;
    final double vBR = heatmapVals.last;
    final double vTR = heatmapVals.length > gridDim ? heatmapVals[gridDim - 1] : 0.0;
    final double vBL = heatmapVals.length > gridDim ? heatmapVals[heatmapVals.length - gridDim] : 0.0;

    final double normStart = (((vTL + vBL) * 0.5 + 1.0) * 0.5).clamp(0.0, 1.0);
    final double normEnd = (((vTR + vBR) * 0.5 + 1.0) * 0.5).clamp(0.0, 1.0);

    final colorStart = Color.lerp(
      const Color(0xFFEC4899),
      const Color(0xFF0284C7),
      normStart,
    )!;
    final colorEnd = Color.lerp(
      Colors.white,
      const Color(0xFF0284C7),
      normEnd,
    )!;

    final gradPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [colorStart, colorEnd],
      )
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, gradPaint);
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => true;
}
