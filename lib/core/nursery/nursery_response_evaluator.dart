import 'nursery_content.dart';
import 'nursery_legacy_visual_aliases.dart';
import 'nursery_practice_generator.dart';

class NurseryEvaluation {
  const NurseryEvaluation({
    required this.correct,
    required this.response,
    this.misconceptionId,
  });

  final bool correct;
  final Object? response;
  final String? misconceptionId;
}

class NurseryActivityExplanation {
  const NurseryActivityExplanation({
    required this.text,
    this.visualTokens = const <String>[],
  });

  final String text;
  final List<String> visualTokens;
}

class NurseryResponseEvaluator {
  const NurseryResponseEvaluator();

  NurseryEvaluation evaluate(NurseryActivity activity, Object? response) =>
      _evaluateRule(
        activity.correctResponseRule,
        response,
        fallbackMisconception: 'nursery_${activity.interaction}_retry',
      );

  NurseryEvaluation evaluateGenerated(
    NurseryGeneratedPractice practice,
    Object? response,
  ) =>
      _evaluateRule(
        practice.correctResponseRule,
        response,
        fallbackMisconception: 'nursery_generated_retry',
      );

  NurseryEvaluation _evaluateRule(
    Map<String, dynamic> rule,
    Object? response, {
    required String fallbackMisconception,
  }) {
    final type = rule['type'];
    final correct = switch (type) {
      'choice' => _sameText(response, rule['value']),
      'pairMatch' => _sameStringMap(response, rule['pairs']),
      'sortBuckets' => _sameStringMap(response, rule['assignments']),
      'traceCheckpoints' => _sameCheckpointOrder(
          response,
          (rule['checkpointCount'] as num?)?.toInt() ?? 0,
        ),
      _ => false,
    };
    return NurseryEvaluation(
      correct: correct,
      response: response,
      misconceptionId: correct ? null : fallbackMisconception,
    );
  }

  List<NurseryOption> choicesFor(NurseryActivity activity) =>
      List<NurseryOption>.unmodifiable(
        _rotate(activity.options, activity.id),
      );

  List<NurseryOption> choicesForGenerated(NurseryGeneratedPractice practice) =>
      List<NurseryOption>.unmodifiable(practice.options);

  String responseLabel(Object? response) {
    if (response is Map) {
      return response.entries
          .map((entry) => '${entry.key} → ${entry.value}')
          .join(', ');
    }
    if (response is List) return response.join(', ');
    return response?.toString() ?? '';
  }

  String correctResponseLabel(NurseryActivity activity) =>
      _correctRuleLabel(activity.correctResponseRule);

  String correctGeneratedResponseLabel(NurseryGeneratedPractice practice) =>
      _correctRuleLabel(practice.correctResponseRule);

