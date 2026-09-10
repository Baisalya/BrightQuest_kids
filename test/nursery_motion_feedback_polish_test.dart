import 'dart:io';

import 'package:brightquest_kids/features/nursery/nursery_lesson_feedback.dart';
import 'package:brightquest_kids/features/nursery/nursery_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nursery motion durations stay short and finite', () {
    for (final cue in NurseryMotionCue.values) {
      expect(
        NurseryMotionPolicy.duration(cue),
        lessThanOrEqualTo(const Duration(milliseconds: 700)),
        reason: cue.name,
      );
    }

    final source = File('lib/features/nursery/nursery_motion.dart')
        .readAsStringSync();
    expect(source, isNot(contains('.repeat(')));
    expect(source, isNot(contains('Timer.periodic')));
    expect(source, isNot(contains('repeat(reverse:')));
  });

  testWidgets('Nursery reactions are one-shot and settle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const NurseryMotionReveal(
                reducedMotion: false,
                child: Text('Ready'),
              ),
              const NurseryMotionReaction(
                trigger: 'success',
                cue: NurseryMotionCue.success,
                reducedMotion: false,
                child: Text('Success'),
              ),
              const NurseryLessonFeedbackPanel(
                message: 'Great job!',
                correct: true,
                reducedMotion: false,
              ),
              const NurseryCheerBurst(reducedMotion: false),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.bySemanticsLabel('Correct answer celebration'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OS disableAnimations makes Nursery motion immediate',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Column(
              children: [
                NurseryMotionReveal(
                  reducedMotion: false,
                  child: Text('Calm reveal'),
                ),
                NurseryMotionReaction(
                  trigger: 'retry',
                  cue: NurseryMotionCue.retry,
                  reducedMotion: false,
                  child: Text('Calm retry'),
                ),
                NurseryLessonFeedbackPanel(
                  message: 'Almost! Try again.',
                  correct: false,
                  reducedMotion: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Calm reveal'), findsOneWidget);
    expect(find.text('Calm retry'), findsOneWidget);
    expect(find.text('Almost! Try again.'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit reduced motion keeps feedback static and semantic',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NurseryLessonFeedbackPanel(
                message: 'Great remembering!',
                correct: true,
                reducedMotion: true,
              ),
              NurseryHintPanel(
                text: 'Look at the first sound.',
                reducedMotion: true,
              ),
              NurseryCheerBurst(reducedMotion: true),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Great remembering!'), findsOneWidget);
    expect(find.text('Look at the first sound.'), findsOneWidget);
    expect(find.bySemanticsLabel('Correct answer celebration'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
