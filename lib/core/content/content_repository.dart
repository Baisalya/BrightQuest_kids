import 'dart:convert';

import '../curriculum/content_contract.dart';
import '../nursery/nursery_content.dart';
import 'content_activity.dart';
import 'content_generators.dart';
import 'content_pack_validator.dart';
import 'game_content.dart';
import 'learning_blueprint.dart';
import 'skill_studio_generators.dart';

class ContentPackFormatException implements Exception {
  const ContentPackFormatException(this.issues);

  final List<ContentPackValidationIssue> issues;

  @override
  String toString() =>
      'Invalid BrightQuest content pack:\n${issues.join('\n')}';
}

class DevelopmentPackAccessPolicy {
  const DevelopmentPackAccessPolicy({
    this.enabled = false,
    this.lockedClasses = const <int>{},
  });

  final bool enabled;
  final Set<int> lockedClasses;

  static const disabled = DevelopmentPackAccessPolicy();

  factory DevelopmentPackAccessPolicy.fromEnvironment({
    required bool developmentMode,
  }) {
    if (!developmentMode) return disabled;
    const enabled = bool.fromEnvironment(
      'BRIGHTQUEST_DEV_PACK_LOCKS',
      defaultValue: false,
    );
    if (!enabled) return disabled;
    const raw = String.fromEnvironment(
      'BRIGHTQUEST_DEV_LOCKED_CLASSES',
      defaultValue: '',
    );
    final classes = raw
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .where((value) => value >= 3 && value <= 5)
        .toSet();
    return DevelopmentPackAccessPolicy(
      enabled: true,
      lockedClasses: Set<int>.unmodifiable(classes),
    );
  }

  bool isUnlocked(int classNumber) =>
      !enabled || !lockedClasses.contains(classNumber);
}

class ContentRepository {
  ContentRepository._({
    required this.curriculum,
    required Map<int, ContentPack> packs,
    required Map<String, LearningBlueprint> learningBlueprints,
    required this.accessPolicy,
    this.verifiedAccessResolver,
    this.nurseryPack,
  })  : _packs = Map<int, ContentPack>.unmodifiable(packs),
        _learningBlueprints =
            Map<String, LearningBlueprint>.unmodifiable(learningBlueprints);

  final CurriculumContract curriculum;
  final Map<int, ContentPack> _packs;
  final Map<String, LearningBlueprint> _learningBlueprints;
  final DevelopmentPackAccessPolicy accessPolicy;
  final bool Function(int classNumber)? verifiedAccessResolver;
  final NurseryContentPack? nurseryPack;

  static const int generatedPracticeVariantsPerFamily = 12;
  static const int maxGeneratedPracticeSeed = 999999999;

  /// Legacy public helper count (Math/Fraction/Grammar/Map, four generated
  /// samples per difficulty) retained for compatibility with existing audits.
  static const int generatedPracticeVariantCountPerClass =
      generatedPracticeVariantsPerFamily * 4;

  /// Step 4 mission planner capacity: eight world-game families × three exact
  /// tiers × twelve deterministic variants per family/tier.
  static const int generatedMissionFamilyCount = 8;
  static const int generatedMissionVariantCountPerClass =
      generatedPracticeVariantsPerFamily * generatedMissionFamilyCount * 3;

  static const List<String> bundledPackPaths = <String>[
    'assets/content/class_3/pack.json',
    'assets/content/class_4/pack.json',
    'assets/content/class_5/pack.json',
  ];

  static const String bundledNurseryPackPath =
      'assets/content/nursery/pack_v1.json';

  static const List<String> bundledBlueprintPaths = <String>[
    'assets/content/class_3/learning_blueprints.json',
    'assets/content/class_4/learning_blueprints.json',
    'assets/content/class_5/learning_blueprints.json',
  ];

  static Future<ContentRepository> loadBundled({
    required Future<String> Function(String path) loadAssetString,
    DevelopmentPackAccessPolicy accessPolicy =
        DevelopmentPackAccessPolicy.disabled,
    bool Function(int classNumber)? verifiedAccessResolver,
  }) async {
    final schemaJson = _decodeMap(
      await loadAssetString('assets/content/content_schema_v1.json'),
    );
    final curriculumJson = _decodeMap(
      await loadAssetString('assets/content/curriculum_map.json'),
    );
    final packs = <Map<String, dynamic>>[];
    for (final path in bundledPackPaths) {
      packs.add(_decodeMap(await loadAssetString(path)));
    }
    final blueprints = <Map<String, dynamic>>[];
    for (final path in bundledBlueprintPaths) {
      blueprints.add(_decodeMap(await loadAssetString(path)));
    }
    final nurseryJson = _decodeMap(
      await loadAssetString(bundledNurseryPackPath),
    );
    return ContentRepository.fromJsonPacks(
      curriculumJson: curriculumJson,
      schemaJson: schemaJson,
      packJson: packs,
      blueprintJson: blueprints,
      nurseryJson: nurseryJson,
      accessPolicy: accessPolicy,
      verifiedAccessResolver: verifiedAccessResolver,
    );
  }

