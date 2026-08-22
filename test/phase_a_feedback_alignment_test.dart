import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  testWidgets(
      'SUN transfer feedback explains S and never falls back to A/Apple',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(
        GameController(),
        const NurseryLessonScreen(skillId: 'alpha_uppercase'),
      ),
    );
    await tester.pump();

    expect(find.text('Choose your adventure'), findsOneWidget);
    final letterChallenge = find.text('Letter Challenge');
    expect(letterChallenge, findsOneWidget);
    await tester.ensureVisible(letterChallenge);
    await tester.pumpAndSettle();
    await tester.tap(letterChallenge);
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('The sign says SUN. Which first letter do you see?'),
      findsOneWidget,
    );
    final answerS = find.bySemanticsLabel('Answer S');
    expect(answerS, findsOneWidget);
    await tester.tap(answerS);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Why: S'), findsOneWidget);
    expect(find.text('SUN starts with S.'), findsOneWidget);
    expect(find.textContaining('A can begin Apple'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
