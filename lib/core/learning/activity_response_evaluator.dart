import '../content/content_activity.dart';
import '../content/game_content.dart';
import '../gameplay/game_logic.dart';

class ActivityEvaluation {
  const ActivityEvaluation({
    required this.correct,
    required this.response,
    this.misconceptionId,
  });

  final bool correct;
  final Object? response;
  final String? misconceptionId;
}

/// One rule interpreter shared by lesson interactions and their tests.
///
/// Content stays declarative: the UI collects a response, while this class is
/// the only place that decides whether that response satisfies a pack rule.
class ActivityResponseEvaluator {
  const ActivityResponseEvaluator();

  ActivityEvaluation evaluate(ContentActivity activity, Object? response) {
    final rule = activity.correctResponseRule;
    final type = rule['type'];
    final correct = switch (type) {
      'exactNumber' => _sameNumber(response, rule['value']),
      'exactText' => _sameText(response, rule['value']),
      'exactTextCaseSensitive' =>
        _sameTextCaseSensitive(response, rule['value']),
      'selectedSlices' => _sameNumber(response, rule['value']),
      'orderedWords' => _sameList(response, rule['value']),
      'grammarParts' => _sameGrammar(response, rule),
      'reachGridGoal' => _reachesCodingGoal(activity, response),
      'experimentOutcome' => _sameIngredientSet(activity, response),
      _ => false,
    };
    return ActivityEvaluation(
      correct: correct,
      response: response,
      misconceptionId: correct ? null : _misconception(activity, response),
    );
  }

  List<Object?> choicesFor(ContentActivity activity) {
    final payloadChoices = activity.payload['choices'];
    if (payloadChoices is List && payloadChoices.isNotEmpty) {
      return List<Object?>.unmodifiable(payloadChoices);
    }
    if (activity.correctResponseRule['type'] == 'exactText' ||
        activity.correctResponseRule['type'] == 'exactTextCaseSensitive') {
      return _rotate(
        <Object?>[
          activity.correctResponseRule['value'],
          ...activity.distractors.map((value) => value.value),
        ],
        activity.id,
      );
    }
    return const <Object?>[];
  }

  String responseLabel(Object? response) {
    if (response is List<CodingCommand>) {
      return response.map(commandLabel).join(', ');
    }
    if (response is List) return response.join(' ');
    if (response is Map) {
      return response.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    }
    return '$response';
  }

  String correctResponseLabel(ContentActivity activity) {
    final rule = activity.correctResponseRule;
    if (rule['type'] == 'grammarParts') {
      return 'noun: ${rule['noun']}, verb: ${rule['verb']}, adjective: ${rule['adjective']}';
    }
    if (rule['type'] == 'reachGridGoal') {
      return 'a command sequence that reaches the goal';
    }
    if (rule['type'] == 'experimentOutcome') {
      return List<String>.from(
        activity.payload['requiredIngredients'] as List,
      ).join(' + ');
    }
    return responseLabel(rule['value']);
  }

  static String commandLabel(CodingCommand command) => switch (command) {
        CodingCommand.move => 'Move',
        CodingCommand.turnLeft => 'Turn left',
        CodingCommand.turnRight => 'Turn right',
        CodingCommand.repeatLast => 'Repeat',
      };

  bool _sameNumber(Object? left, Object? right) =>
      left is num && right is num && left.toDouble() == right.toDouble();

  bool _sameText(Object? left, Object? right) =>
      left is String &&
      right is String &&
      left.trim().toLowerCase() == right.trim().toLowerCase();

  bool _sameTextCaseSensitive(Object? left, Object? right) =>
      left is String && right is String && left.trim() == right.trim();

  bool _sameList(Object? response, Object? answer) {
    if (response is! List ||
        answer is! List ||
        response.length != answer.length) {
      return false;
    }
    for (var index = 0; index < answer.length; index += 1) {
      if (!_sameText('${response[index]}', '${answer[index]}')) return false;
    }
    return true;
  }

  bool _sameGrammar(Object? response, Map<String, dynamic> rule) {
    if (response is! Map) return false;
    for (final part in const <String>['noun', 'verb', 'adjective']) {
      if (!_sameText(response[part], rule[part])) return false;
    }
    return true;
  }

  bool _reachesCodingGoal(ContentActivity activity, Object? response) {
    if (response is! List<CodingCommand>) return false;
    final payload = activity.payload;
    final directionName = payload['startDirection'];
    final direction = FacingDirection.values.where(
      (value) => value.name == directionName,
    );
    if (direction.isEmpty) return false;
    final mission = CodingMission(
      id: activity.id,
      width: payload['width'] as int,
      height: payload['height'] as int,
      startX: payload['startX'] as int,
      startY: payload['startY'] as int,
      goalX: payload['goalX'] as int,
      goalY: payload['goalY'] as int,
      startDirection: direction.first,
      obstacles: Set<String>.from(payload['obstacles'] as List),
      maxCommands: payload['maxCommands'] as int,
      topicId: activity.topicId,
      difficulty: activity.difficulty,
    );
    return response.length <= mission.maxCommands &&
        runCodingMission(mission, response).success;
  }

  bool _sameIngredientSet(ContentActivity activity, Object? response) {
    if (response is! Iterable) return false;
    final selected = response.map((value) => '$value').toSet();
    final required = Set<String>.from(
      activity.payload['requiredIngredients'] as List,
    );
    return selected.length == required.length && selected.containsAll(required);
  }

  String _misconception(ContentActivity activity, Object? response) {
    for (final distractor in activity.distractors) {
      if (_deepEqual(distractor.value, response)) {
        return distractor.misconceptionId;
      }
    }
    return switch (activity.correctResponseRule['type']) {
      'selectedSlices' => 'fraction_slice_count',
      'orderedWords' => 'sentence_sequence',
      'grammarParts' => 'grammar_word_role',
      'reachGridGoal' => 'algorithm_trace_or_turn',
      'experimentOutcome' => 'science_experiment_mix',
      _ => 'rule_check_needed',
    };
  }

  bool _deepEqual(Object? left, Object? right) {
    if (left is num && right is num) return _sameNumber(left, right);
    if (left is String && right is String) return _sameText(left, right);
    if (left is List && right is List) return _sameList(left, right);
    return left == right;
  }

  List<Object?> _rotate(List<Object?> values, String seed) {
    final unique = <Object?>[];
    for (final value in values) {
      if (!unique.any((candidate) => _deepEqual(candidate, value))) {
        unique.add(value);
      }
    }
    if (unique.length < 2) return List<Object?>.unmodifiable(unique);
    final offset = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) %
        unique.length;
    return List<Object?>.unmodifiable(<Object?>[
      ...unique.skip(offset),
      ...unique.take(offset),
    ]);
  }
}
