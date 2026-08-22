import '../curriculum/content_contract.dart';

class NurseryContentFormatException implements Exception {
  const NurseryContentFormatException(this.issues);

  final List<String> issues;

  @override
  String toString() => 'Invalid Nursery content:\n${issues.join('\n')}';
}

class NurseryCommercialContract {
  const NurseryCommercialContract({
    required this.permanentOneTimePriceInr,
    required this.purchaseModel,
    required this.paidEligibility,
    required this.paidEligibilityReason,
    required this.plannedProductId,
    required this.freeSampleActivityIds,
  });

  final int permanentOneTimePriceInr;
  final String purchaseModel;
  final bool paidEligibility;
  final String paidEligibilityReason;
  final String plannedProductId;
  final List<String> freeSampleActivityIds;

  factory NurseryCommercialContract.fromJson(Map<String, dynamic> json) =>
      NurseryCommercialContract(
        permanentOneTimePriceInr:
            (json['permanentOneTimePriceInr'] as num).toInt(),
        purchaseModel: json['purchaseModel'] as String,
        paidEligibility: json['paidEligibility'] as bool,
        paidEligibilityReason: json['paidEligibilityReason'] as String,
        plannedProductId: json['plannedProductId'] as String,
        freeSampleActivityIds: List<String>.unmodifiable(
            List<String>.from(json['freeSampleActivityIds'] as List)),
      );
}

class NurseryReleaseGates {
  const NurseryReleaseGates({
    required this.teacherReviewRecorded,
    required this.supervisedChildPilotRecorded,
    required this.productionBillingConfigured,
    required this.androidQualified,
    required this.windowsQualified,
  });

  final bool teacherReviewRecorded;
  final bool supervisedChildPilotRecorded;
  final bool productionBillingConfigured;
  final bool androidQualified;
  final bool windowsQualified;

  bool get allExternalGatesRecorded =>
      teacherReviewRecorded &&
      supervisedChildPilotRecorded &&
      productionBillingConfigured &&
      androidQualified &&
      windowsQualified;

  factory NurseryReleaseGates.fromJson(Map<String, dynamic> json) =>
      NurseryReleaseGates(
        teacherReviewRecorded: json['teacherReviewRecorded'] as bool? ?? false,
        supervisedChildPilotRecorded:
            json['supervisedChildPilotRecorded'] as bool? ?? false,
        productionBillingConfigured:
            json['productionBillingConfigured'] as bool? ?? false,
        androidQualified: json['androidQualified'] as bool? ?? false,
        windowsQualified: json['windowsQualified'] as bool? ?? false,
      );
}

