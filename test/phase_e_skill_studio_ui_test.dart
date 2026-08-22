import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/learning/class_skill_studio_screen.dart';
import 'package:brightquest_kids/features/learning/lesson_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  testWidgets('Class Skill Studio is responsive and exposes competency paths',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = GameController();
    controller.setClass(3);
    controller.setTextScale(1.3);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _host(controller, const ClassSkillStudioScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Class 3 Skill Studio'), findsOneWidget);
    expect(find.text('Choose a skill to learn'), findsOneWidget);
    expect(find.text('Place value to 999'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'practice-only constructed response never records mastery evidence',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = GameController();
    // This test isolates evidence/mastery behavior; audio feedback is covered
    // separately and would otherwise leave its short delayed speech timer
    // pending in the fake-async widget-test zone.
    controller.setSoundEnabled(false);

    await tester.pumpWidget(
      _host(
        controller,
        const LessonFlowScreen.forCompetency(
          classNumber: 3,
          competencyId: 'c3_eng_short_composition',
          title: 'Short composition',
        ),
      ),
    );
    await tester.pump();

    // Objective -> explanation -> worked example -> guided interaction.
    for (var step = 0; step < 3; step += 1) {
      await tester.tap(find.text('Continue'));
      await tester.pump();
    }

    expect(find.textContaining('Practice only'), findsWidgets);
    const answer = 'One morning, I heard a soft bark near the gate.';
    await tester.tap(find.text(answer));
    await tester.pump();
    await tester.tap(find.text('Check my answer'));
    await tester.pump();

    expect(find.textContaining('Yes.'), findsOneWidget);
    expect(controller.attemptEvidence, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
