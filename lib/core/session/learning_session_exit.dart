enum LearningSessionExitAction {
  continueNext,
  backToWorld,
}

class LearningSessionExit {
  const LearningSessionExit._({
    required this.action,
    this.nextLevelId,
  });

  factory LearningSessionExit.continueToLevel(String levelId) {
    if (levelId.isEmpty) {
      throw ArgumentError.value(levelId, 'levelId', 'must not be empty');
    }
    return LearningSessionExit._(
      action: LearningSessionExitAction.continueNext,
      nextLevelId: levelId,
    );
  }

  static const LearningSessionExit backToWorld = LearningSessionExit._(
    action: LearningSessionExitAction.backToWorld,
  );

  final LearningSessionExitAction action;
  final String? nextLevelId;
}