  factory ContentRepository.fromJsonPacks({
    required Map<String, dynamic> curriculumJson,
    required List<Map<String, dynamic>> packJson,
    List<Map<String, dynamic>> blueprintJson = const <Map<String, dynamic>>[],
    Map<String, dynamic>? schemaJson,
    Map<String, dynamic>? nurseryJson,
    DevelopmentPackAccessPolicy accessPolicy =
        DevelopmentPackAccessPolicy.disabled,
    bool Function(int classNumber)? verifiedAccessResolver,
  }) {
    final curriculum = CurriculumContract.fromJson(curriculumJson);
    const validator = ContentPackValidator();
    final issues = <ContentPackValidationIssue>[];
    if (schemaJson != null) {
      issues.addAll(validator.validateSchemaDocument(schemaJson).issues);
    }
    issues.addAll(
      validator.validateAll(packs: packJson, curriculum: curriculum).issues,
    );
    if (issues.any((issue) => !issue.warning)) {
      throw ContentPackFormatException(List.unmodifiable(issues));
    }

    final packs = <int, ContentPack>{};
    for (final raw in packJson) {
      final pack = ContentPack.fromJson(raw);
      packs[pack.classNumber] = pack;
    }
    final learningBlueprints = _parseLearningBlueprints(
      curriculum: curriculum,
      packs: packs,
      blueprintJson: blueprintJson,
    );
    return ContentRepository._(
      curriculum: curriculum,
      packs: packs,
      learningBlueprints: learningBlueprints,
      nurseryPack:
          nurseryJson == null ? null : NurseryContentPack.fromJson(nurseryJson),
      accessPolicy: accessPolicy,
      verifiedAccessResolver: verifiedAccessResolver,
    );
  }

  static Map<String, dynamic> _decodeMap(String source) =>
      Map<String, dynamic>.from(jsonDecode(source) as Map);

  static Map<String, LearningBlueprint> _parseLearningBlueprints({
    required CurriculumContract curriculum,
    required Map<int, ContentPack> packs,
    required List<Map<String, dynamic>> blueprintJson,
  }) {
    final result = <String, LearningBlueprint>{};
    final seenClasses = <int>{};
    for (final raw in blueprintJson) {
      final pack = LearningBlueprintPack.fromJson(raw);
      if (!seenClasses.add(pack.classNumber)) {
        throw FormatException(
          'Duplicate learning blueprint pack for Class ${pack.classNumber}.',
        );
      }
      final contract = curriculum.classPack(pack.classNumber);
      final contentPack = packs[pack.classNumber];
      if (contract == null || contentPack == null) {
        throw FormatException(
          'Learning blueprints reference unknown Class ${pack.classNumber}.',
        );
      }
      final expected = contract.competencies.map((value) => value.id).toSet();
      final actual = pack.blueprints.map((value) => value.competencyId).toSet();
      if (pack.competencyCount != pack.blueprints.length ||
          actual.length != pack.blueprints.length ||
          !actual.containsAll(expected) ||
          !expected.containsAll(actual)) {
        throw FormatException(
          'Class ${pack.classNumber} learning blueprint coverage does not match its curriculum contract.',
        );
      }
      final activityIds =
          contentPack.activities.map((value) => value.id).toSet();
      for (final blueprint in pack.blueprints) {
        if (blueprint.classNumber != pack.classNumber ||
            blueprint.independentSourceActivityIds
                .any((id) => !activityIds.contains(id))) {
          throw FormatException(
            'Learning blueprint ${blueprint.competencyId} has an invalid class or activity reference.',
          );
        }
        result[blueprint.competencyId] = blueprint;
      }
    }
    return result;
  }

  List<ContentPack> get packs {
    final values = _packs.values.toList()
      ..sort((a, b) => a.classNumber.compareTo(b.classNumber));
    return List<ContentPack>.unmodifiable(values);
  }

  Iterable<ContentActivity> get allActivities sync* {
    for (final pack in packs) {
      yield* pack.activities;
    }
  }

  List<LearningBlueprint> get learningBlueprints {
    final values = _learningBlueprints.values.toList()
      ..sort((a, b) {
        final classOrder = a.classNumber.compareTo(b.classNumber);
        return classOrder != 0
            ? classOrder
            : a.competencyId.compareTo(b.competencyId);
      });
    return List<LearningBlueprint>.unmodifiable(values);
  }

  LearningBlueprint? learningBlueprintForCompetency(String competencyId) =>
      _learningBlueprints[competencyId];

  bool nurseryActivityAccessible(String activityId) {
    final pack = nurseryPack;
    if (pack == null) return false;
    // While Nursery is a review-only, paid-ineligible pack, reviewers may
    // exercise the full pack. If paid eligibility is ever enabled, this
    // repository fails closed to the four declared samples until a separate
    // verified Nursery entitlement resolver is implemented.
    if (!pack.commercial.paidEligibility) return true;
    return pack.isFreeSampleActivity(activityId);
  }

  ContentPack packForClass(int classNumber) {
    final pack = _packs[classNumber];
    if (pack == null) {
      throw StateError('No BrightQuest content pack for Class $classNumber.');
    }
    return pack;
  }

  bool isClassPackUnlocked(int classNumber) {
    final pack = _packs[classNumber];
    if (pack == null) return false;
    if (!accessPolicy.isUnlocked(classNumber)) return false;
    // Unreviewed packs remain fully available for development/testing. Once a
    // pack is marked commercially eligible, production access must come from
    // a verified store/backend resolver rather than a local preference flag.
    if (!pack.commercial.paidEligibility) return true;
    return verifiedAccessResolver?.call(classNumber) ?? false;
  }

  bool isFreeSampleActivity(ContentActivity activity) => packForClass(
        activity.classNumber,
      ).commercial.isFreeSampleActivity(activity.id);

