import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LossChartWidget extends StatelessWidget {
  final List<double> trainLossHistory;
  final List<double> testLossHistory;
  final int currentEpoch;

  const LossChartWidget({
    super.key,
    required this.trainLossHistory,
    required this.testLossHistory,
    required this.currentEpoch,
  });

  @override
  Widget build(BuildContext context) {
    if (trainLossHistory.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Loss Curve (Tap Play to Stream)',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ),
      );
    }

    final List<FlSpot> trainSpots = [];
    final List<FlSpot> testSpots = [];

    double maxY = 1.0;
    for (int i = 0; i < trainLossHistory.length; i++) {
      final y = trainLossHistory[i].clamp(0.0, 10.0);
      trainSpots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) maxY = y;
    }
    for (int i = 0; i < testLossHistory.length; i++) {
      final y = testLossHistory[i].clamp(0.0, 10.0);
      testSpots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) maxY = y;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFFF1F5F9),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trainSpots.length - 1).toDouble().clamp(1.0, 120.0),
          minY: 0,
          maxY: (maxY * 1.1).clamp(0.2, 10.0),
          lineBarsData: [
            LineChartBarData(
              spots: trainSpots,
              isCurved: true,
              color: const Color(0xFFEC4899),
              barWidth: 1.8,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
            if (testSpots.isNotEmpty)
              LineChartBarData(
                spots: testSpots,
                isCurved: true,
                color: const Color(0xFF0284C7),
                barWidth: 1.8,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}
