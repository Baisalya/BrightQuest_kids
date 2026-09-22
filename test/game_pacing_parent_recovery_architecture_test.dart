import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('timed pacing is wired only to short-decision adventure games', () {
    for (final name in <String>[
      'math_market_screen.dart',
      'map_quest_screen.dart',
      'recycling_challenge_screen.dart',
      'science_lab_screen.dart',
    ]) {
      final source = File('lib/features/games/$name').readAsStringSync();
      expect(source, contains('GameTurnPacingPolicy'));
      expect(source, contains('GameTurnTimer('));
      expect(source, contains("'time_limit_exceeded'"));
      expect(source, contains('FeedbackService.wrongAndWait('));
      expect(source, contains('_answerInFlight'));
    }

    for (final name in <String>[
      'story_builder_screen.dart',
      'grammar_puzzle_screen.dart',
      'coding_maze_screen.dart',
      'fraction_pizza_screen.dart',
    ]) {
      final source = File('lib/features/games/$name').readAsStringSync();
      expect(source, isNot(contains('GameTurnTimer(')));
    }
  });

  test('timed feedback waits before manual wrong-answer continuation', () {
    final feedback =
        File('lib/core/services/feedback_service.dart').readAsStringSync();
    expect(feedback, contains('Future<void> wrongAndWait('));
    expect(feedback, contains('Future<void> correctAndWait('));
    expect(feedback, contains('minimumDuration'));
  });

  test('parent gate has confirmed setup, recovery and delayed fallback', () {
    final gate = File('lib/features/parent/parent_gate_screen.dart')
        .readAsStringSync();
    final controller = File('lib/core/state/game_controller.dart')
        .readAsStringSync();

    expect(gate, contains('Confirm PIN'));
    expect(gate, contains('Forgot PIN?'));
    expect(gate, contains('Save your recovery code'));
    expect(gate, contains('Start 24-hour reset'));
    expect(controller, contains('resetParentPinWithRecoveryCode'));
    expect(controller, contains('completeDelayedParentPinReset'));
    expect(controller, contains('parentPinResetDelay = Duration(hours: 24)'));
  });
}
