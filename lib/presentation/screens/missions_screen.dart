import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/missions_repository.dart';
import '../providers/lab_provider.dart';
import '../providers/missions_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/instrument_box.dart';

class MissionsScreen extends StatelessWidget {
  final VoidCallback onNavigateToLab;

  const MissionsScreen({
    super.key,
    required this.onNavigateToLab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            InstrumentBox(
              title: 'Lab',
              titleColor: AppColors.deepGreen,
              borderColor: AppColors.green,
              titleBoxColor: Colors.white,
              titleFontSize: 13.5,
              borderWidth: 1.2,
              borderRadius: 12.0,
              contentPadding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
              margin: const EdgeInsets.only(bottom: 22),
              child: _buildLabModesContent(context),
            ),

            InstrumentBox(
              title: 'Missions',
              titleColor: AppColors.deepGreen,
              borderColor: AppColors.green,
              titleBoxColor: Colors.white,
              titleFontSize: 13.5,
              borderWidth: 1.2,
              borderRadius: 12.0,
              contentPadding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
              margin: const EdgeInsets.only(bottom: 20),
              child: _buildMissionsContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabModesContent(BuildContext context) {
    final labModes = MissionsRepository.getLabModes();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.88,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: labModes.length,
      itemBuilder: (context, index) {
        final mode = labModes[index];
        final bool isPink = mode.is3D;
        final Color cardBorder = isPink ? AppColors.pinkBorder : AppColors.greenBorder;
        final Color cardTitleColor = isPink ? AppColors.darkPink : AppColors.deepGreen;

        return InstrumentBox(
          title: mode.title,
          borderColor: cardBorder,
          titleColor: cardTitleColor,
          titleBoxColor: Colors.white,
          titleFontSize: 11.0,
          margin: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
          onTap: () {
            context.read<LabProvider>().loadMissionConfig(
                  datasetType: mode.datasetType,
                  problemType: mode.problemType,
                  features: ['X1', 'X2'],
                  noise: 0.04,
                  initialLayers: 1,
                  initialNeurons: 2,
                );
            context.read<LabProvider>().setInclude3DLandscape(mode.is3D);
            onNavigateToLab();
          },
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _CardThumbnailPainter(
                    datasetType: mode.datasetType,
                    is3D: mode.is3D,
                  ),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPink ? AppColors.softPink : AppColors.softGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mode.is3D ? '3D Landscape' : '2D Sandbox',
                  style: TextStyle(
                    color: isPink ? AppColors.darkPink : AppColors.darkGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissionsContent(BuildContext context) {
    final missionsProv = context.watch<MissionsProvider>();
    final missions = missionsProv.missions;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        final Color cardBorder = mission.isCompleted ? AppColors.green : AppColors.greenBorder;
        final Color cardTitleColor = mission.isCompleted ? AppColors.deepGreen : AppColors.textPrimary;

        return InstrumentBox(
          title: mission.title,
          borderColor: cardBorder,
          titleColor: cardTitleColor,
          titleBoxColor: Colors.white,
          titleFontSize: 11.0,
          margin: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
          onTap: () {
            missionsProv.selectMission(mission.id);
            context.read<LabProvider>().loadMissionConfig(
                  datasetType: mission.datasetType,
                  problemType: mission.problemType,
                  features: mission.allowedFeatures,
                  noise: mission.initialNoise,
                  initialLayers: 1,
                  initialNeurons: 2,
                );
            onNavigateToLab();
          },
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _CardThumbnailPainter(
                    datasetType: mission.datasetType,
                    is3D: false,
                  ),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: mission.isCompleted ? AppColors.lightGreen : AppColors.softGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.greenBorderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (starIdx) {
                    final bool isFilled = starIdx < mission.starsEarned;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 11,
                        color: isFilled ? AppColors.green : AppColors.textMuted,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardThumbnailPainter extends CustomPainter {
  final String datasetType;
  final bool is3D;

  _CardThumbnailPainter({
    required this.datasetType,
    required this.is3D,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotBlue = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.fill;
    final dotPink = Paint()
      ..color = AppColors.pink
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    if (is3D || datasetType.contains('3d')) {
      _draw3DIsometricBox(canvas, size, datasetType.contains('classification'));
      return;
    }

    if (datasetType == '2d_regression' || datasetType == 'keep_training') {

      const int count = 28;
      for (int i = 0; i < count; i++) {
        final t = i / (count - 1);
        final x = 12.0 + t * (size.width - 24.0);
        final y = (size.height - 12.0) - t * (size.height - 24.0);
        final offsetNoise = (math.sin(i * 1.7) * 2.5);
        canvas.drawCircle(Offset(x, y + offsetNoise), 2.2, dotBlue);
      }
    } else if (datasetType == 'single_step') {

      final points = [
        Offset(size.width * 0.22, size.height * 0.78),
        Offset(size.width * 0.38, size.height * 0.62),
        Offset(size.width * 0.44, size.height * 0.56),
        Offset(size.width * 0.60, size.height * 0.40),
        Offset(size.width * 0.78, size.height * 0.22),
      ];
      for (final p in points) {
        canvas.drawCircle(p, 2.5, dotBlue);
      }
    } else if (datasetType == 'broken_line' || datasetType == 'initialization') {

      const int count = 22;
      for (int i = 0; i < count; i++) {
        final t = i / (count - 1);
        final x = 10.0 + t * (size.width - 20.0);
        final vNorm = (t - 0.5).abs() * 2.0;
        final y = size.height * 0.85 - vNorm * (size.height * 0.65);
        canvas.drawCircle(Offset(x, y), 2.2, dotBlue);
      }
    } else if (datasetType == 'w_line') {

      const int count = 30;
      for (int i = 0; i < count; i++) {
        final t = i / (count - 1);
        final x = 8.0 + t * (size.width - 16.0);
        final wNorm = ((t - 0.5).abs() * 2.0 - 0.5).abs() * 2.0;
        final y = size.height * 0.85 - wNorm * (size.height * 0.55);
        canvas.drawCircle(Offset(x, y), 2.2, dotBlue);
      }
    } else if (datasetType == '2d_classification') {

      for (int i = 0; i < 18; i++) {
        final x = 8.0 + (i / 17) * (size.width - 16.0);

        canvas.drawCircle(Offset(x, size.height * 0.68), 2.0, dotBlue);

        canvas.drawCircle(Offset(x, size.height * 0.32), 2.0, dotBlue);
      }
    } else if (datasetType == 'circle') {

      for (int i = 0; i < 10; i++) {
        final a = i * (2 * math.pi / 10);
        canvas.drawCircle(Offset(cx + 12 * math.cos(a), cy + 12 * math.sin(a)), 2.2, dotPink);
      }
      for (int i = 0; i < 18; i++) {
        final a = i * (2 * math.pi / 18);
        canvas.drawCircle(Offset(cx + 28 * math.cos(a), cy + 28 * math.sin(a)), 2.2, dotBlue);
      }
    } else if (datasetType == 'xor') {

      canvas.drawCircle(Offset(cx - 16, cy - 14), 2.8, dotBlue);
      canvas.drawCircle(Offset(cx + 16, cy + 14), 2.8, dotBlue);
      canvas.drawCircle(Offset(cx + 16, cy - 14), 2.8, dotPink);
      canvas.drawCircle(Offset(cx - 16, cy + 14), 2.8, dotPink);
    } else {

      canvas.drawCircle(Offset(cx - 14, cy - 10), 2.8, dotPink);
      canvas.drawCircle(Offset(cx - 8, cy - 16), 2.2, dotPink);
      canvas.drawCircle(Offset(cx + 14, cy + 10), 2.8, dotBlue);
      canvas.drawCircle(Offset(cx + 8, cy + 16), 2.2, dotBlue);
    }
  }

  void _draw3DIsometricBox(Canvas canvas, Size size, bool isClassification) {
    final wirePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final dotBlue = Paint()..color = AppColors.primaryBlue;
    final dotPink = Paint()..color = AppColors.pink;

    final w = size.width;
    final h = size.height;

    final pBackTop = Offset(w * 0.50, h * 0.14);
    final pBackLeft = Offset(w * 0.16, h * 0.32);
    final pBackRight = Offset(w * 0.84, h * 0.32);
    final pFrontTop = Offset(w * 0.50, h * 0.50);

    final pBackBottom = Offset(w * 0.50, h * 0.54);
    final pBottomLeft = Offset(w * 0.16, h * 0.72);
    final pBottomRight = Offset(w * 0.84, h * 0.72);
    final pFrontBottom = Offset(w * 0.50, h * 0.90);

    canvas.drawLine(pBackTop, pBackLeft, wirePaint);
    canvas.drawLine(pBackTop, pBackRight, wirePaint);
    canvas.drawLine(pBackLeft, pFrontTop, wirePaint);
    canvas.drawLine(pBackRight, pFrontTop, wirePaint);

    canvas.drawLine(pBottomLeft, pFrontBottom, wirePaint);
    canvas.drawLine(pBottomRight, pFrontBottom, wirePaint);
    canvas.drawLine(pBackLeft, pBottomLeft, wirePaint);
    canvas.drawLine(pBackRight, pBottomRight, wirePaint);
    canvas.drawLine(pFrontTop, pFrontBottom, wirePaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final start1 = Offset.lerp(pBottomLeft, pBackBottom, t)!;
      final end1 = Offset.lerp(pFrontBottom, pBottomRight, t)!;
      canvas.drawLine(start1, end1, gridPaint);

      final start2 = Offset.lerp(pBottomLeft, pFrontBottom, t)!;
      final end2 = Offset.lerp(pBackBottom, pBottomRight, t)!;
      canvas.drawLine(start2, end2, gridPaint);
    }

    if (isClassification) {

      for (int i = 0; i < 22; i++) {
        final ox = w * 0.34 + (math.sin(i * 1.5) * 11);
        final oy = h * 0.64 + (math.cos(i * 1.2) * 8);
        canvas.drawCircle(Offset(ox, oy), 2.2, dotPink);
      }

      for (int i = 0; i < 24; i++) {
        final bx = w * 0.68 + (math.sin(i * 1.8) * 12);
        final by = h * 0.38 + (math.cos(i * 1.3) * 9);
        canvas.drawCircle(Offset(bx, by), 2.2, dotBlue);
      }
    } else {

      for (int i = 0; i < 36; i++) {
        final t = i / 35.0;
        final px = w * 0.24 + t * (w * 0.52) + math.sin(i * 2.3) * 6;
        final py = h * 0.66 - t * (h * 0.26) + math.cos(i * 1.7) * 4;
        final isTop = t > 0.5;
        canvas.drawCircle(Offset(px, py), 2.2, isTop ? dotBlue : dotPink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardThumbnailPainter oldDelegate) =>
      oldDelegate.datasetType != datasetType || oldDelegate.is3D != is3D;
}
