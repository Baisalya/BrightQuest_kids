import 'dart:convert';

import '../curriculum/content_contract.dart';

class ContentPackValidationIssue {
  const ContentPackValidationIssue({
    required this.code,
    required this.message,
    this.warning = false,
  });

  final String code;
  final String message;
  final bool warning;

  @override
  String toString() => '${warning ? 'warning' : 'error'}: $code — $message';
}

class ContentPackValidationResult {
  const ContentPackValidationResult(this.issues);

  final List<ContentPackValidationIssue> issues;

  bool get isValid => issues.every((issue) => issue.warning);

  List<ContentPackValidationIssue> get errors =>
      issues.where((issue) => !issue.warning).toList(growable: false);

  List<ContentPackValidationIssue> get warnings =>
      issues.where((issue) => issue.warning).toList(growable: false);
}

class ContentPackValidator {
  const ContentPackValidator();

  static const _classes = <int>{3, 4, 5};
  static const _games = <String>{
    'math_market',
    'fraction_pizza',
    'science_lab',
    'story_builder',
    'grammar_puzzle',
    'map_quest',
    'coding_maze',
    'recycling_challenge',
  };
  static const _reviewStates = <String>{
    'draft',
    'needsReview',
    'inReview',
    'changesRequested',
    'approved',
    'retired',
  };
  static const _activityTypes = <String>{
    'teach',
    'guidedPractice',
    'independentPractice',
    'transfer',
    'masteryCheck',
    'experiment',
    'story',
    'simulation',
  };

  ContentPackValidationResult validateSchemaDocument(
    Map<String, dynamic> schema,
  ) {
    final issues = <ContentPackValidationIssue>[];
    void error(String code, String message) =>
        issues.add(ContentPackValidationIssue(code: code, message: message));

    if (schema[r'$id'] != 'brightquest.content_schema_v1') {
      error(
        'schema.id',
        'content_schema_v1.json must declare brightquest.content_schema_v1.',
      );
    }
    if (schema[r'$schema'] is! String ||
        !(schema[r'$schema'] as String).contains('2020-12')) {
      error(
          'schema.draft', 'Content schema must use JSON Schema draft 2020-12.');
    }
    final required = schema['required'];
    if (required is! List ||
        !required.contains('classNumber') ||
        !required.contains('activities') ||
        !required.contains('packId')) {
      error(
        'schema.root_required',
        'Content schema must require packId, classNumber and activities.',
      );
    }
    final defs = schema[r'$defs'];
    if (defs is! Map || defs['activity'] is! Map) {
      error('schema.activity_def',
          'Content schema must define an activity contract.');
    }
    return ContentPackValidationResult(List.unmodifiable(issues));
  }

  ContentPackValidationResult validateJson({
    required Map<String, dynamic> json,
    required CurriculumContract curriculum,
  }) {
    final issues = <ContentPackValidationIssue>[];

    void error(String code, String message) =>
        issues.add(ContentPackValidationIssue(code: code, message: message));
    void warning(String code, String message) => issues.add(
          ContentPackValidationIssue(
            code: code,
            message: message,
            warning: true,
          ),
        );

    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 1) {
      error('pack.schema_version',
          'Expected schemaVersion 1, found $schemaVersion.');
    }

    final classNumber = json['classNumber'];
    if (classNumber is! int || !_classes.contains(classNumber)) {
      error('pack.class_number', 'Pack classNumber must be one of 3, 4 or 5.');
      return ContentPackValidationResult(List.unmodifiable(issues));
    }

    final classContract = curriculum.classPack(classNumber);
    if (classContract == null) {
      error('pack.curriculum_missing',
          'No curriculum contract for Class $classNumber.');
      return ContentPackValidationResult(List.unmodifiable(issues));
    }

    if (json['packId'] != classContract.packId) {
      error(
        'pack.id_mismatch',
        'Class $classNumber packId must remain ${classContract.packId}.',
      );
    }
    final packVersion = json['packVersion'];
    if (packVersion is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(packVersion)) {
      error('pack.version', 'packVersion must be a semantic x.y.z version.');
    }
    if (json['locale'] is! String ||
        (json['locale'] as String).trim().isEmpty) {
      error('pack.locale', 'Pack locale is required.');
    }

