enum LearningEvidenceState {
  notStarted,
  introduced,
  practising,
  masteredNow,
  reviewDue,
  secure,
  needsSupport,
}

enum DiagnosticBand { ready, learning, needsSupport, strong }

enum LearningAttemptKind {
  diagnostic,
  guided,
  independent,
  transfer,
  review,
  project,
}

class AttemptEvidence {
  const AttemptEvidence({
    required this.id,
    required this.profileId,
    required this.classNumber,
    required this.competencyId,
    required this.itemId,
    required this.kind,
    required this.correct,
    required this.hintLevel,
    required this.retries,
    required this.responseTimeMs,
    required this.confidence,
    required this.recordedAtIso,
    this.misconceptionId,
    this.sourceGameId,
  });

  final String id;
  final String profileId;
  final int classNumber;
  final String competencyId;
  final String itemId;
  final LearningAttemptKind kind;
  final bool correct;
  final int hintLevel;
  final int retries;
  final int responseTimeMs;
  final double confidence;
  final String recordedAtIso;
  final String? misconceptionId;
  final String? sourceGameId;

  bool get independent => hintLevel == 0 && retries == 0;
  bool get delayed => kind == LearningAttemptKind.review;
  bool get transfer => kind == LearningAttemptKind.transfer;

  AttemptEvidence copyWith({
    LearningAttemptKind? kind,
    bool? correct,
    int? hintLevel,
    int? retries,
    int? responseTimeMs,
    double? confidence,
    String? recordedAtIso,
    String? misconceptionId,
    String? sourceGameId,
  }) =>
      AttemptEvidence(
        id: id,
        profileId: profileId,
        classNumber: classNumber,
        competencyId: competencyId,
        itemId: itemId,
        kind: kind ?? this.kind,
        correct: correct ?? this.correct,
        hintLevel: hintLevel ?? this.hintLevel,
        retries: retries ?? this.retries,
        responseTimeMs: responseTimeMs ?? this.responseTimeMs,
        confidence: confidence ?? this.confidence,
        recordedAtIso: recordedAtIso ?? this.recordedAtIso,
        misconceptionId: misconceptionId ?? this.misconceptionId,
        sourceGameId: sourceGameId ?? this.sourceGameId,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'profileId': profileId,
        'classNumber': classNumber,
        'competencyId': competencyId,
        'itemId': itemId,
        'kind': kind.name,
        'correct': correct,
        'hintLevel': hintLevel,
        'retries': retries,
        'responseTimeMs': responseTimeMs,
        'confidence': confidence,
        'recordedAtIso': recordedAtIso,
        'misconceptionId': misconceptionId,
        'sourceGameId': sourceGameId,
      };

  factory AttemptEvidence.fromJson(Map<String, Object?> json) =>
      AttemptEvidence(
        id: json['id'] as String? ?? 'legacy-evidence',
        profileId: json['profileId'] as String? ?? 'child-1',
        classNumber:
            ((json['classNumber'] as num?)?.toInt() ?? 4).clamp(3, 5).toInt(),
        competencyId: json['competencyId'] as String? ?? 'unknown',
        itemId: json['itemId'] as String? ?? 'unknown',
        kind: _attemptKind(json['kind']),
        correct: json['correct'] as bool? ?? false,
        hintLevel:
            ((json['hintLevel'] as num?)?.toInt() ?? 0).clamp(0, 2).toInt(),
        retries: ((json['retries'] as num?)?.toInt() ?? 0).clamp(0, 99).toInt(),
        responseTimeMs: ((json['responseTimeMs'] as num?)?.toInt() ?? 0)
            .clamp(0, 3600000)
            .toInt(),
        confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.5)
            .clamp(0.0, 1.0)
            .toDouble(),
        recordedAtIso: json['recordedAtIso'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        misconceptionId: json['misconceptionId'] as String?,
        sourceGameId: json['sourceGameId'] as String?,
      );

  static LearningAttemptKind _attemptKind(Object? raw) {
    final value = raw as String?;
    return LearningAttemptKind.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => LearningAttemptKind.independent,
    );
  }
}

class SkillMastery {
  const SkillMastery({
    required this.competencyId,
    this.state = LearningEvidenceState.notStarted,
    this.evidenceCount = 0,
    this.correctCount = 0,
    this.independentCorrectCount = 0,
    this.transferCorrectCount = 0,
    this.delayedReviewSuccesses = 0,
    this.confidence = 0,
    this.lastEvidenceIso,
    this.nextReviewIso,
    this.misconceptionCounts = const <String, int>{},
  });

