import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets('Journey stays child-friendly and keeps analytics out',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = GameController();
    await controller.load();

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Journey'));
    await tester.pumpAndSettle();

    expect(find.text('My Journey'), findsOneWidget);
    expect(find.text('Your worlds'), findsOneWidget);
    expect(find.byKey(const Key('journey_hero')), findsOneWidget);
    expect(find.text('Adventure mastery'), findsNothing);
    expect(find.textContaining('Accuracy'), findsNothing);
    expect(find.textContaining('Adaptive D'), findsNothing);
    expect(find.textContaining('hints'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me owns one reward doorway and opens the single Rewards Room',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = GameController();
    await controller.load();

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Me'));
    await tester.pumpAndSettle();

    expect(find.text('My Space'), findsOneWidget);
    expect(find.text('My rewards'), findsOneWidget);
    expect(find.byKey(const Key('profile_rewards_card')), findsOneWidget);
    expect(find.text('Achievements'), findsNothing);
    expect(find.text('Cosmetics owned'), findsNothing);

    final rewardsButton = find.byKey(const Key('open_rewards_from_profile'));
    await tester.ensureVisible(rewardsButton);
    await tester.pumpAndSettle();
    await tester.tap(rewardsButton);
    await tester.pumpAndSettle();

    expect(find.text('Rewards Room'), findsOneWidget);
    expect(find.byKey(const Key('rewards_room_hero')), findsOneWidget);
    expect(find.text('My loadout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
