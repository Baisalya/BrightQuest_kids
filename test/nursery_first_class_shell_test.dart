import 'package:brightquest_kids/core/models/learner_stage.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets('Nursery is a root learner mode, not a Home shortcut',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = GameController();
    await controller.load();
    controller.setLearnerStage(LearnerStage.nursery);

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Nursery Learning Garden'), findsOneWidget);
    expect(find.byKey(const Key('nursery-primary-action')), findsOneWidget);
    expect(find.byKey(const Key('nursery_grown_up_area')), findsOneWidget);

    expect(find.bySemanticsLabel('Today'), findsNothing);
    expect(find.bySemanticsLabel('Worlds'), findsNothing);
    expect(find.bySemanticsLabel('Journey'), findsNothing);
    expect(find.bySemanticsLabel('Me'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing the active profile stage swaps the learner shell',
      (tester) async {
    final controller = GameController();
    await controller.load();
    controller.setLearnerStage(LearnerStage.nursery);

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();
    expect(find.text('Nursery Learning Garden'), findsOneWidget);

    controller.setLearnerStage(LearnerStage.school);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Today'), findsOneWidget);
    expect(find.text('Nursery Learning Garden'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nursery root keeps the grown-up area behind the existing gate',
      (tester) async {
    final controller = GameController();
    await controller.load();
    controller.setLearnerStage(LearnerStage.nursery);

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nursery_grown_up_area')));
    await tester.pumpAndSettle();

    expect(find.text('Create a parent PIN'), findsOneWidget);
    expect(find.text('4-digit PIN'), findsOneWidget);
  });
}
