import 'package:flutter/foundation.dart';
import '../../data/models/mission_model.dart';
import '../../data/repositories/missions_repository.dart';

class MissionsProvider extends ChangeNotifier {
  List<MissionModel> _missions = MissionsRepository.getInitialMissions();
  String? _activeMissionId;

  List<MissionModel> get missions => _missions;
  String? get activeMissionId => _activeMissionId;

  MissionModel? get activeMission {
    if (_activeMissionId == null) return null;
    return _missions.firstWhere(
      (m) => m.id == _activeMissionId,
      orElse: () => _missions.first,
    );
  }

  int get totalStarsEarned =>
      _missions.fold(0, (sum, m) => sum + m.starsEarned);

  int get completedMissionsCount =>
      _missions.where((m) => m.isCompleted).length;

  void selectMission(String id) {
    _activeMissionId = id;
    notifyListeners();
  }

  void completeMission(String id, int epochsTaken, double accuracyAchieved) {
    final index = _missions.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final mission = _missions[index];
    if (accuracyAchieved < mission.targetAccuracy) return;

    int stars = 1;
    if (epochsTaken <= mission.maxEpochsForThreeStars) {
      stars = 3;
    } else if (epochsTaken <= mission.maxEpochsForTwoStars) {
      stars = 2;
    }

    if (stars > mission.starsEarned) {
      _missions[index] = mission.copyWith(
        starsEarned: stars,
        isCompleted: true,
      );
      notifyListeners();
    }
  }

  void resetAllProgress() {
    _missions = MissionsRepository.getInitialMissions();
    _activeMissionId = null;
    notifyListeners();
  }
}
