import 'package:brightquest_kids/core/models/learner_stage.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/parent/parent_learning_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets('School parent report owns game diagnostics', (tester) async {
    final controller = GameController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: buildTestScope(
          controller: controller,
          child: const ParentLearningReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('parent_school_learning_report')),
      findsOneWidget,
    );
    expect(find.text('Adventure diagnostics'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('parent_adventure_diagnostic_math_market')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('adaptive level'), findsOneWidget);
    expect(find.text('Nursery overview'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nursery parent report stays separate from School diagnostics',
      (tester) async {
    final controller = GameController();
    await controller.load();
    controller.setLearnerStage(LearnerStage.nursery);

    await tester.pumpWidget(
      MaterialApp(
        home: buildTestScope(
          controller: controller,
          child: const ParentLearningReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('parent_nursery_learning_report')),
        findsOneWidget);
    expect(find.text('Nursery overview'), findsOneWidget);
    expect(find.text('Adventure diagnostics'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
