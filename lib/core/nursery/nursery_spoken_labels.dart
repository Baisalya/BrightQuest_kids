/// Converts Nursery visual tokens into stable, child-friendly speech.
///
/// We do this before handing text to the platform TTS so Android and Windows
/// do not disagree about emoji/symbol pronunciation. The visible UI remains
/// unchanged; only the spoken representation is normalized.
const Map<String, String> nurseryExactSpokenLabels = <String, String>{
  '🔴': 'red circle',
  '🔵': 'blue circle',
  '🟢': 'green circle',
  '🟡': 'yellow circle',
  '🟠': 'orange circle',
  '🟣': 'purple circle',
  '●': 'circle',
  '▲': 'triangle',
  '🔺': 'triangle',
  '■': 'square',
  '▭': 'rectangle',
  '🍎': 'apple',
  '🍌': 'banana',
  '🍊': 'orange',
  '🥭': 'mango',
  '🥕': 'carrot',
  '🥔': 'potato',
  '🍐': 'pear',
  '🥦': 'broccoli',
  '🐱': 'cat',
  '🐶': 'dog',
  '🐟': 'fish',
  '🐰': 'rabbit',
  '🐐': 'goat',
  '🐮': 'cow',
  '🐯': 'tiger',
  '🐦': 'bird',
  '⚽': 'ball',
  '📘': 'book',
  '👟': 'shoe',
  '🥤': 'cup',
  '🥄': 'spoon',
  '✏️': 'pencil',
  '🧢': 'hat',
  '🔑': 'key',
  '👀': 'eyes',
  '🙌': 'hands',
  '🦶': 'foot',
  '👂': 'ear',
  '👃': 'nose',
  '👄': 'mouth',
  '⭐': 'star',
  '★': 'star',
  '☀️': 'sun',
  '🪁': 'kite',
  '🦆': 'duck',
};

const Map<String, (String, String)> _nurseryCountableVisuals =
    <String, (String, String)>{
  '●': ('dot', 'dots'),
  '★': ('star', 'stars'),
  '⭐': ('star', 'stars'),
  '🍎': ('apple', 'apples'),
  '🍌': ('banana', 'bananas'),
  '🍊': ('orange', 'oranges'),
  '🥭': ('mango', 'mangoes'),
  '🥕': ('carrot', 'carrots'),
  '🐟': ('fish', 'fish'),
  '⚽': ('ball', 'balls'),
  '🦶': ('foot', 'feet'),
  '👂': ('ear', 'ears'),
};

/// A short spoken label for an answer choice or isolated visual token.
String nurserySpokenLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final exact = nurseryExactSpokenLabels[trimmed];
  if (exact != null) return exact;

  for (final entry in nurseryExactSpokenLabels.entries) {
    if (!trimmed.startsWith(entry.key)) continue;
    final remainder = trimmed.substring(entry.key.length).trim();
    if (remainder.toLowerCase() == entry.value.toLowerCase()) {
      return entry.value;
    }
  }

  for (final entry in _nurseryCountableVisuals.entries) {
    final token = entry.key;
    if (!_isOnlyRepeatedToken(trimmed, token)) continue;
    final count = trimmed.length ~/ token.length;
    final names = entry.value;
    return count == 1 ? 'one ${names.$1}' : '$count ${names.$2}';
  }

  final normalized = nurserySpeakableText(trimmed);
  final words = normalized.split(' ');
  if (words.length == 2 && words[0].toLowerCase() == words[1].toLowerCase()) {
    return words.first;
  }
  return normalized;
}

/// Rewrites visual-heavy Nursery prompt/narration text into reliable speech.
String nurserySpeakableText(String value) {
  var result = value;

  // Replace counting visuals with individually speakable objects. Do not say
  // the quantity here: prompts such as "How many apples? 🍎🍎🍎" must
  // remain a real counting task instead of TTS revealing "3 apples".
  for (final entry in _nurseryCountableVisuals.entries) {
    final token = entry.key;
    final singular = entry.value.$1;
    result = result.replaceAllMapped(
      RegExp('(?:${RegExp.escape(token)})+'),
      (match) {
        final raw = match.group(0)!;
        final count = raw.length ~/ token.length;
        return ' ${List<String>.filled(count, singular).join(', ')} ';
      },
    );
  }

  // Then normalize remaining one-off visuals.
  for (final entry in nurseryExactSpokenLabels.entries) {
    result = result.replaceAll(entry.key, ' ${entry.value} ');
  }

  return result
      .replaceAll(' + ', ' plus ')
      .replaceAll(' = ', ' equals ')
      .replaceAll('__', ' blank ')
      .replaceAll('(none)', 'no objects')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool nurseryContainsRawVisualToken(String value) {
  if (value.contains('●') ||
      value.contains('▲') ||
      value.contains('■') ||
      value.contains('▭')) {
    return true;
  }
  return nurseryExactSpokenLabels.keys.any(value.contains);
}

bool _isOnlyRepeatedToken(String value, String token) {
  if (value.isEmpty || token.isEmpty || value.length % token.length != 0) {
    return false;
  }
  return value ==
      List<String>.filled(value.length ~/ token.length, token).join();
}
