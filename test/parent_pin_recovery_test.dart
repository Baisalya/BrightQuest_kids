import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recovery code resets a forgotten PIN without deleting progress', () {
    final controller = GameController();
    controller.recordAnswer(gameId: 'math_market', correct: true);
    final coinsBefore = controller.coins;

    expect(controller.setParentPin('4821'), isTrue);
    final recovery = controller.parentRecoveryCodeForUnlockedSession;
    expect(recovery, isNotNull);
    expect(recovery!.replaceAll('-', '').length, 12);

    controller.lockParentArea();
    expect(
      controller.resetParentPinWithRecoveryCode(
        recoveryCode: '0000-0000-0000',
        newPin: '7314',
      ),
      isFalse,
    );
    expect(
      controller.resetParentPinWithRecoveryCode(
        recoveryCode: recovery,
        newPin: '7314',
      ),
      isTrue,
    );
    expect(controller.coins, coinsBefore);
    expect(controller.parentRecoveryCodeForUnlockedSession, isNot(recovery));

    controller.lockParentArea();
    expect(controller.verifyParentPin('4821'), isFalse);
    expect(controller.verifyParentPin('7314'), isTrue);
  });

  test('legacy PIN creates a recovery code after the next valid unlock', () async {
    final store = MemoryProgressStore();
    await store.write(PlayerSnapshot(parentPinCode: '4821').toJson());
    final controller = GameController(store: store);
    await controller.load();

    expect(controller.hasParentRecoveryCode, isFalse);
    expect(controller.verifyParentPin('4821'), isTrue);
    expect(controller.hasParentRecoveryCode, isTrue);
    expect(controller.parentRecoveryCodeForUnlockedSession, isNotNull);
  });

  test('24-hour fallback cannot reset immediately and preserves progress', () {
    final controller = GameController();
    controller.recordAnswer(gameId: 'science_lab', correct: true);
    final xpBefore = controller.xp;
    expect(controller.setParentPin('4821'), isTrue);
    controller.lockParentArea();

    final requestedAt = DateTime.utc(2026, 9, 14, 8);
    expect(controller.requestParentPinReset(now: requestedAt), isTrue);
    expect(controller.parentPinResetPending, isTrue);
    expect(
      controller.canCompleteDelayedParentPinReset(
        now: requestedAt.add(const Duration(hours: 23, minutes: 59)),
      ),
      isFalse,
    );
    expect(
      controller.completeDelayedParentPinReset(
        '7314',
        now: requestedAt.add(const Duration(hours: 23, minutes: 59)),
      ),
      isFalse,
    );
    expect(
      controller.completeDelayedParentPinReset(
        '7314',
        now: requestedAt.add(const Duration(hours: 24)),
      ),
      isTrue,
    );
    expect(controller.xp, xpBefore);
    expect(controller.parentPinResetPending, isFalse);
    expect(controller.parentRecoveryCodeForUnlockedSession, isNotNull);
  });

  test('a valid PIN unlock cancels a pending delayed reset', () {
    final controller = GameController();
    expect(controller.setParentPin('4821'), isTrue);
    controller.lockParentArea();
    expect(
      controller.requestParentPinReset(now: DateTime.utc(2026, 9, 14)),
      isTrue,
    );
    expect(controller.parentPinResetPending, isTrue);

    expect(controller.verifyParentPin('4821'), isTrue);
    expect(controller.parentPinResetPending, isFalse);
  });

  test('recovery metadata survives snapshot JSON round-trip', () {
    final snapshot = PlayerSnapshot(
      parentPinCode: '4821',
      parentRecoveryCode: '123456789012',
      parentPinResetRequestedAtIso: '2026-09-14T08:00:00.000Z',
    );
    final restored = PlayerSnapshot.fromJson(snapshot.toJson());
    expect(restored.parentPinCode, '4821');
    expect(restored.parentRecoveryCode, '123456789012');
    expect(
      restored.parentPinResetRequestedAtIso,
      '2026-09-14T08:00:00.000Z',
    );
  });
}
