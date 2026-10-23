import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lab_provider.dart';
import '../providers/missions_provider.dart';
import 'knowledge_screen.dart';
import 'lab_screen.dart';
import 'missions_screen.dart';
import 'model_hub_screen.dart';

import '../theme/app_theme.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {

  int _bottomTabIndex = 0;

  void _navigateToLab() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LabScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lab = context.watch<LabProvider>();
    final missions = context.watch<MissionsProvider>();

    if (missions.activeMission != null &&
        lab.state.trainAccuracy >= missions.activeMission!.targetAccuracy &&
        !missions.activeMission!.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        missions.completeMission(
          missions.activeMission!.id,
          lab.state.currentEpoch,
          lab.state.trainAccuracy,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mission "${missions.activeMission!.title}" Cleared! ★★★',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    return PopScope(
      canPop: _bottomTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_bottomTabIndex != 0) {
          setState(() => _bottomTabIndex = 0);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: _bottomTabIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Playground',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),

                            InkWell(
                              onTap: () => _showHelpDialog(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.greenBorderSubtle),
                                ),
                                child: const Center(
                                  child: Text(
                                    '?',
                                    style: TextStyle(
                                      color: AppColors.deepGreen,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: IndexedStack(
            index: _bottomTabIndex,
            children: [
              MissionsScreen(
                onNavigateToLab: _navigateToLab,
              ),
              KnowledgeScreen(
                section: 'all',
                onBack: () => setState(() => _bottomTabIndex = 0),
              ),
              const ModelHubScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
          boxShadow: [
            BoxShadow(
              color: Color(0x06000000),
              offset: Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: SizedBox(
            height: 58,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavItem(
                      index: 0,
                      customIcon: _buildShapesIcon(_bottomTabIndex == 0),
                      label: 'Playground',
                    ),
                    _buildBottomNavItem(
                      index: 1,
                      icon: Icons.menu_book_outlined,
                      label: 'Knowledge',
                    ),
                    _buildBottomNavItem(
                      index: 2,
                      icon: Icons.all_inclusive,
                      label: 'Model',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildShapesIcon(bool isSelected) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _ShapesIconPainter(isSelected: isSelected),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    IconData? icon,
    Widget? customIcon,
    required String label,
  }) {
    final bool isSelected = _bottomTabIndex == index;
    const Color activeColor = AppColors.darkGreen;
    const Color inactiveColor = AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _bottomTabIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ??
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Lab', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
        content: const Text(
          'Build, train, and visualize multi-layer perceptrons (MLPs) 100% offline.\n\n'
          '• Connect features to hidden layers.\n'
          '• Tap Play to stream training weights live.\n'
          '• Inspect each neuron\'s internal feature heatmap.\n'
          '• Explore the 3D loss landscape surface.\n'
          '• Solve Missions to earn gold stars!',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ShapesIconPainter extends CustomPainter {
  final bool isSelected;

  _ShapesIconPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final triPaint = Paint()
      ..color = isSelected ? AppColors.primaryBlue : AppColors.textMuted
      ..style = PaintingStyle.fill;
    final squarePaint = Paint()
      ..color = isSelected ? AppColors.green : AppColors.textMuted
      ..style = PaintingStyle.fill;
    final circlePaint = Paint()
      ..color = isSelected ? AppColors.pink : AppColors.textMuted
      ..style = PaintingStyle.fill;

    final triPath = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width / 2 - 5, 10)
      ..lineTo(size.width / 2 + 5, 10)
      ..close();
    canvas.drawPath(triPath, triPaint);

    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 8, 12, 6.5, 6.5), squarePaint);

    canvas.drawCircle(Offset(size.width / 2 + 5, 15.2), 3.4, circlePaint);
  }

  @override
  bool shouldRepaint(covariant _ShapesIconPainter oldDelegate) => oldDelegate.isSelected != isSelected;
}
