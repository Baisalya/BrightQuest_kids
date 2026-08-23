import 'package:brightquest_kids/core/learning/activity_response_evaluator.dart';
import 'package:brightquest_kids/core/learning/contextual_feedback_engine.dart';
import 'package:brightquest_kids/core/learning/contextual_feedback_models.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_resolver.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_models.dart';
import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/features/learning/gameplay/learning_game_guidance.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const engine = ContextualFeedbackEngine();
  const resolver = GameplayActivityResolver();

  test('correct feedback keeps authored explanation and world identity', () {
    final repository = buildContentRepository();
    final activity = repository.activityById('c3_math_market_q01')!;
    final spec = resolver.resolve(activity);
    final evaluation = ActivityEvaluation(
      correct: true,
      response: activity.correctResponseRule['value'],
    );

    final feedback = engine.build(
      activity: activity,
      spec: spec,
      evaluation: evaluation,
      attemptNumber: 1,
      revealedHintCount: 0,
      hasUnrevealedHint: false,
      rescueAvailable: true,
    );

    expect(feedback.correct, isTrue);
    expect(feedback.stage, ContextualFeedbackStage.success);
    expect(feedback.headline, contains('Kingdom'));
    expect(feedback.message, startsWith('Yes.'));
    expect(feedback.message, contains(activity.explanation));
    expect(feedback.suggestHint, isFalse);
  });

  test('wrong feedback coaches the misconception without revealing the answer',
      () {
    final repository = buildContentRepository();
    final activity = repository.activityById('c3_math_market_q01')!;
    final spec = resolver.resolve(activity);
    final wrong = activity.distractors.first;
    final evaluation = const ActivityResponseEvaluator().evaluate(
      activity,
      wrong.value,
    );
    final correctLabel =
        const ActivityResponseEvaluator().correctResponseLabel(activity);

    final feedback = engine.build(
      activity: activity,
      spec: spec,
      evaluation: evaluation,
      attemptNumber: 1,
      revealedHintCount: 0,
      hasUnrevealedHint: true,
      rescueAvailable: true,
    );

    expect(feedback.correct, isFalse);
    expect(feedback.stage, ContextualFeedbackStage.nudge);
    expect(feedback.cue, ContextualFeedbackCue.calculate);
    expect(feedback.strategy, contains('operation'));
    expect(feedback.message, isNot(contains(activity.explanation)));
    expect(feedback.message, isNot(contains(correctLabel)));
    expect(feedback.suggestHint, isTrue);
  });

  test('legacy LessonEngine feedback boundary delegates to safe coaching', () {
    final repository = buildContentRepository();
    final activity = repository.activityById('c3_math_market_q01')!;
    final wrong = activity.distractors.first.value;

    final text = const LessonEngine().feedbackFor(
      activity: activity,
      correct: false,
      selectedAnswer: wrong,
    );

    expect(text, isNot(contains(activity.explanation)));
    expect(text, contains('operation'));
  });

  test('repeated misses escalate from strategy to authored power-up', () {
    final repository = buildContentRepository();
    final activity = repository.activityById('c3_math_market_q01')!;
    final spec = resolver.resolve(activity);
    final evaluation = const ActivityResponseEvaluator().evaluate(
      activity,
      activity.distractors.first.value,
    );

    final second = engine.build(
      activity: activity,
      spec: spec,
      evaluation: evaluation,
      attemptNumber: 2,
      revealedHintCount: 1,
      hasUnrevealedHint: false,
      rescueAvailable: true,
    );
    final third = engine.build(
      activity: activity,
      spec: spec,
      evaluation: evaluation,
      attemptNumber: 3,
      revealedHintCount: 1,
      hasUnrevealedHint: false,
      rescueAvailable: true,
    );

    expect(second.stage, ContextualFeedbackStage.strategy);
    expect(second.suggestRescue, isTrue);
    expect(third.stage, ContextualFeedbackStage.powerUp);
    expect(third.headline.toLowerCase(), contains('power-up'));
  });

  test(
      'independent play hides clues before the attempt but can use them after a miss',
      () {
    const guidance = LearningGameGuidance(
      mode: LearningGamePlayMode.solo,
      hints: <String>['Authored clue'],
      rescueText: 'Authored reteach strategy',
    );

    expect(guidance.allowsCoachBeforeAttempt, isFalse);
    expect(guidance.allowsHintsAfterMiss, isTrue);
    expect(guidance.allowsRescueAfterMiss, isTrue);
  });

  test(
      'all bundled Class 3-5 activities receive deterministic non-empty feedback',
      () {
    final repository = buildContentRepository();
    for (final classNumber in <int>[3, 4, 5]) {
      for (final activity in repository.activitiesForClass(classNumber)) {
        final spec = resolver.resolve(activity);
        final correct = ActivityEvaluation(
          correct: true,
          response: activity.correctResponseRule['value'],
        );
        final success = engine.build(
          activity: activity,
          spec: spec,
          evaluation: correct,
          attemptNumber: 1,
          revealedHintCount: 0,
          hasUnrevealedHint: false,
          rescueAvailable: true,
        );
        final miss = engine.build(
          activity: activity,
          spec: spec,
          evaluation: const ActivityEvaluation(
            correct: false,
            response: '__step6_miss__',
            misconceptionId: 'rule_check_needed',
          ),
          attemptNumber: 1,
          revealedHintCount: 0,
          hasUnrevealedHint: activity.hints.isNotEmpty,
          rescueAvailable: true,
        );

        expect(success.message.trim(), isNotEmpty, reason: activity.id);
        expect(success.headline.trim(), isNotEmpty, reason: activity.id);
        expect(miss.message.trim(), isNotEmpty, reason: activity.id);
        expect(miss.strategy.trim(), isNotEmpty, reason: activity.id);
        expect(miss.message, isNot(contains(activity.explanation)),
            reason: activity.id);
        expect(spec.theme, isA<LearningGameTheme>(), reason: activity.id);
      }
    }
  });
}
