import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../domain/entities/network_state.dart';
import '../../src/rust/api/neural_net.dart';

class LabProvider extends ChangeNotifier {
  NetworkState _state = const NetworkState(
    hiddenLayerNeurons: [4, 2],
    activation: 'tanh',
    learningRate: 0.05,
    momentum: 0.9,
    regularization: 'none',
    regRate: 0.001,
    problemType: 'classification',
    datasetType: 'circle',
    noise: 0.10,
    totalSamples: 200,
    trainPercent: 50,
    batchSize: 11,
    activeFeatures: ['X1', 'X2'],
  );

  Timer? _trainingTimer;
  bool _include3DLandscape = false;
  int _stepCounter = 0;

  NetworkState get state => _state;
  bool get include3DLandscape => _include3DLandscape;

  LabProvider() {
    initLab();
  }

  void setInclude3DLandscape(bool value) {
    _include3DLandscape = value;
    notifyListeners();
  }

  void initLab() {

    final int trainCount = (_state.totalSamples * _state.trainPercent / 100).round();
    final int testCount = math.max(10, _state.totalSamples - trainCount);

    final trainData = generateDataset(
      datasetType: _state.datasetType,
      count: BigInt.from(trainCount),
      noise: _state.noise,
    );
    final testData = generateDataset(
      datasetType: _state.datasetType,
      count: BigInt.from(testCount),
      noise: _state.noise,
    );

    _state = _state.copyWith(
      trainPoints: trainData,
      testPoints: testData,
      currentEpoch: 0,
      trainLoss: 0.0,
      testLoss: 0.0,
      trainAccuracy: 0.0,
      testAccuracy: 0.0,
      lossHistoryTrain: [],
      lossHistoryTest: [],
    );

    _rebuildRustNetwork();
  }

  void _rebuildRustNetwork() {
    final inputDim = _state.activeFeatures.length;
    final layers = <LayerConfig>[];

    int prevDim = inputDim;
    for (final neuronCount in _state.hiddenLayerNeurons) {
      layers.add(
        LayerConfig(
          inFeatures: BigInt.from(prevDim),
          outFeatures: BigInt.from(neuronCount),
          activation: _state.activation,
        ),
      );
      prevDim = neuronCount;
    }

    layers.add(
      LayerConfig(
        inFeatures: BigInt.from(prevDim),
        outFeatures: BigInt.from(1),
        activation: _state.problemType == 'classification' ? 'sigmoid' : 'linear',
      ),
    );

    final config = NetworkConfig(
      layers: layers,
      learningRate: _state.learningRate,
      momentum: _state.momentum,
      regularization: _state.regularization,
      regRate: _state.regRate,
      problemType: _state.problemType,
    );

    initNetwork(config: config);

    final initialMetrics = stepTraining(
      trainPoints: _state.trainPoints,
      testPoints: _state.testPoints,
      epochs: 0,
      includeLandscape: _include3DLandscape,
    );
    _applyTrainingResult(initialMetrics);
  }

  void _applyTrainingResult(TrainingEpochResult result) {
    final List<List<List<double>>> weights = [];
    for (final layer in result.weightsSummary) {
      final List<List<double>> layerW = [];
      for (final row in layer) {
        layerW.add(row.toList());
      }
      weights.add(layerW);
    }

    final List<List<double>> biases = [];
    for (final b in result.biasesSummary) {
      biases.add(b.toList());
    }

    final List<List<double>> neuronHeatmaps = [];
    for (final hm in result.neuronActivationsGrid) {
      neuronHeatmaps.add(hm.toList());
    }

    final trainLossHistory = List<double>.from(_state.lossHistoryTrain);
    final testLossHistory = List<double>.from(_state.lossHistoryTest);

    if (result.epoch > 0) {
      trainLossHistory.add(result.trainLoss);
      testLossHistory.add(result.testLoss);
      if (trainLossHistory.length > 120) {
        trainLossHistory.removeAt(0);
        testLossHistory.removeAt(0);
      }
    }

    _state = _state.copyWith(
      currentEpoch: result.epoch,
      trainLoss: result.trainLoss,
      testLoss: result.testLoss,
      trainAccuracy: result.trainAccuracy,
      testAccuracy: result.testAccuracy,
      lossHistoryTrain: trainLossHistory,
      lossHistoryTest: testLossHistory,
      weights: weights,
      biases: biases,
      decisionBoundary: result.decisionBoundary.toList(),
      neuronHeatmaps: neuronHeatmaps,
      lossLandscape3D: result.landscape3D,
    );

    notifyListeners();
  }

  void toggleTraining() {
    if (_state.isTraining) {
      pauseTraining();
    } else {
      startTraining();
    }
  }

  void startTraining() {
    _trainingTimer?.cancel();
    _state = _state.copyWith(isTraining: true, isPaused: false);
    notifyListeners();

    _trainingTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_state.isTraining || _state.isPaused) {
        timer.cancel();
        return;
      }

      _stepCounter++;

      final calcLandscape = _include3DLandscape && (_stepCounter % 15 == 0);

      final result = stepTraining(
        trainPoints: _state.trainPoints,
        testPoints: _state.testPoints,
        epochs: 4,
        includeLandscape: calcLandscape,
      );

