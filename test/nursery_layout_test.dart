import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_screen.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  testWidgets('Nursery hub is overflow-free on phone tablet and Windows sizes',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = <Size>[
      Size(360, 640),
      Size(700, 800),
      Size(1024, 768),
      Size(1440, 900),
    ];
    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester
          .pumpWidget(_host(GameController(), const NurseryHomeScreen()));
      await tester.pump();
      expect(find.text('Nursery Learning Garden'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Nursery hub at $size');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Alphabet discovery exposes multiple animated picture words',
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
    expect(find.text('Let’s play!'), findsOneWidget);
    expect(find.text('Learn First'), findsOneWidget);
    await tester.tap(find.text('Learn First'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Explore letter words'), findsOneWidget);
    expect(find.text('A for Apple'), findsWidgets);
    expect(
      find.bySemanticsLabel('Apple picture. Tap to animate.'),
      findsOneWidget,
    );
    expect(find.text('Another word'), findsOneWidget);
    expect(find.text('Next letter'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nursery teaching flow is overflow-free across free-form widths',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = <Size>[
      Size(360, 640),
      Size(600, 700),
      Size(900, 700),
      Size(1400, 900),
    ];
    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _host(
          GameController(),
          const NurseryLessonScreen(skillId: 'math_add_objects'),
        ),
      );
      await tester.pump();
      expect(find.text('Let’s play!'), findsOneWidget);
      expect(find.text('Learn First'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
      expect(find.text('More games'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Nursery lesson at $size');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
  testWidgets('My World and thinking skills use the same game-board shell',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(
        GameController(),
        const NurseryLessonScreen(skillId: 'knowledge_colours'),
      ),
    );
    await tester.pump();
    expect(find.text('Let’s play!'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
    expect(find.text('More games'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        GameController(),
        const NurseryLessonScreen(skillId: 'thinking_patterns'),
      ),
    );
    await tester.pump();
    expect(find.text('Let’s play!'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
    expect(find.text('More games'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