    List<String>? freeSampleActivityIds;
    final commercial = json['commercial'];
    if (commercial is! Map) {
      error('pack.commercial', 'Pack commercial metadata is required.');
    } else {
      if (commercial['priceInr'] != 299) {
        error('pack.price',
            'Class packs must retain the ₹299 one-time price contract.');
      }
      if (commercial['purchaseModel'] != 'oneTimePerClass') {
        error('pack.purchase_model', 'Class packs must use oneTimePerClass.');
      }
      if (commercial['paidEligibility'] !=
          classContract.commercial.paidEligibility) {
        error(
          'pack.paid_eligibility',
          'Pack paidEligibility must match the curriculum review contract.',
        );
      }
      final rawSamples = commercial['freeSampleActivityIds'];
      if (rawSamples is! List || rawSamples.any((value) => value is! String)) {
        error(
          'pack.free_samples',
          'Pack must declare explicit freeSampleActivityIds.',
        );
      } else {
        freeSampleActivityIds = rawSamples.cast<String>();
        if (freeSampleActivityIds.length != 8 ||
            freeSampleActivityIds.toSet().length != 8) {
          error(
            'pack.free_sample_count',
            'Class $classNumber must expose exactly 8 unique demo activities.',
          );
        }
        final contractSamples =
            classContract.commercial.freeSampleCandidateActivityIds.toSet();
        final packSamples = freeSampleActivityIds.toSet();
        if (packSamples.length != contractSamples.length ||
            !packSamples.containsAll(contractSamples)) {
          error(
            'pack.free_sample_contract',
            'Class $classNumber free demos must match the pending curriculum review boundary.',
          );
        }
      }
    }

    final development = json['development'];
    if (development is! Map ||
        development['lockable'] is! bool ||
        development['defaultLocked'] is! bool) {
      error(
        'pack.development_lock',
        'Development lock metadata must contain bool lockable/defaultLocked.',
      );
    }

    final activities = json['activities'];
    if (activities is! List || activities.isEmpty) {
      error('pack.activities', 'Pack must contain at least one activity.');
      return ContentPackValidationResult(List.unmodifiable(issues));
    }

    final competencyById = <String, CompetencyContract>{
      for (final value in classContract.competencies) value.id: value,
    };
    final outcomeById = <String, LearningOutcomeContract>{
      for (final value in classContract.learningOutcomes) value.id: value,
    };
    final unitIds = classContract.units.map((value) => value.id).toSet();
    final mappingBySelector = <String, CurrentContentMapping>{
      for (final value in classContract.currentContentMappings)
        '$classNumber::${value.gameId}::${value.topicId}': value,
    };
    final namedReviewerIds = curriculum.reviewers
        .where((value) => (value.ownerName ?? '').trim().isNotEmpty)
        .map((value) => value.id)
        .toSet();

    final localIds = <String>{};
    final legacyKeys = <String>{};
    var fallbackReactionCount = 0;

