import 'nursery_asset_catalog.dart';
import 'nursery_content.dart';
import 'nursery_legacy_visual_aliases.dart';
import 'nursery_spoken_labels.dart';

/// Semantic visual concepts used by Nursery presentation.
///
/// Learning/content code should describe *what* a child needs to see rather
/// than committing to a platform emoji or a specific Flutter widget. The
/// presentation layer is responsible for turning these concepts into bundled
/// illustrations, painted vectors, or typography.
enum NurseryVisualConcept {
  garden,
  alphabet,
  maths,
  world,
  thinking,
  listening,
  tracing,
  matching,
  sorting,
  pictureWords,
  counting,
  addition,
  colours,
  shapes,
  animals,
  food,
  objects,
  body,
  routines,
  patterns,
  observation,
  celebration,
  play,
  review,
  letter,
  number,
  localPicture,
  text,
}

enum NurseryVisualSource {
  painted,
  localAsset,
  typography,
}

/// Framework-neutral description of a visual shown to a Nursery learner.
///
/// This deliberately contains no Flutter types. It can therefore be produced
/// by content/generator code and tested without coupling the learning model to
/// Material icons, Unicode emoji, or rendering implementation details.
class NurseryVisualSpec {
  const NurseryVisualSpec({
    required this.key,
    required this.concept,
    required this.source,
    required this.semanticLabel,
    this.assetPath,
    this.text,
    this.variant,
    this.count = 1,
  });

  final String key;
  final NurseryVisualConcept concept;
  final NurseryVisualSource source;
  final String semanticLabel;
  final String? assetPath;
  final String? text;

  /// Optional semantic variant such as `red`, `triangle`, `star`, or `apple`.
  /// The renderer owns the visual implementation; content stays Flutter-free.
  final String? variant;

  /// Number of identical visual items represented by this spec.
  /// Used for counting groups without repeating Unicode pictograms.
  final int count;

  bool get usesLocalAsset =>
      source == NurseryVisualSource.localAsset &&
      assetPath != null &&
      assetPath!.trim().isNotEmpty;
}

/// Central semantic resolver for Nursery visuals.
///
/// Existing content currently contains legacy `emoji`/picture strings. Those
/// inputs are accepted here only as a compatibility boundary. New UI code
/// should ask this resolver for a semantic visual instead of rendering the raw
/// string directly.
abstract final class NurseryVisualResolver {
  static NurseryVisualSpec forDomain(NurseryDomain domain) =>
      forDomainId(domain.id, semanticLabel: domain.title);

  static NurseryVisualSpec forDomainId(
    String domainId, {
    String? semanticLabel,
  }) {
    final normalized = domainId.trim().toLowerCase();
    return switch (normalized) {
      'alphabet' => _painted(
          key: 'domain:alphabet',
          concept: NurseryVisualConcept.alphabet,
          label: semanticLabel ?? 'Letters and sounds',
        ),
      'math' => _painted(
          key: 'domain:math',
          concept: NurseryVisualConcept.maths,
          label: semanticLabel ?? 'Numbers',
        ),
      'knowledge' => _painted(
          key: 'domain:knowledge',
          concept: NurseryVisualConcept.world,
          label: semanticLabel ?? 'My world',
        ),
      'thinking' => _painted(
          key: 'domain:thinking',
          concept: NurseryVisualConcept.thinking,
          label: semanticLabel ?? 'Match and think',
        ),
      _ => _painted(
          key: 'domain:$normalized',
          concept: NurseryVisualConcept.play,
          label: semanticLabel ?? 'Learning game',
        ),
    };
  }

  static NurseryVisualSpec forSkill(NurserySkill skill) => forSkillId(
        skill.id,
        skill.domainId,
        semanticLabel: skill.title,
      );

