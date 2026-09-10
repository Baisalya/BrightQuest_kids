import 'nursery_legacy_visual_aliases.dart';

/// Stable spoken labels for semantic Nursery visual tokens.
///
/// Authored/generated Nursery content is semantic after Step 8. Old emoji are
/// normalized by [NurseryLegacyVisualAliases] before speech is produced.
const Map<String, String> nurseryExactSpokenLabels = <String, String>{
  '●': 'circle',
  '▲': 'triangle',
  '■': 'square',
  '▭': 'rectangle',
  '★': 'star',
  'alphabet': 'letters',
  'numbers': 'numbers',
  'colours': 'colours',
  'thinking': 'thinking',
  'matching': 'matching',
  'listening': 'listening',
  'sorting': 'sorting',
  'picture words': 'picture words',
  'celebration': 'great job',
  'addition': 'addition',
};

const Map<String, (String, String)> _nurseryCountableSemanticVisuals =
    <String, (String, String)>{
  'dot': ('dot', 'dots'),
  'star': ('star', 'stars'),
  'apple': ('apple', 'apples'),
  'banana': ('banana', 'bananas'),
  'orange': ('orange', 'oranges'),
  'mango': ('mango', 'mangoes'),
  'carrot': ('carrot', 'carrots'),
  'fish': ('fish', 'fish'),
  'ball': ('ball', 'balls'),
  'foot': ('foot', 'feet'),
  'ear': ('ear', 'ears'),
};

/// A short child-friendly label for an answer or isolated visual token.
String nurserySpokenLabel(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return '';
  final canonical = nurseryCanonicalLegacyVisualValue(raw);
  final semanticPrefix = RegExp(r'^(?:colour|color|shape):(.+)$')
      .firstMatch(canonical.toLowerCase());
  if (semanticPrefix != null) return semanticPrefix.group(1)!.trim();
  final exact = nurseryExactSpokenLabels[canonical];
  if (exact != null) return exact;

  final counted = _parseCountedSemantic(canonical);
  if (counted != null) {
    return nurseryCountedSemanticLabel(counted.$1, counted.$2);
  }

  final normalized = nurserySpeakableText(canonical);
  final words = normalized.split(' ');
  if (words.length == 2 && words[0].toLowerCase() == words[1].toLowerCase()) {
    return words.first;
  }
  return normalized;
}

/// Rewrites Nursery prompt/narration text into reliable platform speech.
String nurserySpeakableText(String value) {
  var result = nurseryReplaceLegacyEmojiInText(value);

  for (final entry in nurseryExactSpokenLabels.entries) {
    if (entry.key.length != 1) continue;
    result = result.replaceAll(entry.key, ' ${entry.value} ');
  }

  return result
      .replaceAll(' + ', ' plus ')
      .replaceAll(' = ', ' equals ')
      .replaceAll(' & ', ' and ')
      .replaceAll('__', ' blank ')
      .replaceAll('(none)', 'no objects')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Returns only legacy inline visual groups embedded in pre-Step-8 copy.
/// New Nursery content carries semantic visuals explicitly in activity payloads
/// or visual-token lists and therefore does not need text parsing.
List<String> nurseryVisualTokensInText(String value) {
  if (value.isEmpty) return const <String>[];
  final pictograms = nurseryLegacyEmojiTokensInText(value);
  final result = <String>[...pictograms];

  const symbols = <String>['●', '★', '▲', '■', '▭'];
  for (final symbol in symbols) {
    var index = 0;
    while (index < value.length) {
      final found = value.indexOf(symbol, index);
      if (found < 0) break;
      var end = found + symbol.length;
      while (value.startsWith(symbol, end)) {
        end += symbol.length;
      }
      result.add(value.substring(found, end));
      index = end;
    }
  }
  return List<String>.unmodifiable(result);
}

/// Child-facing copy with legacy inline pictograms removed. Step 8 content is
/// already visual-free prose; this remains as a backwards-compatibility guard.
String nurseryVisualFreeText(String value) {
  var result = value;
  for (final token in nurseryVisualTokensInText(value)) {
    result = result.replaceFirst(token, ' ');
  }
  result = result
      .replaceAll('__', 'the missing card')
      .replaceAllMapped(
        RegExp(r'\s+([?.!,:;])'),
        (match) => match.group(1)!,
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (result.startsWith('What comes next?')) {
    return 'What comes next in this pattern?';
  }
  if (result.startsWith('Remember the pair')) {
    return 'Look carefully. Which pair did you see?';
  }
  if (result.startsWith('Look:') && result.contains('different')) {
    return 'Look carefully. Which picture is different?';
  }
  if (result.startsWith('Which colour word matches')) {
    return 'Which colour word matches this colour?';
  }
  if (result.startsWith('Do these have the same amount?')) {
    return 'Do these picture groups have the same amount?';
  }
  if (result.startsWith('Are these amounts same or different?')) {
    return 'Are these picture groups the same amount or different?';
  }
  if (result.startsWith('+') || result.contains(' +  =')) {
    return 'Add the picture groups. How many altogether?';
  }
  return result.isEmpty ? 'Look at the pictures.' : result;
}

bool nurseryContainsRawVisualToken(String value) {
  if (value.contains('●') ||
      value.contains('★') ||
      value.contains('▲') ||
      value.contains('■') ||
      value.contains('▭')) {
    return true;
  }
  return nurseryContainsLegacyEmoji(value);
}

(int, String)? _parseCountedSemantic(String value) {
  final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(value.trim().toLowerCase());
  if (match == null) return null;
  final count = int.tryParse(match.group(1)!);
  if (count == null) return null;
  var noun = match.group(2)!.trim();
  final singular = _singularCountable(noun);
  if (singular == null) return null;
  return (count, singular);
}

String? _singularCountable(String noun) {
  final normalized = noun.trim().toLowerCase();
  for (final entry in _nurseryCountableSemanticVisuals.entries) {
    if (normalized == entry.value.$1 || normalized == entry.value.$2) {
      return entry.key;
    }
  }
  return null;
}
