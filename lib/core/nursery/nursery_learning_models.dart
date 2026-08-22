import '../learning/learning_models.dart';

class NurseryAttemptEvidence {
  const NurseryAttemptEvidence({
    required this.id,
    required this.profileId,
    required this.packId,
    required this.skillId,
    required this.itemId,
    required this.kind,
    required this.correct,
    required this.hintLevel,
    required this.retries,
    required this.responseTimeMs,
    required this.recordedAtIso,
    required this.contributesToMastery,
    this.misconceptionId,
    this.generatedSeed,
  });

  final String id;
  final String profileId;
  final String packId;
  final String skillId;
  final String itemId;
  final LearningAttemptKind kind;
  final bool correct;
  final int hintLevel;
  final int retries;
  final int responseTimeMs;
  final String recordedAtIso;
  final bool contributesToMastery;
  final String? misconceptionId;
  final int? generatedSeed;

  bool get clean => hintLevel == 0 && retries == 0;
  bool get cleanIndependent =>
      contributesToMastery &&
      kind == LearningAttemptKind.independent &&
      correct &&
      clean;
  bool get cleanTransfer =>
      contributesToMastery &&
      kind == LearningAttemptKind.transfer &&
      correct &&
      clean;
  bool get cleanReview =>
      contributesToMastery &&
      kind == LearningAttemptKind.review &&
      correct &&
      clean;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'profileId': profileId,
        'packId': packId,
        'skillId': skillId,
        'itemId': itemId,
        'kind': kind.name,
        'correct': correct,
        'hintLevel': hintLevel,
        'retries': retries,
        'responseTimeMs': responseTimeMs,
        'recordedAtIso': recordedAtIso,
        'contributesToMastery': contributesToMastery,
        'misconceptionId': misconceptionId,
        'generatedSeed': generatedSeed,
      };

  factory NurseryAttemptEvidence.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String?;
    return NurseryAttemptEvidence(
      id: json['id'] as String? ?? 'nursery:legacy-evidence',
      profileId: json['profileId'] as String? ?? 'child-1',
      packId: json['packId'] as String? ?? 'brightquest_nursery',
      skillId: json['skillId'] as String? ?? 'unknown',
      itemId: json['itemId'] as String? ?? 'unknown',
      kind: LearningAttemptKind.values.firstWhere(
        (candidate) => candidate.name == kindName,
        orElse: () => LearningAttemptKind.independent,
      ),
      correct: json['correct'] as bool? ?? false,
      hintLevel:
          ((json['hintLevel'] as num?)?.toInt() ?? 0).clamp(0, 2).toInt(),
      retries: ((json['retries'] as num?)?.toInt() ?? 0).clamp(0, 99).toInt(),
      responseTimeMs: ((json['responseTimeMs'] as num?)?.toInt() ?? 0)
          .clamp(0, 3600000)
          .toInt(),
      recordedAtIso: json['recordedAtIso'] as String? ??
          DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      contributesToMastery: json['contributesToMastery'] as bool? ?? true,
      misconceptionId: json['misconceptionId'] as String?,
      generatedSeed: (json['generatedSeed'] as num?)?.toInt(),
    );
  }
}

class NurserySkillMastery {
  const NurserySkillMastery({
    required this.skillId,
    this.state = LearningEvidenceState.notStarted,
    this.scorableEvidenceCount = 0,
    this.correctCount = 0,
    this.cleanIndependentCorrectCount = 0,
    this.cleanTransferCorrectCount = 0,
    this.cleanDelayedReviewSuccesses = 0,
    this.confidence = 0,
    this.lastEvidenceIso,
    this.nextReviewIso,
    this.misconceptionCounts = const <String, int>{},
  });

  final String skillId;
  final LearningEvidenceState state;
  final int scorableEvidenceCount;
  final int correctCount;
  final int cleanIndependentCorrectCount;
  final int cleanTransferCorrectCount;
  final int cleanDelayedReviewSuccesses;
  final double confidence;
  final String? lastEvidenceIso;
  final String? nextReviewIso;
  final Map<String, int> misconceptionCounts;

