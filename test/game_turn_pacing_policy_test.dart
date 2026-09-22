import 'package:brightquest_kids/core/curriculum/curriculum_models.dart';
import 'package:brightquest_kids/core/learning/game_turn_pacing.dart';
import 'package:brightquest_kids/core/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = GameTurnPacingPolicy();

  LearningLevel level(LearningLevelType type) => LearningLevel(
        id: 'test-level-${type.name}',
        classNumber: 4,
        subject: SubjectWorld.maths,
        gameId: 'math_market',
        curriculumTopicId: 'test-topic',
        title: 'Test',
        summary: 'Test pacing',
        order: 1,
        difficulty: 2,
        type: type,
      );

  test('only short decision challenge and mastery games are timed', () {
    for (final gameId in <String>[
      'math_market',
      'map_quest',
      'recycling_challenge',
      'science_lab',
    ]) {
      final challenge = policy.forGame(
        gameId: gameId,
        learningLevel: level(LearningLevelType.challenge),
        endlessPractice: false,
      );
      final mastery = policy.forGame(
        gameId: gameId,
        learningLevel: level(LearningLevelType.mastery),
        endlessPractice: false,
      );
      expect(challenge.turnLimit, const Duration(seconds: 30));
      expect(mastery.turnLimit, const Duration(seconds: 25));
      expect(challenge.autoCommitSelection, isTrue);
      expect(challenge.autoAdvanceCorrect, isTrue);
      expect(challenge.manualAdvanceAfterWrong, isTrue);
    }
  });

  test('practice, endless and construction-heavy games remain untimed', () {
    expect(
      policy
          .forGame(
            gameId: 'math_market',
            learningLevel: level(LearningLevelType.practice),
            endlessPractice: false,
          )
          .isTimed,
      isFalse,
    );
    expect(
      policy
          .forGame(
            gameId: 'math_market',
            learningLevel: level(LearningLevelType.mastery),
            endlessPractice: true,
          )
          .isTimed,
      isFalse,
    );
    for (final gameId in <String>[
      'story_builder',
      'grammar_puzzle',
      'coding_maze',
      'fraction_pizza',
    ]) {
      expect(
        policy
            .forGame(
              gameId: gameId,
              learningLevel: level(LearningLevelType.mastery),
              endlessPractice: false,
            )
            .isTimed,
        isFalse,
      );
    }
  });
}
