import 'package:brightquest_kids/core/presentation/game_feel_models.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/widgets/bright_design_system.dart';
import 'package:brightquest_kids/widgets/bright_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets('moment reactions are finite and settle', (tester) async {
    final controller = GameController();
    const moment = BrightGameFeelMoment(
      kind: BrightMomentKind.success,
      mood: BrightMascotMood.celebrating,
      emoji: '🌟',
      semanticLabel: 'Celebration',
    );

    await tester.pumpWidget(
      buildTestScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BrightLeoMoment(
                message: 'Mission move cleared!',
                moment: moment,
                trigger: 'success-1',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Mission move cleared!'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps moment reactions immediately stable',
      (tester) async {
    final controller = GameController();
    controller.setReducedMotionEnabled(true);

    await tester.pumpWidget(
      buildTestScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: BrightMomentReaction(
              trigger: 'retry-1',
              kind: BrightMomentKind.retry,
              child: Text('Calm retry'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Calm retry'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