  final String competencyId;
  final LearningEvidenceState state;
  final int evidenceCount;
  final int correctCount;
  final int independentCorrectCount;
  final int transferCorrectCount;
  final int delayedReviewSuccesses;
  final double confidence;
  final String? lastEvidenceIso;
  final String? nextReviewIso;
  final Map<String, int> misconceptionCounts;

  double get accuracy =>
      evidenceCount == 0 ? 0.0 : correctCount / evidenceCount;

  SkillMastery copyWith({
    LearningEvidenceState? state,
    int? evidenceCount,
    int? correctCount,
    int? independentCorrectCount,
    int? transferCorrectCount,
    int? delayedReviewSuccesses,
    double? confidence,
    String? lastEvidenceIso,
    String? nextReviewIso,
    bool clearNextReviewIso = false,
    Map<String, int>? misconceptionCounts,
  }) =>
      SkillMastery(
        competencyId: competencyId,
        state: state ?? this.state,
        evidenceCount: evidenceCount ?? this.evidenceCount,
        correctCount: correctCount ?? this.correctCount,
        independentCorrectCount:
            independentCorrectCount ?? this.independentCorrectCount,
        transferCorrectCount: transferCorrectCount ?? this.transferCorrectCount,
        delayedReviewSuccesses:
            delayedReviewSuccesses ?? this.delayedReviewSuccesses,
        confidence: confidence ?? this.confidence,
        lastEvidenceIso: lastEvidenceIso ?? this.lastEvidenceIso,
        nextReviewIso:
            clearNextReviewIso ? null : (nextReviewIso ?? this.nextReviewIso),
        misconceptionCounts: misconceptionCounts ?? this.misconceptionCounts,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'competencyId': competencyId,
        'state': state.name,
        'evidenceCount': evidenceCount,
        'correctCount': correctCount,
        'independentCorrectCount': independentCorrectCount,
        'transferCorrectCount': transferCorrectCount,
        'delayedReviewSuccesses': delayedReviewSuccesses,
        'confidence': confidence,
        'lastEvidenceIso': lastEvidenceIso,
        'nextReviewIso': nextReviewIso,
        'misconceptionCounts': misconceptionCounts,
      };

  factory SkillMastery.fromJson(Map<String, Object?> json) {
    final misconceptions = <String, int>{};
    final rawMisconceptions = json['misconceptionCounts'];
    if (rawMisconceptions is Map) {
      for (final entry in rawMisconceptions.entries) {
        if (entry.key is String && entry.value is num) {
          misconceptions[entry.key as String] = (entry.value as num).toInt();
        }
      }
    }
    final stateName = json['state'] as String?;
    return SkillMastery(
      competencyId: json['competencyId'] as String? ?? 'unknown',
      state: LearningEvidenceState.values.firstWhere(
        (candidate) => candidate.name == stateName,
        orElse: () => LearningEvidenceState.notStarted,
      ),
      evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      independentCorrectCount:
          (json['independentCorrectCount'] as num?)?.toInt() ?? 0,
      transferCorrectCount:
          (json['transferCorrectCount'] as num?)?.toInt() ?? 0,
      delayedReviewSuccesses:
          (json['delayedReviewSuccesses'] as num?)?.toInt() ?? 0,
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      lastEvidenceIso: json['lastEvidenceIso'] as String?,
      nextReviewIso: json['nextReviewIso'] as String?,
      misconceptionCounts: misconceptions,
    );
  }
}

class ReviewTask {
  const ReviewTask({
    required this.id,
    required this.competencyId,
    required this.classNumber,
    required this.dueIso,
    required this.intervalIndex,
    this.sourceItemId,
    this.completed = false,
  });

  final String id;
  final String competencyId;
  final int classNumber;
  final String dueIso;
  final int intervalIndex;
  final String? sourceItemId;
  final bool completed;

  DateTime? get dueAt => DateTime.tryParse(dueIso);

  ReviewTask copyWith({
    String? dueIso,
    int? intervalIndex,
    String? sourceItemId,
    bool? completed,
  }) =>
      ReviewTask(
        id: id,
        competencyId: competencyId,
        classNumber: classNumber,
        dueIso: dueIso ?? this.dueIso,
        intervalIndex: intervalIndex ?? this.intervalIndex,
        sourceItemId: sourceItemId ?? this.sourceItemId,
        completed: completed ?? this.completed,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'competencyId': competencyId,
        'classNumber': classNumber,
        'dueIso': dueIso,
        'intervalIndex': intervalIndex,
        'sourceItemId': sourceItemId,
        'completed': completed,
      };

