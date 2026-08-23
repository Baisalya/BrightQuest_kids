import '../content/content_activity.dart';
import 'activity_response_evaluator.dart';
import 'gameplay_activity_models.dart';

/// Converts an authored [ContentActivity] into a safe gameplay capability.
///
/// The resolver never infers educational facts from prompt text and never
/// changes the authored correctness rule. It opts into a richer renderer only
/// when the existing activity payload contains the fields that mechanic needs.
class GameplayActivityResolver {
  const GameplayActivityResolver();

  static const ActivityResponseEvaluator _evaluator =
      ActivityResponseEvaluator();

  LearningGameActivitySpec resolve(ContentActivity activity) {
    final ruleType = activity.correctResponseRule['type'];
    final theme = _themeFor(activity);
    final sceneGameId = _sceneFor(activity, theme);
    final choicePresentation = _choicePresentationFor(theme);

    LearningGameActivitySpec build(
      LearningGameActivityKind kind,
      LearningGameMechanic mechanic, {
      List<Object?> choices = const <Object?>[],
      String? unsupportedReason,
    }) =>
        LearningGameActivitySpec(
          kind: kind,
          mechanic: mechanic,
          theme: theme,
          sceneGameId: sceneGameId,
          choiceValues: choices,
          choicePresentation: choicePresentation,
          unsupportedReason: unsupportedReason,
        );

    if (ruleType == 'selectedSlices' && _hasFractionPayload(activity)) {
      return build(
        LearningGameActivityKind.fractionBuilder,
        LearningGameMechanic.construction,
      );
    }

    if (ruleType == 'orderedWords' && _hasWordPayload(activity)) {
      return build(
        LearningGameActivityKind.sentenceBuilder,
        LearningGameMechanic.construction,
      );
    }

    if (ruleType == 'grammarParts' && _hasGrammarPayload(activity)) {
      return build(
        LearningGameActivityKind.grammarSort,
        LearningGameMechanic.sorting,
      );
    }

    if (ruleType == 'reachGridGoal' && _hasCodingPayload(activity)) {
      return build(
        LearningGameActivityKind.robotRoute,
        LearningGameMechanic.navigation,
      );
    }

    if (ruleType == 'experimentOutcome' && _hasExperimentPayload(activity)) {
      return build(
        LearningGameActivityKind.experimentMixer,
        LearningGameMechanic.simulation,
      );
    }

    final choices = _evaluator.choicesFor(activity);
    if ((ruleType == 'exactNumber' ||
            ruleType == 'exactText' ||
            ruleType == 'exactTextCaseSensitive') &&
        choices.isNotEmpty) {
      final recycling = activity.gameId == 'recycling_challenge' &&
          activity.payload['name'] is String &&
          activity.payload['emoji'] is String &&
          activity.payload['bin'] is String;
      return build(
        recycling
            ? LearningGameActivityKind.recyclingSort
            : LearningGameActivityKind.themedChoice,
        recycling
            ? LearningGameMechanic.sorting
            : LearningGameMechanic.decision,
        choices: choices,
      );
    }

    return build(
      LearningGameActivityKind.unsupported,
      LearningGameMechanic.unavailable,
      unsupportedReason:
          'The authored response rule does not expose enough structured data for an interactive renderer.',
    );
  }

  bool _hasFractionPayload(ContentActivity activity) {
    final total = activity.payload['totalSlices'];
    final value = activity.correctResponseRule['value'];
    return total is int && total > 0 && value is num;
  }

  bool _hasWordPayload(ContentActivity activity) {
    final words = activity.payload['words'];
    final answer = activity.correctResponseRule['value'];
    return words is List &&
        words.isNotEmpty &&
        words.every((value) => value is String) &&
        answer is List &&
        answer.isNotEmpty;
  }

  bool _hasGrammarPayload(ContentActivity activity) {
    final sentence = activity.payload['sentence'];
    final rule = activity.correctResponseRule;
    return sentence is String &&
        sentence.trim().isNotEmpty &&
        rule['noun'] is String &&
        rule['verb'] is String &&
        rule['adjective'] is String;
  }

  bool _hasCodingPayload(ContentActivity activity) {
    final payload = activity.payload;
    final direction = payload['startDirection'];
    return payload['width'] is int &&
        (payload['width'] as int) > 0 &&
        payload['height'] is int &&
        (payload['height'] as int) > 0 &&
        payload['startX'] is int &&
        payload['startY'] is int &&
        payload['goalX'] is int &&
        payload['goalY'] is int &&
        direction is String &&
        const <String>['north', 'east', 'south', 'west'].contains(direction) &&
        payload['obstacles'] is List &&
        payload['maxCommands'] is int &&
        (payload['maxCommands'] as int) > 0;
  }

  bool _hasExperimentPayload(ContentActivity activity) {
    final required = activity.payload['requiredIngredients'];
    return required is List &&
        required.isNotEmpty &&
        required.every((value) => value is String);
  }

  LearningGameTheme _themeFor(ContentActivity activity) {
    if (activity.gameId == 'fraction_pizza' ||
        activity.gameId == 'math_market') {
      return LearningGameTheme.maths;
    }
    if (activity.gameId == 'story_builder' ||
        activity.gameId == 'grammar_puzzle') {
      return LearningGameTheme.story;
    }
    if (activity.gameId == 'science_lab') {
      return LearningGameTheme.science;
    }
    if (activity.gameId == 'recycling_challenge') {
      return LearningGameTheme.nature;
    }
    if (activity.gameId == 'map_quest') {
      return LearningGameTheme.map;
    }
    if (activity.gameId == 'coding_maze') {
      return LearningGameTheme.coding;
    }

    return switch (activity.subject.toLowerCase()) {
      'maths' => LearningGameTheme.maths,
      'english' => LearningGameTheme.story,
      'science' => LearningGameTheme.science,
      'evs' => LearningGameTheme.nature,
      'social' => LearningGameTheme.map,
      'coding' => LearningGameTheme.coding,
      _ => LearningGameTheme.neutral,
    };
  }

  LearningGameChoicePresentation _choicePresentationFor(
    LearningGameTheme theme,
  ) =>
      switch (theme) {
        LearningGameTheme.maths => LearningGameChoicePresentation.marketStalls,
        LearningGameTheme.story => LearningGameChoicePresentation.storyTrail,
        LearningGameTheme.science => LearningGameChoicePresentation.labScanner,
        LearningGameTheme.nature => LearningGameChoicePresentation.ecoTrail,
        LearningGameTheme.map => LearningGameChoicePresentation.mapExpedition,
        LearningGameTheme.coding => LearningGameChoicePresentation.robotConsole,
        LearningGameTheme.neutral => LearningGameChoicePresentation.questCards,
      };

  String _sceneFor(
    ContentActivity activity,
    LearningGameTheme theme,
  ) {
    if (activity.gameId != 'skill_studio' && activity.gameId.isNotEmpty) {
      return activity.gameId;
    }
    return switch (theme) {
      LearningGameTheme.maths => 'math_market',
      LearningGameTheme.story => 'story_builder',
      LearningGameTheme.science => 'science_lab',
      LearningGameTheme.nature => 'recycling_challenge',
      LearningGameTheme.map => 'map_quest',
      LearningGameTheme.coding => 'coding_maze',
      LearningGameTheme.neutral => 'rewards_room',
    };
  }
}
