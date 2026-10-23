import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lab_provider.dart';
import 'decision_boundary_painter.dart';
import 'loss_landscape_3d_painter.dart';

class InspectionModalScreen extends StatefulWidget {
  final int initialTab;

  const InspectionModalScreen({
    super.key,
    this.initialTab = 0,
  });

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InspectionModalScreen(initialTab: initialTab),
      ),
    );
  }

  @override
  State<InspectionModalScreen> createState() => _InspectionModalScreenState();
}

class _InspectionModalScreenState extends State<InspectionModalScreen> {
  late int _selectedTab;

  int _datasetSelection = 1;
  int _outputSelection = 0;

  int _lossDatasetSelection = 0;
  int _resolutionSelection = 0;

  bool _w00Active = true;
  bool _w10Active = true;
  bool _b0Active = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final lab = context.watch<LabProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF1E293B), size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),

                  Container(
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopPill(
                          title: 'Output',
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        _buildTopPill(
                          title: 'Loss Landscape',
                          isSelected: _selectedTab == 1,
                          onTap: () {
                            setState(() => _selectedTab = 1);
                            lab.setInclude3DLandscape(true);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            Expanded(
              child: _selectedTab == 0
                  ? _buildOutputView(lab)
                  : _buildLossLandscapeView(lab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputView(LabProvider lab) {
    final state = lab.state;
    final w00 = (state.weights.isNotEmpty && state.weights[0].isNotEmpty && state.weights[0][0].isNotEmpty)
        ? state.weights[0][0][0]
        : 0.2;
    final w10 = (state.weights.isNotEmpty && state.weights[0].isNotEmpty && state.weights[0][0].length > 1)
        ? state.weights[0][0][1]
        : -0.3;
    final b0 = (state.biases.isNotEmpty && state.biases[0].isNotEmpty) ? state.biases[0][0] : 0.1;

    final String actLabel = state.activation.toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final isShortHeight = constraints.maxHeight < 320;

        final Widget previewBox = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: _outputSelection == 0
              ? LossLandscape3DWidget(
                  landscape: state.lossLandscape3D,
                  scatterPoints: _datasetSelection != 0 ? state.trainPoints : null,
                  isLossLandscapeMode: false,
                )
              : DecisionBoundaryWidget(
                  decisionBoundary: state.decisionBoundary,
                  dataPoints: state.trainPoints,
                  showTestData: _datasetSelection == 2,
                ),
        );

        final Widget datasetSelector = Row(
          children: [
            const SizedBox(
              width: 52,
              child: Text('Dataset', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
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
        );

        final Widget outputSelector = Row(
          children: [
            const SizedBox(
              width: 52,
              child: Text('Output', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _buildPillOption('3D', 0, _outputSelection, (idx) => setState(() => _outputSelection = idx)),
                    _buildPillOption('Heatmap', 1, _outputSelection, (idx) => setState(() => _outputSelection = idx)),
                  ],
                ),
              ),
            ),
          ],
        );

        final Widget mathAndSliders = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: isShortHeight ? 4 : 10),
            Center(
              child: Text(
                'a₀⁽²⁾ = $actLabel(∑ᵢ₌₀¹ wᵢ,₀⁽¹⁾ aᵢ⁽¹⁾ + b₀⁽¹⁾)',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: isShortHeight ? 15 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            SizedBox(height: isShortHeight ? 8 : 14),
            const Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: isShortHeight ? 4 : 8),
            _buildManualWeightRow(
              label: 'w₀,₀⁽¹⁾',
              value: w00,
              onChanged: (val) => lab.setManualWeight(0, 0, 0, val),
            ),
            SizedBox(height: isShortHeight ? 8 : 16),
            _buildManualWeightRow(
              label: 'w₁,₀⁽¹⁾',
              value: w10,
              onChanged: (val) => lab.setManualWeight(0, 0, 1, val),
            ),
            SizedBox(height: isShortHeight ? 8 : 16),
            _buildManualWeightRow(
              label: 'b₀⁽¹⁾',
              value: b0,
              onChanged: (val) => lab.setManualBias(0, 0, val),
            ),
          ],
        );

        if (isCompact) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 220, child: previewBox),
                const SizedBox(height: 10),
                datasetSelector,
                const SizedBox(height: 6),
                outputSelector,
                const SizedBox(height: 12),
                mathAndSliders,
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isShortHeight ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: previewBox),
                    SizedBox(height: isShortHeight ? 4 : 8),
                    datasetSelector,
                    SizedBox(height: isShortHeight ? 3 : 6),
                    outputSelector,
                  ],
                ),
              ),
              SizedBox(width: isShortHeight ? 14 : 24),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: mathAndSliders,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLossLandscapeView(LabProvider lab) {
    final state = lab.state;
    final w00 = (state.weights.isNotEmpty && state.weights[0].isNotEmpty && state.weights[0][0].isNotEmpty)
        ? state.weights[0][0][0]
        : 0.2;
    final w10 = (state.weights.isNotEmpty && state.weights[0].isNotEmpty && state.weights[0][0].length > 1)
        ? state.weights[0][0][1]
        : -0.3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final isShortHeight = constraints.maxHeight < 320;

        final Widget previewBox = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: LossLandscape3DWidget(
            landscape: state.lossLandscape3D,
            isLossLandscapeMode: true,
            showPin: true,
          ),
        );

        final Widget datasetSelector = Row(
          children: [
            const SizedBox(
              width: 65,
              child: Text('Dataset', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _buildPillOption('Training', 0, _lossDatasetSelection, (idx) => setState(() => _lossDatasetSelection = idx)),
                    _buildPillOption('Test', 1, _lossDatasetSelection, (idx) => setState(() => _lossDatasetSelection = idx)),
                  ],
                ),
              ),
            ),
          ],
        );

        final Widget resolutionSelector = Row(
          children: [
            const SizedBox(
              width: 65,
              child: Text('Resolution', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _buildPillOption('Low', 0, _resolutionSelection, (idx) => setState(() => _resolutionSelection = idx)),
                    _buildPillOption('Medium', 1, _resolutionSelection, (idx) => setState(() => _resolutionSelection = idx)),
                    _buildPillOption('High', 2, _resolutionSelection, (idx) => setState(() => _resolutionSelection = idx)),
                  ],
                ),
              ),
            ),
          ],
        );

        final Widget controlsColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: isShortHeight ? 4 : 10),
            Center(
              child: Text(
                'loss = ∑ᵢᴺ l(w₀,₀⁽¹⁾, w₁,₀⁽¹⁾, Xᵢ)',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: isShortHeight ? 15 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            SizedBox(height: isShortHeight ? 8 : 14),
            const Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: isShortHeight ? 4 : 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeightToggle(label: 'w₀,₀⁽¹⁾', active: _w00Active, onToggle: (v) => setState(() => _w00Active = v)),
                  const SizedBox(width: 14),
                  _buildWeightToggle(label: 'w₁,₀⁽¹⁾', active: _w10Active, onToggle: (v) => setState(() => _w10Active = v)),
                  const SizedBox(width: 14),
                  _buildWeightToggle(label: 'b₀⁽¹⁾', active: _b0Active, onToggle: (v) => setState(() => _b0Active = v)),
                ],
              ),
            ),
            SizedBox(height: isShortHeight ? 6 : 12),
            const Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: isShortHeight ? 4 : 8),
            _buildManualWeightRow(
              label: 'w₀,₀⁽¹⁾',
              value: w00,
              onChanged: (val) => lab.setManualWeight(0, 0, 0, val),
            ),
            SizedBox(height: isShortHeight ? 8 : 16),
            _buildManualWeightRow(
              label: 'w₁,₀⁽¹⁾',
              value: w10,
              onChanged: (val) => lab.setManualWeight(0, 0, 1, val),
            ),
          ],
        );

        if (isCompact) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 220, child: previewBox),
                const SizedBox(height: 10),
                datasetSelector,
                const SizedBox(height: 6),
                resolutionSelector,
                const SizedBox(height: 12),
                controlsColumn,
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isShortHeight ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: previewBox),
                    SizedBox(height: isShortHeight ? 4 : 8),
                    datasetSelector,
                    SizedBox(height: isShortHeight ? 3 : 6),
                    resolutionSelector,
                  ],
                ),
              ),
              SizedBox(width: isShortHeight ? 14 : 24),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: controlsColumn,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeightToggle({
    required String label,
    required bool active,
    required ValueChanged<bool> onToggle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: Color(0xFF334155)),
        ),
        const SizedBox(width: 4),
        Transform.scale(
          scale: 0.72,
          child: Switch(
            value: active,
            onChanged: onToggle,
            activeThumbColor: const Color(0xFF0284C7),
            activeTrackColor: const Color(0xFF94A3B8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildManualWeightRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            '$label = ${value >= 0 ? ' ' : ''}${value.toStringAsFixed(1)}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () => onChanged((value - 0.1).clamp(-3.0, 3.0)),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.remove, size: 16, color: Color(0xFF94A3B8)),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.5,
                  activeTrackColor: const Color(0xFF1E293B),
                  inactiveTrackColor: const Color(0xFFCBD5E1),
                  thumbColor: const Color(0xFF0284C7),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                ),
                child: Slider(
                  value: value.clamp(-3.0, 3.0),
                  min: -3.0,
                  max: 3.0,
                  onChanged: onChanged,
                ),
              ),
            ),
            InkWell(
              onTap: () => onChanged((value + 0.1).clamp(-3.0, 3.0)),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.add, size: 16, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ],
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
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
