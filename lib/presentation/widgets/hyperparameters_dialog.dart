import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lab_provider.dart';

class HyperparametersDialog extends StatefulWidget {
  const HyperparametersDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => const HyperparametersDialog(),
    );
  }

  @override
  State<HyperparametersDialog> createState() => _HyperparametersDialogState();
}

class _HyperparametersDialogState extends State<HyperparametersDialog> {
  late double _batchSize;
  late String _activation;
  late double _learningRate;
  late String _regularization;
  late double _regRate;

  final List<String> _activations = const ['ReLU', 'Tanh', 'Sigmoid', 'Linear'];
  final List<double> _learningRates = const [0.0001, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1.0];
  final List<String> _regularizations = const ['None', 'L1', 'L2'];
  final List<double> _regRates = const [0.0, 0.001, 0.003, 0.01, 0.03, 0.1];

  @override
  void initState() {
    super.initState();
    final state = context.read<LabProvider>().state;
    _batchSize = state.batchSize.toDouble().clamp(1, 50);
    _activation = _mapActivationToLabel(state.activation);
    _learningRate = state.learningRate;
    _regularization = _mapRegularizationToLabel(state.regularization);
    _regRate = state.regRate;
  }

  String _mapActivationToLabel(String act) {
    switch (act.toLowerCase()) {
      case 'relu':
        return 'ReLU';
      case 'tanh':
        return 'Tanh';
      case 'sigmoid':
        return 'Sigmoid';
      default:
        return 'Linear';
    }
  }

  String _mapRegularizationToLabel(String reg) {
    switch (reg.toLowerCase()) {
      case 'l1':
        return 'L1';
      case 'l2':
        return 'L2';
      default:
        return 'None';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lab = context.watch<LabProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: SizedBox(
          width: 340,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

              Text(
                'Batch size ${_batchSize.round()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              _buildStepperSlider(
                value: _batchSize,
                min: 1,
                max: 40,
                divisions: 39,
                step: 1,
                onChanged: (val) {
                  setState(() => _batchSize = val);
                  lab.setBatchSize(val.round());
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Text(
                    'Activation function:',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildHelpBadge('Activation adds non-linearity to hidden neurons (ReLU, Tanh, Sigmoid).'),
                ],
              ),
              _buildDropdownUnderlined<String>(
                value: _activation,
                items: _activations.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _activation = val);
                    lab.setActivation(val.toLowerCase());
                  }
                },
              ),
              const SizedBox(height: 12),

              const Text(
                'Learning rate:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildDropdownUnderlined<double>(
                value: _learningRates.contains(_learningRate) ? _learningRate : 0.03,
                items: _learningRates.map((lr) => DropdownMenuItem(value: lr, child: Text('$lr'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _learningRate = val);
                    lab.setLearningRate(val);
                  }
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Text(
                    'Regularization:',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildHelpBadge('L1/L2 penalty prevents overfitting by penalizing large weights.'),
                ],
              ),
              _buildDropdownUnderlined<String>(
                value: _regularization,
                items: _regularizations.map((r) => DropdownMenuItem(value: r, child: Text(r == 'None' ? '—' : r))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _regularization = val);
                    lab.setRegularization(val == 'None' ? 'none' : val.toLowerCase(), _regRate);
                  }
                },
              ),
              const SizedBox(height: 12),

              const Text(
                'Regularization rate:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildDropdownUnderlined<double>(
                value: _regRates.contains(_regRate) ? _regRate : 0.001,
                items: _regRates.map((rr) => DropdownMenuItem(value: rr, child: Text('$rr'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _regRate = val);
                    lab.setRegularization(_regularization == 'None' ? 'none' : _regularization.toLowerCase(), val);
                  }
                },
              ),
            ],
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
            ),
            child: const Text(
              'HYPERPARAMETERS',
              style: TextStyle(
                color: Color(0xFF0369A1),
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                letterSpacing: 0.3,
              ),
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

  Widget _buildHelpBadge(String tooltip) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        width: 15,
        height: 15,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownUnderlined<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStepperSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required double step,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        InkWell(
          onTap: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
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
              overlayColor: const Color(0x150284C7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        InkWell(
          onTap: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.add, size: 16, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }
}
