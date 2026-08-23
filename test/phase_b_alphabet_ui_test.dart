import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  testWidgets('alphabet skill boards expose one obvious child play path',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final skillId in <String>[
      'alpha_uppercase',
      'alpha_letter_sounds',
      'alpha_beginning_sound',
      'alpha_listen_select',
    ]) {
      await tester.pumpWidget(
        _host(
          GameController(),
          NurseryLessonScreen(skillId: skillId),
        ),
      );
      await tester.pump();
      expect(find.text('Let’s play!'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
      expect(find.text('Learn First'), findsOneWidget);
      expect(find.text('More games'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('all alphabet skill boards are overflow-free at target sizes',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const skillIds = <String>[
      'alpha_uppercase',
      'alpha_lowercase',
      'alpha_case_match',
      'alpha_word_picture',
      'alpha_letter_sounds',
      'alpha_listen_select',
      'alpha_beginning_sound',
      'alpha_visual_discrimination',
      'alpha_trace_upper',
      'alpha_trace_lower',
    ];
    const sizes = <Size>[
      Size(360, 640),
      Size(700, 800),
      Size(1024, 768),
      Size(1440, 900),
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      for (final skillId in skillIds) {
        await tester.pumpWidget(
          _host(
            GameController(),
            NurseryLessonScreen(skillId: skillId),
          ),
        );
        await tester.pump();
        expect(find.text('Let’s play!'), findsOneWidget);
        expect(find.text('Next'), findsNothing);
        expect(
          tester.takeException(),
          isNull,
          reason: '$skillId at $size',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
      'letter discovery keeps picture semantics separate from card text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(
        GameController(),
        const NurseryLessonScreen(skillId: 'alpha_word_picture'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Learn First'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.bySemanticsLabel('Apple picture. Tap to animate.'),
      findsOneWidget,
    );
    expect(find.text('Another word'), findsOneWidget);
    expect(find.text('Next letter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
