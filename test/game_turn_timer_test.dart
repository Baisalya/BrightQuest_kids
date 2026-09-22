import 'package:brightquest_kids/widgets/game_turn_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('question timer expires once and resets with a new turn key',
      (tester) async {
    var expired = 0;
    var resetKey = 1;

    Widget buildTimer() => MaterialApp(
          home: Scaffold(
            body: GameTurnTimer(
              duration: const Duration(seconds: 3),
              resetKey: resetKey,
              paused: false,
              onExpired: () => expired += 1,
            ),
          ),
        );

    await tester.pumpWidget(buildTimer());
    await tester.pump(const Duration(seconds: 2));
    expect(expired, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(expired, 1);

    // The expiry callback is one-shot even if more frames are rendered.
    await tester.pump(const Duration(seconds: 1));
    expect(expired, 1);

    resetKey = 2;
    await tester.pumpWidget(buildTimer());
    await tester.pump(const Duration(seconds: 3));
    expect(expired, 2);
  });

  testWidgets('paused timer does not consume question time', (tester) async {
    var expired = 0;
    var paused = true;

    Widget buildTimer() => MaterialApp(
          home: Scaffold(
            body: GameTurnTimer(
              duration: const Duration(seconds: 2),
              resetKey: 'same-turn',
              paused: paused,
              onExpired: () => expired += 1,
            ),
          ),
        );

    await tester.pumpWidget(buildTimer());
    await tester.pump(const Duration(seconds: 5));
    expect(expired, 0);

    paused = false;
    await tester.pumpWidget(buildTimer());
    await tester.pump(const Duration(seconds: 2));
    expect(expired, 1);
  });
}