    for (var index = 0; index < activities.length; index += 1) {
      final raw = activities[index];
      if (raw is! Map) {
        error('activity.type', 'Activity #$index must be a JSON object.');
        continue;
      }
      final activity = Map<String, dynamic>.from(raw);
      final id = activity['id'];
      final label = id is String ? id : 'activity#$index';

      if (id is! String ||
          !RegExp('^c${classNumber}_[a-z0-9_]+\$').hasMatch(id)) {
        error(
          'activity.id',
          '$label must have a stable Class $classNumber ID beginning c${classNumber}_.',
        );
      } else if (!localIds.add(id)) {
        error('activity.duplicate_id', 'Duplicate activity ID: $id.');
      }

      final legacyContentId = activity['legacyContentId'];
      if (legacyContentId is! String || legacyContentId.trim().isEmpty) {
        error('activity.legacy_id', '$label is missing legacyContentId.');
      } else {
        final legacyKey =
            '$classNumber::${activity['gameId']}::$legacyContentId';
        if (!legacyKeys.add(legacyKey)) {
          error(
            'activity.duplicate_legacy_id',
            '$label duplicates legacy content identity $legacyKey.',
          );
        }
      }

      if (activity['classNumber'] != classNumber) {
        error(
          'activity.class_boundary',
          '$label has classNumber ${activity['classNumber']} inside Class $classNumber pack.',
        );
      }

      final gameId = activity['gameId'];
      final topicId = activity['topicId'];
      if (gameId is! String || !_games.contains(gameId)) {
        error('activity.game_id', '$label has unsupported gameId $gameId.');
      }
      if (topicId is! String || topicId.trim().isEmpty) {
        error('activity.topic_id', '$label requires a non-empty topicId.');
      }
      if (gameId is String && topicId is String) {
        final selectorKey = '$classNumber::$gameId::$topicId';
        if (!mappingBySelector.containsKey(selectorKey)) {
          error(
            'activity.selector_mapping',
            '$label selector $selectorKey is not in the Phase 0 curriculum mapping.',
          );
        }
      }

      final unitId = activity['unitId'];
      if (unitId is! String || !unitIds.contains(unitId)) {
        error('activity.unit_ref', '$label references unknown unitId $unitId.');
      }

      final competencyIds = <String>[];
      final primaryCompetency = activity['competencyId'];
      if (primaryCompetency is String) competencyIds.add(primaryCompetency);
      final relatedCompetencies = activity['relatedCompetencyIds'];
      if (relatedCompetencies is List) {
        for (final value in relatedCompetencies) {
          if (value is String) competencyIds.add(value);
        }
      } else {
        error(
          'activity.related_competencies',
          '$label requires relatedCompetencyIds as a list.',
        );
      }
      if (competencyIds.isEmpty) {
        error('activity.competency_ref', '$label requires a competencyId.');
      }
      if (competencyIds.toSet().length != competencyIds.length) {
        error('activity.competency_duplicate',
            '$label repeats a competency reference.');
      }
      for (final competencyId in competencyIds) {
        final competency = competencyById[competencyId];
        if (competency == null) {
          error(
            'activity.competency_ref',
            '$label references unknown competency $competencyId.',
          );
          continue;
        }
        if (activity['subject'] != competency.subject) {
          error(
            'activity.subject_boundary',
            '$label subject ${activity['subject']} does not match $competencyId (${competency.subject}).',
          );
        }
      }

      if (gameId is String && topicId is String) {
        final mapping = mappingBySelector['$classNumber::$gameId::$topicId'];
        if (mapping != null) {
          final allowed = mapping.competencyIds.toSet();
          for (final competencyId in competencyIds) {
            if (!allowed.contains(competencyId)) {
              error(
                'activity.mapping_drift',
                '$label competency $competencyId is outside the selector mapping.',
              );
            }
          }
        }
      }

      final outcomeIds = <String>[];
      final primaryOutcome = activity['learningOutcomeId'];
      if (primaryOutcome is String) outcomeIds.add(primaryOutcome);
      final relatedOutcomes = activity['relatedLearningOutcomeIds'];
      if (relatedOutcomes is List) {
        for (final value in relatedOutcomes) {
          if (value is String) outcomeIds.add(value);
        }
      } else {
        error(
          'activity.related_outcomes',
          '$label requires relatedLearningOutcomeIds as a list.',
        );
      }
      if (outcomeIds.isEmpty) {
        error('activity.outcome_ref', '$label requires a learningOutcomeId.');
      }
      if (outcomeIds.toSet().length != outcomeIds.length) {
        error('activity.outcome_duplicate',
            '$label repeats a learning outcome reference.');
      }
      for (final outcomeId in outcomeIds) {
        final outcome = outcomeById[outcomeId];
        if (outcome == null) {
          error(
            'activity.outcome_ref',
            '$label references unknown learning outcome $outcomeId.',
          );
          continue;
        }
        if (!competencyIds.contains(outcome.competencyId)) {
          error(
            'activity.outcome_competency',
            '$label outcome $outcomeId belongs to ${outcome.competencyId}, which the activity does not reference.',
          );
        }
      }

      final type = activity['activityType'];
      if (type is! String || !_activityTypes.contains(type)) {
        error(
            'activity.activity_type', '$label has invalid activityType $type.');
      }
      final difficulty = activity['difficulty'];
      if (difficulty is! int || difficulty < 1 || difficulty > 5) {
        error('activity.difficulty',
            '$label difficulty must be between 1 and 5.');
      }
      for (final field in <String>[
        'prompt',
        'explanation',
        'locale',
        'author',
      ]) {
        final value = activity[field];
        if (value is! String || value.trim().isEmpty) {
          error('activity.$field', '$label requires non-empty $field.');
        }
      }
      final narration = activity['narration'];
      if (narration is! Map ||
          narration['text'] is! String ||
          (narration['text'] as String).trim().isEmpty) {
        error('activity.narration', '$label requires narration.text.');
      }

      final status = activity['status'];
      if (status is! String || !_reviewStates.contains(status)) {
        error('activity.review_status',
            '$label has invalid review status $status.');
      }
      final revision = activity['revision'];
      if (revision is! int || revision < 1) {
        error('activity.revision', '$label revision must be >= 1.');
      }
      if (status == 'approved') {
        final reviewerOwnerId = activity['reviewerOwnerId'];
        if (reviewerOwnerId is! String ||
            !namedReviewerIds.contains(reviewerOwnerId)) {
          error(
            'activity.approval_without_reviewer',
            '$label cannot be approved without a named qualified reviewer owner.',
          );
        }
      }

      final generation = activity['generation'];
      if (generation is! Map) {
        error('activity.generation', '$label requires generation metadata.');
      } else {
        final mode = generation['mode'];
        if (mode != 'authored' && mode != 'generated') {
          error('activity.generation_mode',
              '$label has invalid generation mode $mode.');
        }
        if (mode == 'generated') {
          final seed = generation['deterministicSeed'];
          if (seed is! String || seed.trim().isEmpty) {
            error(
              'activity.generation_seed',
              '$label generated content requires a deterministic seed.',
            );
          }
        }
      }

      final rule = activity['correctResponseRule'];
      if (rule is! Map || rule.isEmpty) {
        error(
            'activity.correct_rule', '$label requires a correctResponseRule.');
      }

      final payload = activity['payload'];
      if (payload is! Map || payload.isEmpty) {
        error('activity.payload', '$label requires game-specific payload.');
      } else if (gameId is String) {
        _validatePayload(
          label: label,
          gameId: gameId,
          payload: Map<String, dynamic>.from(payload),
          rule: rule is Map ? Map<String, dynamic>.from(rule) : const {},
          error: error,
        );
        if (gameId == 'science_lab' &&
            payload['fallback'] == true &&
            payload['reactionId'] == 'none') {
          fallbackReactionCount += 1;
        }
      }

      final distractorValues = <String>{};
      final distractors = activity['distractors'];
      if (distractors is! List) {
        error('activity.distractors', '$label distractors must be a list.');
      } else {
        final correctValue = rule is Map ? rule['value'] : null;
        final correctFingerprint = _fingerprint(correctValue);
        for (final rawDistractor in distractors) {
          if (rawDistractor is! Map) {
            error('activity.distractor_type',
                '$label has a non-object distractor.');
            continue;
          }
          final misconceptionId = rawDistractor['misconceptionId'];
          if (misconceptionId is! String || misconceptionId.trim().isEmpty) {
            error(
              'activity.distractor_misconception',
              '$label distractor is missing misconceptionId.',
            );
          }
          final fp = _fingerprint(rawDistractor['value']);
          if (!distractorValues.add(fp)) {
            error('activity.duplicate_distractor',
                '$label repeats distractor ${rawDistractor['value']}.');
          }
          if (correctValue != null && fp == correctFingerprint) {
            error(
              'activity.distractor_equals_answer',
              '$label includes the correct answer as a distractor.',
            );
          }
        }
      }

      final hints = activity['hints'];
      if (hints is! List) {
        error('activity.hints', '$label hints must be a list.');
      } else {
        final steps = <int>{};
        for (final rawHint in hints) {
          if (rawHint is! Map ||
              rawHint['step'] is! int ||
              rawHint['text'] is! String ||
              (rawHint['text'] as String).trim().isEmpty) {
            error('activity.hint_shape', '$label contains an invalid hint.');
            continue;
          }
          if (!steps.add(rawHint['step'] as int)) {
            error('activity.hint_step', '$label repeats a hint step number.');
          }
        }
      }
    }

