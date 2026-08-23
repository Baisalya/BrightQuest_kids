import 'package:brightquest_kids/core/learning/gameplay_activity_models.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const resolver = GameplayActivityResolver();

  test('all runtime Class 3-5 lesson activities resolve to a safe renderer',
      () {
    final repository = buildContentRepository();
    for (final classNumber in <int>[3, 4, 5]) {
      final activities = repository.activitiesForClass(classNumber);
      expect(activities, isNotEmpty);
      for (final activity in activities) {
        final fallbackExperiment =
            activity.correctResponseRule['type'] == 'experimentOutcome' &&
                activity.payload['fallback'] == true;
        final spec = resolver.resolve(activity);
        if (fallbackExperiment) {
          expect(spec.kind, LearningGameActivityKind.unsupported);
          continue;
        }
        expect(
          spec.isSupported,
          isTrue,
          reason:
              '${activity.id} (${activity.correctResponseRule['type']}) should have a renderer',
        );
        expect(spec.sceneGameId, isNotEmpty, reason: activity.id);
      }
    }
  });

  test('structured response rules choose genuinely different game families',
      () {
    final repository = buildContentRepository();
    final kinds = <String, LearningGameActivityKind>{};

    for (final activity in repository.activitiesForClass(4)) {
      kinds.putIfAbsent(
        '${activity.gameId}:${activity.correctResponseRule['type']}',
        () => resolver.resolve(activity).kind,
      );
    }

    expect(
      kinds['fraction_pizza:selectedSlices'],
      LearningGameActivityKind.fractionBuilder,
    );
    expect(
      kinds['story_builder:orderedWords'],
      LearningGameActivityKind.sentenceBuilder,
    );
    expect(
      kinds['grammar_puzzle:grammarParts'],
      LearningGameActivityKind.grammarSort,
    );
    expect(
      kinds['coding_maze:reachGridGoal'],
      LearningGameActivityKind.robotRoute,
    );
    expect(
      kinds['science_lab:experimentOutcome'],
      LearningGameActivityKind.experimentMixer,
    );
    expect(
      kinds['recycling_challenge:exactText'],
      LearningGameActivityKind.recyclingSort,
    );
  });

  test('case-sensitive authored choices are no longer left without a renderer',
      () {
    final repository = buildContentRepository();
    final activity = repository.activitiesForClass(3).firstWhere(
          (value) =>
              value.correctResponseRule['type'] == 'exactTextCaseSensitive',
        );

    final spec = resolver.resolve(activity);
    expect(spec.kind, LearningGameActivityKind.themedChoice);
    expect(spec.choiceValues, isNotEmpty);
  });

  test('Step 3 exposes mechanic capabilities independently from visual theme',
      () {
    final repository = buildContentRepository();
    final class4 = repository.activitiesForClass(4);

    LearningGameActivitySpec specFor(String gameId) => resolver.resolve(
          class4.firstWhere((activity) => activity.gameId == gameId),
        );

    expect(
      specFor('fraction_pizza').mechanic,
      LearningGameMechanic.construction,
    );
    expect(
      specFor('grammar_puzzle').mechanic,
      LearningGameMechanic.sorting,
    );
    expect(
      specFor('coding_maze').mechanic,
      LearningGameMechanic.navigation,
    );
    expect(
      specFor('science_lab').mechanic,
      anyOf(
        LearningGameMechanic.decision,
        LearningGameMechanic.simulation,
      ),
    );
    expect(
      specFor('recycling_challenge').usesDirectManipulation,
      isTrue,
    );
  });

  test('generic choice activities receive a world-specific play presentation',
      () {
    final repository = buildContentRepository();
    final class4 = repository.activitiesForClass(4);

    LearningGameActivitySpec firstChoiceForSubject(String subject) =>
        resolver.resolve(
          class4.firstWhere(
            (activity) =>
                activity.subject.toLowerCase() == subject &&
                resolver.resolve(activity).kind ==
                    LearningGameActivityKind.themedChoice,
          ),
        );

    expect(
      firstChoiceForSubject('maths').choicePresentation,
      LearningGameChoicePresentation.marketStalls,
    );
    expect(
      firstChoiceForSubject('english').choicePresentation,
      LearningGameChoicePresentation.storyTrail,
    );
    expect(
      firstChoiceForSubject('science').choicePresentation,
      LearningGameChoicePresentation.labScanner,
    );
  });
}
