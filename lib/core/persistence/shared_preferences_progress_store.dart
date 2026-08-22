import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'progress_store.dart';

class SharedPreferencesProgressStore implements ProgressStore {
  SharedPreferencesProgressStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _keyV6 = 'brightquest.player_snapshot.v6';
  static const _legacyKeyV5 = 'brightquest.player_snapshot.v5';
  static const _legacyKeyV3 = 'brightquest.player_snapshot.v3';
  static const _legacyKeyV2 = 'brightquest.player_snapshot.v2';
  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<String, Object?>?> read() async {
    final current = await _decodeKey(_keyV6);
    if (current != null) return current;
    final phase2Snapshot = await _decodeKey(_legacyKeyV5);
    if (phase2Snapshot != null) return phase2Snapshot;
    final phase1Snapshot = await _decodeKey(_legacyKeyV3);
    if (phase1Snapshot != null) return phase1Snapshot;
    return _decodeKey(_legacyKeyV2);
  }

  Future<Map<String, Object?>?> _decodeKey(String key) async {
    final encoded = await _preferences.getString(key);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } on FormatException {
      // Corrupt/non-JSON preferences are treated as a clean start.
    }
    return null;
  }

  @override
  Future<void> write(Map<String, Object?> snapshot) async {
    await _preferences.setString(_keyV6, jsonEncode(snapshot));
    await _preferences.remove(_legacyKeyV5);
    await _preferences.remove(_legacyKeyV3);
    await _preferences.remove(_legacyKeyV2);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_keyV6);
    await _preferences.remove(_legacyKeyV5);
    await _preferences.remove(_legacyKeyV3);
    await _preferences.remove(_legacyKeyV2);
  }
}
