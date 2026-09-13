import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/games/rewards_room_screen.dart';
import 'package:brightquest_kids/features/home/home_screen.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_screen.dart';
import 'package:brightquest_kids/features/profile/profile_screen.dart';
import 'package:brightquest_kids/features/progress/progress_screen.dart';
import 'package:brightquest_kids/widgets/bright_adaptive.dart';
import 'package:brightquest_kids/widgets/bright_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  Future<void> pumpReadableSurface(
    WidgetTester tester, {
    required GameController controller,
    required Widget child,
    Size size = const Size(360, 640),
    double textScale = 2,
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        home: buildTestScope(
          controller: controller,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: BrightLayoutHost(child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shared header exposes an accessible 48dp Back action',
      (tester) async {
    final controller = GameController();
    await controller.load();

    await pumpReadableSurface(
      tester,
      controller: controller,
      child: const Scaffold(
        body: BrightHeader(showBack: true, title: 'Readable page'),
      ),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home, Journey and Me tolerate 2x text on a phone viewport',
      (tester) async {
    final controller = GameController();
    await controller.load();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final page in <Widget>[
      const HomeScreen(),
      const ProgressScreen(),
      const ProfileScreen(),
    ]) {
      await pumpReadableSurface(
        tester,
        controller: controller,
        child: page,
      );

      expect(
        tester.takeException(),
        isNull,
        reason: '${page.runtimeType} overflowed at 2x text',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Nursery root tolerates 2x text on compact and short surfaces',
      (tester) async {
    final controller = GameController();
    await controller.load();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in <Size>[
      const Size(360, 640),
      const Size(800, 480),
    ]) {
      await pumpReadableSurface(
        tester,
        controller: controller,
        child: const NurseryHomeScreen(rootMode: true),
        size: size,
      );

      expect(find.text('Nursery Learning Garden'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Nursery root overflowed at 2x text on $size',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Rewards Room tolerates 2x text and a short free-form window',
      (tester) async {
    final controller = GameController();
    await controller.load();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpReadableSurface(
      tester,
      controller: controller,
      child: const RewardsRoomScreen(),
      size: const Size(900, 600),
    );

    expect(find.byKey(const Key('rewards_room_hero')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
