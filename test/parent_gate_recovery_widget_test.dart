import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/parent/parent_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Widget _gateHost(GameController controller) => buildTestScope(
      controller: controller,
      child: const MaterialApp(home: ParentGateScreen()),
    );

void main() {
  testWidgets('parent PIN setup requires confirmation before creating recovery',
      (tester) async {
    final controller = GameController();
    await tester.pumpWidget(_gateHost(controller));
    await tester.pumpAndSettle();

    expect(find.text('Create a parent PIN'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('parent_pin_input')), '4821');
    await tester.enterText(find.byKey(const Key('parent_pin_confirm_input')), '1111');
    await tester.tap(find.text('Create parent PIN'));
    await tester.pump();

    expect(find.text('Enter the same 4-digit PIN twice.'), findsOneWidget);
    expect(controller.hasParentPin, isFalse);

    await tester.enterText(find.byKey(const Key('parent_pin_confirm_input')), '4821');
    await tester.tap(find.text('Create parent PIN'));
    await tester.pumpAndSettle();

    expect(controller.hasParentPin, isTrue);
    expect(controller.hasParentRecoveryCode, isTrue);
    expect(find.text('Save your recovery code'), findsOneWidget);
    expect(find.byKey(const Key('parent_recovery_code')), findsOneWidget);
  });

  testWidgets('forgot PIN recovery resets access without clearing child progress',
      (tester) async {
    final controller = GameController();
    controller.recordAnswer(gameId: 'math_market', correct: true);
    final xpBefore = controller.xp;
    expect(controller.setParentPin('4821'), isTrue);
    final recovery = controller.parentRecoveryCodeForUnlockedSession!;
    controller.lockParentArea();

    await tester.pumpWidget(_gateHost(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('parent_forgot_pin_button')));
    await tester.pumpAndSettle();

    expect(find.text('Recover parent access'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('parent_recovery_input')), recovery);
    await tester.enterText(
      find.byKey(const Key('parent_recovery_new_pin')),
      '7314',
    );
    await tester.enterText(
      find.byKey(const Key('parent_recovery_confirm_pin')),
      '7314',
    );
    await tester.tap(find.byKey(const Key('parent_recovery_reset_button')));
    await tester.pumpAndSettle();

    expect(controller.xp, xpBefore);
    expect(controller.isParentSessionUnlocked, isTrue);
    expect(find.text('Save your recovery code'), findsOneWidget);
    expect(controller.parentRecoveryCodeForUnlockedSession, isNot(recovery));
  });
}
