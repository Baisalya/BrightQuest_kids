import 'dart:convert';

import 'game_session_models.dart';

abstract interface class GameSessionStore {
  Future<Map<String, GameSessionCheckpoint>> readAll();
  Future<void> writeAll(Map<String, GameSessionCheckpoint> sessions);
  Future<void> clear();
}

class MemoryGameSessionStore implements GameSessionStore {
  Map<String, Object?>? _data;

  @override
  Future<Map<String, GameSessionCheckpoint>> readAll() async {
    if (_data == null) return <String, GameSessionCheckpoint>{};
    final cloned = Map<String, Object?>.from(
      jsonDecode(jsonEncode(_data)) as Map,
    );
    return _decodeSessions(cloned);
  }

  @override
  Future<void> writeAll(Map<String, GameSessionCheckpoint> sessions) async {
    _data = <String, Object?>{
      'schemaVersion': 1,
      'sessions': <String, Object?>{
        for (final checkpoint in sessions.values)
          checkpoint.slotKey: checkpoint.toJson(),
      },
    };
  }

  @override
  Future<void> clear() async => _data = null;
}

Map<String, GameSessionCheckpoint> decodeGameSessions(
  Map<String, Object?> json,
) =>
    _decodeSessions(json);

Map<String, GameSessionCheckpoint> _decodeSessions(Map<String, Object?> json) {
  final result = <String, GameSessionCheckpoint>{};
  final schemaVersion = (json['schemaVersion'] as num?)?.toInt();
  if (schemaVersion != 1) return result;
  final rawSessions = json['sessions'];
  if (rawSessions is! Map) return result;
  for (final entry in rawSessions.entries) {
    if (entry.key is! String || entry.value is! Map) continue;
    try {
      final checkpoint = GameSessionCheckpoint.fromJson(
        Map<String, Object?>.from(entry.value as Map),
      );
      if (checkpoint.profileId.isEmpty || checkpoint.gameId.isEmpty) continue;
      final slotKey = checkpoint.slotKey;
      final existing = result[slotKey];
      if (existing == null) {
        result[slotKey] = checkpoint;
        continue;
      }
      final existingUpdated = DateTime.tryParse(existing.updatedAtIso);
      final candidateUpdated = DateTime.tryParse(checkpoint.updatedAtIso);
      if (existingUpdated == null ||
          (candidateUpdated != null &&
              candidateUpdated.isAfter(existingUpdated))) {
        result[slotKey] = checkpoint;
      }
    } catch (_) {
      // Corrupt session checkpoints are intentionally ignored. They are
      // resumability aids, never the authoritative progress snapshot.
    }
  }
  return result;
}
