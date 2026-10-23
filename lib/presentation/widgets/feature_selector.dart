import 'dart:math' as math;
import 'package:flutter/material.dart';

class DataAndFeatureSelector extends StatelessWidget {
  final String activeDataset;
  final Function(String) onSelectDataset;
  final List<String> activeFeatures;
  final Function(String) onToggleFeature;

  const DataAndFeatureSelector({
    super.key,
    required this.activeDataset,
    required this.onSelectDataset,
    required this.activeFeatures,
    required this.onToggleFeature,
  });

  static const List<Map<String, dynamic>> datasets = [
    {'id': 'linear'},
    {'id': 'circle'},
    {'id': 'xor'},
    {'id': 'sinewave'},
    {'id': 'spiral'},
  ];

  static const List<Map<String, String>> features = [
    {'id': 'X1', 'label': 'x₁'},
    {'id': 'X2', 'label': 'x₂'},
    {'id': 'X1^2', 'label': 'x₁²'},
    {'id': 'X2^2', 'label': 'x₂²'},
    {'id': 'X1X2', 'label': 'x₁x₂'},
    {'id': 'sin(X1)', 'label': 'cos(x₁)'},
    {'id': 'sin(X2)', 'label': 'cos(x₂)'},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        final bool isCompact = maxHeight < 260.0;
        final double vPadding = isCompact ? 2.0 : 4.0;
        final double itemGap = isCompact ? 3.0 : 5.0;
        final double datasetTileSize = isCompact ? 28.0 : 32.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              width: 52,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: vPadding),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    for (final d in datasets) ...[
                      _buildDatasetTile(d['id'] as String, size: datasetTileSize),
                      SizedBox(height: itemGap),
                    ],

                    Container(
                      width: datasetTileSize,
                      height: datasetTileSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 15, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

            Container(
              width: 64,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: vPadding),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    for (final f in features) ...[
                      _buildFeatureRow(f['id']!, f['label']!, isCompact: isCompact),
                      SizedBox(height: itemGap),
                    ],

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 24),
                        Container(
                          width: isCompact ? 19 : 22,
                          height: isCompact ? 19 : 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Center(
                            child: Icon(Icons.add, size: isCompact ? 12 : 14, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDatasetTile(String id, {double size = 32.0}) {
    final bool isSelected = activeDataset == id;

    return InkWell(
      onTap: () => onSelectDataset(id),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0x330284C7),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: CustomPaint(
          painter: _DatasetThumbnailPainter(datasetId: id),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String id, String label, {bool isCompact = false}) {
    final bool isActive = activeFeatures.contains(id);
    final double boxSize = isCompact ? 19.0 : 22.0;

    return InkWell(
      onTap: () => onToggleFeature(id),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          SizedBox(
            width: 24,
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                fontSize: isCompact ? 9.5 : 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'serif',
              ),
            ),
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isActive ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                    width: isActive ? 1.5 : 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: CustomPaint(
                    painter: _FeatureBoxPainter(featureId: id),
                  ),
                ),
              ),
              if (isActive)
                Positioned(
                  right: -3,
                  top: 8,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEC4899),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatasetThumbnailPainter extends CustomPainter {
  final String datasetId;

  _DatasetThumbnailPainter({required this.datasetId});

  @override
  void paint(Canvas canvas, Size size) {
    final pinkPaint = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.fill;
    final bluePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    if (datasetId == 'circle') {
      canvas.drawCircle(Offset(cx, cy), 3.0, pinkPaint);
      for (int i = 0; i < 6; i++) {
        final a = i * (2 * math.pi / 6);
        final r = size.width * 0.38;
        canvas.drawCircle(Offset(cx + r * math.cos(a), cy + r * math.sin(a)), 1.8, bluePaint);
      }
    } else if (datasetId == 'xor') {
      canvas.drawCircle(Offset(cx - 6, cy - 6), 2.0, bluePaint);
      canvas.drawCircle(Offset(cx + 6, cy + 6), 2.0, bluePaint);
      canvas.drawCircle(Offset(cx + 6, cy - 6), 2.0, pinkPaint);
      canvas.drawCircle(Offset(cx - 6, cy + 6), 2.0, pinkPaint);
    } else if (datasetId == 'spiral') {
      canvas.drawCircle(Offset(cx - 4, cy - 6), 1.8, bluePaint);
      canvas.drawCircle(Offset(cx + 5, cy - 3), 1.8, bluePaint);
      canvas.drawCircle(Offset(cx + 4, cy + 6), 1.8, pinkPaint);
      canvas.drawCircle(Offset(cx - 5, cy + 3), 1.8, pinkPaint);
    } else {

      canvas.drawCircle(Offset(cx - 5, cy - 5), 2.0, pinkPaint);
      canvas.drawCircle(Offset(cx - 8, cy + 1), 1.6, pinkPaint);
      canvas.drawCircle(Offset(cx + 5, cy + 5), 2.0, bluePaint);
      canvas.drawCircle(Offset(cx + 7, cy - 1), 1.6, bluePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DatasetThumbnailPainter oldDelegate) =>
      oldDelegate.datasetId != datasetId;
}

class _FeatureBoxPainter extends CustomPainter {
  final String featureId;

  _FeatureBoxPainter({required this.featureId});

  @override
  void paint(Canvas canvas, Size size) {
    final pinkPaint = Paint()..color = const Color(0xFFEC4899);
    final bluePaint = Paint()..color = const Color(0xFF0284C7);
    final whitePaint = Paint()..color = Colors.white;

    if (featureId == 'X1') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 2, size.height), pinkPaint);
      canvas.drawRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height), bluePaint);
    } else if (featureId == 'X2') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height / 2), pinkPaint);
      canvas.drawRect(Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2), bluePaint);
    } else if (featureId == 'X1^2') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.35, size.height), bluePaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.35, 0, size.width * 0.3, size.height), whitePaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.65, 0, size.width * 0.35, size.height), bluePaint);
    } else if (featureId == 'X2^2') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.35), bluePaint);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.3), whitePaint);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35), bluePaint);
    } else if (featureId == 'X1X2') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 2, size.height / 2), bluePaint);
      canvas.drawRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height / 2), pinkPaint);
      canvas.drawRect(Rect.fromLTWH(0, size.height / 2, size.width / 2, size.height / 2), pinkPaint);
      canvas.drawRect(Rect.fromLTWH(size.width / 2, size.height / 2, size.width / 2, size.height / 2), bluePaint);
    } else {

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.33, size.height), bluePaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.33, 0, size.width * 0.34, size.height), pinkPaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.67, 0, size.width * 0.33, size.height), bluePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FeatureBoxPainter oldDelegate) =>
      oldDelegate.featureId != featureId;
}
