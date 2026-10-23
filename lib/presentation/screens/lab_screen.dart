import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/lab_provider.dart';
import '../widgets/data_config_dialog.dart';
import '../widgets/decision_boundary_painter.dart';
import '../widgets/feature_selector.dart';
import '../widgets/hyperparameters_dialog.dart';
import '../widgets/inspection_modal.dart';
import '../widgets/loss_landscape_3d_painter.dart';
import '../widgets/network_canvas.dart';
import '../theme/app_theme.dart';
import 'knowledge_screen.dart';

class LabScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const LabScreen({super.key, this.onBack});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {

  int _datasetSelection = 1;

  int _outputSelection = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  @override
  void didChangeDependencies() {
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    super.didChangeDependencies();
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _setPortraitOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lab = context.watch<LabProvider>();
    final state = lab.state;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _setPortraitOrientation();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
            ),
            child: SafeArea(
              left: false,
              right: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.deepGreen, size: 22),
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        _setPortraitOrientation();
                        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Lab',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: AppColors.deepGreen, size: 20),
                      tooltip: 'Ask Gemini AI Tutor',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const KnowledgeScreen(section: 'knowledge', initialTab: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: ColoredBox(
          color: Colors.white,
          child: SafeArea(
            left: false,
            right: false,
            minimum: const EdgeInsets.only(right: 0, bottom: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableHeight = constraints.maxHeight;
                final bool isCompactHeight = availableHeight < 320.0;
                final double studioWidth = constraints.maxWidth;

                return SizedBox(
                  width: studioWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [

                      _buildSubHeader(lab, studioWidth),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      Expanded(
                        child: Stack(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                DataAndFeatureSelector(
                                  activeDataset: state.datasetType,
                                  onSelectDataset: lab.setDatasetType,
                                  activeFeatures: state.activeFeatures,
                                  onToggleFeature: lab.toggleFeature,
                                ),
                                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                                Expanded(
                                  child: _buildCanvasWithLayerHeader(lab),
                                ),
                                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                                _buildOutputPanel(lab, isCompactHeight: isCompactHeight),
                              ],
                            ),

                            Positioned(
                              bottom: isCompactHeight ? 4 : 12,
                              left: 118,
                              right: 212,
                              child: Center(
                                child: _buildFloatingControls(lab, isCompact: isCompactHeight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeader(LabProvider lab, double totalWidth) {
    final state = lab.state;

    return Container(
      height: 32,
      width: totalWidth,
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [

          SizedBox(
            width: 52,
            child: InkWell(
              onTap: () => DataConfigDialog.show(context),
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DATA',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

          const SizedBox(
            width: 64,
            child: Center(
              child: Text('FEATURES', style: TextStyle(color: Color(0xFF334155), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'HIDDEN LAYERS',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: state.hiddenLayerNeurons.length > 1 ? lab.removeHiddenLayer : null,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                        child: Container(
                          width: 24,
                          height: 22,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.remove,
                            size: 13,
                            color: state.hiddenLayerNeurons.length > 1 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${state.hiddenLayerNeurons.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      InkWell(
                        onTap: state.hiddenLayerNeurons.length < 5 ? lab.addHiddenLayer : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                        child: Container(
                          width: 24,
                          height: 22,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add,
                            size: 13,
                            color: state.hiddenLayerNeurons.length < 5 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

          SizedBox(
            width: 210,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => HyperparametersDialog.show(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OUTPUT',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => InspectionModalScreen.show(context, initialTab: 0),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.grid_view_sharp, size: 14, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasWithLayerHeader(LabProvider lab) {
    final state = lab.state;
    final layers = state.hiddenLayerNeurons;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double paddingX = 20.0;
        final double availableWidth = width - paddingX * 2;
        final int totalCols = 1 + layers.length + 1;
        final double colSpacing = totalCols > 1 ? (availableWidth / (totalCols - 1)) : availableWidth;
        final double pillWidth = math.min(54.0, colSpacing - 8.0).clamp(40.0, 54.0);
        final double halfWidth = pillWidth / 2.0;

        return Column(
          children: [

            SizedBox(
              height: 28,
              width: width,
              child: Stack(
                children: [

                  for (int i = 0; i < layers.length; i++) ...[
                    Positioned(
                      left: (paddingX + (i + 1) * colSpacing) - halfWidth,
                      top: 3,
                      width: pillWidth,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: layers[i] > 1 ? () => lab.removeNeuronFromLayer(i) : null,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                                child: Center(
                                  child: Icon(
                                    Icons.remove,
                                    size: 12,
                                    color: layers[i] > 1 ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                '${layers[i]}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: layers[i] < 8 ? () => lab.addNeuronToLayer(i) : null,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    size: 12,
                                    color: layers[i] < 8 ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: NetworkCanvas(
                inputFeatures: state.activeFeatures,
                hiddenLayers: state.hiddenLayerNeurons,
                weights: state.weights,
                biases: state.biases,
                neuronHeatmaps: state.neuronHeatmaps,
                isTraining: state.isTraining,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutputPanel(LabProvider lab, {bool isCompactHeight = false}) {
    final state = lab.state;

    return Container(
      width: 210,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(6, isCompactHeight ? 2 : 4, 8, isCompactHeight ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Epoch ${state.currentEpoch}',
                style: const TextStyle(color: Color(0xFF334155), fontSize: 10, fontWeight: FontWeight.bold),
              ),

              Container(
                width: 60,
                height: 1.5,
                color: const Color(0xFF0F172A),
              ),
            ],
          ),
          SizedBox(height: isCompactHeight ? 1 : 2),
          Text(
            'Training loss ${state.trainLoss.toStringAsFixed(3)}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
          ),
          Text(
            'Test loss ${state.testLoss.toStringAsFixed(3)}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
          ),
          SizedBox(height: isCompactHeight ? 2 : 4),

          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: _outputSelection == 0
                        ? LossLandscape3DWidget(
                            landscape: state.lossLandscape3D,
                            scatterPoints: _datasetSelection != 0 ? state.trainPoints : null,
                            onEditTap: () => InspectionModalScreen.show(context, initialTab: 0),
                          )
                        : DecisionBoundaryWidget(
                            decisionBoundary: state.decisionBoundary,
                            dataPoints: state.trainPoints,
                            showTestData: _datasetSelection == 2,
                          ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
                      ),
                      child: Text(
                        _outputSelection == 0 ? '3D LOSS SURFACE' : 'DECISION BOUNDARY',
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompactHeight ? 3 : 6),

          Row(
            children: [
              const SizedBox(
                width: 44,
                child: Text('Dataset', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Container(
                  height: isCompactHeight ? 18 : 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      _buildPillOption('None', 0, _datasetSelection, (idx) => setState(() => _datasetSelection = idx)),
                      _buildPillOption('Training', 1, _datasetSelection, (idx) => setState(() => _datasetSelection = idx)),
                      _buildPillOption('Test', 2, _datasetSelection, (idx) => setState(() => _datasetSelection = idx)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompactHeight ? 2 : 4),

          Row(
            children: [
              const SizedBox(
                width: 44,
                child: Text('Output', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Container(
                  height: isCompactHeight ? 18 : 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      _buildPillOption('3D', 0, _outputSelection, (idx) {
                        setState(() => _outputSelection = idx);
                        lab.setInclude3DLandscape(idx == 0);
                      }),
                      _buildPillOption('Heatmap', 1, _outputSelection, (idx) {
                        setState(() => _outputSelection = idx);
                        lab.setInclude3DLandscape(idx == 0);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillOption(String label, int index, int currentSelection, Function(int) onSelect) {
    final bool isSelected = currentSelection == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingControls(LabProvider lab, {bool isCompact = false}) {
    final state = lab.state;
    final double playSize = isCompact ? 40.0 : 52.0;
    final double playIconSize = isCompact ? 24.0 : 30.0;
    final double sideIconSize = isCompact ? 22.0 : 28.0;
    final double gap = isCompact ? 10.0 : 14.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          InkWell(
            onTap: lab.reset,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 4 : 6),
              child: Icon(Icons.replay, color: const Color(0xFF1E293B), size: sideIconSize),
            ),
          ),
          SizedBox(width: gap),

          InkWell(
            onTap: lab.toggleTraining,
            borderRadius: BorderRadius.circular(playSize / 2),
            child: Container(
              width: playSize,
              height: playSize,
              decoration: BoxDecoration(
                color: state.isTraining ? const Color(0xFFEC4899) : const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (state.isTraining ? const Color(0xFFEC4899) : const Color(0xFF10B981)).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                state.isTraining ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: playIconSize,
              ),
            ),
          ),
          SizedBox(width: gap),

          InkWell(
            onTap: !state.isTraining ? lab.stepOnce : null,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 4 : 6),
              child: Icon(
                Icons.skip_next,
                color: !state.isTraining ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                size: sideIconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

