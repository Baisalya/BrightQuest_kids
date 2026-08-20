import 'dart:convert';

abstract interface class ProgressStore {
  Future<Map<String, Object?>?> read();
  Future<void> write(Map<String, Object?> snapshot);
  Future<void> clear();
}

class MemoryProgressStore implements ProgressStore {
  Map<String, Object?>? _data;

  @override
  Future<Map<String, Object?>?> read() async {
    if (_data == null) return null;
    return _clone(_data!);
  }

  @override
  Future<void> write(Map<String, Object?> snapshot) async {
    _data = _clone(snapshot);
  }

  @override
  Future<void> clear() async {
    _data = null;
  }

  Map<String, Object?> _clone(Map<String, Object?> input) {
    final encoded = jsonEncode(input);
    return Map<String, Object?>.from(jsonDecode(encoded) as Map);
  }
}
