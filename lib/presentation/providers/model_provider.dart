import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/neural_model_definition.dart';
import '../../data/repositories/model_repository.dart';

class ModelProvider extends ChangeNotifier {
  final List<NeuralModelDefinition> _models = ModelRepository.getInitialModels();
  String _selectedModelId = 'lenet5';
  bool _isTrainingMode = false;

  bool get isTrainingMode => _isTrainingMode;
  void setTrainingMode(bool val) {
    _isTrainingMode = val;
    notifyListeners();
  }

  bool _isTraining = false;
  int _currentEpoch = 0;
  double _currentLoss = 2.302;
  double _currentAccuracy = 10.2;
  final List<double> _lossHistory = [2.302];
  final List<double> _accuracyHistory = [10.2];
  Timer? _trainingTimer;

  String _activeDataset = 'MNIST (Digits 0-9)';
  final List<String> datasets = [
    'MNIST (Digits 0-9)',
    'Fashion-MNIST',
    'CIFAR-10 (Objects)',
  ];

  List<Map<String, dynamic>> _samplePredictions = [];

  ModelProvider() {
    _generateSamplePredictions();
  }

  List<NeuralModelDefinition> get models => List.unmodifiable(_models);
  String get selectedModelId => _selectedModelId;
  NeuralModelDefinition get activeModel =>
      _models.firstWhere((m) => m.id == _selectedModelId, orElse: () => _models.first);

  bool get isTraining => _isTraining;
  int get currentEpoch => _currentEpoch;
  double get currentLoss => _currentLoss;
  double get currentAccuracy => _currentAccuracy;
  List<double> get lossHistory => List.unmodifiable(_lossHistory);
  List<double> get accuracyHistory => List.unmodifiable(_accuracyHistory);
  String get activeDataset => _activeDataset;
  List<Map<String, dynamic>> get samplePredictions => _samplePredictions;

  void selectModel(String id) {
    _selectedModelId = id;
    _resetTraining();
    notifyListeners();
  }

  void setActiveDataset(String ds) {
    _activeDataset = ds;
    _resetTraining();
    notifyListeners();
  }

  void toggleTraining() {
    _isTraining = !_isTraining;
    if (_isTraining) {
      _startTrainingLoop();
    } else {
      _trainingTimer?.cancel();
    }
    notifyListeners();
  }

  void stepTraining() {
    _performTrainingStep();
    notifyListeners();
  }

  void resetTraining() {
    _trainingTimer?.cancel();
    _isTraining = false;
    _resetTraining();
    notifyListeners();
  }

  void _resetTraining() {
    _currentEpoch = 0;
    _currentLoss = 2.302;
    _currentAccuracy = 10.2;
    _lossHistory.clear();
    _lossHistory.add(_currentLoss);
    _accuracyHistory.clear();
    _accuracyHistory.add(_currentAccuracy);
    _generateSamplePredictions();
  }