  factory ReviewTask.fromJson(Map<String, Object?> json) => ReviewTask(
        id: json['id'] as String? ?? 'review',
        competencyId: json['competencyId'] as String? ?? 'unknown',
        classNumber:
            ((json['classNumber'] as num?)?.toInt() ?? 4).clamp(3, 5).toInt(),
        dueIso: json['dueIso'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        intervalIndex:
            ((json['intervalIndex'] as num?)?.toInt() ?? 0).clamp(0, 4).toInt(),
        sourceItemId: json['sourceItemId'] as String?,
        completed: json['completed'] as bool? ?? false,
      );
}

class DiagnosticProgress {
  const DiagnosticProgress({
    this.classNumber = 4,
    this.itemIds = const <String>[],
    this.currentIndex = 0,
    this.startedAtIso,
    this.completedAtIso,
  });

  final int classNumber;
  final List<String> itemIds;
  final int currentIndex;
  final String? startedAtIso;
  final String? completedAtIso;

  bool get started => itemIds.isNotEmpty;
  bool get completed => completedAtIso != null;
  double get progress => itemIds.isEmpty
      ? 0.0
      : (currentIndex / itemIds.length).clamp(0.0, 1.0).toDouble();

  DiagnosticProgress copyWith({
    int? classNumber,
    List<String>? itemIds,
    int? currentIndex,
    String? startedAtIso,
    String? completedAtIso,
    bool clearCompletedAt = false,
  }) =>
      DiagnosticProgress(
        classNumber: classNumber ?? this.classNumber,
        itemIds: itemIds ?? this.itemIds,
        currentIndex: currentIndex ?? this.currentIndex,
        startedAtIso: startedAtIso ?? this.startedAtIso,
        completedAtIso:
            clearCompletedAt ? null : (completedAtIso ?? this.completedAtIso),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'classNumber': classNumber,
        'itemIds': itemIds,
        'currentIndex': currentIndex,
        'startedAtIso': startedAtIso,
        'completedAtIso': completedAtIso,
      };

  factory DiagnosticProgress.fromJson(Map<String, Object?> json) =>
      DiagnosticProgress(
        classNumber:
            ((json['classNumber'] as num?)?.toInt() ?? 4).clamp(3, 5).toInt(),
        itemIds: (json['itemIds'] as List?)?.whereType<String>().toList() ??
            const <String>[],
        currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
        startedAtIso: json['startedAtIso'] as String?,
        completedAtIso: json['completedAtIso'] as String?,
      );
}

class ProjectEvidence {
  const ProjectEvidence({
    required this.id,
    required this.missionId,
    required this.classNumber,
    required this.competencyIds,
    required this.correctness,
    required this.strategy,
    required this.independence,
    required this.explanation,
    required this.completedAtIso,
    this.adultVerified = false,
  });

  final String id;
  final String missionId;
  final int classNumber;
  final List<String> competencyIds;
  final double correctness;
  final double strategy;
  final double independence;
  final double explanation;
  final String completedAtIso;
  final bool adultVerified;

  double get overall =>
      (correctness + strategy + independence + explanation) / 4;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'missionId': missionId,
        'classNumber': classNumber,
        'competencyIds': competencyIds,
        'correctness': correctness,
        'strategy': strategy,
        'independence': independence,
        'explanation': explanation,
        'completedAtIso': completedAtIso,
        'adultVerified': adultVerified,
      };

  factory ProjectEvidence.fromJson(Map<String, Object?> json) =>
      ProjectEvidence(
        id: json['id'] as String? ?? 'project-evidence',
        missionId: json['missionId'] as String? ?? 'project',
        classNumber:
            ((json['classNumber'] as num?)?.toInt() ?? 4).clamp(3, 5).toInt(),
        competencyIds:
            (json['competencyIds'] as List?)?.whereType<String>().toList() ??
                const <String>[],
        correctness: ((json['correctness'] as num?)?.toDouble() ?? 0)
            .clamp(0.0, 1.0)
            .toDouble(),
        strategy: ((json['strategy'] as num?)?.toDouble() ?? 0)
            .clamp(0.0, 1.0)
            .toDouble(),
        independence: ((json['independence'] as num?)?.toDouble() ?? 0)
            .clamp(0.0, 1.0)
            .toDouble(),
        explanation: ((json['explanation'] as num?)?.toDouble() ?? 0)
            .clamp(0.0, 1.0)
            .toDouble(),
        completedAtIso: json['completedAtIso'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        adultVerified: json['adultVerified'] as bool? ?? false,
      );
}

class LearningProfileState {
  const LearningProfileState({
    this.diagnostic = const DiagnosticProgress(),
    this.attemptEvidence = const <AttemptEvidence>[],
    this.skillMastery = const <String, SkillMastery>{},
    this.reviewTasks = const <ReviewTask>[],
    this.projectEvidence = const <ProjectEvidence>[],
    this.localeCode = 'en-IN',
    this.dyslexiaFriendlySpacing = false,
    this.readingFocusEnabled = false,
    this.captionsEnabled = true,
  });