  double get accuracy =>
      scorableEvidenceCount == 0 ? 0 : correctCount / scorableEvidenceCount;

  NurserySkillMastery copyWith({
    LearningEvidenceState? state,
    int? scorableEvidenceCount,
    int? correctCount,
    int? cleanIndependentCorrectCount,
    int? cleanTransferCorrectCount,
    int? cleanDelayedReviewSuccesses,
    double? confidence,
    String? lastEvidenceIso,
    String? nextReviewIso,
    bool clearNextReviewIso = false,
    Map<String, int>? misconceptionCounts,
  }) =>
      NurserySkillMastery(
        skillId: skillId,
        state: state ?? this.state,
        scorableEvidenceCount:
            scorableEvidenceCount ?? this.scorableEvidenceCount,
        correctCount: correctCount ?? this.correctCount,
        cleanIndependentCorrectCount:
            cleanIndependentCorrectCount ?? this.cleanIndependentCorrectCount,
        cleanTransferCorrectCount:
            cleanTransferCorrectCount ?? this.cleanTransferCorrectCount,
        cleanDelayedReviewSuccesses:
            cleanDelayedReviewSuccesses ?? this.cleanDelayedReviewSuccesses,
        confidence: confidence ?? this.confidence,
        lastEvidenceIso: lastEvidenceIso ?? this.lastEvidenceIso,
        nextReviewIso:
            clearNextReviewIso ? null : (nextReviewIso ?? this.nextReviewIso),
        misconceptionCounts: misconceptionCounts ?? this.misconceptionCounts,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'skillId': skillId,
        'state': state.name,
        'scorableEvidenceCount': scorableEvidenceCount,
        'correctCount': correctCount,
        'cleanIndependentCorrectCount': cleanIndependentCorrectCount,
        'cleanTransferCorrectCount': cleanTransferCorrectCount,
        'cleanDelayedReviewSuccesses': cleanDelayedReviewSuccesses,
        'confidence': confidence,
        'lastEvidenceIso': lastEvidenceIso,
        'nextReviewIso': nextReviewIso,
        'misconceptionCounts': misconceptionCounts,
      };

