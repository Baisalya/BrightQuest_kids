import '../content/content_repository.dart';
import '../curriculum/curriculum_models.dart';
import 'gameplay_activity_models.dart';
import 'mission_run_models.dart';
import 'mission_run_planner.dart';

/// Capacity-aware run shape for one Learning World level.
///
/// Step 4 gives every World family deterministic exact-tier variants while
/// retaining this policy as the fail-safe: if a future class/tier loses valid
/// content, the run shrinks instead of silently repeating Training in Game.
class MissionRunAllocationProfile {
  const MissionRunAllocationProfile({
    required this.trainingItemCount,
    required this.gameItemCount,
    required this.gameMechanics,
  });

  final int trainingItemCount;
  final int gameItemCount;

  /// Mechanics that the existing real-game screen for this family can render.
  /// Training may still use any supported mechanic exposed by the reusable
  /// lesson activity renderer.
  final Set<LearningGameMechanic> gameMechanics;

  bool allowsGameCandidate(MissionCandidate candidate) =>
      gameMechanics.isEmpty || gameMechanics.contains(candidate.mechanic);
}

class MissionRunAllocationPolicy {
  const MissionRunAllocationPolicy({
    this.maxTrainingItems = 5,
    this.maxGameItems = 5,
  })  : assert(maxTrainingItems >= 0),
        assert(maxGameItems > 0);

  final int maxTrainingItems;
  final int maxGameItems;

  MissionRunAllocationProfile forLevel({
    required ContentRepository repository,
    required LearningLevel level,
    MissionRunPlanner planner = const MissionRunPlanner(),
  }) {
    final candidates = planner.candidatesForLevel(
      repository: repository,
      level: level,
    );
    if (candidates.isEmpty) {
      throw StateError('No mission candidates are available for ${level.id}.');
    }

    final gameMechanics = _gameMechanicsFor(level.gameId);
    final gameEligible = candidates
        .where(
          (candidate) =>
              gameMechanics.isEmpty ||
              gameMechanics.contains(candidate.mechanic),
        )
        .toList(growable: false);
    if (gameEligible.isEmpty) {
      throw StateError(
        '${level.gameId} has no exact-tier candidate that its real-game '
        'renderer can consume for ${level.id}.',
      );
    }

    // Keep roughly half of a small pool for the real game, capped at five.
    // Larger generated pools retain the Step 2 5 Training + 5 Game shape.
    final halfPool = (candidates.length + 1) ~/ 2;
    final gameCount = _min3(maxGameItems, gameEligible.length, halfPool)
        .clamp(1, maxGameItems)
        .toInt();
    final trainingCapacity = candidates.length - gameCount;
    final trainingCount = trainingCapacity <= 0
        ? 0
        : trainingCapacity.clamp(0, maxTrainingItems).toInt();

    return MissionRunAllocationProfile(
      trainingItemCount: trainingCount,
      gameItemCount: gameCount,
      gameMechanics: gameMechanics,
    );
  }

  Set<LearningGameMechanic> _gameMechanicsFor(String gameId) =>
      switch (gameId) {
        'math_market' => const <LearningGameMechanic>{
            LearningGameMechanic.decision,
          },
        'fraction_pizza' => const <LearningGameMechanic>{
            LearningGameMechanic.construction,
          },
        'story_builder' => const <LearningGameMechanic>{
            LearningGameMechanic.construction,
          },
        'grammar_puzzle' => const <LearningGameMechanic>{
            LearningGameMechanic.sorting,
          },
        // The current Science Lab real-game quiz renderer consumes authored
        // choice questions. Experiment-mixer activities remain eligible for
        // Training and for the lab simulation stage, but are not forced through
        // the quiz model.
        'science_lab' => const <LearningGameMechanic>{
            LearningGameMechanic.decision,
          },
        'map_quest' => const <LearningGameMechanic>{
            LearningGameMechanic.decision,
          },
        'coding_maze' => const <LearningGameMechanic>{
            LearningGameMechanic.navigation,
          },
        'recycling_challenge' => const <LearningGameMechanic>{
            LearningGameMechanic.sorting,
          },
        _ => const <LearningGameMechanic>{},
      };

  int _min3(int a, int b, int c) {
    var value = a;
    if (b < value) value = b;
    if (c < value) value = c;
    return value;
  }
}
