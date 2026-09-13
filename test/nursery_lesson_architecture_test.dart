import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nursery lesson screen remains an orchestration boundary', () {
    final screen = File('lib/features/nursery/nursery_lesson_screen.dart')
        .readAsStringSync();

    expect(screen.split('\n').length, lessThan(750));
    expect(screen, contains('NurseryTeachingStage('));
    expect(screen, contains('NurseryActivityStage('));
    expect(screen, contains('NurseryReviewStage('));
    expect(screen, contains('recordNurseryEvidence('));
    expect(screen, contains('_submitActivity('));
    expect(screen, contains('_submitGenerated('));

    expect(screen, isNot(contains('class _GameSceneBanner')));
    expect(screen, isNot(contains('class _ReviewBody')));
    expect(screen, isNot(contains('class _LetterDiscoveryShowcase')));
    expect(screen, isNot(contains('class _AnswerExplanation')));
  });

  test('lesson stages stay presentation-only and do not mutate progress', () {
    final stageFiles = <String>[
      'lib/features/nursery/nursery_lesson_teaching.dart',
      'lib/features/nursery/nursery_lesson_activity.dart',
      'lib/features/nursery/nursery_lesson_review.dart',
      'lib/features/nursery/nursery_lesson_feedback.dart',
      'lib/features/nursery/nursery_motion.dart',
    ];

    for (final path in stageFiles) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('BrightQuestScope')), reason: path);
      expect(source, isNot(contains('recordNurseryEvidence')), reason: path);
      expect(source, isNot(contains('NurseryResponseEvaluator')), reason: path);
      expect(source, isNot(contains('NurseryReviewSeedPlanner')), reason: path);
      expect(source, isNot(contains('NurseryPracticeGenerator')), reason: path);
    }
  });

  test('stage responsibilities are separated into explicit components', () {
    final teaching = File('lib/features/nursery/nursery_lesson_teaching.dart')
        .readAsStringSync();
    final activity = File('lib/features/nursery/nursery_lesson_activity.dart')
        .readAsStringSync();
    final review = File('lib/features/nursery/nursery_lesson_review.dart')
        .readAsStringSync();
    final feedback = File('lib/features/nursery/nursery_lesson_feedback.dart')
        .readAsStringSync();
    final motion =
        File('lib/features/nursery/nursery_motion.dart').readAsStringSync();

    expect(teaching, contains('class NurseryTeachingStage'));
    expect(teaching, contains('class NurseryLetterDiscoveryShowcase'));
    expect(teaching, contains('class NurseryWorkedExampleVisual'));

    expect(activity, contains('class NurseryActivityStage'));
    expect(activity, contains('class NurseryGameSceneBanner'));
    expect(activity, contains('NurseryActivityInteraction('));

    expect(review, contains('class NurseryReviewStage'));
    expect(review, contains("'Memory Game'"));

    expect(feedback, contains('class NurseryLessonFeedbackPanel'));
    expect(feedback, contains('class NurseryHintPanel'));
    expect(feedback, contains('class NurseryCheerBurst'));
    expect(feedback, contains('class NurseryAnswerExplanation'));

    expect(motion, contains('class NurseryMotionPolicy'));
    expect(motion, contains('class NurseryMotionReaction'));
    expect(motion, contains('class NurseryMotionReveal'));
    expect(motion, isNot(contains('.repeat(')));
    expect(motion, isNot(contains('Timer.periodic')));
  });
}