  ContentActivity? activityById(String activityId) {
    for (final activity in allActivities) {
      if (activity.id == activityId) return activity;
    }

    final skillGenerated = RegExp(
      r'^skillgen_(c[345]_[a-z0-9_]+)_s(\d{1,9})$',
    ).firstMatch(activityId);
    if (skillGenerated != null) {
      final competencyId = skillGenerated.group(1)!;
      final classNumber = int.parse(competencyId.substring(1, 2));
      final seed = int.parse(skillGenerated.group(2)!);
      if (!isClassPackUnlocked(classNumber)) return null;
      ContentActivity? template;
      for (final candidate in packForClass(classNumber).activities) {
        if (candidate.gameId == 'skill_studio' &&
            candidate.competencyId == competencyId) {
          template = candidate;
          break;
        }
      }
      if (template == null) return null;
      return const SkillStudioPracticeGenerators().generate(
        template: template,
        seed: seed,
      );
    }

    // Mission-run plans persist canonical generated activity ids. Rehydrate
    // them through the same deterministic generator bridge used by legacy
    // content ids so lesson/game resume never needs to store answer payloads.
    final generated = RegExp(
      r'^c([345])_generated_(math|fraction|grammar|map|story|science|coding|recycling)_d([123])_s(\d{1,9})$',
    ).firstMatch(activityId);
    if (generated == null) return null;
    final classNumber = int.parse(generated.group(1)!);
    final family = generated.group(2)!;
    final difficulty = int.parse(generated.group(3)!);
    final seed = int.parse(generated.group(4)!);
    if (seed < 0 || seed > maxGeneratedPracticeSeed) return null;
    final gameId = switch (family) {
      'math' => 'math_market',
      'fraction' => 'fraction_pizza',
      'grammar' => 'grammar_puzzle',
      'map' => 'map_quest',
      'story' => 'story_builder',
      'science' => 'science_lab',
      'coding' => 'coding_maze',
      'recycling' => 'recycling_challenge',
      _ => '',
    };
    if (gameId.isEmpty || !isClassPackUnlocked(classNumber)) return null;
    return _generatedPracticeActivity(
      classNumber: classNumber,
      gameId: gameId,
      legacyContentId: 'gen_${family}_c${classNumber}_d${difficulty}_s$seed',
    );
  }

  ContentActivity? activityForLegacyContent({
    required int classNumber,
    required String gameId,
    required String legacyContentId,
  }) {
    for (final activity in packForClass(classNumber).activities) {
      if (activity.gameId == gameId &&
          activity.legacyContentId == legacyContentId) {
        return activity;
      }
    }
    if (!isClassPackUnlocked(classNumber)) return null;
    return _generatedPracticeActivity(
      classNumber: classNumber,
      gameId: gameId,
      legacyContentId: legacyContentId,
    );
  }

  ContentActivity? activityForScienceReaction({
    required int classNumber,
    required String reactionId,
  }) {
    for (final activity in packForClass(classNumber).activities) {
      if (activity.gameId == 'science_lab' &&
          activity.payload['reactionId'] == reactionId) {
        return activity;
      }
    }
    return null;
  }

  List<ContentActivity> activitiesForCompetency(
    int classNumber,
    String competencyId,
  ) =>
      List<ContentActivity>.unmodifiable(
        activitiesForClass(classNumber)
            .where(
              (activity) => activity.allCompetencyIds.contains(competencyId),
            )
            .toList(growable: false),
      );

  /// Returns a rolling generated practice window for direct Skill Studio.
  ///
  /// Existing audited World generators are reused only when their generated
  /// activity still belongs to the requested competency. Dedicated Skill
  /// Studio Maths gaps use the conservative parameterised generator.
  /// Knowledge-heavy competencies deliberately return an empty list and rely
  /// on authored spaced review instead of fabricated content.
  List<ContentActivity> generatedSkillStudioPracticeForCompetency(
    int classNumber,
    String competencyId, {
    required int seedBase,
    int candidateCount = 32,
  }) {
    if (!isClassPackUnlocked(classNumber) || candidateCount <= 0) {
      return const <ContentActivity>[];
    }
    final authored = activitiesForCompetency(classNumber, competencyId);
    if (authored.isEmpty) return const <ContentActivity>[];

    final result = <ContentActivity>[];
    final seenIds = <String>{};
    void add(ContentActivity activity) {
      if (activity.classNumber == classNumber &&
          activity.competencyId == competencyId &&
          seenIds.add(activity.id)) {
        result.add(activity);
      }
    }

    final gameIds = authored
        .map((activity) => activity.gameId)
        .where(_supportsGeneratedWorldFamily)
        .toSet();
    for (final gameId in gameIds) {
      final generated = generatedEndlessPracticeActivitiesForGame(
        classNumber,
        gameId,
        maxDifficulty: 3,
        seedBase: seedBase,
        candidatesPerDifficulty: 16,
      );
      for (final activity in generated) {
        if (activity.competencyId == competencyId) add(activity);
        if (result.length >= candidateCount) {
          return List<ContentActivity>.unmodifiable(result);
        }
      }
    }

    ContentActivity? template;
    for (final activity in authored) {
      if (activity.gameId == 'skill_studio') {
        template = activity;
        break;
      }
    }
    final generators = const SkillStudioPracticeGenerators();
    if (template != null && generators.supports(competencyId)) {
      final normalizedBase = seedBase.abs() % 900000000;
      for (var offset = 0; offset < candidateCount * 2; offset += 1) {
        final seed = (normalizedBase + offset * 104729 + 17) %
            (SkillStudioPracticeGenerators.maxSeed + 1);
        final activity = generators.generate(template: template, seed: seed);
        if (activity != null) add(activity);
        if (result.length >= candidateCount) break;
      }
    }
    return List<ContentActivity>.unmodifiable(result);
  }

