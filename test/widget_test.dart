import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets('BrightQuest app boots with the project root widget',
      (tester) async {
    await tester.pumpWidget(buildTestApp(GameController()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_primary_action')), findsOneWidget);
    expect(find.bySemanticsLabel('Today'), findsOneWidget);
    expect(find.bySemanticsLabel('Grown-up area'), findsOneWidget);
  });
}