  final DiagnosticProgress diagnostic;
  final List<AttemptEvidence> attemptEvidence;
  final Map<String, SkillMastery> skillMastery;
  final List<ReviewTask> reviewTasks;
  final List<ProjectEvidence> projectEvidence;
  final String localeCode;
  final bool dyslexiaFriendlySpacing;
  final bool readingFocusEnabled;
  final bool captionsEnabled;

  LearningProfileState copyWith({
    DiagnosticProgress? diagnostic,
    List<AttemptEvidence>? attemptEvidence,
    Map<String, SkillMastery>? skillMastery,
    List<ReviewTask>? reviewTasks,
    List<ProjectEvidence>? projectEvidence,
    String? localeCode,
    bool? dyslexiaFriendlySpacing,
    bool? readingFocusEnabled,
    bool? captionsEnabled,
  }) =>
      LearningProfileState(
        diagnostic: diagnostic ?? this.diagnostic,
        attemptEvidence: attemptEvidence ?? this.attemptEvidence,
        skillMastery: skillMastery ?? this.skillMastery,
        reviewTasks: reviewTasks ?? this.reviewTasks,
        projectEvidence: projectEvidence ?? this.projectEvidence,
        localeCode: localeCode ?? this.localeCode,
        dyslexiaFriendlySpacing:
            dyslexiaFriendlySpacing ?? this.dyslexiaFriendlySpacing,
        readingFocusEnabled: readingFocusEnabled ?? this.readingFocusEnabled,
        captionsEnabled: captionsEnabled ?? this.captionsEnabled,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'diagnostic': diagnostic.toJson(),
        'attemptEvidence':
            attemptEvidence.map((item) => item.toJson()).toList(),
        'skillMastery': skillMastery.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
        'reviewTasks': reviewTasks.map((item) => item.toJson()).toList(),
        'projectEvidence':
            projectEvidence.map((item) => item.toJson()).toList(),
        'localeCode': localeCode,
        'dyslexiaFriendlySpacing': dyslexiaFriendlySpacing,
        'readingFocusEnabled': readingFocusEnabled,
        'captionsEnabled': captionsEnabled,
      };

  factory LearningProfileState.fromJson(Map<String, Object?> json) {
    final mastery = <String, SkillMastery>{};
    final rawMastery = json['skillMastery'];
    if (rawMastery is Map) {
      for (final entry in rawMastery.entries) {
        if (entry.key is String && entry.value is Map) {
          mastery[entry.key as String] = SkillMastery.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        }
      }
    }
    return LearningProfileState(
      diagnostic: json['diagnostic'] is Map
          ? DiagnosticProgress.fromJson(
              Map<String, Object?>.from(json['diagnostic'] as Map),
            )
          : const DiagnosticProgress(),
      attemptEvidence:
          _mapList(json['attemptEvidence'], AttemptEvidence.fromJson),
      skillMastery: mastery,
      reviewTasks: _mapList(json['reviewTasks'], ReviewTask.fromJson),
      projectEvidence:
          _mapList(json['projectEvidence'], ProjectEvidence.fromJson),
      localeCode: json['localeCode'] as String? ?? 'en-IN',
      dyslexiaFriendlySpacing:
          json['dyslexiaFriendlySpacing'] as bool? ?? false,
      readingFocusEnabled: json['readingFocusEnabled'] as bool? ?? false,
      captionsEnabled: json['captionsEnabled'] as bool? ?? true,
    );
  }

  static List<T> _mapList<T>(
    Object? raw,
    T Function(Map<String, Object?> json) decoder,
  ) {
    if (raw is! List) return <T>[];
    return raw
        .whereType<Map>()
        .map((value) => decoder(Map<String, Object?>.from(value)))
        .toList();
  }
}

class LearningRecommendation {
  const LearningRecommendation({
    required this.competencyId,
    required this.reason,
    required this.priority,
    required this.state,
  });

  final String competencyId;
  final String reason;
  final int priority;
  final LearningEvidenceState state;
}
