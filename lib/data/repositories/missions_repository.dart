import '../models/mission_model.dart';

class LabModeModel {
  final String id;
  final String title;
  final String datasetType;
  final String problemType;
  final bool is3D;

  const LabModeModel({
    required this.id,
    required this.title,
    required this.datasetType,
    required this.problemType,
    required this.is3D,
  });
}

class MissionsRepository {
  static List<MissionModel> getInitialMissions() {
    return [
      const MissionModel(
        id: 'mission_2d_regression',
        title: '2D Regression',
        subtitle: 'Linear Fitting',
        description:
            'Train a single perceptron or linear model to fit a continuous slope of data points.',
        datasetType: '2d_regression',
        problemType: 'regression',
        maxNeurons: 2,
        maxLayers: 1,
        targetAccuracy: 0.95,
        maxEpochsForThreeStars: 40,
        maxEpochsForTwoStars: 80,
        allowedFeatures: ['X1'],
        initialNoise: 0.04,
      ),
      const MissionModel(
        id: 'mission_single_step',
        title: 'Single-step Training',
        subtitle: 'Gradient Step Dynamics',
        description:
            'Observe how a single gradient descent step adjusts weights and reduces loss.',
        datasetType: 'single_step',
        problemType: 'regression',
        maxNeurons: 2,
        maxLayers: 1,
        targetAccuracy: 0.90,
        maxEpochsForThreeStars: 30,
        maxEpochsForTwoStars: 60,
        allowedFeatures: ['X1'],
        initialNoise: 0.02,
      ),
      const MissionModel(
        id: 'mission_keep_training',
        title: 'Keep Training',
        subtitle: 'Iterative Convergence',
        description:
            'Let the network train continuously to minimize mean squared error and reach optimal weights.',
        datasetType: 'keep_training',
        problemType: 'regression',
        maxNeurons: 3,
        maxLayers: 1,
        targetAccuracy: 0.95,
        maxEpochsForThreeStars: 50,
        maxEpochsForTwoStars: 90,
        allowedFeatures: ['X1'],
        initialNoise: 0.03,
      ),
      const MissionModel(
        id: 'mission_broken_line',
        title: 'Broken Line',
        subtitle: 'Piecewise Nonlinearity',
        description:
            'A single linear unit cannot fit a V-shaped line. Add hidden neurons with ReLU activation to fit piecewise curves.',
        datasetType: 'broken_line',
        problemType: 'regression',
        maxNeurons: 4,
        maxLayers: 1,
        targetAccuracy: 0.92,
        maxEpochsForThreeStars: 80,
        maxEpochsForTwoStars: 140,
        allowedFeatures: ['X1'],
        initialNoise: 0.04,
      ),
      const MissionModel(
        id: 'mission_w_line',
        title: 'W Line',
        subtitle: 'Multi-Bend Curve Fitting',
        description:
            'Fit a W-shaped double-trough curve using multiple hidden neurons to capture inflection points.',
        datasetType: 'w_line',
        problemType: 'regression',
        maxNeurons: 6,
        maxLayers: 2,
        targetAccuracy: 0.90,
        maxEpochsForThreeStars: 100,
        maxEpochsForTwoStars: 180,
        allowedFeatures: ['X1'],
        initialNoise: 0.04,
      ),
      const MissionModel(
        id: 'mission_initialization',
        title: 'Initialization',
        subtitle: 'Symmetry Breaking',
        description:
            'Observe how random weight initialization separates two simple clusters or non-linear curves.',
        datasetType: 'broken_line',
        problemType: 'regression',
        maxNeurons: 4,
        maxLayers: 1,
        targetAccuracy: 0.95,
        maxEpochsForThreeStars: 40,
        maxEpochsForTwoStars: 80,
        allowedFeatures: ['X1'],
        initialNoise: 0.04,
      ),
      const MissionModel(
        id: 'mission_xor',
        title: 'The XOR Problem',
        subtitle: 'The Minsky-Papert Proof',
        description:
            'A single linear perceptron cannot solve XOR. Add at least one hidden layer with 3-4 neurons.',
        datasetType: 'xor',
        problemType: 'classification',
        maxNeurons: 5,
        maxLayers: 2,
        targetAccuracy: 0.92,
        maxEpochsForThreeStars: 90,
        maxEpochsForTwoStars: 150,
        allowedFeatures: ['X1', 'X2'],
        initialNoise: 0.05,
      ),
      const MissionModel(
        id: 'mission_circle',
        title: 'Concentric Circles',
        subtitle: 'Radial Decision Boundaries',
        description:
            'Classify the inner core vs outer ring. Use a hidden layer or enable quadratic features.',
        datasetType: 'circle',
        problemType: 'classification',
        maxNeurons: 6,
        maxLayers: 2,
        targetAccuracy: 0.94,
        maxEpochsForThreeStars: 80,
        maxEpochsForTwoStars: 140,
        allowedFeatures: ['X1', 'X2', 'X1^2', 'X2^2'],
        initialNoise: 0.08,
      ),
      const MissionModel(
        id: 'mission_spiral',
        title: 'The Spiral Challenge',
        subtitle: 'Deep Manifold Untangling',
        description:
            'Classify two interlocking spirals with deep hidden layers.',
        datasetType: 'spiral',
        problemType: 'classification',
        maxNeurons: 12,
        maxLayers: 4,
        targetAccuracy: 0.90,
        maxEpochsForThreeStars: 250,
        maxEpochsForTwoStars: 400,
        allowedFeatures: ['X1', 'X2', 'X1^2', 'X2^2', 'sin(X1)', 'sin(X2)'],
        initialNoise: 0.04,
      ),
    ];
  }

  static List<LabModeModel> getLabModes() {
    return const [
      LabModeModel(
        id: 'lab_2d_regression',
        title: '2D Regression',
        datasetType: '2d_regression',
        problemType: 'regression',
        is3D: false,
      ),
      LabModeModel(
        id: 'lab_2d_classification',
        title: '2D Classification',
        datasetType: '2d_classification',
        problemType: 'classification',
        is3D: false,
      ),
      LabModeModel(
        id: 'lab_3d_regression',
        title: '3D Regression',
        datasetType: '3d_regression',
        problemType: 'regression',
        is3D: true,
      ),
      LabModeModel(
        id: 'lab_3d_classification',
        title: '3D Classification',
        datasetType: '3d_classification',
        problemType: 'classification',
        is3D: true,
      ),
    ];
  }
}
