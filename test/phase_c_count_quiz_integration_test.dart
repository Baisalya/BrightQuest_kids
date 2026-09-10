import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  testWidgets('Count game scores the visible objects and explains the same answer',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = GameController();

    await tester.pumpWidget(
      _host(
        controller,
        const NurseryLessonScreen(skillId: 'math_count_0_5'),
      ),
    );
    await tester.pump();

    final playNow = find.text('Play Now');
    await tester.ensureVisible(playNow);
    await tester.tap(playNow);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('How many apples are shown?'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.bySemanticsLabel('Answer 2'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Answer 2'));
    await tester.pump();

    expect(find.text('Why: 2'), findsOneWidget);
    expect(find.text('Counting each object once gives 2.'), findsOneWidget);
    expect(
      controller.nurseryAttemptEvidence.last.correct,
      isTrue,
    );
    expect(
      controller.nurseryAttemptEvidence.last.skillId,
      'math_count_0_5',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('My World road-safety quiz uses the precise safe routine',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = GameController();

    await tester.pumpWidget(
      _host(
        controller,
        const NurseryLessonScreen(skillId: 'knowledge_routines'),
      ),
    );
    await tester.pump();

    const prompt =
        'When crossing a road with an adult, which choice is safest?';
    await tester.ensureVisible(find.text('More games'));
    await tester.tap(find.text('More games'));
    await tester.pumpAndSettle();
    final starGame = find.text('Star Game');
    await tester.ensureVisible(starGame);
    await tester.tap(starGame);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(prompt), findsOneWidget);
    const answer = 'stay with the adult and wait until it is safe to cross';
    final answerFinder = find.bySemanticsLabel('Answer $answer');
    await tester.ensureVisible(answerFinder);
    await tester.tap(answerFinder);
    await tester.pump();

    expect(find.text('Why: $answer'), findsOneWidget);
    expect(find.text('The helpful or safer routine is $answer.'), findsOneWidget);
    expect(controller.nurseryAttemptEvidence.last.correct, isTrue);
    expect(
      controller.nurseryAttemptEvidence.last.skillId,
      'knowledge_routines',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Math and My World boards remain usable at phone and Windows sizes',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = <Size>[
      Size(360, 640),
      Size(700, 800),
      Size(1024, 768),
      Size(1440, 900),
    ];
    const skills = <String>[
      'math_numbers_0_5',
      'math_count_0_5',
      'math_number_quantity',
      'math_more_less',
      'math_add_objects',
      'knowledge_colours',
      'knowledge_shapes',
      'knowledge_animals',
      'knowledge_foods',
      'knowledge_objects',
      'knowledge_body',
      'knowledge_routines',
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      for (final skillId in skills) {
        await tester.pumpWidget(
          _host(
            GameController(),
            NurseryLessonScreen(skillId: skillId),
          ),
        );
        await tester.pump();
        expect(find.text('Let’s play!'), findsOneWidget);
        expect(find.text('Next'), findsNothing);
        expect(tester.takeException(), isNull, reason: '$skillId at $size');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });
}
