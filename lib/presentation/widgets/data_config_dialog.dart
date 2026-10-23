import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lab_provider.dart';

class DataConfigDialog extends StatefulWidget {
  const DataConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => const DataConfigDialog(),
    );
  }

  @override
  State<DataConfigDialog> createState() => _DataConfigDialogState();
}

class _DataConfigDialogState extends State<DataConfigDialog> {
  late double _totalSamples;
  late double _trainPercent;
  late double _noise;

  @override
  void initState() {
    super.initState();
    final state = context.read<LabProvider>().state;
    _totalSamples = state.totalSamples.toDouble().clamp(50, 500);
    _trainPercent = state.trainPercent.toDouble().clamp(10, 90);
    _noise = (state.noise * 100).clamp(0, 50);
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
          width: 330,
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
                'Total samples ${_totalSamples.round()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              _buildStepperSlider(
                value: _totalSamples,
                min: 50,
                max: 400,
                divisions: 35,
                step: 10,
                onChanged: (val) {
                  setState(() => _totalSamples = val);
                  lab.setTotalSamples(val.round());
                },
              ),
              const SizedBox(height: 12),

              Text(
                'Percent of training samples ${_trainPercent.round()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              _buildStepperSlider(
                value: _trainPercent,
                min: 10,
                max: 90,
                divisions: 16,
                step: 5,
                onChanged: (val) {
                  setState(() => _trainPercent = val);
                  lab.setTrainPercent(val.round());
                },
              ),
              const SizedBox(height: 12),

              Text(
                'Noise ${_noise.round()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              _buildStepperSlider(
                value: _noise,
                min: 0,
                max: 50,
                divisions: 20,
                step: 2.5,
                onChanged: (val) {
                  setState(() => _noise = val);
                  lab.setNoise(val / 100.0);
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              InkWell(
                onTap: () {
                  lab.regenerateDataset();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'REGENERATE',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
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
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
            ),
            child: const Text(
              'DATASET CONFIGURATION',
              style: TextStyle(
                color: Color(0xFF047857),
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
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.8),
              activeTickMarkColor: const Color(0xFF475569),
              inactiveTickMarkColor: const Color(0xFF94A3B8),
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