  void _startTrainingLoop() {
    _trainingTimer?.cancel();
    _trainingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!_isTraining) {
        timer.cancel();
        return;
      }
      _performTrainingStep();
      notifyListeners();
    });
  }

  void _performTrainingStep() {
    _currentEpoch++;

    final double decay = math.exp(-_currentEpoch * 0.035);
    final double noise = (math.Random().nextDouble() - 0.5) * 0.02;
    _currentLoss = (decay * 2.25 + 0.035 + noise).clamp(0.015, 2.5);

    final double targetAcc = 98.6;
    _currentAccuracy = (targetAcc - (decay * 88.0) + (noise * 50)).clamp(10.0, 99.4);

    _lossHistory.add(_currentLoss);
    if (_lossHistory.length > 50) _lossHistory.removeAt(0);

    _accuracyHistory.add(_currentAccuracy);
    if (_accuracyHistory.length > 50) _accuracyHistory.removeAt(0);

    if (_currentEpoch % 3 == 0) {
      _generateSamplePredictions();
    }
  }

  void _generateSamplePredictions() {
    final rand = math.Random();
    final bool highAccuracy = _currentAccuracy > 80.0;

    _samplePredictions = List.generate(8, (i) {
      final int groundTruth = (i * 2 + 1) % 10;
      final bool isCorrect = highAccuracy ? rand.nextDouble() > 0.12 : rand.nextDouble() > 0.55;
      final int predicted = isCorrect ? groundTruth : (groundTruth + rand.nextInt(8) + 1) % 10;
      final double confidence = isCorrect ? (0.75 + rand.nextDouble() * 0.24) : (0.40 + rand.nextDouble() * 0.35);

      return {
        'id': i,
        'digit': groundTruth,
        'predicted': predicted,
        'confidence': confidence,
        'isCorrect': isCorrect,
      };
    });
  }

  void addBlockToActiveModel(NeuralLayerBlock block) {
    final model = activeModel;
    model.blocks.add(block);
    if (model.blocks.length > 1) {
      model.connections.add([model.blocks.length - 2, model.blocks.length - 1]);
    }
    notifyListeners();
  }

  void removeBlockFromActiveModel(int index) {
    final model = activeModel;
    if (index >= 0 && index < model.blocks.length) {
      model.blocks.removeAt(index);
      model.connections.removeWhere((c) => c[0] == index || c[1] == index);

      for (final c in model.connections) {
        if (c[0] > index) c[0]--;
        if (c[1] > index) c[1]--;
      }
      notifyListeners();
    }
  }

  void updateBlockParams(int index, Map<String, dynamic> params) {
    final model = activeModel;
    if (index >= 0 && index < model.blocks.length) {
      model.blocks[index].parameters.addAll(params);
      notifyListeners();
    }
  }

  String createCustomModel({String name = 'My Custom Network'}) {
    final custom = NeuralModelDefinition(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: 'Custom',
      year: DateTime.now().year,
      author: 'You',
      shortDescription: 'Custom multi-stage neural network built with visual block editor.',
      isLocked: false,
      blocks: [
        NeuralLayerBlock(
          id: 'b_in',
          name: 'Inputs',
          type: LayerBlockType.input,
          tensorShape: '[N, 1, 28, 28]',
          parameters: {'channels': 1, 'height': 28, 'width': 28},
          description: 'Standard 28x28 grayscale image input tensor.',
          position: const Offset(40, 120),
        ),
        NeuralLayerBlock(
          id: 'b_conv',
          name: 'Conv2D + ReLU',
          type: LayerBlockType.conv2d,
          tensorShape: '[N, 32, 26, 26]',
          parameters: {'out_channels': 32, 'kernel_size': 3},
          description: 'Extracts 32 spatial feature maps using 3x3 kernels.',
          position: const Offset(240, 120),
        ),
        NeuralLayerBlock(
          id: 'b_pool',
          name: 'MaxPool',
          type: LayerBlockType.maxpool,
          tensorShape: '[N, 32, 13, 13]',
          parameters: {'kernel_size': 2, 'stride': 2},
          description: 'Downsamples spatial dimensions by half.',
          position: const Offset(430, 120),
        ),
        NeuralLayerBlock(
          id: 'b_flat',
          name: 'Flatten',
          type: LayerBlockType.flatten,
          tensorShape: '[N, 5408]',
          parameters: {'start_dim': 1},
          description: 'Flattens spatial channels into a 1D vector.',
          position: const Offset(610, 120),
        ),
        NeuralLayerBlock(
          id: 'b_out',
          name: 'Outputs',
          type: LayerBlockType.output,
          tensorShape: '[N, 10]',
          parameters: {'num_classes': 10},
          description: 'Final 10-class prediction vector.',
          position: const Offset(790, 120),
        ),
      ],
      connections: [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
      ],
    );

    _models.insert(1, custom);
    _selectedModelId = custom.id;
    notifyListeners();
    return custom.id;
  }

  bool importNnFile(String jsonContent) {
    try {
      final model = NeuralModelDefinition.fromNnFileString(jsonContent);
      _models.insert(1, model);
      _selectedModelId = model.id;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _trainingTimer?.cancel();
    super.dispose();
  }
}
