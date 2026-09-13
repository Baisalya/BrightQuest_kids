import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('final release architecture keeps explicit migration contracts', () {
    final progressStore = File(
      'lib/core/persistence/shared_preferences_progress_store.dart',
    ).readAsStringSync();
    final sessionStore = File(
      'lib/core/session/shared_preferences_game_session_store.dart',
    ).readAsStringSync();
    final sessions =
        File('lib/core/session/game_session_models.dart').readAsStringSync();
    final snapshot =
        File('lib/core/models/progress_models.dart').readAsStringSync();
    final controller =
        File('lib/core/state/game_controller.dart').readAsStringSync();
    final entitlement = File('lib/core/entitlements/entitlement_service.dart')
        .readAsStringSync();

    expect(progressStore, contains('brightquest.player_snapshot.v6'));
    expect(progressStore, contains('brightquest.player_snapshot.v5'));
    expect(progressStore, contains('brightquest.player_snapshot.v3'));
    expect(progressStore, contains('brightquest.player_snapshot.v2'));
    expect(progressStore, contains('await _decodeKey(_keyV6)'));
    expect(progressStore, contains('await _decodeKey(_legacyKeyV5)'));

    expect(sessionStore, contains('brightquest.active_game_sessions.v1'));
    expect(sessionStore, contains("'schemaVersion': 1"));
    expect(sessions, contains('if (schemaVersion != 1)'));

    expect(snapshot, contains('schemaVersion: 6'));
    expect(snapshot, contains('_supportedClassFromStorage'));
    expect(snapshot, contains('profile.id = profileId'));
    expect(
      snapshot,
      contains(
        'LearnerCapabilityBoundary.isSupportedSchoolClass(classNumber)',
      ),
    );
    expect(snapshot, contains('entitlement.classNumber == classNumber'));

    expect(controller, contains('_snapshot.schemaVersion = 6'));
    expect(controller, contains('_discardInvalidSessionCheckpoints()'));

    // Persisted cache is display-only; it must not seed verified access.
    expect(
      entitlement,
      matches(
        RegExp(
          r'void\s+observeLocalCache\s*\([^)]*\)\s*\{\s*\}',
          multiLine: true,
        ),
      ),
    );
  });
}