      _applyTrainingResult(result);
    });
  }

  void pauseTraining() {
    _trainingTimer?.cancel();
    _trainingTimer = null;
    _state = _state.copyWith(isTraining: false, isPaused: true);
    notifyListeners();

    if (_include3DLandscape) {
      final result = stepTraining(
        trainPoints: _state.trainPoints,
        testPoints: _state.testPoints,
        epochs: 0,
        includeLandscape: true,
      );
      _applyTrainingResult(result);
    }
  }

  void stepOnce() {
    final result = stepTraining(
      trainPoints: _state.trainPoints,
      testPoints: _state.testPoints,
      epochs: 1,
      includeLandscape: _include3DLandscape,
    );
    _applyTrainingResult(result);
  }

  void reset() {
    pauseTraining();
    resetTraining();
    initLab();
  }

  void addHiddenLayer() {
    if (_state.hiddenLayerNeurons.length >= 6) return;
    final updated = List<int>.from(_state.hiddenLayerNeurons)..add(3);
    _state = _state.copyWith(hiddenLayerNeurons: updated);
    _rebuildRustNetwork();
  }

  void removeHiddenLayer() {
    if (_state.hiddenLayerNeurons.length <= 1) return;
    final updated = List<int>.from(_state.hiddenLayerNeurons)..removeLast();
    _state = _state.copyWith(hiddenLayerNeurons: updated);
    _rebuildRustNetwork();
  }

  void addNeuronToLayer(int layerIndex) {
    if (layerIndex >= _state.hiddenLayerNeurons.length) return;
    if (_state.hiddenLayerNeurons[layerIndex] >= 8) return;
    final updated = List<int>.from(_state.hiddenLayerNeurons);
    updated[layerIndex] += 1;
    _state = _state.copyWith(hiddenLayerNeurons: updated);
    _rebuildRustNetwork();
  }

  void removeNeuronFromLayer(int layerIndex) {
    if (layerIndex >= _state.hiddenLayerNeurons.length) return;
    if (_state.hiddenLayerNeurons[layerIndex] <= 1) return;
    final updated = List<int>.from(_state.hiddenLayerNeurons);
    updated[layerIndex] -= 1;
    _state = _state.copyWith(hiddenLayerNeurons: updated);
    _rebuildRustNetwork();
  }

  void setActivation(String act) {
    _state = _state.copyWith(activation: act);
    _rebuildRustNetwork();
  }

  void setLearningRate(double lr) {
    _state = _state.copyWith(learningRate: lr);
    _rebuildRustNetwork();
  }

  void setRegularization(String reg, double rate) {
    _state = _state.copyWith(regularization: reg, regRate: rate);
    _rebuildRustNetwork();
  }

  void setProblemType(String type) {
    _state = _state.copyWith(problemType: type);
    _rebuildRustNetwork();
  }

  void setDatasetType(String type) {
    pauseTraining();
    _state = _state.copyWith(datasetType: type);
    initLab();
  }

  void setNoise(double noise) {
    _state = _state.copyWith(noise: noise);
    initLab();
  }

  void toggleFeature(String feature) {
    final current = List<String>.from(_state.activeFeatures);
    if (current.contains(feature)) {
      if (current.length <= 1) return;
      current.remove(feature);
    } else {
      current.add(feature);
    }
    _state = _state.copyWith(activeFeatures: current);
    _rebuildRustNetwork();
  }

  void loadMissionConfig({
    required String datasetType,
    required String problemType,
    required List<String> features,
    required double noise,
    required int initialLayers,
    required int initialNeurons,
  }) {
    pauseTraining();
    _state = _state.copyWith(
      datasetType: datasetType,
      problemType: problemType,
      activeFeatures: features,
      noise: noise,
      hiddenLayerNeurons: List.filled(initialLayers, initialNeurons),
    );
    initLab();
  }

  void setTotalSamples(int total) {
    _state = _state.copyWith(totalSamples: total);
    notifyListeners();
  }

  void setTrainPercent(int percent) {
    _state = _state.copyWith(trainPercent: percent);
    notifyListeners();
  }

  void setBatchSize(int batchSize) {
    _state = _state.copyWith(batchSize: batchSize);
    notifyListeners();
  }

  void regenerateDataset() {
    pauseTraining();
    initLab();
  }

  void setManualWeight(int layerIdx, int row, int col, double val) {
    updateManualWeight(
      layerIdx: BigInt.from(layerIdx),
      row: BigInt.from(row),
      col: BigInt.from(col),
      val: val,
    );
    final result = stepTraining(
      trainPoints: _state.trainPoints,
      testPoints: _state.testPoints,
      epochs: 0,
      includeLandscape: true,
    );
    _applyTrainingResult(result);
  }

  void setManualBias(int layerIdx, int idx, double val) {
    updateManualBias(
      layerIdx: BigInt.from(layerIdx),
      idx: BigInt.from(idx),
      val: val,
    );
    final result = stepTraining(
      trainPoints: _state.trainPoints,
      testPoints: _state.testPoints,
      epochs: 0,
      includeLandscape: true,
    );
    _applyTrainingResult(result);
  }

  @override
  void dispose() {
    _trainingTimer?.cancel();
    super.dispose();
  }
}
