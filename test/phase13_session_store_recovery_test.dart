import 'dart:convert';

import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/session/shared_preferences_game_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sessionKey = 'brightquest.active_game_sessions.v1';
  const progressKey = 'brightquest.player_snapshot.v6';

  late SharedPreferencesAsync preferences;
  late SharedPreferencesGameSessionStore store;

  GameSessionCheckpoint checkpoint({
    String profileId = 'child-1',
    int classNumber = 4,
    String gameId = 'math_market',
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return GameSessionCheckpoint(
      profileId: profileId,
      classNumber: classNumber,
      gameId: gameId,
      difficulty: 1,
      stage: GameSessionStage.game,
      cursor: 1,
      score: 1,
      maxScore: 5,
      startedAtIso: now,
      updatedAtIso: now,
    );
  }

  setUp(() {
    preferences = _MemoryPreferences();
    store = SharedPreferencesGameSessionStore(preferences: preferences);
  });

  test('schema v1 sessions round-trip by canonical slot key', () async {
    final value = checkpoint();

    await store.writeAll(<String, GameSessionCheckpoint>{
      value.slotKey: value,
    });
    final restored = await store.readAll();

    expect(restored.keys, <String>[value.slotKey]);
    expect(restored[value.slotKey]?.profileId, value.profileId);
    expect(restored[value.slotKey]?.classNumber, 4);
    expect(restored[value.slotKey]?.gameId, 'math_market');
  });

  test('one corrupt checkpoint is ignored without losing valid sibling',
      () async {
    final valid = checkpoint();
    await preferences.setString(
      sessionKey,
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'sessions': <String, Object?>{
          valid.slotKey: valid.toJson(),
          'bad': <String, Object?>{
            'schemaVersion': 99,
            'profileId': 'child-1',
          },
        },
      }),
    );

    final restored = await store.readAll();

    expect(restored.length, 1);
    expect(restored.containsKey(valid.slotKey), isTrue);
  });

  test('malformed outer session payload is cleared without touching progress',
      () async {
    await preferences.setString(progressKey, '{"progress":"keep"}');
    await preferences.setString(sessionKey, '{broken');

    expect(await store.readAll(), isEmpty);
    expect(await preferences.getString(sessionKey), isNull);
    expect(await preferences.getString(progressKey), '{"progress":"keep"}');
  });

  test('wrong outer session schema is cleared without touching progress',
      () async {
    await preferences.setString(progressKey, '{"progress":"keep"}');
    await preferences.setString(
      sessionKey,
      jsonEncode(<String, Object?>{
        'schemaVersion': 2,
        'sessions': <String, Object?>{},
      }),
    );

    expect(await store.readAll(), isEmpty);
    expect(await preferences.getString(sessionKey), isNull);
    expect(await preferences.getString(progressKey), '{"progress":"keep"}');
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
