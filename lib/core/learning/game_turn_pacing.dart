import '../curriculum/curriculum_models.dart';

/// Defines when a child-facing game turn should be time-boxed and how a
/// completed answer should move through feedback.
///
/// Timers are intentionally limited to short, single-decision challenge and
/// mastery games. Construction-heavy activities (story building, coding,
/// grammar assembly, experiments, etc.) remain untimed so the clock never
/// competes with thinking or accessibility needs.
class GameTurnPacingPolicy {
  const GameTurnPacingPolicy();

  static const Set<String> _quickTimedGames = <String>{
    'math_market',
    'map_quest',
    'recycling_challenge',
    'science_lab',
  };

  GameTurnPacing forGame({
    required String gameId,
    required LearningLevel? learningLevel,
    required bool endlessPractice,
  }) {
    if (endlessPractice ||
        learningLevel == null ||
        learningLevel.type == LearningLevelType.practice ||
        !_quickTimedGames.contains(gameId)) {
      return GameTurnPacing.untimed;
    }

    final limit = switch (learningLevel.type) {
      LearningLevelType.challenge => const Duration(seconds: 30),
      LearningLevelType.mastery => const Duration(seconds: 25),
      LearningLevelType.practice => null,
    };

    if (limit == null) return GameTurnPacing.untimed;
    return GameTurnPacing(
      turnLimit: limit,
      autoCommitSelection: true,
      autoAdvanceCorrect: true,
      manualAdvanceAfterWrong: true,
    );
  }
}

class GameTurnPacing {
  const GameTurnPacing({
    required this.turnLimit,
    required this.autoCommitSelection,
    required this.autoAdvanceCorrect,
    required this.manualAdvanceAfterWrong,
  });

  static const GameTurnPacing untimed = GameTurnPacing(
    turnLimit: null,
    autoCommitSelection: false,
    autoAdvanceCorrect: false,
    manualAdvanceAfterWrong: true,
  );

  final Duration? turnLimit;
  final bool autoCommitSelection;
  final bool autoAdvanceCorrect;
  final bool manualAdvanceAfterWrong;

  bool get isTimed => turnLimit != null;

  String get modeLabel => isTimed ? 'Timed challenge' : 'Take your time';
}
