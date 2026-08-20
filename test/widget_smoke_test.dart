import 'package:brightquest_kids/app/brightquest_app.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _scrollHomeUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  final homeScroll = find.byType(CustomScrollView);
  expect(homeScroll, findsOneWidget);

  for (var attempt = 0;
      attempt < 12 && target.evaluate().isEmpty;
      attempt += 1) {
    await tester.drag(homeScroll, const Offset(0, -320));
    await tester.pumpAndSettle();
  }

  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await tester.pumpAndSettle();
}

Future<void> _scrollGameUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  final gameList = find.byType(ListView);
  expect(gameList, findsOneWidget);

  for (var attempt = 0;
      attempt < 10 && target.evaluate().isEmpty;
      attempt += 1) {
    await tester.drag(gameList, const Offset(0, -280));
    await tester.pumpAndSettle();
  }

  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app shell renders core navigation and daily quests',
      (tester) async {
    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Adventure!'), findsOneWidget);
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Worlds'), findsOneWidget);
    expect(find.bySemanticsLabel('Progress'), findsOneWidget);
    expect(find.bySemanticsLabel('Parents'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile'), findsOneWidget);

    final dailyQuests = find.text('Daily learning quests');
    await _scrollHomeUntilVisible(tester, dailyQuests);
    expect(dailyQuests, findsOneWidget);
  });

  testWidgets(
      'Math Market opens from Quick Play and locks adaptive level for the run',
      (tester) async {
    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();

    final mathMarket = find.byKey(const Key('adventure_card_math_market'));
    await _scrollHomeUntilVisible(tester, mathMarket);
    await tester.tap(mathMarket);
    await tester.pumpAndSettle();

    expect(find.text('Math Market'), findsWidgets);
    expect(find.byKey(const Key('math_market_guide')), findsOneWidget);
    expect(find.textContaining('Adaptive level 1'), findsOneWidget);

    final hintButton = find.byKey(const Key('math_market_hint_button'));
    await _scrollGameUntilVisible(tester, hintButton);
    expect(hintButton, findsOneWidget);
  });

  testWidgets(
      'Math Market wide layout stays finite and overflow-free at 800x600',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();

    final mathMarket = find.byKey(const Key('adventure_card_math_market'));
    await _scrollHomeUntilVisible(tester, mathMarket);
    await tester.tap(mathMarket);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('math_market_guide')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Parents tab starts behind a PIN gate', (tester) async {
    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Parents'));
    await tester.pumpAndSettle();

    expect(find.text('Create a parent PIN'), findsOneWidget);
    expect(find.text('4-digit PIN'), findsOneWidget);
  });

  testWidgets('home cards remain overflow-free at a compact viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();

    final mathMarket = find.byKey(const Key('adventure_card_math_market'));
    await _scrollHomeUntilVisible(tester, mathMarket);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily limit blocks learning game launch', (tester) async {
    final controller = GameController();
    controller.setDailyTimeLimitMinutes(15);
    controller.setTimeLimitEnabled(true);
    controller.addStudySeconds(300);
    controller.addStudySeconds(300);
    controller.addStudySeconds(300);

    await tester.pumpWidget(BrightQuestApp(controller: controller));
    await tester.pumpAndSettle();

    final mathMarket = find.byKey(const Key('adventure_card_math_market'));
    await _scrollHomeUntilVisible(tester, mathMarket);
    await tester.tap(mathMarket);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('time_limit_break_title')), findsOneWidget);
  });

  testWidgets(
      'responsive shell stays overflow-free across phone tablet and desktop widths',
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
      await tester.pumpWidget(BrightQuestApp(controller: GameController()));
      await tester.pumpAndSettle();
      expect(find.text('Choose Your Adventure!'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Unexpected layout exception at $size');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
      'Windows-sized startup keeps accessibility controls on Material surfaces',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Comfort & accessibility'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