class NurseryDomain {
  const NurseryDomain({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;

  factory NurseryDomain.fromJson(Map<String, dynamic> json) => NurseryDomain(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        emoji: json['emoji'] as String,
      );
}

class NurseryLetterExample {
  const NurseryLetterExample({
    required this.word,
    required this.picture,
    required this.assetPath,
    required this.soundCue,
    required this.soundPracticeEligible,
    required this.beginningSoundEligible,
    required this.displayPhrase,
  });

  final String word;
  final String picture;
  final String assetPath;
  final String soundCue;
  final bool soundPracticeEligible;
  final bool beginningSoundEligible;
  final String displayPhrase;

  factory NurseryLetterExample.fromJson(Map<String, dynamic> json) =>
      NurseryLetterExample(
        word: json['word'] as String,
        picture: json['picture'] as String,
        assetPath: json['assetPath'] as String? ?? '',
        soundCue: json['soundCue'] as String,
        soundPracticeEligible: json['soundPracticeEligible'] as bool? ?? false,
        beginningSoundEligible:
            json['beginningSoundEligible'] as bool? ?? false,
        displayPhrase:
            json['displayPhrase'] as String? ?? "${json['word'] as String}",
      );
}

class NurseryLetterAssociation {
  const NurseryLetterAssociation({
    required this.uppercase,
    required this.lowercase,
    required this.examples,
    required this.review,
  });

  final String uppercase;
  final String lowercase;
  final List<NurseryLetterExample> examples;
  final ReviewMetadata review;

  NurseryLetterExample get primaryExample => examples.first;
  String get word => primaryExample.word;
  String get picture => primaryExample.picture;
  String get soundCue => primaryExample.soundCue;

  List<NurseryLetterExample> get soundPracticeExamples =>
      List<NurseryLetterExample>.unmodifiable(
        examples.where((example) => example.soundPracticeEligible),
      );

  List<NurseryLetterExample> get beginningSoundExamples =>
      List<NurseryLetterExample>.unmodifiable(
        examples.where((example) => example.beginningSoundEligible),
      );

  factory NurseryLetterAssociation.fromJson(Map<String, dynamic> json) {
    final rawExamples = json['examples'];
    final examples = rawExamples is List && rawExamples.isNotEmpty
        ? rawExamples
            .whereType<Map>()
            .map(
              (value) => NurseryLetterExample.fromJson(
                Map<String, dynamic>.from(value),
              ),
            )
            .toList()
        : <NurseryLetterExample>[
            NurseryLetterExample(
              word: json['word'] as String,
              picture: json['picture'] as String,
              assetPath: '',
              soundCue: json['soundCue'] as String,
              soundPracticeEligible: false,
              beginningSoundEligible: false,
              displayPhrase:
                  "${json['uppercase'] as String} for ${json['word'] as String}",
            ),
          ];
    return NurseryLetterAssociation(
      uppercase: json['uppercase'] as String,
      lowercase: json['lowercase'] as String,
      examples: List<NurseryLetterExample>.unmodifiable(examples),
      review: ReviewMetadata.fromJson(
        Map<String, dynamic>.from(json['review'] as Map),
      ),
    );
  }
}

class NurseryWorkedExample {
  const NurseryWorkedExample({
    required this.headline,
    required this.visuals,
    required this.caption,
  });

  final String headline;
  final List<String> visuals;
  final String caption;

  factory NurseryWorkedExample.fromJson(Map<String, dynamic> json) =>
      NurseryWorkedExample(
        headline: json['headline'] as String,
        visuals: List<String>.unmodifiable(
          List<String>.from(json['visuals'] as List),
        ),
        caption: json['caption'] as String,
      );
}

class NurserySkill {
  const NurserySkill({
    required this.id,
    required this.domainId,
    required this.title,
    required this.objective,
    required this.explanation,
    required this.workedExample,
    required this.activityIds,
    required this.reviewActivityId,
    required this.review,
    this.generatorFamily,
  });

  final String id;
  final String domainId;
  final String title;
  final String objective;
  final String explanation;
  final NurseryWorkedExample workedExample;
  final List<String> activityIds;
  final String reviewActivityId;
  final String? generatorFamily;
  final ReviewMetadata review;

  factory NurserySkill.fromJson(Map<String, dynamic> json) => NurserySkill(
        id: json['id'] as String,
        domainId: json['domainId'] as String,
        title: json['title'] as String,
        objective: json['objective'] as String,
        explanation: json['explanation'] as String,
        workedExample: NurseryWorkedExample.fromJson(
          Map<String, dynamic>.from(json['workedExample'] as Map),
        ),
        activityIds: List<String>.unmodifiable(
          List<String>.from(json['activityIds'] as List),
        ),
        reviewActivityId: json['reviewActivityId'] as String,
        generatorFamily: json['generatorFamily'] as String?,
        review: ReviewMetadata.fromJson(
          Map<String, dynamic>.from(json['review'] as Map),
        ),
      );
}

class NurseryOption {
  const NurseryOption({required this.id, required this.label});

  final String id;
  final String label;

  factory NurseryOption.fromJson(Map<String, dynamic> json) => NurseryOption(
        id: json['id'] as String,
        label: json['label'] as String,
      );
}

class NurseryActivity {
  const NurseryActivity({
    required this.id,
    required this.skillId,
    required this.phase,
    required this.interaction,
    required this.prompt,
    required this.narration,
    required this.hint,
    required this.successFeedback,
    required this.wrongFeedback,
    required this.options,
    required this.payload,
    required this.correctResponseRule,
    required this.masteryEligible,
    required this.review,
  });

  final String id;
  final String skillId;
  final String phase;
  final String interaction;
  final String prompt;
  final String narration;
  final String hint;
  final String successFeedback;
  final String wrongFeedback;
  final List<NurseryOption> options;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> correctResponseRule;
  final bool masteryEligible;
  final ReviewMetadata review;

  bool get isGuided => phase == 'guided';
  bool get isIndependent => phase == 'independent';
  bool get isTransfer => phase == 'transfer';
  bool get isTrace => interaction == 'trace';

  factory NurseryActivity.fromJson(Map<String, dynamic> json) =>
      NurseryActivity(
        id: json['id'] as String,
        skillId: json['skillId'] as String,
        phase: json['phase'] as String,
        interaction: json['interaction'] as String,
        prompt: json['prompt'] as String,
        narration: json['narration'] as String,
        hint: json['hint'] as String,
        successFeedback: json['successFeedback'] as String,
        wrongFeedback: json['wrongFeedback'] as String,
        options: List<NurseryOption>.unmodifiable(
          (json['options'] as List)
              .whereType<Map>()
              .map((value) => NurseryOption.fromJson(
                    Map<String, dynamic>.from(value),
                  )),
        ),
        payload: Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(json['payload'] as Map),
        ),
        correctResponseRule: Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(json['correctResponseRule'] as Map),
        ),
        masteryEligible: json['masteryEligible'] as bool,
        review: ReviewMetadata.fromJson(
          Map<String, dynamic>.from(json['review'] as Map),
        ),
      );
}

