import 'package:brightquest_kids/core/content/game_content.dart';
import 'package:brightquest_kids/core/learning/activity_response_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const evaluator = ActivityResponseEvaluator();

  test('every bundled response rule has a working interactive evaluator', () {
    final repository = buildContentRepository();
    final classActivities = repository.packForClass(3).activities;

    final math = classActivities.firstWhere(
      (activity) => activity.gameId == 'math_market',
    );
    expect(evaluator.evaluate(math, 4).correct, isTrue);
    expect(evaluator.evaluate(math, 3).correct, isFalse);

    final fraction = classActivities.firstWhere(
      (activity) => activity.gameId == 'fraction_pizza',
    );
    expect(evaluator.evaluate(fraction, 2).correct, isTrue);
    expect(
      evaluator.evaluate(fraction, 1).misconceptionId,
      'fraction_slice_count',
    );

    final grammar = classActivities.firstWhere(
      (activity) => activity.gameId == 'grammar_puzzle',
    );
    expect(
      evaluator.evaluate(grammar, <String, String>{
        'noun': 'dog',
        'verb': 'runs',
        'adjective': 'brave',
      }).correct,
      isTrue,
    );

    final map = classActivities.firstWhere(
      (activity) => activity.gameId == 'map_quest',
    );
    expect(evaluator.evaluate(map, 'east').correct, isTrue);

    final science = classActivities.firstWhere(
      (activity) =>
          activity.gameId == 'science_lab' &&
          activity.correctResponseRule['type'] == 'exactText',
    );
    expect(evaluator.evaluate(science, 'Roots').correct, isTrue);

    final experiment = classActivities.firstWhere(
      (activity) =>
          activity.correctResponseRule['type'] == 'experimentOutcome' &&
          activity.payload['fallback'] == false,
    );
    expect(
      evaluator
          .evaluate(
            experiment,
            List<String>.from(
                experiment.payload['requiredIngredients'] as List),
          )
          .correct,
      isTrue,
    );

    final recycling = classActivities.firstWhere(
      (activity) => activity.gameId == 'recycling_challenge',
    );
    expect(evaluator.choicesFor(recycling), contains('Paper'));
    expect(evaluator.evaluate(recycling, 'Paper').correct, isTrue);

    final story = classActivities.firstWhere(
      (activity) => activity.gameId == 'story_builder',
    );
    expect(
      evaluator.evaluate(
        story,
        <String>['Ria', 'found', 'a', 'red', 'kite', 'near', 'the', 'tree'],
      ).correct,
      isTrue,
    );

    final coding = classActivities.firstWhere(
      (activity) => activity.id == 'c3_coding_maze_c3_code_1',
    );
    expect(
      evaluator.evaluate(
        coding,
        <CodingCommand>[CodingCommand.move, CodingCommand.move],
      ).correct,
      isTrue,
    );
    expect(
      evaluator
          .evaluate(coding, <CodingCommand>[CodingCommand.turnLeft]).correct,
      isFalse,
    );
  });
}