  static NurseryVisualSpec forSkillId(
    String skillId,
    String domainId, {
    String? semanticLabel,
  }) {
    final id = skillId.trim().toLowerCase();
    final label = semanticLabel ?? _humanize(skillId);
    if (id.contains('trace')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.tracing,
        label: label,
      );
    }
    if (id.contains('sound') || id.contains('listen')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.listening,
        label: label,
      );
    }
    if (id.contains('word_picture')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.pictureWords,
        label: label,
      );
    }
    if (id.contains('case_match') || id.contains('matching')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.matching,
        label: label,
      );
    }
    if (id.contains('sorting')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.sorting,
        label: label,
      );
    }
    if (id.contains('count') || id.contains('quantity')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.counting,
        label: label,
      );
    }
    if (id.contains('add')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.addition,
        label: label,
      );
    }
    if (id.contains('number') || id.contains('missing_number')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.maths,
        label: label,
      );
    }
    if (id.contains('colour')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.colours,
        label: label,
      );
    }
    if (id.contains('shape')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.shapes,
        label: label,
      );
    }
    if (id.contains('animal')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.animals,
        label: label,
      );
    }
    if (id.contains('food')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.food,
        label: label,
      );
    }
    if (id.contains('object')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.objects,
        label: label,
      );
    }
    if (id.contains('body')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.body,
        label: label,
      );
    }
    if (id.contains('routine')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.routines,
        label: label,
      );
    }
    if (id.contains('pattern')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.patterns,
        label: label,
      );
    }
    if (id.contains('observation')) {
      return _painted(
        key: 'skill:$id',
        concept: NurseryVisualConcept.observation,
        label: label,
      );
    }
    return forDomainId(domainId, semanticLabel: label);
  }

  static NurseryVisualSpec forLearningPath(
    String pathId,
    String domainId, {
    String? semanticLabel,
  }) {
    final id = pathId.trim().toLowerCase();
    final label = semanticLabel ?? _humanize(pathId);
    if (id.contains('trace')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.tracing,
        label: label,
      );
    }
    if (id.contains('sound') || id.contains('listen')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.listening,
        label: label,
      );
    }
    if (id.contains('picture')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.pictureWords,
        label: label,
      );
    }
    if (id.contains('count')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.counting,
        label: label,
      );
    }
    if (id.contains('add')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.addition,
        label: label,
      );
    }
    if (id.contains('colour') || id.contains('shape')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.shapes,
        label: label,
      );
    }
    if (id.contains('animal') || id.contains('food')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.animals,
        label: label,
      );
    }
    if (id.contains('everyday')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.routines,
        label: label,
      );
    }
    if (id.contains('match') || id.contains('sort')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.matching,
        label: label,
      );
    }
    if (id.contains('pattern')) {
      return _painted(
        key: 'path:$id',
        concept: NurseryVisualConcept.patterns,
        label: label,
      );
    }
    return forDomainId(domainId, semanticLabel: label);
  }

  static NurseryVisualSpec forActivity(
    NurserySkill skill,
    NurseryActivity activity, {
    String? semanticLabel,
  }) {
    final label = semanticLabel ?? skill.title;
    if (activity.isTrace) {
      return _painted(
        key: 'activity:${activity.id}',
        concept: NurseryVisualConcept.tracing,
        label: label,
      );
    }
    if (activity.interaction == 'pairMatch') {
      return _painted(
        key: 'activity:${activity.id}',
        concept: NurseryVisualConcept.matching,
        label: label,
      );
    }
    if (activity.interaction == 'sortBuckets') {
      return _painted(
        key: 'activity:${activity.id}',
        concept: NurseryVisualConcept.sorting,
        label: label,
      );
    }
    if (activity.phase == 'transfer') {
      return _painted(
        key: 'activity:${activity.id}',
        concept: NurseryVisualConcept.celebration,
        label: label,
      );
    }
    return forSkillId(
      skill.id,
      skill.domainId,
      semanticLabel: label,
    );
  }

  static NurseryVisualSpec forLetterExample(
    NurseryLetterAssociation letter,
    NurseryLetterExample example,
  ) {
    if (example.assetPath.trim().isNotEmpty) {
      return NurseryVisualSpec(
        key: 'letter:${letter.uppercase}:${example.word.toLowerCase()}',
        concept: NurseryVisualConcept.localPicture,
        source: NurseryVisualSource.localAsset,
        semanticLabel: '${example.word} picture',
        assetPath: example.assetPath,
        text: letter.uppercase,
      );
    }
    return NurseryVisualSpec(
      key: 'letter:${letter.uppercase}:${example.word.toLowerCase()}:fallback',
      concept: NurseryVisualConcept.letter,
      source: NurseryVisualSource.typography,
      semanticLabel: '${example.word} picture',
      text: letter.uppercase,
    );
  }

  static NurseryVisualSpec forSemanticPicture(
    String label, {
    String? fallbackText,
  }) {
    final normalized = label.trim().toLowerCase();
    final assetPath = NurseryAssetCatalog.assetForLabel(normalized);
    if (assetPath != null) {
      return NurseryVisualSpec(
        key: 'semantic-picture:$normalized',
        concept: _conceptForHint(normalized),
        source: NurseryVisualSource.localAsset,
        semanticLabel: label,
        assetPath: assetPath,
        text: fallbackText,
        variant: normalized,
      );
    }
    return _painted(
      key: 'semantic-picture:$normalized:fallback',
      concept: _conceptForHint(normalized),
      label: label,
      variant: normalized,
    );
  }

  /// Resolves a child-facing game value without changing its authored value.
  ///
  /// Unlike [fromLegacyToken], this boundary also promotes plain semantic
  /// words (for example `dog`, `ball`, `red`, or `triangle`) to bundled
  /// pictures or painted vectors. [skillId] and [prompt] disambiguate words
  /// such as `orange`, which can mean a fruit or a colour.
  static NurseryVisualSpec forInteractionValue(
    String value, {
    String? skillId,
    String? prompt,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const NurseryVisualSpec(
        key: 'interaction:empty',
        concept: NurseryVisualConcept.text,
        source: NurseryVisualSource.typography,
        semanticLabel: 'Empty learning card',
        text: '',
      );
    }

    final normalized = trimmed.toLowerCase();
    final context = '${skillId ?? ''} ${prompt ?? ''}'.toLowerCase();

    if (normalized.startsWith('colour:') || normalized.startsWith('color:')) {
      final variant = normalized.substring(normalized.indexOf(':') + 1).trim();
      final colour = _colourVariant('', variant);
      if (colour != null) {
        return _painted(
          key: 'interaction:colour:$colour',
          concept: NurseryVisualConcept.colours,
          label: colour,
          variant: colour,
        );
      }
    }
    if (normalized.startsWith('shape:')) {
      final variant = normalized.substring('shape:'.length).trim();
      final shape = _shapeVariant('', variant);
      if (shape != null) {
        return _painted(
          key: 'interaction:shape:$shape',
          concept: NurseryVisualConcept.shapes,
          label: shape,
          variant: shape,
        );
      }
    }

    final spoken = nurserySpokenLabel(trimmed);

    // Context-sensitive concepts must win before generic picture lookup.
    // `orange` in a colour lesson should be a colour swatch, while `orange`
    // in a food lesson should remain the bundled fruit illustration.
    if (context.contains('colour') || context.contains('color')) {
      final colour = _colourVariant('', normalized);
      if (colour != null) {
        return _painted(
          key: 'interaction:colour:$colour',
          concept: NurseryVisualConcept.colours,
          label: spoken,
          variant: colour,
        );
      }
    }
    if (context.contains('shape')) {
      final shape = _shapeVariant('', normalized);
      if (shape != null) {
        return _painted(
          key: 'interaction:shape:$shape',
          concept: NurseryVisualConcept.shapes,
          label: spoken,
          variant: shape,
        );
      }
    }

    if (nurseryContainsRawVisualToken(trimmed)) {
      return fromLegacyToken(trimmed, semanticHint: spoken);
    }

    final counted = _countedSemanticVisual(trimmed, spoken);
    if (counted != null) return counted;

    final normalizedSkill = (skillId ?? '').trim().toLowerCase();
    final alphabetWordShouldStayText = normalizedSkill.startsWith('alpha_') &&
        !normalizedSkill.contains('word_picture') &&
        RegExp(r'^[A-Za-z]+$').hasMatch(trimmed) &&
        trimmed.length > 1;
    if (alphabetWordShouldStayText) {
      return NurseryVisualSpec(
        key: 'interaction:text:${normalized.replaceAll(' ', '-')}',
        concept: _typographyConcept(trimmed),
        source: NurseryVisualSource.typography,
        semanticLabel: spoken.isEmpty ? trimmed : spoken,
        text: trimmed,
      );
    }

    if (normalized == 'none' || normalized == '(none)') {
      return NurseryVisualSpec(
        key: 'interaction:none',
        concept: NurseryVisualConcept.number,
        source: NurseryVisualSource.typography,
        semanticLabel: 'no objects',
        text: '0',
      );
    }

    final assetPath = NurseryAssetCatalog.assetForLabel(trimmed);
    if (assetPath != null) {
      return NurseryVisualSpec(
        key: 'interaction:asset:${normalized.replaceAll(' ', '-')}',
        concept: _conceptForHint(normalized),
        source: NurseryVisualSource.localAsset,
        semanticLabel: spoken.isEmpty ? trimmed : spoken,
        assetPath: assetPath,
        text: trimmed.isEmpty ? null : trimmed[0].toUpperCase(),
        variant: normalized,
      );
    }

    // Plain colour/shape words also appear in sorting buckets where the
    // activity prompt carries the semantic context rather than the skill id.
    final colour = _colourVariant('', normalized);
    if (colour != null && normalized != 'orange') {
      return _painted(
        key: 'interaction:colour:$colour',
        concept: NurseryVisualConcept.colours,
        label: spoken,
        variant: colour,
      );
    }
    final shape = _shapeVariant('', normalized);
    if (shape != null) {
      return _painted(
        key: 'interaction:shape:$shape',
        concept: NurseryVisualConcept.shapes,
        label: spoken,
        variant: shape,
      );
    }

    if (const <String>{'fruit', 'fruits', 'food'}.contains(normalized)) {
      return _painted(
        key: 'interaction:food:$normalized',
        concept: NurseryVisualConcept.food,
        label: spoken,
        variant: normalized,
      );
    }
    if (const <String>{'animal', 'animals'}.contains(normalized)) {
      return _painted(
        key: 'interaction:animal:$normalized',
        concept: NurseryVisualConcept.animals,
        label: spoken,
        variant: normalized,
      );
    }
    if (const <String>{'object', 'objects'}.contains(normalized)) {
      return _painted(
        key: 'interaction:object:$normalized',
        concept: NurseryVisualConcept.objects,
        label: spoken,
        variant: normalized,
      );
    }
    if (const <String>{
      'eyes',
      'ears',
      'hair',
      'hands',
      'feet',
      'knees',
      'nose',
      'mouth',
    }.contains(normalized)) {
      return _painted(
        key: 'interaction:body:$normalized',
        concept: NurseryVisualConcept.body,
        label: spoken,
        variant: normalized,
      );
    }
    if (normalized == 'same' || normalized == 'different') {
      return _painted(
        key: 'interaction:observation:$normalized',
        concept: NurseryVisualConcept.observation,
        label: spoken,
        variant: normalized,
      );
    }

    final semanticConcept = switch (normalized) {
      'alphabet' => NurseryVisualConcept.alphabet,
      'numbers' => NurseryVisualConcept.maths,
      'world' => NurseryVisualConcept.world,
      'thinking' => NurseryVisualConcept.thinking,
      'listening' => NurseryVisualConcept.listening,
      'pencil' => NurseryVisualConcept.tracing,
      'sorting' => NurseryVisualConcept.sorting,
      'matching' => NurseryVisualConcept.matching,
      'picture words' => NurseryVisualConcept.pictureWords,
      'celebration' => NurseryVisualConcept.celebration,
      'addition' => NurseryVisualConcept.addition,
      'play' => NurseryVisualConcept.play,
      _ => null,
    };
    if (semanticConcept != null) {
      return _painted(
        key: 'interaction:concept:${normalized.replaceAll(' ', '-')}',
        concept: semanticConcept,
        label: spoken.isEmpty ? trimmed : spoken,
        variant: normalized,
      );
    }

    return NurseryVisualSpec(
      key: 'interaction:text:${normalized.replaceAll(' ', '-')}',
      concept: _typographyConcept(trimmed),
      source: NurseryVisualSource.typography,
      semanticLabel: spoken.isEmpty ? trimmed : spoken,
      text: trimmed,
    );
  }

  static NurseryVisualSpec garden({String label = 'Learning garden'}) =>
      _painted(
        key: 'scene:garden',
        concept: NurseryVisualConcept.garden,
        label: label,
      );

  static NurseryVisualSpec play({String label = 'Play'}) => _painted(
        key: 'action:play',
        concept: NurseryVisualConcept.play,
        label: label,
      );

  static NurseryVisualSpec review({String label = 'Play again'}) => _painted(
        key: 'action:review',
        concept: NurseryVisualConcept.review,
        label: label,
      );

  static NurseryVisualSpec celebration({String label = 'Great job'}) =>
      _painted(
        key: 'feedback:celebration',
        concept: NurseryVisualConcept.celebration,
        label: label,
      );

  /// Compatibility bridge for pre-Step-8 pictogram strings.
  ///
  /// The old Unicode value is normalized immediately and never reaches the
  /// presentation layer. New semantic content may also call this method while
  /// older widgets are being migrated; semantic values pass through safely.
  static NurseryVisualSpec fromLegacyToken(
    String token, {
    String? semanticHint,
  }) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return const NurseryVisualSpec(
        key: 'legacy:empty',
        concept: NurseryVisualConcept.text,
        source: NurseryVisualSource.typography,
        semanticLabel: 'Empty learning card',
        text: '',
      );
    }

    final canonical = nurseryCanonicalLegacyVisualValue(trimmed);
    final spokenHint = semanticHint?.trim();
    final spoken = spokenHint != null &&
            spokenHint.isNotEmpty &&
            !nurseryContainsLegacyEmoji(spokenHint)
        ? spokenHint
        : nurserySpokenLabel(canonical);

    if (canonical == '●' || canonical == '★') {
      final variant = canonical == '●' ? 'dot' : 'star';
      return _painted(
        key: 'legacy-count:$variant',
        concept: NurseryVisualConcept.counting,
        label: spoken,
        variant: variant,
      );
    }
    final shape = _shapeVariant(canonical, canonical.toLowerCase());
    if (shape != null && const <String>{'▲', '■', '▭'}.contains(canonical)) {
      return _painted(
        key: 'legacy-shape:$shape',
        concept: NurseryVisualConcept.shapes,
        label: spoken,
        variant: shape,
      );
    }

    return forInteractionValue(canonical);
  }

  static List<String> compactVisualTokens(Iterable<String> tokens) {
    final result = <String>[];
    String? previous;
    var runCount = 0;

    void flush() {
      final value = previous;
      if (value == null) return;
      if (runCount > 1 && _isCountableSemantic(value)) {
        result.add(nurseryCountedSemanticLabel(runCount, value));
      } else {
        for (var index = 0; index < runCount; index += 1) {
          result.add(value);
        }
      }
    }

    for (final raw in tokens) {
      final token = nurseryCanonicalLegacyVisualValue(raw.trim());
      if (token.isEmpty) continue;
      if (previous == token) {
        runCount += 1;
        continue;
      }
      flush();
      previous = token;
      runCount = 1;
    }
    flush();
    return List<String>.unmodifiable(result);
  }

  /// Extracts visual groups embedded in authored prompt text. This lets the
  /// presentation show real illustrations/vectors while keeping the original
  /// authored string untouched for IDs, narration and evaluation contracts.
  static List<NurseryVisualSpec> visualsInText(String value) {
    final tokens = nurseryVisualTokensInText(value);
    return <NurseryVisualSpec>[
      for (final token in tokens) fromLegacyToken(token),
    ];
  }

  static String? _colourVariant(String token, String hint) {
    final normalized = hint.trim().toLowerCase();
    if (const <String>{'red', 'blue', 'green', 'yellow', 'orange', 'purple'}
        .contains(normalized)) {
      return normalized;
    }
    if (normalized.contains('red')) return 'red';
    if (normalized.contains('blue')) return 'blue';
    if (normalized.contains('green')) return 'green';
    if (normalized.contains('yellow')) return 'yellow';
    if (normalized.contains('orange') && !normalized.contains('fruit')) {
      return 'orange';
    }
    if (normalized.contains('purple')) return 'purple';
    return null;
  }

  static String? _shapeVariant(String token, String hint) {
    if (token == '▲') return 'triangle';
    if (token == '■') return 'square';
    if (token == '▭') return 'rectangle';
    final normalized = hint.trim().toLowerCase();
    if (normalized.contains('triangle')) return 'triangle';
    if (normalized.contains('square')) return 'square';
    if (normalized.contains('rectangle')) return 'rectangle';
    if (normalized == 'circle') return 'circle';
    return null;
  }

  static NurseryVisualSpec? _countedSemanticVisual(
    String value,
    String spoken,
  ) {
    final match =
        RegExp(r'^(\d+)\s+(.+)$').firstMatch(value.trim().toLowerCase());
    if (match == null) return null;
    final count = int.tryParse(match.group(1)!);
    if (count == null || count < 1) return null;
    final singular = _singularCountable(match.group(2)!);
    if (singular == null) return null;

    final assetPath = NurseryAssetCatalog.assetForLabel(singular);
    if (assetPath != null) {
      return NurseryVisualSpec(
        key: 'interaction:count:$singular:$count',
        concept: _conceptForHint(singular),
        source: NurseryVisualSource.localAsset,
        semanticLabel: spoken,
        assetPath: assetPath,
        text: singular[0].toUpperCase(),
        variant: singular,
        count: count,
      );
    }
    if (singular == 'dot' || singular == 'star') {
      return _painted(
        key: 'interaction:count:$singular:$count',
        concept: NurseryVisualConcept.counting,
        label: spoken,
        variant: singular,
        count: count,
      );
    }
    return null;
  }

  static bool _isCountableSemantic(String value) =>
      _singularCountable(value) != null;

  static String? _singularCountable(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'dot' || 'dots' => 'dot',
      'star' || 'stars' => 'star',
      'apple' || 'apples' => 'apple',
      'banana' || 'bananas' => 'banana',
      'orange' || 'oranges' => 'orange',
      'mango' || 'mangoes' => 'mango',
      'carrot' || 'carrots' => 'carrot',
      'fish' => 'fish',
      'ball' || 'balls' => 'ball',
      'foot' || 'feet' => 'foot',
      'ear' || 'ears' => 'ear',
      _ => null,
    };
  }

  static NurseryVisualConcept _typographyConcept(String value) {
    if (RegExp(r'^[A-Za-z]$').hasMatch(value))
      return NurseryVisualConcept.letter;
    if (RegExp(r'^\d+$').hasMatch(value)) return NurseryVisualConcept.number;
    return NurseryVisualConcept.text;
  }

  static NurseryVisualSpec _painted({
    required String key,
    required NurseryVisualConcept concept,
    required String label,
    String? variant,
    int count = 1,
  }) =>
      NurseryVisualSpec(
        key: key,
        concept: concept,
        source: NurseryVisualSource.painted,
        semanticLabel: label,
        variant: variant,
        count: count,
      );

  static NurseryVisualConcept _conceptForHint(String hint) {
    if (hint.contains('letter') || hint.contains('alphabet')) {
      return NurseryVisualConcept.alphabet;
    }
    if (hint.contains('number') || hint.contains('math')) {
      return NurseryVisualConcept.maths;
    }
    if (hint.contains('listen') ||
        hint.contains('sound') ||
        hint.contains('ear')) {
      return NurseryVisualConcept.listening;
    }
    if (hint.contains('trace') || hint.contains('pencil')) {
      return NurseryVisualConcept.tracing;
    }
    if (hint.contains('match')) return NurseryVisualConcept.matching;
    if (hint.contains('sort')) return NurseryVisualConcept.sorting;
    if (hint.contains('colour') || hint.contains('color')) {
      return NurseryVisualConcept.colours;
    }
    if (hint.contains('shape') ||
        hint.contains('circle') ||
        hint.contains('triangle')) {
      return NurseryVisualConcept.shapes;
    }
    if (hint.contains('cat') ||
        hint.contains('dog') ||
        hint.contains('fish') ||
        hint.contains('bird') ||
        hint.contains('animal')) {
      return NurseryVisualConcept.animals;
    }
    if (hint.contains('apple') ||
        hint.contains('banana') ||
        hint.contains('fruit') ||
        hint.contains('food')) {
      return NurseryVisualConcept.food;
    }
    return NurseryVisualConcept.play;
  }

  static String _humanize(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