class NurseryContentPack {
  NurseryContentPack({
    required this.schemaVersion,
    required this.packId,
    required this.displayName,
    required this.contentVersion,
    required this.locale,
    required this.review,
    required this.commercial,
    required this.releaseGates,
    required List<NurseryDomain> domains,
    required List<NurseryLetterAssociation> letterAssociations,
    required List<NurserySkill> skills,
    required List<NurseryActivity> activities,
  })  : domains = List<NurseryDomain>.unmodifiable(domains),
        letterAssociations =
            List<NurseryLetterAssociation>.unmodifiable(letterAssociations),
        skills = List<NurserySkill>.unmodifiable(skills),
        activities = List<NurseryActivity>.unmodifiable(activities),
        _skillsById = Map<String, NurserySkill>.unmodifiable(
          <String, NurserySkill>{for (final skill in skills) skill.id: skill},
        ),
        _activitiesById = Map<String, NurseryActivity>.unmodifiable(
          <String, NurseryActivity>{
            for (final activity in activities) activity.id: activity,
          },
        );

  static const String nurseryPackId = 'brightquest_nursery';

  final int schemaVersion;
  final String packId;
  final String displayName;
  final int contentVersion;
  final String locale;
  final ReviewMetadata review;
  final NurseryCommercialContract commercial;
  final NurseryReleaseGates releaseGates;
  final List<NurseryDomain> domains;
  final List<NurseryLetterAssociation> letterAssociations;
  final List<NurserySkill> skills;
  final List<NurseryActivity> activities;
  final Map<String, NurserySkill> _skillsById;
  final Map<String, NurseryActivity> _activitiesById;

  NurserySkill? skillById(String id) => _skillsById[id];
  NurseryActivity? activityById(String id) => _activitiesById[id];

  List<NurserySkill> skillsForDomain(String domainId) =>
      List<NurserySkill>.unmodifiable(
        skills.where((skill) => skill.domainId == domainId),
      );

  List<NurseryActivity> activitiesForSkill(String skillId) =>
      List<NurseryActivity>.unmodifiable(
        skillsByActivityOrder(skillId),
      );

  Iterable<NurseryActivity> skillsByActivityOrder(String skillId) sync* {
    final skill = _skillsById[skillId];
    if (skill == null) return;
    for (final id in skill.activityIds) {
      final activity = _activitiesById[id];
      if (activity != null) yield activity;
    }
  }

  bool isFreeSampleActivity(String activityId) =>
      commercial.freeSampleActivityIds.contains(activityId);