  factory NurserySkillMastery.fromJson(Map<String, Object?> json) {
    final stateName = json['state'] as String?;
    final misconceptions = <String, int>{};
    final rawMisconceptions = json['misconceptionCounts'];
    if (rawMisconceptions is Map) {
      for (final entry in rawMisconceptions.entries) {
        if (entry.key is String && entry.value is num) {
          misconceptions[entry.key as String] = (entry.value as num).toInt();
        }
      }
    }
    return NurserySkillMastery(
      skillId: json['skillId'] as String? ?? 'unknown',
      state: LearningEvidenceState.values.firstWhere(
        (candidate) => candidate.name == stateName,
        orElse: () => LearningEvidenceState.notStarted,
      ),
      scorableEvidenceCount:
          (json['scorableEvidenceCount'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      cleanIndependentCorrectCount:
          (json['cleanIndependentCorrectCount'] as num?)?.toInt() ?? 0,
      cleanTransferCorrectCount:
          (json['cleanTransferCorrectCount'] as num?)?.toInt() ?? 0,
      cleanDelayedReviewSuccesses:
          (json['cleanDelayedReviewSuccesses'] as num?)?.toInt() ?? 0,
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      lastEvidenceIso: json['lastEvidenceIso'] as String?,
      nextReviewIso: json['nextReviewIso'] as String?,
      misconceptionCounts: Map<String, int>.unmodifiable(misconceptions),
    );
  }
}

class NurseryReviewTask {
  const NurseryReviewTask({
    required this.id,
    required this.packId,
    required this.skillId,
    required this.dueIso,
    required this.intervalIndex,
    required this.sourceItemId,
    this.completed = false,
  });

  final String id;
  final String packId;
  final String skillId;
  final String dueIso;
  final int intervalIndex;
  final String sourceItemId;
  final bool completed;

  DateTime? get dueAt => DateTime.tryParse(dueIso);

  NurseryReviewTask copyWith({
    String? dueIso,
    int? intervalIndex,
    bool? completed,
  }) =>
      NurseryReviewTask(
        id: id,
        packId: packId,
        skillId: skillId,
        dueIso: dueIso ?? this.dueIso,
        intervalIndex: intervalIndex ?? this.intervalIndex,
        sourceItemId: sourceItemId,
        completed: completed ?? this.completed,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'packId': packId,
        'skillId': skillId,
        'dueIso': dueIso,
        'intervalIndex': intervalIndex,
        'sourceItemId': sourceItemId,
        'completed': completed,
      };

  factory NurseryReviewTask.fromJson(Map<String, Object?> json) =>
      NurseryReviewTask(
        id: json['id'] as String? ?? 'nursery-review:unknown',
        packId: json['packId'] as String? ?? 'brightquest_nursery',
        skillId: json['skillId'] as String? ?? 'unknown',
        dueIso: json['dueIso'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        intervalIndex:
            ((json['intervalIndex'] as num?)?.toInt() ?? 0).clamp(0, 4).toInt(),
        sourceItemId: json['sourceItemId'] as String? ?? 'unknown',
        completed: json['completed'] as bool? ?? false,
      );
}

class NurseryLearningState {
  const NurseryLearningState({
    this.packId = 'brightquest_nursery',
    this.contentVersion = 1,
    this.attemptEvidence = const <NurseryAttemptEvidence>[],
    this.skillMastery = const <String, NurserySkillMastery>{},
    this.reviewTasks = const <NurseryReviewTask>[],
  });

  final String packId;
  final int contentVersion;
  final List<NurseryAttemptEvidence> attemptEvidence;
  final Map<String, NurserySkillMastery> skillMastery;
  final List<NurseryReviewTask> reviewTasks;

  NurseryLearningState copyWith({
    int? contentVersion,
    List<NurseryAttemptEvidence>? attemptEvidence,
    Map<String, NurserySkillMastery>? skillMastery,
    List<NurseryReviewTask>? reviewTasks,
  }) =>
      NurseryLearningState(
        packId: packId,
        contentVersion: contentVersion ?? this.contentVersion,
        attemptEvidence: attemptEvidence ?? this.attemptEvidence,
        skillMastery: skillMastery ?? this.skillMastery,
        reviewTasks: reviewTasks ?? this.reviewTasks,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'packId': packId,
        'contentVersion': contentVersion,
        'attemptEvidence':
            attemptEvidence.map((evidence) => evidence.toJson()).toList(),
        'skillMastery': skillMastery.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
        'reviewTasks': reviewTasks.map((task) => task.toJson()).toList(),
      };

  factory NurseryLearningState.fromJson(Map<String, Object?> json) {
    if (json['packId'] != null && json['packId'] != 'brightquest_nursery') {
      return const NurseryLearningState();
    }
    final mastery = <String, NurserySkillMastery>{};
    final rawMastery = json['skillMastery'];
    if (rawMastery is Map) {
      for (final entry in rawMastery.entries) {
        if (entry.key is String && entry.value is Map) {
          mastery[entry.key as String] = NurserySkillMastery.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        }
      }
    }
    return NurseryLearningState(
      contentVersion: ((json['contentVersion'] as num?)?.toInt() ?? 1)
          .clamp(1, 1000)
          .toInt(),
      attemptEvidence: _decodeList(
        json['attemptEvidence'],
        NurseryAttemptEvidence.fromJson,
      ),
      skillMastery: Map<String, NurserySkillMastery>.unmodifiable(mastery),
      reviewTasks: _decodeList(
        json['reviewTasks'],
        NurseryReviewTask.fromJson,
      ),
    );
  }

  static List<T> _decodeList<T>(
    Object? raw,
    T Function(Map<String, Object?> json) decoder,
  ) {
    if (raw is! List) return <T>[];
    return List<T>.unmodifiable(
      raw.whereType<Map>().map(
            (value) => decoder(Map<String, Object?>.from(value)),
          ),
    );
  }
}
