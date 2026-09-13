import 'dart:convert';

import 'package:brightquest_kids/core/models/learner_stage.dart';
import 'package:brightquest_kids/core/persistence/shared_preferences_progress_store.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/session/shared_preferences_game_session_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const v6 = 'brightquest.player_snapshot.v6';
  const v5 = 'brightquest.player_snapshot.v5';
  const sessionKey = 'brightquest.active_game_sessions.v1';

  late SharedPreferencesAsync preferences;

  Map<String, Object?> legacySnapshot({
    int selectedClass = 6,
    int coins = 777,
  }) =>
      <String, Object?>{
        'schemaVersion': 5,
        'activeProfileId': 'child-upgrade',
        'profiles': <String, Object?>{
          'child-upgrade': <String, Object?>{
            'id': 'stale-id',
            'name': 'Upgrade Child',
            'selectedClass': selectedClass,
            'coins': coins,
            'stars': 9,
            'xp': 123,
          },
        },
      };

  setUp(() {
    preferences = _MemoryPreferences();
  });

  GameController controller() => GameController(
        store: SharedPreferencesProgressStore(preferences: preferences),
        sessionStore:
            SharedPreferencesGameSessionStore(preferences: preferences),
      );

  test('old snapshot upgrades without losing identity or earned progress',
      () async {
    await preferences.setString(v5, jsonEncode(legacySnapshot()));

    final value = controller();
    await value.load();

    expect(value.activeProfileId, 'child-upgrade');
    expect(value.activeProfileName, 'Upgrade Child');
    expect(value.selectedClass, 4);
    expect(value.learnerStage, LearnerStage.school);
    expect(value.coins, 777);
    expect(value.stars, 9);
    expect(value.xp, 123);

    await value.flushAll();

    expect(await preferences.getString(v6), isNotNull);
    expect(await preferences.getString(v5), isNull);

    final persisted =
        jsonDecode((await preferences.getString(v6))!) as Map<String, Object?>;
    expect(persisted['schemaVersion'], 6);
    expect(persisted['activeProfileId'], 'child-upgrade');
  });

  test('corrupt v6 falls back to v5 and next flush retires legacy key',
      () async {
    await preferences.setString(v6, '{broken');
    await preferences.setString(
      v5,
      jsonEncode(legacySnapshot(selectedClass: 5, coins: 888)),
    );

    final value = controller();
    await value.load();

    expect(value.selectedClass, 5);
    expect(value.coins, 888);

    await value.flushAll();

    expect(await preferences.getString(v6), isNotNull);
    expect(await preferences.getString(v5), isNull);
  });

  test('invalid resumable session is discarded while progress survives',
      () async {
    await preferences.setString(
        v5, jsonEncode(legacySnapshot(selectedClass: 4)));

    final now = DateTime.now().toUtc().toIso8601String();
    final invalidForApp = GameSessionCheckpoint(
      profileId: 'child-upgrade',
      classNumber: 4,
      gameId: 'not_a_brightquest_game',
      difficulty: 1,
      stage: GameSessionStage.game,
      cursor: 0,
      score: 0,
      maxScore: 5,
      startedAtIso: now,
      updatedAtIso: now,
    );
    await preferences.setString(
      sessionKey,
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'sessions': <String, Object?>{
          invalidForApp.slotKey: invalidForApp.toJson(),
        },
      }),
    );

    final value = controller();
    await value.load();

    expect(value.coins, 777);
    expect(value.resumableGameSessions, isEmpty);

    final sessionStore =
        SharedPreferencesGameSessionStore(preferences: preferences);
    expect(await sessionStore.readAll(), isEmpty);
  });
}

class _MemoryPreferences extends Fake implements SharedPreferencesAsync {
  final Map<String, String> _strings = <String, String>{};

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> setString(String key, String value) async {
    _strings[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _strings.remove(key);
  }
}