  factory NurseryContentPack.fromJson(Map<String, dynamic> json) {
    final issues = NurseryContentValidator.validate(json);
    if (issues.isNotEmpty) {
      throw NurseryContentFormatException(List<String>.unmodifiable(issues));
    }
    return NurseryContentPack(
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      packId: json['packId'] as String,
      displayName: json['displayName'] as String,
      contentVersion: (json['contentVersion'] as num).toInt(),
      locale: json['locale'] as String,
      review: ReviewMetadata.fromJson(
        Map<String, dynamic>.from(json['review'] as Map),
      ),
      commercial: NurseryCommercialContract.fromJson(
        Map<String, dynamic>.from(json['commercial'] as Map),
      ),
      releaseGates: NurseryReleaseGates.fromJson(
        Map<String, dynamic>.from(json['releaseGates'] as Map),
      ),
      domains: (json['domains'] as List)
          .whereType<Map>()
          .map((value) => NurseryDomain.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
      letterAssociations: (json['letterAssociations'] as List)
          .whereType<Map>()
          .map((value) => NurseryLetterAssociation.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
      skills: (json['skills'] as List)
          .whereType<Map>()
          .map((value) => NurserySkill.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
      activities: (json['activities'] as List)
          .whereType<Map>()
          .map((value) => NurseryActivity.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
    );
  }
}

class NurseryContentValidator {
  const NurseryContentValidator._();

  static const Set<String> _domains = <String>{
    'alphabet',
    'math',
    'knowledge',
    'thinking',
  };
  static const Set<String> _interactions = <String>{
    'choice',
    'pairMatch',
    'sortBuckets',
    'trace',
  };
  static const Set<String> _ruleTypes = <String>{
    'choice',
    'pairMatch',
    'sortBuckets',
    'traceCheckpoints',
  };
  static const Set<String> _generatorFamilies = <String>{
    'letterChoice',
    'caseMatch',
    'wordPicture',
    'letterSound',
    'listenLetter',
    'beginningSound',
    'numberRecognition',
    'counting',
    'numberQuantity',
    'missingNumber',
    'comparison',
    'addition',
    'colourChoice',
    'shapeChoice',
    'knowledgeChoice',
    'routineChoice',
    'pattern',
    'matching',
    'sorting',
    'observation',
  };

  static List<String> validate(Map<String, dynamic> json) {
    final issues = <String>[];
    void error(String message) => issues.add(message);

    if (json['schemaVersion'] != 1) error('Expected schemaVersion 1.');
    if (json['packId'] != NurseryContentPack.nurseryPackId) {
      error('Expected packId ${NurseryContentPack.nurseryPackId}.');
    }
    if ((json['contentVersion'] as num?)?.toInt() != 1) {
      error('Expected Nursery contentVersion 1.');
    }
    if (json['locale'] != 'en-IN') error('Nursery v1 locale must be en-IN.');
    final packReview = json['review'];
    if (packReview is! Map || packReview['status'] == 'approved') {
      error('Nursery pack must remain reviewable and not pre-approved.');
    }

    final commercial = json['commercial'];
    if (commercial is! Map) {
      error('commercial is required.');
    } else {
      if (commercial['permanentOneTimePriceInr'] != 299) {
        error('Nursery planned permanent price must be ₹299.');
      }
      if (commercial['purchaseModel'] != 'oneTimePack') {
        error('Nursery purchaseModel must be oneTimePack.');
      }
      if (commercial['plannedProductId'] != NurseryContentPack.nurseryPackId) {
        error(
            'Nursery planned product ID must stay ${NurseryContentPack.nurseryPackId}.');
      }
      if (commercial['paidEligibility'] != false) {
        error(
            'Nursery paidEligibility must remain false until external gates pass.');
      }
      final samples = commercial['freeSampleActivityIds'];
      if (samples is! List || samples.length != 4) {
        error('Nursery must define exactly four free sample activities.');
      }
    }

    final releaseGates = json['releaseGates'];
    if (releaseGates is! Map) {
      error('releaseGates is required.');
    } else if (releaseGates.values.any((value) => value == true)) {
      error(
          'External Nursery release gates may not be pre-approved in source.');
    }

    final domains = json['domains'];
    final domainIds = <String>{};
    if (domains is! List) {
      error('domains must be a list.');
    } else {
      for (final raw in domains.whereType<Map>()) {
        final id = raw['id'];
        if (id is! String || !_domains.contains(id)) {
          error('Unknown Nursery domain: $id.');
        } else if (!domainIds.add(id)) {
          error('Duplicate Nursery domain: $id.');
        }
      }
      if (!domainIds.containsAll(_domains) ||
          !_domains.containsAll(domainIds)) {
        error(
            'Nursery domains must contain alphabet, math, knowledge and thinking exactly once.');
      }
    }

    final letters = json['letterAssociations'];
    if (letters is! List || letters.length != 26) {
      error('Nursery must contain exactly 26 A–Z letter associations.');
    } else {
      final uppercase = letters
          .whereType<Map>()
          .map((value) => value['uppercase'])
          .whereType<String>()
          .toList();
      if (uppercase.join() != 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') {
        error('Letter associations must cover A–Z in order.');
      }
      final assetPaths = <String>{};
      for (final raw in letters.whereType<Map>()) {
        final letter = raw['uppercase'];
        final examples = raw['examples'];
        if (letter is! String || examples is! List || examples.length < 8) {
          error(
              'Letter $letter must define at least eight discovery examples.');
          continue;
        }
        for (final example in examples.whereType<Map>()) {
          final word = example['word'];
          final picture = example['picture'];
          final assetPath = example['assetPath'];
          final soundCue = example['soundCue'];
          final soundPracticeEligible = example['soundPracticeEligible'];
          final beginningSoundEligible = example['beginningSoundEligible'];
          final displayPhrase = example['displayPhrase'];
          if (word is! String || word.trim().isEmpty) {
            error('Letter $letter has a discovery example without a word.');
          }
          if (picture is! String || picture.trim().isEmpty) {
            error('Letter $letter example $word requires a picture fallback.');
          }
          if (soundCue is! String || soundCue.trim().isEmpty) {
            error('Letter $letter example $word requires a sound cue.');
          }
          if (soundPracticeEligible is! bool) {
            error(
              'Letter $letter example $word requires explicit soundPracticeEligible.',
            );
          }
          if (beginningSoundEligible is! bool) {
            error(
              'Letter $letter example $word requires explicit beginningSoundEligible.',
            );
          }
          if (displayPhrase is! String || displayPhrase.trim().isEmpty) {
            error('Letter $letter example $word requires a display phrase.');
          }
          if (assetPath is! String ||
              !assetPath.startsWith('assets/nursery/letter_cards/')) {
            error(
                'Letter $letter example $word requires a bundled Nursery asset path.');
          } else if (!assetPaths.add(assetPath)) {
            error('Duplicate Nursery letter asset path: $assetPath.');
          }
        }
      }
      if (assetPaths.length < 200) {
        error(
            'Nursery A–Z discovery must provide at least 200 unique picture cards.');
      }
    }

    final skillsRaw = json['skills'];
    final skillIds = <String>{};
    final skillActivityIds = <String, List<String>>{};
    if (skillsRaw is! List || skillsRaw.length != 32) {
      error('Nursery v1 must define exactly 32 skills.');
    } else {
      for (final raw in skillsRaw.whereType<Map>()) {
        final id = raw['id'];
        final domainId = raw['domainId'];
        if (id is! String || id.isEmpty) {
          error('Every Nursery skill needs a non-empty id.');
          continue;
        }
        if (!skillIds.add(id)) error('Duplicate Nursery skill id: $id.');
        if (domainId is! String || !_domains.contains(domainId)) {
          error('Skill $id has unknown domain $domainId.');
        }
        final activityIds = raw['activityIds'];
        if (activityIds is! List || activityIds.length < 4) {
          error('Skill $id must reference at least four activities.');
        } else {
          skillActivityIds[id] = activityIds.whereType<String>().toList();
        }
        final generatorFamily = raw['generatorFamily'];
        if (generatorFamily is! String ||
            !_generatorFamilies.contains(generatorFamily)) {
          error('Skill $id has unsupported generator family $generatorFamily.');
        }
        final reviewActivityId = raw['reviewActivityId'];
        if (reviewActivityId is! String || reviewActivityId.isEmpty) {
          error('Skill $id requires a reviewActivityId.');
        }
        final review = raw['review'];
        if (review is! Map || review['status'] == 'approved') {
          error('Skill $id must remain reviewable and not pre-approved.');
        }
      }
    }

    final activitiesRaw = json['activities'];
    final activityIds = <String>{};
    final phasesBySkill = <String, List<String>>{};
    final activityPhaseById = <String, String>{};
    final samples =
        commercial is Map && commercial['freeSampleActivityIds'] is List
            ? Set<String>.from(commercial['freeSampleActivityIds'] as List)
            : <String>{};
    if (activitiesRaw is! List || activitiesRaw.length < 128) {
      error('Nursery requires at least 128 authored activities.');
    } else {
      for (final raw in activitiesRaw.whereType<Map>()) {
        final id = raw['id'];
        final skillId = raw['skillId'];
        if (id is! String || id.isEmpty) {
          error('Every Nursery activity needs an id.');
          continue;
        }
        if (!activityIds.add(id)) error('Duplicate Nursery activity id: $id.');
        if (skillId is! String || !skillIds.contains(skillId)) {
          error('Activity $id references unknown skill $skillId.');
        }
        final interaction = raw['interaction'];
        if (interaction is! String || !_interactions.contains(interaction)) {
          error('Activity $id has unsupported interaction $interaction.');
        }
        final rule = raw['correctResponseRule'];
        if (rule is! Map || !_ruleTypes.contains(rule['type'])) {
          error('Activity $id has unsupported response rule.');
        }
        final phase = raw['phase'];
        if (skillId is String && phase is String) {
          phasesBySkill.putIfAbsent(skillId, () => <String>[]).add(phase);
          activityPhaseById[id] = phase;
        }
        final masteryEligible = raw['masteryEligible'] as bool? ?? false;
        if (interaction == 'trace' && masteryEligible) {
          error('Tracing activity $id may not be mastery eligible.');
        }
        if ((phase == 'guided' ||
                phase == 'independent' ||
                phase == 'transfer') &&
            !masteryEligible) {
          error('Core scorable activity $id must be mastery eligible.');
        }
        if (interaction == 'choice') {
          final options = raw['options'];
          if (options is! List || options.length < 2) {
            error('Choice activity $id needs at least two options.');
          } else {
            final optionIds = options
                .whereType<Map>()
                .map((value) => value['id'])
                .whereType<String>()
                .toList();
            if (optionIds.toSet().length != optionIds.length) {
              error('Choice activity $id has duplicate options.');
            }
            if (rule is Map &&
                rule['type'] == 'choice' &&
                !optionIds.contains(rule['value'])) {
              error('Choice activity $id answer is not in its options.');
            }
          }
        }
        final review = raw['review'];
        if (review is! Map || review['status'] == 'approved') {
          error('Activity $id must remain reviewable and not pre-approved.');
        }
      }
    }

    for (final skillId in skillIds) {
      final refs = skillActivityIds[skillId] ?? const <String>[];
      for (final id in refs) {
        if (!activityIds.contains(id)) {
          error('Skill $skillId references missing activity $id.');
        }
      }
      final skillRaw = skillsRaw is List
          ? skillsRaw.whereType<Map>().cast<Map>().firstWhere(
                (raw) => raw['id'] == skillId,
                orElse: () => const <Object?, Object?>{},
              )
          : const <Object?, Object?>{};
      final reviewActivityId = skillRaw['reviewActivityId'];
      if (reviewActivityId is! String || !refs.contains(reviewActivityId)) {
        error(
            'Skill $skillId reviewActivityId must reference one of its activities.');
      } else if (activityPhaseById[reviewActivityId] != 'transfer') {
        error(
            'Skill $skillId reviewActivityId must point to its transfer activity.');
      }
      final phases = phasesBySkill[skillId] ?? const <String>[];
      if (!phases.contains('guided'))
        error('Skill $skillId has no guided activity.');
      if (phases.where((phase) => phase == 'independent').length < 2) {
        error('Skill $skillId needs two independent activities.');
      }
      if (!phases.contains('transfer'))
        error('Skill $skillId has no transfer activity.');
    }
    for (final id in samples) {
      if (!activityIds.contains(id))
        error('Free sample activity $id does not exist.');
    }

    return List<String>.unmodifiable(issues);
  }
}