    if (freeSampleActivityIds != null) {
      final activityById = <String, Map<String, dynamic>>{
        for (final raw in activities.whereType<Map>())
          if (raw['id'] is String)
            raw['id'] as String: Map<String, dynamic>.from(raw),
      };
      final sampleGames = <String>{};
      for (final sampleId in freeSampleActivityIds) {
        final sample = activityById[sampleId];
        if (sample == null) {
          error(
            'pack.free_sample_missing',
            'Free demo activity $sampleId does not exist in Class $classNumber.',
          );
          continue;
        }
        if (sample['difficulty'] != 1) {
          error(
            'pack.free_sample_difficulty',
            'Free demo activity $sampleId must be difficulty 1.',
          );
        }
        final gameId = sample['gameId'];
        if (gameId is! String || !sampleGames.add(gameId)) {
          error(
            'pack.free_sample_game',
            'Free demos must contain exactly one activity from each game.',
          );
        }
      }
      if (!sampleGames.containsAll(_games) || sampleGames.length != 8) {
        error(
          'pack.free_sample_coverage',
          'Class $classNumber free demos must cover all 8 games exactly once.',
        );
      }
    }

    if (fallbackReactionCount != 1) {
      error(
        'pack.reaction_fallback',
        'Class $classNumber must contain exactly one Science Lab fallback reaction; found $fallbackReactionCount.',
      );
    }