  NurseryActivityExplanation explanationFor(NurseryActivity activity) {
    final rule = activity.correctResponseRule;
    final answer = _correctRuleLabel(rule);
    final type = rule['type'];

    if (type == 'choice') {
      final sameFirstSoundMatch = RegExp(
        r'\b(?:word|picture)\s+starts\s+with\s+the\s+same\s+first\s+sound\s+as\s+([A-Za-z]+)',
        caseSensitive: false,
      ).firstMatch(activity.prompt);
      if (sameFirstSoundMatch != null) {
        final cueWord = sameFirstSoundMatch.group(1)!;
        return NurseryActivityExplanation(
          text: '$cueWord and $answer start with the same first sound.',
          visualTokens: <String>[cueWord, 'matches', answer],
        );
      }

      final firstLetterMatch = RegExp(
        r'\b(?:says|word\s+is)\s+([A-Za-z]+)\b.*\bfirst\s+letter\b',
        caseSensitive: false,
      ).firstMatch(activity.prompt);
      if (firstLetterMatch != null) {
        final word = firstLetterMatch.group(1)!;
        return NurseryActivityExplanation(
          text: '$word starts with $answer.',
          visualTokens: <String>[word, '→', answer],
        );
      }

      final startsWithMatch = RegExp(
        r'\b(?:starts|begins)\s+with\s+([A-Za-z])\b',
        caseSensitive: false,
      ).firstMatch(activity.prompt);
      if (startsWithMatch != null) {
        return NurseryActivityExplanation(
          text: 'The correct beginning letter is $answer.',
          visualTokens: <String>[answer],
        );
      }

      final promptLower = activity.prompt.toLowerCase();
      if (promptLower.contains('uppercase') ||
          promptLower.contains('big letter')) {
        return NurseryActivityExplanation(
          text: '$answer is the uppercase letter asked for.',
          visualTokens: <String>[answer],
        );
      }
      if (promptLower.contains('lowercase') ||
          promptLower.contains('small letter')) {
        return NurseryActivityExplanation(
          text: '$answer is the lowercase letter asked for.',
          visualTokens: <String>[answer],
        );
      }

      if (activity.skillId.startsWith('math_count_')) {
        return NurseryActivityExplanation(
          text: answer == '0'
              ? 'No objects are shown, so the count is 0.'
              : 'Counting each object once gives $answer.',
          visualTokens: <String>[answer],
        );
      }

      if (activity.skillId == 'math_add_objects' ||
          activity.skillId == 'math_add_numerals') {
        final numericAddition =
            RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(activity.prompt);
        if (numericAddition != null) {
          final left = numericAddition.group(1)!;
          final right = numericAddition.group(2)!;
          return NurseryActivityExplanation(
            text: '$left plus $right makes $answer.',
            visualTokens: <String>[left, '+', right, '=', answer],
          );
        }
        return NurseryActivityExplanation(
          text: 'Joining the two groups gives $answer objects.',
          visualTokens: <String>[answer],
        );
      }

      if (activity.skillId == 'math_missing_number') {
        return NurseryActivityExplanation(
          text: '$answer is the number that completes the counting order.',
          visualTokens: <String>[answer],
        );
      }

      if (activity.skillId == 'math_more_less') {
        return NurseryActivityExplanation(
          text: '$answer is the amount asked for after comparing both choices.',
          visualTokens: <String>[answer],
        );
      }

      if (activity.skillId == 'math_same_different') {
        return NurseryActivityExplanation(
          text:
              'The two things are $answer in the way this question asks us to compare them.',
          visualTokens: <String>[answer],
        );
      }

      if (activity.skillId.startsWith('math_numbers_')) {
        return NurseryActivityExplanation(
          text: '$answer is the numeral asked for.',
          visualTokens: <String>[answer],
        );
      }

      if (activity.skillId == 'knowledge_colours') {
        return NurseryActivityExplanation(
          text: 'The correct colour is $answer.',
          visualTokens: <String>[answer],
        );
      }
      if (activity.skillId == 'knowledge_shapes') {
        return NurseryActivityExplanation(
          text: 'The shape that matches the clue is $answer.',
          visualTokens: <String>[answer],
        );
      }
      if (activity.skillId == 'knowledge_animals') {
        return NurseryActivityExplanation(
          text: 'The animal that matches the clue is $answer.',
          visualTokens: <String>[answer],
        );
      }
      if (activity.skillId == 'knowledge_foods') {
        return NurseryActivityExplanation(
          text: 'The food choice that matches the clue is $answer.',
          visualTokens: <String>[answer],
        );
      }
      if (activity.skillId == 'knowledge_objects') {
        return NurseryActivityExplanation(
          text: 'The everyday object that matches the clue is $answer.',
          visualTokens: <String>[answer],
        );
      }
      if (activity.skillId == 'knowledge_body') {
        return NurseryActivityExplanation(
          text: 'The body part that matches the clue is $answer.',
          visualTokens: <String>[answer],
        );
      }
      if (activity.skillId == 'knowledge_routines') {
        return NurseryActivityExplanation(
          text: 'The helpful or safer routine is $answer.',
          visualTokens: <String>[answer],
        );
      }

      return NurseryActivityExplanation(
        text: 'The correct answer is $answer.',
        visualTokens: <String>[answer],
      );
    }

    if (type == 'pairMatch') {
      return NurseryActivityExplanation(
        text: 'These pairs belong together: $answer.',
      );
    }
    if (type == 'sortBuckets') {
      return NurseryActivityExplanation(
        text: 'These items belong in these groups: $answer.',
      );
    }
    if (type == 'traceCheckpoints') {
      return const NurseryActivityExplanation(
        text: 'You followed the guide dots in order.',
      );
    }

    return NurseryActivityExplanation(
      text: 'The correct answer is $answer.',
    );
  }

  String _correctRuleLabel(Map<String, dynamic> rule) {
    return switch (rule['type']) {
      'choice' => '${rule['value']}',
      'pairMatch' => responseLabel(rule['pairs']),
      'sortBuckets' => responseLabel(rule['assignments']),
      'traceCheckpoints' => 'the guide dots in order',
      _ => 'the matching answer',
    };
  }

  bool _sameText(Object? left, Object? right) =>
      left is String &&
      right is String &&
      nurseryCanonicalLegacyVisualValue(left) ==
          nurseryCanonicalLegacyVisualValue(right);

  bool _sameStringMap(Object? response, Object? expected) {
    if (response is! Map ||
        expected is! Map ||
        response.length != expected.length) {
      return false;
    }
    final normalizedResponse = <String, String>{};
    for (final entry in response.entries) {
      if (entry.key is! String || entry.value is! String) return false;
      normalizedResponse[
              nurseryCanonicalLegacyVisualValue(entry.key as String)] =
          nurseryCanonicalLegacyVisualValue(entry.value as String);
    }
    for (final entry in expected.entries) {
      if (entry.key is! String || entry.value is! String) return false;
      final key = nurseryCanonicalLegacyVisualValue(entry.key as String);
      final value = nurseryCanonicalLegacyVisualValue(entry.value as String);
      if (normalizedResponse[key] != value) return false;
    }
    return true;
  }

  bool _sameCheckpointOrder(Object? response, int count) {
    if (response is! List || count <= 0 || response.length != count) {
      return false;
    }
    for (var index = 0; index < count; index += 1) {
      if (response[index] is! num ||
          (response[index] as num).toInt() != index) {
        return false;
      }
    }
    return true;
  }

  List<NurseryOption> _rotate(List<NurseryOption> values, String seed) {
    if (values.length < 2) return values;
    final offset = seed.codeUnits.fold<int>(0, (sum, value) => sum + value) %
        values.length;
    return <NurseryOption>[
      ...values.skip(offset),
      ...values.take(offset),
    ];
  }
}
