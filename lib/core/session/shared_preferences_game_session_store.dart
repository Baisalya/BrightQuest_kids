import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_session_models.dart';
import 'game_session_store.dart';

class SharedPreferencesGameSessionStore implements GameSessionStore {
  SharedPreferencesGameSessionStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'brightquest.active_game_sessions.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<String, GameSessionCheckpoint>> readAll() async {
    final encoded = await _preferences.getString(storageKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <String, GameSessionCheckpoint>{};
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        await _preferences.remove(storageKey);
        return <String, GameSessionCheckpoint>{};
      }
      final payload = Map<String, Object?>.from(decoded);
      if ((payload['schemaVersion'] as num?)?.toInt() != 1) {
        await _preferences.remove(storageKey);
        return <String, GameSessionCheckpoint>{};
      }
      return decodeGameSessions(payload);
    } catch (_) {
      await _preferences.remove(storageKey);
      return <String, GameSessionCheckpoint>{};
    }
  }

  @override
  Future<void> writeAll(Map<String, GameSessionCheckpoint> sessions) async {
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'sessions': <String, Object?>{
        for (final checkpoint in sessions.values)
          checkpoint.slotKey: checkpoint.toJson(),
      },
    };
    await _preferences.setString(storageKey, jsonEncode(payload));
  }

  @override
  Future<void> clear() => _preferences.remove(storageKey);
}