  bool supportsGeneratedSkillStudioPractice(
    int classNumber,
    String competencyId,
  ) {
    if (!isClassPackUnlocked(classNumber)) return false;
    final authored = activitiesForCompetency(classNumber, competencyId);
    final skillGenerators = const SkillStudioPracticeGenerators();
    if (authored.any(
      (activity) =>
          activity.gameId == 'skill_studio' &&
          skillGenerators.supports(competencyId),
    )) {
      return true;
    }
    for (final activity in authored) {
      if (!_supportsGeneratedWorldFamily(activity.gameId) ||
          activity.difficulty < 1 ||
          activity.difficulty > 3) {
        continue;
      }
      final generated = generatedPracticeActivitiesForGameAtExactDifficulty(
        classNumber,
        activity.gameId,
        difficulty: activity.difficulty,
      );
      if (generated.any(
        (candidate) => candidate.competencyId == competencyId,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool _supportsGeneratedWorldFamily(String gameId) =>
      const <String>{
        'math_market',
        'fraction_pizza',
        'grammar_puzzle',
        'map_quest',
        'story_builder',
        'science_lab',
        'coding_maze',
        'recycling_challenge',
      }.contains(gameId);

  List<ContentActivity> freeSampleActivitiesForClass(int classNumber) =>
      List<ContentActivity>.unmodifiable(
        packForClass(classNumber)
            .activities
            .where(isFreeSampleActivity)
            .toList(growable: false),
      );

  List<ContentActivity> activitiesForClass(int classNumber) {
    if (!accessPolicy.isUnlocked(classNumber)) return const <ContentActivity>[];
    final activities = packForClass(classNumber).activities;
    if (isClassPackUnlocked(classNumber)) {
      return List<ContentActivity>.unmodifiable(activities);
    }
    return List<ContentActivity>.unmodifiable(
      activities.where(isFreeSampleActivity),
    );
  }

  bool canOpenLearningLevel({
    required int classNumber,
    required String gameId,
    required int difficulty,
  }) {
    if (!accessPolicy.isUnlocked(classNumber)) return false;
    final exactDifficulty = difficulty.clamp(1, 3).toInt();
    return packForClass(classNumber).activities.any(
          (activity) =>
              activity.gameId == gameId &&
              activity.difficulty == exactDifficulty &&
              (isClassPackUnlocked(classNumber) ||
                  isFreeSampleActivity(activity)),
        );
  }

  bool isGameFreeSample(int classNumber, String gameId) => packForClass(
        classNumber,
      ).activities.any(
            (activity) =>
                activity.gameId == gameId && isFreeSampleActivity(activity),
          );

  bool canOpenGame(int classNumber, String gameId) {
    if (!accessPolicy.isUnlocked(classNumber)) return false;
    return isClassPackUnlocked(classNumber) ||
        isGameFreeSample(classNumber, gameId);
  }

  /// Exact-tier authored activities used by the mission planner.
  ///
  /// The existing [activitiesForGame] API intentionally remains cumulative for
  /// legacy game screens. This exact-tier API lets the new mission-selection
  /// layer avoid replaying lower-difficulty content in Challenge/Mastery before
  /// those screens are migrated.
  List<ContentActivity> activitiesForGameAtExactDifficulty(
    int classNumber,
    String gameId, {
    required int difficulty,
  }) {
    if (!accessPolicy.isUnlocked(classNumber)) {
      throw StateError(
        'Class $classNumber content pack is locked by the development-only access policy.',
      );
    }
    final safeDifficulty = difficulty.clamp(1, 3).toInt();
    final unlocked = isClassPackUnlocked(classNumber);
    final values = packForClass(classNumber)
        .activities
        .where(
          (activity) =>
              activity.gameId == gameId &&
              activity.difficulty == safeDifficulty &&
              (unlocked || isFreeSampleActivity(activity)),
        )
        .toList(growable: false);
    return List<ContentActivity>.unmodifiable(values);
  }

  /// Deterministic generated mission variants for one exact tier.
  ///
  /// Every family is converted back into the same ContentActivity schema used
  /// by authored packs, so the mission planner, lesson engine and game adapters
  /// share one correctness/persistence boundary.
  List<ContentActivity> generatedPracticeActivitiesForGameAtExactDifficulty(
    int classNumber,
    String gameId, {
    required int difficulty,
  }) {
    if (!isClassPackUnlocked(classNumber)) return const <ContentActivity>[];
    final safeDifficulty = difficulty.clamp(1, 3).toInt();
    final family = switch (gameId) {
      'math_market' => 'math',
      'fraction_pizza' => 'fraction',
      'grammar_puzzle' => 'grammar',
      'map_quest' => 'map',
      'story_builder' => 'story',
      'science_lab' => 'science',
      'coding_maze' => 'coding',
      'recycling_challenge' => 'recycling',
      _ => null,
    };
    if (family == null) return const <ContentActivity>[];

    final result = <ContentActivity>[];
    for (var seed = 0; seed < generatedPracticeVariantsPerFamily; seed += 1) {
      final legacyContentId =
          'gen_${family}_c${classNumber}_d${safeDifficulty}_s$seed';
      final activity = _generatedPracticeActivity(
        classNumber: classNumber,
        gameId: gameId,
        legacyContentId: legacyContentId,
      );
      if (activity != null) result.add(activity);
    }
    return List<ContentActivity>.unmodifiable(result);
  }

  /// Builds a deterministic seed window for post-progression practice.
  ///
  /// The normal Learning World candidate bank remains fixed at
  /// [generatedPracticeVariantsPerFamily]. Endless Practice uses larger seeds
  /// only through this explicit API, so the 72-level release contract and its
  /// quality audit remain unchanged.
  List<ContentActivity> generatedEndlessPracticeActivitiesForGame(
    int classNumber,
    String gameId, {
    required int maxDifficulty,
    required int seedBase,
    int candidatesPerDifficulty = 24,
  }) {
    if (!isClassPackUnlocked(classNumber) || candidatesPerDifficulty <= 0) {
      return const <ContentActivity>[];
    }
    final safeDifficulty = maxDifficulty.clamp(1, 3).toInt();
    final family = switch (gameId) {
      'math_market' => 'math',
      'fraction_pizza' => 'fraction',
      'grammar_puzzle' => 'grammar',
      'map_quest' => 'map',
      'story_builder' => 'story',
      'science_lab' => 'science',
      'coding_maze' => 'coding',
      'recycling_challenge' => 'recycling',
      _ => null,
    };
    if (family == null) return const <ContentActivity>[];

    final normalizedBase = seedBase.abs() % 900000000;
    final result = <ContentActivity>[];
    for (var difficulty = 1; difficulty <= safeDifficulty; difficulty += 1) {
      for (var offset = 0; offset < candidatesPerDifficulty; offset += 1) {
        final seed = (normalizedBase + difficulty * 100003 + offset) %
            (maxGeneratedPracticeSeed + 1);
        final activity = _generatedPracticeActivity(
          classNumber: classNumber,
          gameId: gameId,
          legacyContentId:
              'gen_${family}_c${classNumber}_d${difficulty}_s$seed',
        );
        if (activity != null) result.add(activity);
      }
    }
    return List<ContentActivity>.unmodifiable(result);
  }

  List<ContentActivity> activitiesForGame(
    int classNumber,
    String gameId, {
    int difficulty = 3,
  }) {
    if (!accessPolicy.isUnlocked(classNumber)) {
      throw StateError(
        'Class $classNumber content pack is locked by the development-only access policy.',
      );
    }
    final safeDifficulty = difficulty.clamp(1, 3).toInt();
    final unlocked = isClassPackUnlocked(classNumber);
    final values = packForClass(classNumber)
        .activities
        .where(
          (activity) =>
              activity.gameId == gameId &&
              activity.difficulty <= safeDifficulty &&
              (unlocked || isFreeSampleActivity(activity)),
        )
        .toList(growable: false);
    if (values.isEmpty) {
      throw StateError(
        'No $gameId content for Class $classNumber at difficulty $safeDifficulty.',
      );
    }
    return List<ContentActivity>.unmodifiable(values);
  }

  List<MathQuestion> mathQuestionsForClass(
    int classNumber, {
    int difficulty = 3,
    bool includeGeneratedPractice = true,
  }) {
    final authored = activitiesForGame(
      classNumber,
      'math_market',
      difficulty: difficulty,
    ).map((activity) {
      final payload = activity.payload;
      return MathQuestion(
        activity.prompt,
        payload['answer'] as int,
        List<int>.from(payload['choices'] as List),
        payload['hint'] as String,
        id: activity.legacyContentId,
        topicId: activity.topicId,
        difficulty: activity.difficulty,
      );
    }).toList(growable: false);
    if (!includeGeneratedPractice || !isClassPackUnlocked(classNumber)) {
      return authored;
    }
    return <MathQuestion>[
      ...authored,
      ..._generatedByDifficulty(
        difficulty,
        (tier, seed) => const DeterministicContentGenerators().arithmetic(
          classNumber: classNumber,
          difficulty: tier,
          seed: seed,
        ),
      ),
    ];
  }

  List<FractionMission> fractionMissionsForClass(
    int classNumber, {
    int difficulty = 3,
    bool includeGeneratedPractice = true,
  }) {
    final authored = activitiesForGame(
      classNumber,
      'fraction_pizza',
      difficulty: difficulty,
    ).map((activity) {
      final payload = activity.payload;
      return FractionMission(
        id: activity.legacyContentId,
        totalSlices: payload['totalSlices'] as int,
        numerator: payload['numerator'] as int,
        denominator: payload['denominator'] as int,
        topicId: activity.topicId,
        difficulty: activity.difficulty,
      );
    }).toList(growable: false);
    if (!includeGeneratedPractice || !isClassPackUnlocked(classNumber)) {
      return authored;
    }
    return <FractionMission>[
      ...authored,
      ..._generatedByDifficulty(
        difficulty,
        (tier, seed) => const DeterministicContentGenerators().fraction(
          classNumber: classNumber,
          difficulty: tier,
          seed: seed,
        ),
      ),
    ];
  }

  List<ScienceQuizQuestion> scienceQuestionsForClass(
    int classNumber, {
    int difficulty = 3,
  }) =>
      activitiesForGame(
        classNumber,
        'science_lab',
        difficulty: difficulty,
      )
          .where((activity) => !activity.payload.containsKey('reactionId'))
          .map((activity) {
        final payload = activity.payload;
        return ScienceQuizQuestion(
          activity.prompt,
          payload['answer'] as String,
          List<String>.from(payload['choices'] as List),
          activity.explanation,
          id: activity.legacyContentId,
          topicId: activity.topicId,
          difficulty: activity.difficulty,
        );
      }).toList(growable: false);

  ScienceReaction scienceReactionForIngredients(
    int classNumber,
    Set<String> ingredients,
  ) {
    final reactions = activitiesForGame(
      classNumber,
      'science_lab',
      difficulty: 3,
    ).where((activity) => activity.payload.containsKey('reactionId'));

    ContentActivity? fallback;
    for (final activity in reactions) {
      final payload = activity.payload;
      if (payload['fallback'] == true) {
        fallback = activity;
        continue;
      }
      final required = Set<String>.from(payload['requiredIngredients'] as List);
      if (required.isNotEmpty && ingredients.containsAll(required)) {
        return _scienceReactionFrom(activity);
      }
    }
    if (fallback == null) {
      throw StateError(
        'Class $classNumber Science Lab pack has no fallback reaction.',
      );
    }
    return _scienceReactionFrom(fallback);
  }

  List<ScienceReaction> scienceReactionsForClass(int classNumber) =>
      activitiesForGame(classNumber, 'science_lab', difficulty: 3)
          .where((activity) => activity.payload.containsKey('reactionId'))
          .map(_scienceReactionFrom)
          .toList(growable: false);

  ScienceReaction _scienceReactionFrom(ContentActivity activity) {
    final payload = activity.payload;
    return ScienceReaction(
      id: payload['reactionId'] as String,
      title: payload['title'] as String,
      explanation: activity.explanation,
      emoji: payload['emoji'] as String,
    );
  }

  List<StoryMission> storyMissionsForClass(
    int classNumber, {
    int difficulty = 3,
  }) =>
      activitiesForGame(
        classNumber,
        'story_builder',
        difficulty: difficulty,
      )
          .map(
            (activity) => StoryMission(
              id: activity.legacyContentId,
              prompt: activity.prompt,
              words: List<String>.from(activity.payload['words'] as List),
              topicId: activity.topicId,
              difficulty: activity.difficulty,
            ),
          )
          .toList(growable: false);

  List<GrammarMission> grammarMissionsForClass(
    int classNumber, {
    int difficulty = 3,
    bool includeGeneratedPractice = true,
  }) {
    final authored = activitiesForGame(
      classNumber,
      'grammar_puzzle',
      difficulty: difficulty,
    ).map((activity) {
      final payload = activity.payload;
      return GrammarMission(
        id: activity.legacyContentId,
        sentence: payload['sentence'] as String,
        noun: payload['noun'] as String,
        verb: payload['verb'] as String,
        adjective: payload['adjective'] as String,
        topicId: activity.topicId,
        difficulty: activity.difficulty,
      );
    }).toList(growable: false);
    if (!includeGeneratedPractice || !isClassPackUnlocked(classNumber)) {
      return authored;
    }
    return <GrammarMission>[
      ...authored,
      ..._generatedByDifficulty(
        difficulty,
        (tier, seed) => const DeterministicContentGenerators().grammar(
          classNumber: classNumber,
          difficulty: tier,
          seed: seed,
        ),
      ),
    ];
  }

  List<MapQuestion> mapQuestionsForClass(
    int classNumber, {
    int difficulty = 3,
    bool includeGeneratedPractice = true,
  }) {
    final authored = activitiesForGame(
      classNumber,
      'map_quest',
      difficulty: difficulty,
    ).map((activity) {
      final payload = activity.payload;
      return MapQuestion(
        activity.legacyContentId,
        activity.prompt,
        payload['answer'] as String,
        List<String>.from(payload['choices'] as List),
        payload['hint'] as String,
        topicId: activity.topicId,
        difficulty: activity.difficulty,
      );
    }).toList(growable: false);
    if (!includeGeneratedPractice || !isClassPackUnlocked(classNumber)) {
      return authored;
    }
    return <MapQuestion>[
      ...authored,
      ..._generatedByDifficulty(
        difficulty,
        (tier, seed) => const DeterministicContentGenerators().mapDirection(
          classNumber: classNumber,
          difficulty: tier,
          seed: seed,
        ),
      ),
    ];
  }

  List<CodingMission> codingMissionsForClass(
    int classNumber, {
    int difficulty = 3,
  }) =>
      activitiesForGame(
        classNumber,
        'coding_maze',
        difficulty: difficulty,
      ).map((activity) {
        final payload = activity.payload;
        return CodingMission(
          id: activity.legacyContentId,
          width: payload['width'] as int,
          height: payload['height'] as int,
          startX: payload['startX'] as int,
          startY: payload['startY'] as int,
          goalX: payload['goalX'] as int,
          goalY: payload['goalY'] as int,
          startDirection: _parseFacingDirection(
            payload['startDirection'] as String,
          ),
          obstacles: Set<String>.from(payload['obstacles'] as List),
          maxCommands: payload['maxCommands'] as int,
          topicId: activity.topicId,
          difficulty: activity.difficulty,
        );
      }).toList(growable: false);

  List<RecyclingItem> recyclingItemsForClass(
    int classNumber, {
    int difficulty = 3,
  }) =>
      activitiesForGame(
        classNumber,
        'recycling_challenge',
        difficulty: difficulty,
      ).map((activity) {
        final payload = activity.payload;
        return RecyclingItem(
          activity.legacyContentId,
          payload['name'] as String,
          payload['emoji'] as String,
          payload['bin'] as String,
          topicId: activity.topicId,
          difficulty: activity.difficulty,
        );
      }).toList(growable: false);

  List<T> _generatedByDifficulty<T>(
    int requestedDifficulty,
    T Function(int difficulty, int seed) build,
  ) {
    final safeDifficulty = requestedDifficulty.clamp(1, 3).toInt();
    return List<T>.unmodifiable(<T>[
      for (var difficulty = 1; difficulty <= safeDifficulty; difficulty += 1)
        for (var seed = 0; seed < 4; seed += 1) build(difficulty, seed),
    ]);
  }

  ContentActivity? _generatedPracticeActivity({
    required int classNumber,
    required String gameId,
    required String legacyContentId,
  }) {
    final match = RegExp(
      r'^gen_(math|fraction|grammar|map|story|science|coding|recycling)_c([345])_d([123])_s(\d{1,9})$',
    ).firstMatch(legacyContentId);
    if (match == null || int.parse(match.group(2)!) != classNumber) return null;
    final parsedSeed = int.parse(match.group(4)!);
    if (parsedSeed < 0 || parsedSeed > maxGeneratedPracticeSeed) {
      return null;
    }
    final family = match.group(1)!;
    final expectedGameId = switch (family) {
      'math' => 'math_market',
      'fraction' => 'fraction_pizza',
      'grammar' => 'grammar_puzzle',
      'map' => 'map_quest',
      'story' => 'story_builder',
      'science' => 'science_lab',
      'coding' => 'coding_maze',
      'recycling' => 'recycling_challenge',
      _ => '',
    };
    if (expectedGameId != gameId) return null;
    final difficulty = int.parse(match.group(3)!);
    final seed = parsedSeed;
    const generators = DeterministicContentGenerators();

    late String prompt;
    late String topicId;
    late Map<String, dynamic> rule;
    late Map<String, dynamic> payload;
    late String explanation;
    var distractors = const <ContentDistractor>[];
    var hints = const <ContentHint>[];

    switch (family) {
      case 'math':
        final item = generators.arithmetic(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        prompt = item.text;
        topicId = item.topicId;
        rule = <String, dynamic>{'type': 'exactNumber', 'value': item.answer};
        payload = <String, dynamic>{
          'answer': item.answer,
          'choices': item.choices,
          'hint': item.hint,
        };
        explanation = '${item.text.replaceFirst('?', '${item.answer}')} '
            'Check the operation one place-value step at a time.';
        distractors = <ContentDistractor>[
          for (final choice
              in item.choices.where((value) => value != item.answer))
            ContentDistractor(
              value: choice,
              misconceptionId: 'generated_arithmetic_step',
            ),
        ];
        hints = <ContentHint>[ContentHint(step: 1, text: item.hint)];
        break;
      case 'fraction':
        final item = generators.fraction(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        final selected = item.totalSlices * item.numerator ~/ item.denominator;
        prompt =
            'Select the slices that show ${item.numerator}/${item.denominator} of ${item.totalSlices} equal slices.';
        topicId = item.topicId;
        rule = <String, dynamic>{
          'type': 'selectedSlices',
          'value': selected,
          'totalSlices': item.totalSlices,
        };
        payload = <String, dynamic>{
          'totalSlices': item.totalSlices,
          'numerator': item.numerator,
          'denominator': item.denominator,
        };
        explanation =
            '${item.numerator}/${item.denominator} of ${item.totalSlices} equal slices is $selected slices.';
        distractors = <ContentDistractor>[
          for (final choice in <int>{
            if (selected > 1) selected - 1,
            if (selected < item.totalSlices) selected + 1,
          })
            ContentDistractor(
              value: choice,
              misconceptionId: 'fraction_slice_count',
            ),
        ];
        hints = <ContentHint>[
          const ContentHint(
            step: 1,
            text: 'Split the whole into equal denominator-sized groups.',
          ),
        ];
        break;
      case 'grammar':
        final item = generators.grammar(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        prompt = 'Find the noun, verb and adjective in: ${item.sentence}';
        topicId = item.topicId;
        rule = <String, dynamic>{
          'type': 'grammarParts',
          'noun': item.noun,
          'verb': item.verb,
          'adjective': item.adjective,
        };
        payload = <String, dynamic>{
          'sentence': item.sentence,
          'noun': item.noun,
          'verb': item.verb,
          'adjective': item.adjective,
        };
        explanation =
            '${item.noun} names something, ${item.verb} shows the action and ${item.adjective} describes the noun.';
        hints = const <ContentHint>[
          ContentHint(
            step: 1,
            text:
                'Ask: who or what, what happens, and which word describes it?',
          ),
        ];
        break;
      case 'map':
        final item = generators.mapDirection(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        prompt = item.question;
        topicId = item.topicId;
        rule = <String, dynamic>{'type': 'exactText', 'value': item.answer};
        payload = <String, dynamic>{
          'answer': item.answer,
          'choices': item.choices,
          'hint': item.hint,
        };
        explanation = '${item.answer} is correct. ${item.hint}';
        distractors = <ContentDistractor>[
          for (final choice
              in item.choices.where((value) => value != item.answer))
            ContentDistractor(
              value: choice,
              misconceptionId: 'direction_turn_confusion',
            ),
        ];
        hints = <ContentHint>[ContentHint(step: 1, text: item.hint)];
        break;
      case 'story':
        final item = generators.story(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        prompt = item.prompt;
        topicId = item.topicId;
        rule = <String, dynamic>{
          'type': 'orderedWords',
          'value': item.words,
        };
        payload = <String, dynamic>{'words': item.words};
        explanation =
            'The sentence is complete when the words are arranged in this order: ${item.words.join(' ')}.';
        hints = const <ContentHint>[
          ContentHint(
            step: 1,
            text: 'Find the opening idea first, then place words so the sentence sounds complete.',
          ),
        ];
        break;
      case 'science':
        final item = generators.scienceQuiz(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        prompt = item.question;
        topicId = item.topicId;
        rule = <String, dynamic>{'type': 'exactText', 'value': item.answer};
        payload = <String, dynamic>{
          'answer': item.answer,
          'choices': item.choices,
        };
        explanation = item.explanation;
        distractors = <ContentDistractor>[
          for (final choice
              in item.choices.where((value) => value != item.answer))
            ContentDistractor(
              value: choice,
              misconceptionId: 'generated_science_concept_confusion',
            ),
        ];
        hints = <ContentHint>[
          ContentHint(step: 1, text: item.explanation),
        ];
        break;
      case 'coding':
        final item = generators.codingRoute(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        prompt =
            'On a ${item.width}×${item.height} grid, guide the robot facing ${item.startDirection.name} from (${item.startX}, ${item.startY}) to (${item.goalX}, ${item.goalY}) within ${item.maxCommands} commands.';
        topicId = item.topicId;
        rule = <String, dynamic>{
          'type': 'reachGridGoal',
          'goalX': item.goalX,
          'goalY': item.goalY,
          'maxCommands': item.maxCommands,
        };
        payload = <String, dynamic>{
          'width': item.width,
          'height': item.height,
          'startX': item.startX,
          'startY': item.startY,
          'goalX': item.goalX,
          'goalY': item.goalY,
          'startDirection': item.startDirection.name,
          'obstacles': item.obstacles.toList(growable: false),
          'maxCommands': item.maxCommands,
        };
        explanation =
            'Plan a valid route to the goal without entering blocked cells or leaving the grid.';
        hints = const <ContentHint>[
          ContentHint(
            step: 1,
            text: 'Plan the turns before adding moves, then check the command limit.',
          ),
        ];
        break;
      case 'recycling':
        final item = generators.recycling(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        prompt = 'Put ${item.name} in the correct waste-sorting bin.';
        topicId = item.topicId;
        rule = <String, dynamic>{'type': 'exactText', 'value': item.bin};
        payload = <String, dynamic>{
          'name': item.name,
          'emoji': item.emoji,
          'bin': item.bin,
        };
        explanation =
            '${item.name} belongs in the ${item.bin} material group for this practice.';
        distractors = <ContentDistractor>[
          for (final bin in const <String>['Paper', 'Plastic', 'Organic'])
            if (bin != item.bin)
              ContentDistractor(
                value: bin,
                misconceptionId: 'generated_waste_material_confusion',
              ),
        ];
        hints = const <ContentHint>[
          ContentHint(
            step: 1,
            text: 'Think about the main material, or whether the item is food or plant waste.',
          ),
        ];
        break;
    }

    final candidates = packForClass(classNumber)
        .activities
        .where((activity) => activity.gameId == gameId)
        .toList(growable: false);
    ContentActivity? template;
    for (final candidate in candidates) {
      if (candidate.topicId == topicId && candidate.difficulty == difficulty) {
        template = candidate;
        break;
      }
    }
    template ??= candidates.firstWhere(
      (activity) => activity.difficulty == difficulty,
      orElse: () => candidates.first,
    );
    return ContentActivity(
      id: 'c${classNumber}_generated_${family}_d${difficulty}_s$seed',
      legacyContentId: legacyContentId,
      classNumber: classNumber,
      gameId: gameId,
      topicId: topicId,
      subject: template.subject,
      unitId: template.unitId,
      competencyId: template.competencyId,
      relatedCompetencyIds: template.relatedCompetencyIds,
      learningOutcomeId: template.learningOutcomeId,
      relatedLearningOutcomeIds: template.relatedLearningOutcomeIds,
      activityType: family == 'coding' ? 'simulation' : 'independentPractice',
      difficulty: difficulty,
      prompt: prompt,
      correctResponseRule: rule,
      explanation: explanation,
      distractors: distractors,
      hints: hints,
      narrationText: prompt,
      locale: template.locale,
      author: 'brightquest-deterministic-generator',
      reviewerOwnerId: template.reviewerOwnerId,
      status: 'needsReview',
      revision: 1,
      generation: ContentGeneration(
        mode: 'generated',
        deterministicSeed: legacyContentId,
      ),
      payload: payload,
    );
  }

  static FacingDirection _parseFacingDirection(String value) => switch (value) {
        'north' => FacingDirection.north,
        'east' => FacingDirection.east,
        'south' => FacingDirection.south,
        'west' => FacingDirection.west,
        _ => throw FormatException('Unknown FacingDirection $value'),
      };
}
