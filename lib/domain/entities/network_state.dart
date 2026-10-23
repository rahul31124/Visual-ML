import '../../src/rust/api/neural_net.dart';

class NetworkState {
  final List<int> hiddenLayerNeurons;
  final String activation;
  final double learningRate;
  final double momentum;
  final String regularization;
  final double regRate;
  final String problemType;
  final String datasetType;
  final double noise;
  final int totalSamples;
  final int trainPercent;
  final int batchSize;
  final List<String> activeFeatures;
  final bool isTraining;
  final bool isPaused;
  final int currentEpoch;
  final double trainLoss;
  final double testLoss;
  final double trainAccuracy;
  final double testAccuracy;
  final List<double> lossHistoryTrain;
  final List<double> lossHistoryTest;
  final List<List<List<double>>> weights;
  final List<List<double>> biases;
  final List<double> decisionBoundary;
  final List<List<double>> neuronHeatmaps;
  final LossLandscape3D? lossLandscape3D;
  final List<DataPoint> trainPoints;
  final List<DataPoint> testPoints;

  const NetworkState({
    required this.hiddenLayerNeurons,
    this.activation = 'relu',
    this.learningRate = 0.03,
    this.momentum = 0.9,
    this.regularization = 'none',
    this.regRate = 0.001,
    this.problemType = 'classification',
    this.datasetType = 'circle',
    this.noise = 0.10,
    this.totalSamples = 200,
    this.trainPercent = 50,
    this.batchSize = 11,
    this.activeFeatures = const ['X1', 'X2'],
    this.isTraining = false,
    this.isPaused = false,
    this.currentEpoch = 0,
    this.trainLoss = 0.0,
    this.testLoss = 0.0,
    this.trainAccuracy = 0.0,
    this.testAccuracy = 0.0,
    this.lossHistoryTrain = const [],
    this.lossHistoryTest = const [],
    this.weights = const [],
    this.biases = const [],
    this.decisionBoundary = const [],
    this.neuronHeatmaps = const [],
    this.lossLandscape3D,
    this.trainPoints = const [],
    this.testPoints = const [],
  });

  NetworkState copyWith({
    List<int>? hiddenLayerNeurons,
    String? activation,
    double? learningRate,
    double? momentum,
    String? regularization,
    double? regRate,
    String? problemType,
    String? datasetType,
    double? noise,
    int? totalSamples,
    int? trainPercent,
    int? batchSize,
    List<String>? activeFeatures,
    bool? isTraining,
    bool? isPaused,
    int? currentEpoch,
    double? trainLoss,
    double? testLoss,
    double? trainAccuracy,
    double? testAccuracy,
    List<double>? lossHistoryTrain,
    List<double>? lossHistoryTest,
    List<List<List<double>>>? weights,
    List<List<double>>? biases,
    List<double>? decisionBoundary,
    List<List<double>>? neuronHeatmaps,
    LossLandscape3D? lossLandscape3D,
    List<DataPoint>? trainPoints,
    List<DataPoint>? testPoints,
  }) {
    return NetworkState(
      hiddenLayerNeurons: hiddenLayerNeurons ?? this.hiddenLayerNeurons,
      activation: activation ?? this.activation,
      learningRate: learningRate ?? this.learningRate,
      momentum: momentum ?? this.momentum,
      regularization: regularization ?? this.regularization,
      regRate: regRate ?? this.regRate,
      problemType: problemType ?? this.problemType,
      datasetType: datasetType ?? this.datasetType,
      noise: noise ?? this.noise,
      totalSamples: totalSamples ?? this.totalSamples,
      trainPercent: trainPercent ?? this.trainPercent,
      batchSize: batchSize ?? this.batchSize,
      activeFeatures: activeFeatures ?? this.activeFeatures,
      isTraining: isTraining ?? this.isTraining,
      isPaused: isPaused ?? this.isPaused,
      currentEpoch: currentEpoch ?? this.currentEpoch,
      trainLoss: trainLoss ?? this.trainLoss,
      testLoss: testLoss ?? this.testLoss,
      trainAccuracy: trainAccuracy ?? this.trainAccuracy,
      testAccuracy: testAccuracy ?? this.testAccuracy,
      lossHistoryTrain: lossHistoryTrain ?? this.lossHistoryTrain,
      lossHistoryTest: lossHistoryTest ?? this.lossHistoryTest,
      weights: weights ?? this.weights,
      biases: biases ?? this.biases,
      decisionBoundary: decisionBoundary ?? this.decisionBoundary,
      neuronHeatmaps: neuronHeatmaps ?? this.neuronHeatmaps,
      lossLandscape3D: lossLandscape3D ?? this.lossLandscape3D,
      trainPoints: trainPoints ?? this.trainPoints,
      testPoints: testPoints ?? this.testPoints,
    );
  }
}
