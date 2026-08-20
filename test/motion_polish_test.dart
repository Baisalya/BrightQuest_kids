import 'package:brightquest_kids/app/brightquest_scope.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/widgets/bright_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('finite motion widgets settle without leaving scheduled frames',
      (tester) async {
    final controller = GameController();

    await tester.pumpWidget(
      BrightQuestScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrightReveal(child: Text('Reveal')),
                  SizedBox(height: 8),
                  SizedBox(
                      width: 220, child: BrightAnimatedProgress(value: 0.72)),
                  BrightCelebrationBurst(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Reveal'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overshooting reveal curve keeps opacity in Flutter range',
      (tester) async {
    final controller = GameController();

    await tester.pumpWidget(
      BrightQuestScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BrightReveal(
                duration: Duration(milliseconds: 620),
                curve: Curves.easeOutBack,
                child: Text('Safe overshoot'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Safe overshoot'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce motion preference keeps polish widgets stable',
      (tester) async {
    final controller = GameController();
    controller.setReducedMotionEnabled(true);

    await tester.pumpWidget(
      BrightQuestScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BrightReveal(child: Text('Calm mode')),
                SizedBox(width: 220, child: BrightAnimatedProgress(value: 0.5)),
                BrightCelebrationBurst(),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Calm mode'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
