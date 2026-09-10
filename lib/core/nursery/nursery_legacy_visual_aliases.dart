/// Legacy Nursery pictogram compatibility.
///
/// Step 8 migrated authored/generated Nursery content to semantic values. This
/// is the only production boundary that intentionally knows the old Unicode
/// pictograms so stale responses, old tests/data fixtures, and pre-migration
/// generated values can still be normalized without rendering emoji.
abstract final class NurseryLegacyVisualAliases {
  static const Map<String, String> exact = <String, String>{
    '🔤': 'alphabet',
    '🔠': 'alphabet',
    '🔢': 'numbers',
    '🌈': 'colours',
    '🧩': 'thinking',
    '🃏': 'matching',
    '👂': 'ear',
    '🎧': 'listening',
    '🔊': 'listening',
    '✏️': 'pencil',
    '🧺': 'sorting',
    '🖼️': 'picture words',
    '👀': 'eyes',
    '⭐': 'star',
    '✨': 'celebration',
    '🎉': 'celebration',
    '➕': 'addition',
    '🔴': 'red',
    '🔵': 'blue',
    '🟢': 'green',
    '🟡': 'yellow',
    '🟠': 'orange',
    '🟣': 'purple',
    '🔺': 'triangle',
    '🔷': 'diamond',
    '🐱': 'cat',
    '🐶': 'dog',
    '🐟': 'fish',
    '🐰': 'rabbit',
    '🐐': 'goat',
    '🐮': 'cow',
    '🐯': 'tiger',
    '🐦': 'bird',
    '🍎': 'apple',
    '🍌': 'banana',
    '🍊': 'orange',
    '🥭': 'mango',
    '🥕': 'carrot',
    '🥔': 'potato',
    '🍐': 'pear',
    '🥦': 'broccoli',
    '⚽': 'ball',
    '🧸': 'teddy',
    '📘': 'book',
    '👟': 'shoe',
    '🥤': 'cup',
    '🥄': 'spoon',
    '🧢': 'hat',
    '🔑': 'key',
    '🙋': 'body',
    '🙌': 'hands',
    '🦶': 'foot',
    '👃': 'nose',
    '👄': 'mouth',
    '🌞': 'sun',
    '☀️': 'sun',
    '🌍': 'world',
    '🗺️': 'world',
    '💡': 'thinking',
    '🎈': 'play',
    '🚀': 'play',
    '🪄': 'play',
    '🪁': 'kite',
    '🦆': 'duck',
  };

  /// Legacy non-emoji Unicode picture symbols used by early Nursery maths
  /// and pattern content. These are normalized alongside old emoji values,
  /// but intentionally remain separate from [exact] so the Step 8 emoji
  /// isolation audit can distinguish geometric symbols from pictographic emoji.
  static const Map<String, String> symbols = <String, String>{
    '●': 'dot',
    '★': 'star',
    '▲': 'triangle',
    '■': 'square',
    '▭': 'rectangle',
  };

  static const Map<String, String> composite = <String, String>{
    '🍎 Apple': 'apple',
    '🐶 Dog': 'dog',
    '☀️ Sun': 'sun',
    '🥭 Mango': 'mango',
    '🐰 Rabbit': 'rabbit',
    '🪁 Kite': 'kite',
    '🐐 Goat': 'goat',
    '🍊 Orange': 'orange',
    '🍎 apple': 'apple',
    '🥕 carrot': 'carrot',
    '🥔 potato': 'potato',
    '⭐⭐': '2 stars',
    '⭐⭐⭐⭐': '4 stars',
    '🍎🍎🍎': '3 apples',
    '🍎🍎🍎🍎': '4 apples',
    '⭐ ⚽': 'star & ball',
    '🍎 🐟': 'apple & fish',
    '🔺 🔵': 'triangle & blue',
  };
}

bool nurseryContainsLegacyEmoji(String value) =>
    NurseryLegacyVisualAliases.exact.keys.any(value.contains);

String nurseryCanonicalLegacyVisualValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final composite = NurseryLegacyVisualAliases.composite[trimmed];
  if (composite != null) return composite;

  final repeated = _repeatedExactAlias(trimmed);
  if (repeated != null) {
    return nurseryCountedSemanticLabel(repeated.$2, repeated.$1);
  }

  final exact = NurseryLegacyVisualAliases.exact[trimmed] ??
      NurseryLegacyVisualAliases.symbols[trimmed];
  if (exact != null) return exact;

  var result = trimmed;
  final aliases = <MapEntry<String, String>>[
    ...NurseryLegacyVisualAliases.exact.entries,
    ...NurseryLegacyVisualAliases.symbols.entries,
  ]..sort((a, b) => b.key.length.compareTo(a.key.length));
  for (final entry in aliases) {
    result = result.replaceAll(entry.key, ' ${entry.value} ');
  }
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Rewrites legacy pictograms embedded in prose to speakable semantic words.
/// Repeated pictures remain repeated words so counting prompts never reveal
/// the answer through narration.
String nurseryReplaceLegacyEmojiInText(String value) {
  var result = value;
  final aliases = NurseryLegacyVisualAliases.exact.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));
  for (final entry in aliases) {
    result = result.replaceAll(entry.key, ' ${entry.value} ');
  }
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Extracts old pictogram runs from a pre-Step-8 string. This is used only as
/// a backwards-compatible rendering fallback; new content supplies semantic
/// visual tokens directly.
List<String> nurseryLegacyEmojiTokensInText(String value) {
  if (value.isEmpty) return const <String>[];
  final candidates = NurseryLegacyVisualAliases.exact.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final result = <String>[];
  var index = 0;
  while (index < value.length) {
    String? match;
    for (final token in candidates) {
      if (value.startsWith(token, index)) {
        match = token;
        break;
      }
    }
    if (match == null) {
      index += 1;
      continue;
    }
    final start = index;
    index += match.length;
    while (value.startsWith(match, index)) {
      index += match.length;
    }
    result.add(value.substring(start, index));
  }
  return List<String>.unmodifiable(result);
}

String nurseryCountedSemanticLabel(int count, String singular) {
  final normalized = singular.trim().toLowerCase();
  if (count <= 0) return 'empty group';
  if (count == 1) return '1 $normalized';
  final plural = switch (normalized) {
    'fish' => 'fish',
    'foot' => 'feet',
    'ear' => 'ears',
    'mango' => 'mangoes',
    'star' => 'stars',
    'apple' => 'apples',
    'banana' => 'bananas',
    'orange' => 'oranges',
    'carrot' => 'carrots',
    'ball' => 'balls',
    'dot' => 'dots',
    _ when normalized.endsWith('s') => normalized,
    _ => '${normalized}s',
  };
  return '$count $plural';
}

(String, int)? _repeatedExactAlias(String value) {
  final aliases = <MapEntry<String, String>>[
    ...NurseryLegacyVisualAliases.exact.entries,
    ...NurseryLegacyVisualAliases.symbols.entries,
  ]..sort((a, b) => b.key.length.compareTo(a.key.length));
  for (final entry in aliases) {
    final token = entry.key;
    if (token.isEmpty || value.length % token.length != 0) continue;
    final count = value.length ~/ token.length;
    if (count < 2) continue;
    if (value == List<String>.filled(count, token).join()) {
      return (entry.value, count);
    }
  }
  return null;
}