    if (activities.length < 63) {
      warning(
        'pack.activity_count',
        'Class $classNumber currently contains only ${activities.length} migrated activities.',
      );
    }

    final coveredCompetencies = <String>{};
    for (final raw in activities.whereType<Map>()) {
      final primary = raw['competencyId'];
      if (primary is String) coveredCompetencies.add(primary);
      final related = raw['relatedCompetencyIds'];
      if (related is List)
        coveredCompetencies.addAll(related.whereType<String>());
    }
    final missingCompetencies = classContract.competencies
        .where((value) => !coveredCompetencies.contains(value.id))
        .toList(growable: false);
    if (missingCompetencies.isNotEmpty) {
      warning(
        'pack.competency_activity_gap',
        'Class $classNumber has ${missingCompetencies.length} competencies without an authored scorable activity: '
            '${missingCompetencies.map((value) => value.id).join(', ')}.',
      );
    }

    return ContentPackValidationResult(List.unmodifiable(issues));
  }

  ContentPackValidationResult validateAll({
    required List<Map<String, dynamic>> packs,
    required CurriculumContract curriculum,
  }) {
    final issues = <ContentPackValidationIssue>[];
    final classes = <int>{};
    final ids = <String>{};

    for (final pack in packs) {
      final result = validateJson(json: pack, curriculum: curriculum);
      issues.addAll(result.issues);
      final classNumber = pack['classNumber'];
      if (classNumber is int && !classes.add(classNumber)) {
        issues.add(ContentPackValidationIssue(
          code: 'packs.duplicate_class',
          message: 'More than one pack was supplied for Class $classNumber.',
        ));
      }
      final activities = pack['activities'];
      if (activities is List) {
        for (final raw in activities) {
          if (raw is Map &&
              raw['id'] is String &&
              !ids.add(raw['id'] as String)) {
            issues.add(ContentPackValidationIssue(
              code: 'packs.duplicate_activity_id',
              message: 'Activity ID ${raw['id']} occurs in more than one pack.',
            ));
          }
        }
      }
    }

    if (classes.length != 3 || !classes.containsAll(_classes)) {
      issues.add(const ContentPackValidationIssue(
        code: 'packs.classes',
        message:
            'ContentRepository requires exactly one bundled pack for Classes 3, 4 and 5.',
      ));
    }

    return ContentPackValidationResult(List.unmodifiable(issues));
  }

  static String _fingerprint(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '$key:${_fingerprint(value[key])}').join(',')}}';
    }
    if (value is Iterable) {
      return '[${value.map(_fingerprint).join(',')}]';
    }
    return jsonEncode(value);
  }

  void _validatePayload({
    required String label,
    required String gameId,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> rule,
    required void Function(String code, String message) error,
  }) {
    bool hasInt(String field) => payload[field] is int;
    bool nonEmptyList(String field) =>
        payload[field] is List && (payload[field] as List).isNotEmpty;

    switch (gameId) {
      case 'math_market':
        if (!hasInt('answer') ||
            !nonEmptyList('choices') ||
            payload['hint'] is! String) {
          error('payload.math', '$label has an invalid Math Market payload.');
          return;
        }
        _validateChoicePayload(
            label, payload['choices'] as List, payload['answer'], error);
        break;
      case 'fraction_pizza':
        if (!hasInt('totalSlices') ||
            !hasInt('numerator') ||
            !hasInt('denominator')) {
          error('payload.fraction',
              '$label has an invalid Fraction Pizza payload.');
          return;
        }
        final total = payload['totalSlices'] as int;
        final numerator = payload['numerator'] as int;
        final denominator = payload['denominator'] as int;
        if (total <= 0 ||
            numerator <= 0 ||
            denominator <= 0 ||
            numerator > denominator) {
          error('payload.fraction_range',
              '$label has an impossible fraction definition.');
        } else if ((total * numerator) % denominator != 0) {
          error(
            'payload.fraction_slices',
            '$label cannot be represented by a whole number of its configured slices.',
          );
        }
        break;
      case 'science_lab':
        if (payload.containsKey('reactionId')) {
          if (payload['reactionId'] is! String ||
              payload['title'] is! String ||
              payload['emoji'] is! String ||
              payload['requiredIngredients'] is! List ||
              payload['fallback'] is! bool) {
            error('payload.reaction',
                '$label has an invalid science reaction payload.');
          }
        } else {
          if (payload['answer'] is! String || !nonEmptyList('choices')) {
            error('payload.science',
                '$label has an invalid Science Lab quiz payload.');
            return;
          }
          _validateChoicePayload(
              label, payload['choices'] as List, payload['answer'], error);
        }
        break;
      case 'story_builder':
        if (!nonEmptyList('words') ||
            (payload['words'] as List).any((value) => value is! String)) {
          error('payload.story',
              '$label has an invalid Story Builder word sequence.');
        }
        break;
      case 'grammar_puzzle':
        for (final field in <String>['sentence', 'noun', 'verb', 'adjective']) {
          if (payload[field] is! String ||
              (payload[field] as String).trim().isEmpty) {
            error(
                'payload.grammar', '$label has invalid grammar field $field.');
          }
        }
        break;
      case 'map_quest':
        if (payload['answer'] is! String ||
            !nonEmptyList('choices') ||
            payload['hint'] is! String) {
          error('payload.map', '$label has an invalid Map Quest payload.');
          return;
        }
        _validateChoicePayload(
            label, payload['choices'] as List, payload['answer'], error);
        break;
      case 'coding_maze':
        final fields = <String>[
          'width',
          'height',
          'startX',
          'startY',
          'goalX',
          'goalY',
          'maxCommands',
        ];
        if (fields.any((field) => payload[field] is! int) ||
            payload['startDirection'] is! String ||
            payload['obstacles'] is! List) {
          error('payload.coding', '$label has an invalid Coding Maze payload.');
          return;
        }
        if (!_codingMissionHasSolution(payload)) {
          error(
            'payload.coding_impossible',
            '$label has no valid route to its goal within the command budget.',
          );
        }
        break;
      case 'recycling_challenge':
        if (payload['name'] is! String ||
            payload['emoji'] is! String ||
            payload['bin'] is! String ||
            !const {'Paper', 'Organic', 'Plastic'}.contains(payload['bin'])) {
          error(
              'payload.recycling', '$label has an invalid recycling payload.');
        }
        break;
    }

    if (rule['type'] == 'exactNumber' && rule['value'] != payload['answer']) {
      error('payload.rule_drift',
          '$label correct-response rule differs from its payload answer.');
    }
    if (rule['type'] == 'exactText' &&
        payload.containsKey('answer') &&
        rule['value'] != payload['answer']) {
      error('payload.rule_drift',
          '$label correct-response rule differs from its payload answer.');
    }
  }

  void _validateChoicePayload(
    String label,
    List<dynamic> choices,
    Object? answer,
    void Function(String code, String message) error,
  ) {
    final fingerprints = choices.map(_fingerprint).toList(growable: false);
    if (fingerprints.toSet().length != fingerprints.length) {
      error('payload.duplicate_choice',
          '$label contains duplicate answer choices.');
    }
    final answerFingerprint = _fingerprint(answer);
    final answerCount =
        fingerprints.where((value) => value == answerFingerprint).length;
    if (answerCount != 1) {
      error(
        'payload.answer_choice',
        '$label must contain its correct answer exactly once among the choices.',
      );
    }
  }

  bool _codingMissionHasSolution(Map<String, dynamic> payload) {
    final width = payload['width'] as int;
    final height = payload['height'] as int;
    final startX = payload['startX'] as int;
    final startY = payload['startY'] as int;
    final goalX = payload['goalX'] as int;
    final goalY = payload['goalY'] as int;
    final maxCommands = payload['maxCommands'] as int;
    final directionName = payload['startDirection'] as String;
    const directions = <String>['north', 'east', 'south', 'west'];
    final startDirection = directions.indexOf(directionName);
    if (width <= 0 ||
        height <= 0 ||
        maxCommands <= 0 ||
        startDirection < 0 ||
        startX < 0 ||
        startY < 0 ||
        goalX < 0 ||
        goalY < 0 ||
        startX >= width ||
        goalX >= width ||
        startY >= height ||
        goalY >= height) {
      return false;
    }
    final obstacles =
        (payload['obstacles'] as List).map((value) => '$value').toSet();
    if (obstacles.contains('$startX,$startY') ||
        obstacles.contains('$goalX,$goalY')) {
      return false;
    }

    final queue = <(int, int, int, int)>[(startX, startY, startDirection, 0)];
    final seen = <String>{'$startX,$startY,$startDirection,0'};
    var cursor = 0;
    const delta = <(int, int)>[(0, -1), (1, 0), (0, 1), (-1, 0)];

    while (cursor < queue.length) {
      final state = queue[cursor++];
      final (x, y, direction, steps) = state;
      if (x == goalX && y == goalY) return true;
      if (steps >= maxCommands) continue;

      final nextSteps = steps + 1;
      for (final nextDirection in <int>[
        (direction + 3) % 4,
        (direction + 1) % 4,
      ]) {
        final key = '$x,$y,$nextDirection,$nextSteps';
        if (seen.add(key)) queue.add((x, y, nextDirection, nextSteps));
      }

      final (dx, dy) = delta[direction];
      final nextX = x + dx;
      final nextY = y + dy;
      if (nextX >= 0 &&
          nextY >= 0 &&
          nextX < width &&
          nextY < height &&
          !obstacles.contains('$nextX,$nextY')) {
        final key = '$nextX,$nextY,$direction,$nextSteps';
        if (seen.add(key)) queue.add((nextX, nextY, direction, nextSteps));
      }
    }
    return false;
  }
}
