class ContentDistractor {
  const ContentDistractor({
    required this.value,
    required this.misconceptionId,
  });

  final Object? value;
  final String misconceptionId;

  factory ContentDistractor.fromJson(Map<String, dynamic> json) =>
      ContentDistractor(
        value: json['value'],
        misconceptionId: json['misconceptionId'] as String,
      );
}

class ContentHint {
  const ContentHint({required this.step, required this.text});

  final int step;
  final String text;

  factory ContentHint.fromJson(Map<String, dynamic> json) => ContentHint(
        step: json['step'] as int,
        text: json['text'] as String,
      );
}

class ContentGeneration {
  const ContentGeneration({
    required this.mode,
    required this.deterministicSeed,
  });

  final String mode;
  final String? deterministicSeed;

  factory ContentGeneration.fromJson(Map<String, dynamic> json) =>
      ContentGeneration(
        mode: json['mode'] as String,
        deterministicSeed: json['deterministicSeed'] as String?,
      );
}

class ContentActivity {
  const ContentActivity({
    required this.id,
    required this.legacyContentId,
    required this.classNumber,
    required this.gameId,
    required this.topicId,
    required this.subject,
    required this.unitId,
    required this.competencyId,
    required this.relatedCompetencyIds,
    required this.learningOutcomeId,
    required this.relatedLearningOutcomeIds,
    required this.activityType,
    required this.difficulty,
    required this.prompt,
    required this.correctResponseRule,
    required this.explanation,
    required this.distractors,
    required this.hints,
    required this.narrationText,
    required this.locale,
    required this.author,
    required this.reviewerOwnerId,
    required this.status,
    required this.revision,
    required this.generation,
    required this.payload,
  });

  final String id;
  final String legacyContentId;
  final int classNumber;
  final String gameId;
  final String topicId;
  final String subject;
  final String unitId;
  final String competencyId;
  final List<String> relatedCompetencyIds;
  final String learningOutcomeId;
  final List<String> relatedLearningOutcomeIds;
  final String activityType;
  final int difficulty;
  final String prompt;
  final Map<String, dynamic> correctResponseRule;
  final String explanation;
  final List<ContentDistractor> distractors;
  final List<ContentHint> hints;
  final String narrationText;
  final String locale;
  final String author;
  final String? reviewerOwnerId;
  final String status;
  final int revision;
  final ContentGeneration generation;
  final Map<String, dynamic> payload;

  Iterable<String> get allCompetencyIds sync* {
    yield competencyId;
    yield* relatedCompetencyIds;
  }

  Iterable<String> get allLearningOutcomeIds sync* {
    yield learningOutcomeId;
    yield* relatedLearningOutcomeIds;
  }

  factory ContentActivity.fromJson(Map<String, dynamic> json) {
    final narration = Map<String, dynamic>.from(json['narration'] as Map);
    return ContentActivity(
      id: json['id'] as String,
      legacyContentId: json['legacyContentId'] as String,
      classNumber: json['classNumber'] as int,
      gameId: json['gameId'] as String,
      topicId: json['topicId'] as String,
      subject: json['subject'] as String,
      unitId: json['unitId'] as String,
      competencyId: json['competencyId'] as String,
      relatedCompetencyIds:
          List<String>.from(json['relatedCompetencyIds'] as List),
      learningOutcomeId: json['learningOutcomeId'] as String,
      relatedLearningOutcomeIds:
          List<String>.from(json['relatedLearningOutcomeIds'] as List),
      activityType: json['activityType'] as String,
      difficulty: json['difficulty'] as int,
      prompt: json['prompt'] as String,
      correctResponseRule:
          Map<String, dynamic>.from(json['correctResponseRule'] as Map),
      explanation: json['explanation'] as String,
      distractors: (json['distractors'] as List)
          .map(
            (value) => ContentDistractor.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
      hints: (json['hints'] as List)
          .map(
            (value) => ContentHint.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
      narrationText: narration['text'] as String,
      locale: json['locale'] as String,
      author: json['author'] as String,
      reviewerOwnerId: json['reviewerOwnerId'] as String?,
      status: json['status'] as String,
      revision: json['revision'] as int,
      generation: ContentGeneration.fromJson(
        Map<String, dynamic>.from(json['generation'] as Map),
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

class ContentPackCommercial {
  const ContentPackCommercial({
    required this.priceInr,
    required this.purchaseModel,
    required this.paidEligibility,
    this.freeSampleActivityIds = const <String>[],
  });

  final int priceInr;
  final String purchaseModel;
  final bool paidEligibility;
  final List<String> freeSampleActivityIds;

  bool isFreeSampleActivity(String activityId) =>
      freeSampleActivityIds.contains(activityId);

  factory ContentPackCommercial.fromJson(Map<String, dynamic> json) =>
      ContentPackCommercial(
        priceInr: json['priceInr'] as int,
        purchaseModel: json['purchaseModel'] as String,
        paidEligibility: json['paidEligibility'] as bool,
        freeSampleActivityIds: (json['freeSampleActivityIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[],
      );
}

class ContentPackDevelopment {
  const ContentPackDevelopment({
    required this.lockable,
    required this.defaultLocked,
  });

  final bool lockable;
  final bool defaultLocked;

  factory ContentPackDevelopment.fromJson(Map<String, dynamic> json) =>
      ContentPackDevelopment(
        lockable: json['lockable'] as bool,
        defaultLocked: json['defaultLocked'] as bool,
      );
}

class ContentPack {
  const ContentPack({
    required this.schemaVersion,
    required this.packId,
    required this.packVersion,
    required this.classNumber,
    required this.locale,
    required this.commercial,
    required this.development,
    required this.activities,
  });

  final int schemaVersion;
  final String packId;
  final String packVersion;
  final int classNumber;
  final String locale;
  final ContentPackCommercial commercial;
  final ContentPackDevelopment development;
  final List<ContentActivity> activities;

  factory ContentPack.fromJson(Map<String, dynamic> json) => ContentPack(
        schemaVersion: json['schemaVersion'] as int,
        packId: json['packId'] as String,
        packVersion: json['packVersion'] as String,
        classNumber: json['classNumber'] as int,
        locale: json['locale'] as String,
        commercial: ContentPackCommercial.fromJson(
          Map<String, dynamic>.from(json['commercial'] as Map),
        ),
        development: ContentPackDevelopment.fromJson(
          Map<String, dynamic>.from(json['development'] as Map),
        ),
        activities: (json['activities'] as List)
            .map(
              (value) => ContentActivity.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList(growable: false),
      );
}
