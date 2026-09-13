import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/widgets/bright_adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  test('adaptive metrics classify usable surfaces without OS assumptions', () {
    final phone = BrightLayoutMetrics.fromSize(const Size(390, 700));
    final tablet = BrightLayoutMetrics.fromSize(const Size(700, 800));
    final freeform = BrightLayoutMetrics.fromSize(const Size(1024, 700));
    final desktop = BrightLayoutMetrics.fromSize(const Size(1440, 900));
    final shortDesktop = BrightLayoutMetrics.fromSize(const Size(1280, 600));

    expect(phone.windowClass, BrightWindowClass.phone);
    expect(phone.usesBottomNavigation, isTrue);
    expect(tablet.windowClass, BrightWindowClass.tablet);
    expect(tablet.usesNavigationRail, isTrue);
    expect(freeform.windowClass, BrightWindowClass.freeform);
    expect(freeform.usesNavigationRail, isTrue);
    expect(desktop.windowClass, BrightWindowClass.desktop);
    expect(desktop.usesExpandedNavigation, isTrue);
    expect(shortDesktop.shortViewport, isTrue);
    for (final metrics in <BrightLayoutMetrics>[
      phone,
      tablet,
      freeform,
      desktop,
      shortDesktop,
    ]) {
      expect(metrics.minimumTapTarget, 48);
    }
  });

  testWidgets('adaptive shell stays overflow-free across resize classes',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = <Size>[
      Size(360, 640),
      Size(600, 700),
      Size(700, 800),
      Size(900, 700),
      Size(1024, 768),
      Size(1280, 600),
      Size(1440, 900),
      Size(1920, 1080),
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(buildTestApp(GameController()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_primary_action')), findsOneWidget);
      expect(find.bySemanticsLabel('Today'), findsOneWidget);
      expect(find.bySemanticsLabel('Grown-up area'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Unexpected adaptive layout exception at $size');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('free-form navigation keeps active page while resizing',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1024, 768));
    await tester.pumpWidget(buildTestApp(GameController()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Journey'));
    await tester.pumpAndSettle();
    expect(find.text('My Journey'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(700, 800));
    await tester.pumpAndSettle();
    expect(find.text('My Journey'), findsOneWidget);
    expect(find.bySemanticsLabel('Journey'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent controls are a guarded utility route, not a learner tab',
      (tester) async {
    await tester.pumpWidget(buildTestApp(GameController()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Grown-up area'), findsOneWidget);
    expect(find.bySemanticsLabel('Parents'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Grown-up area'));
    await tester.pumpAndSettle();

    expect(find.text('Parents'), findsOneWidget);
    expect(find.text('Create a parent PIN'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('Class 3 moves profile out of the primary learner navigation',
      (tester) async {
    final controller = GameController();
    controller.setClass(3);

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Today'), findsOneWidget);
    expect(find.bySemanticsLabel('Worlds'), findsOneWidget);
    expect(find.bySemanticsLabel('Journey'), findsOneWidget);
    expect(find.bySemanticsLabel('Me'), findsOneWidget);
    expect(find.bySemanticsLabel('Grown-up area'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('world grid adapts across tablet free-form and short desktop',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = <Size>[
      Size(600, 700),
      Size(900, 700),
      Size(1280, 600),
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(buildTestApp(GameController()));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Worlds'));
      await tester.pumpAndSettle();

      expect(find.text('Learning Worlds'), findsOneWidget);
      expect(find.text('Choose a world'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'World grid overflowed at $size');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
