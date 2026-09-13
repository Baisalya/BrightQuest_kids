import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/games/game_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Widget _gameLaunchHost(GameController controller) => buildTestScope(
      controller: controller,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('launch_math_market'),
                onPressed: () => openGame(context, 'math_market'),
                child: const Text('Launch Math Market'),
              ),
            ),
          ),
        ),
      ),
    );

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
  testWidgets(
      'app shell renders one focused Home action and learner navigation',
      (tester) async {
    await tester.pumpWidget(buildTestApp(GameController()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_primary_action')), findsOneWidget);
    expect(find.byKey(const Key('home_primary_action_button')), findsOneWidget);
    expect(find.byKey(const Key('home_daily_wins')), findsOneWidget);
    expect(find.bySemanticsLabel('Today'), findsOneWidget);
    expect(find.bySemanticsLabel('Worlds'), findsOneWidget);
    expect(find.bySemanticsLabel('Journey'), findsOneWidget);
    expect(find.bySemanticsLabel('Me'), findsOneWidget);
    expect(find.bySemanticsLabel('Grown-up area'), findsOneWidget);
    expect(find.bySemanticsLabel('Parents'), findsNothing);

    // The old competing Home catalogs are intentionally gone.
    expect(find.text('Explorer shortcuts'), findsNothing);
    expect(find.text('Explore by Subject / World'), findsNothing);
    expect(find.text('All Adventures'), findsNothing);
  });

  testWidgets(
      'Math Market still opens through the shared game router and locks adaptive level',
      (tester) async {
    await tester.pumpWidget(_gameLaunchHost(GameController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('launch_math_market')));
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

    await tester.pumpWidget(_gameLaunchHost(GameController()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch_math_market')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('math_market_guide')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grown-up utility starts behind the existing PIN gate',
      (tester) async {
    await tester.pumpWidget(buildTestApp(GameController()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Grown-up area'));
    await tester.pumpAndSettle();

    expect(find.text('Create a parent PIN'), findsOneWidget);
    expect(find.text('4-digit PIN'), findsOneWidget);
  });

  testWidgets('simplified Home remains overflow-free at a compact viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(GameController()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_primary_action')), findsOneWidget);
    expect(find.byKey(const Key('home_daily_wins')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily limit still blocks direct learning game launch',
      (tester) async {
    final controller = GameController();
    controller.setDailyTimeLimitMinutes(15);
    controller.setTimeLimitEnabled(true);
    controller.addStudySeconds(300);
    controller.addStudySeconds(300);
    controller.addStudySeconds(300);

    await tester.pumpWidget(_gameLaunchHost(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch_math_market')));
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
      await tester.pumpWidget(buildTestApp(GameController()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_primary_action')), findsOneWidget);
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

    await tester.pumpWidget(buildTestApp(GameController()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Me'));
    await tester.pumpAndSettle();

    expect(find.text('Comfort & accessibility'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
