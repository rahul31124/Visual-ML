class MissionModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String datasetType;
  final String problemType;
  final int maxNeurons;
  final int maxLayers;
  final double targetAccuracy;
  final int maxEpochsForThreeStars;
  final int maxEpochsForTwoStars;
  final List<String> allowedFeatures;
  final double initialNoise;
  final int starsEarned;
  final bool isCompleted;

  const MissionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.datasetType,
    this.problemType = 'classification',
    this.maxNeurons = 6,
    this.maxLayers = 3,
    required this.targetAccuracy,
    required this.maxEpochsForThreeStars,
    required this.maxEpochsForTwoStars,
    this.allowedFeatures = const ['X1', 'X2'],
    this.initialNoise = 0.05,
    this.starsEarned = 0,
    this.isCompleted = false,
  });

  MissionModel copyWith({
    int? starsEarned,
    bool? isCompleted,
  }) {
    return MissionModel(
      id: id,
      title: title,
      subtitle: subtitle,
      description: description,
      datasetType: datasetType,
      problemType: problemType,
      maxNeurons: maxNeurons,
      maxLayers: maxLayers,
      targetAccuracy: targetAccuracy,
      maxEpochsForThreeStars: maxEpochsForThreeStars,
      maxEpochsForTwoStars: maxEpochsForTwoStars,
      allowedFeatures: allowedFeatures,
      initialNoise: initialNoise,
      starsEarned: starsEarned ?? this.starsEarned,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
