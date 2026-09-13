import 'dart:convert';

import 'package:brightquest_kids/core/persistence/shared_preferences_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const v6 = 'brightquest.player_snapshot.v6';
  const v5 = 'brightquest.player_snapshot.v5';
  const v3 = 'brightquest.player_snapshot.v3';
  const v2 = 'brightquest.player_snapshot.v2';

  late SharedPreferencesAsync preferences;
  late SharedPreferencesProgressStore store;

  setUp(() {
    preferences = _MemoryPreferences();
    store = SharedPreferencesProgressStore(preferences: preferences);
  });

  test('current v6 snapshot wins over all legacy keys', () async {
    await preferences.setString(v2, jsonEncode(<String, Object?>{'source': 2}));
    await preferences.setString(v3, jsonEncode(<String, Object?>{'source': 3}));
    await preferences.setString(v5, jsonEncode(<String, Object?>{'source': 5}));
    await preferences.setString(v6, jsonEncode(<String, Object?>{'source': 6}));

    expect(await store.read(), containsPair('source', 6));
  });

  test('corrupt current snapshot falls back in v5 then v3 then v2 order',
      () async {
    await preferences.setString(v6, '{corrupt');
    await preferences.setString(v5, jsonEncode(<String, Object?>{'source': 5}));
    await preferences.setString(v3, jsonEncode(<String, Object?>{'source': 3}));
    await preferences.setString(v2, jsonEncode(<String, Object?>{'source': 2}));

    expect(await store.read(), containsPair('source', 5));

    await preferences.remove(v5);
    expect(await store.read(), containsPair('source', 3));

    await preferences.remove(v3);
    expect(await store.read(), containsPair('source', 2));
  });

  test('writing current snapshot retires every legacy progress key', () async {
    for (final key in <String>[v5, v3, v2]) {
      await preferences.setString(
          key, jsonEncode(<String, Object?>{'old': key}));
    }

    await store.write(<String, Object?>{
      'schemaVersion': 6,
      'activeProfileId': 'child-1',
    });

    expect(await preferences.getString(v6), isNotNull);
    expect(await preferences.getString(v5), isNull);
    expect(await preferences.getString(v3), isNull);
    expect(await preferences.getString(v2), isNull);
  });

  test('clear removes current and all supported legacy progress keys',
      () async {
    for (final key in <String>[v6, v5, v3, v2]) {
      await preferences.setString(key, '{}');
    }

    await store.clear();

    for (final key in <String>[v6, v5, v3, v2]) {
      expect(await preferences.getString(key), isNull);
    }
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
