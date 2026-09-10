import 'gameplay_activity_models.dart';
import 'mission_run_models.dart';

/// One persisted exposure to child-visible mission content.
///
/// The record intentionally stores only stable selection metadata. Correct
/// answers, payloads and scoring data remain owned by the content repository.
class MissionExposureRecord {
  const MissionExposureRecord({
    required this.classNumber,
    required this.levelId,
    required this.gameId,
    required this.activityKey,
    required this.archetypeId,
    required this.mechanicName,
    required this.roleName,
    required this.runSeed,
    required this.seenAtIso,
    this.contentFingerprint = '',
    this.topicId = '',
    this.competencyId = '',
    this.difficulty = 0,
  });

  final int classNumber;
  final String levelId;
  final String gameId;
  final String activityKey;
  final String archetypeId;
  final String mechanicName;
  final String roleName;
  final int runSeed;
  final String seenAtIso;

  /// Optional Step 13 advisory metadata. Older schema-v1 records do not carry
  /// these fields and remain fully readable.
  final String contentFingerprint;
  final String topicId;
  final String competencyId;
  final int difficulty;

  Map<String, Object?> toJson() => <String, Object?>{
        'classNumber': classNumber,
        'levelId': levelId,
        'gameId': gameId,
        'activityKey': activityKey,
        'archetypeId': archetypeId,
        'mechanicName': mechanicName,
        'roleName': roleName,
        'runSeed': runSeed,
        'seenAtIso': seenAtIso,
        if (contentFingerprint.isNotEmpty)
          'contentFingerprint': contentFingerprint,
        if (topicId.isNotEmpty) 'topicId': topicId,
        if (competencyId.isNotEmpty) 'competencyId': competencyId,
        if (difficulty > 0) 'difficulty': difficulty,
      };

  static MissionExposureRecord? tryFromJson(Map<String, Object?> json) {
    final classNumber = (json['classNumber'] as num?)?.toInt() ?? 0;
    final levelId = json['levelId'] as String? ?? '';
    final gameId = json['gameId'] as String? ?? '';
    final activityKey = json['activityKey'] as String? ?? '';
    final archetypeId = json['archetypeId'] as String? ?? '';
    final mechanicName = json['mechanicName'] as String? ?? '';
    final roleName = json['roleName'] as String? ?? '';
    final runSeed = (json['runSeed'] as num?)?.toInt();
    final seenAtIso = json['seenAtIso'] as String? ?? '';
    final contentFingerprint = json['contentFingerprint'] as String? ?? '';
    final topicId = json['topicId'] as String? ?? '';
    final competencyId = json['competencyId'] as String? ?? '';
    final difficulty = (json['difficulty'] as num?)?.toInt() ?? 0;
    if (classNumber < 3 ||
        classNumber > 5 ||
        levelId.isEmpty ||
        gameId.isEmpty ||
        activityKey.isEmpty ||
        archetypeId.isEmpty ||
        runSeed == null ||
        DateTime.tryParse(seenAtIso) == null ||
        !LearningGameMechanic.values.any((item) => item.name == mechanicName) ||
        !MissionRunRole.values.any((item) => item.name == roleName) ||
        difficulty < 0 ||
        difficulty > 5) {
      return null;
    }
    return MissionExposureRecord(
      classNumber: classNumber,
      levelId: levelId,
      gameId: gameId,
      activityKey: activityKey,
      archetypeId: archetypeId,
      mechanicName: mechanicName,
      roleName: roleName,
      runSeed: runSeed,
      seenAtIso: seenAtIso,
      contentFingerprint: contentFingerprint,
      topicId: topicId,
      competencyId: competencyId,
      difficulty: difficulty,
    );
  }
}

class MissionClassExposureMemory {
  MissionClassExposureMemory({
    List<MissionExposureRecord>? recent,
    List<String>? recordedRunIds,
  })  : recent = recent ?? <MissionExposureRecord>[],
        recordedRunIds = recordedRunIds ?? <String>[];

  final List<MissionExposureRecord> recent;
  final List<String> recordedRunIds;

  Map<String, Object?> toJson() => <String, Object?>{
        'recent': recent.map((item) => item.toJson()).toList(growable: false),
        'recordedRunIds': List<String>.from(recordedRunIds),
      };

  factory MissionClassExposureMemory.fromJson(Map<String, Object?> json) {
    final recent = <MissionExposureRecord>[];
    final rawRecent = json['recent'];
    if (rawRecent is List) {
      for (final raw in rawRecent) {
        if (raw is! Map) continue;
        final parsed = MissionExposureRecord.tryFromJson(
          Map<String, Object?>.from(raw),
        );
        if (parsed != null) recent.add(parsed);
      }
    }
    final recordedRunIds = (json['recordedRunIds'] as List?)
            ?.whereType<String>()
            .where((id) => id.trim().isNotEmpty)
            .toList(growable: true) ??
        <String>[];
    return MissionClassExposureMemory(
      recent: recent,
      recordedRunIds: recordedRunIds,
    );
  }
}

/// Bounded, profile-owned anti-repeat memory.
///
/// History is split by class so switching between Class 3, 4 and 5 cannot
/// pollute another pack's mission rotation. Each activity key is retained only
/// at its most recent position, making selection truly least-recently-seen.
class MissionExposureMemory {
  MissionExposureMemory({Map<int, MissionClassExposureMemory>? byClass})
      : byClass = byClass ?? <int, MissionClassExposureMemory>{};

  static const int schemaVersion = 1;
  // 240 keeps roughly three 10-item rounds per generated family when a child
  // alternates across all eight games, while remaining small enough for the
  // existing profile-owned SharedPreferences snapshot.
  static const int maxRecentItemsPerClass = 240;
  static const int maxRecordedRunIdsPerClass = 64;

  final Map<int, MissionClassExposureMemory> byClass;

  MissionExposureHistory historyFor({
    required int classNumber,
    required String gameId,
  }) {
    final memory = byClass[classNumber];
    if (memory == null) return const MissionExposureHistory();
    final relevant = memory.recent
        .where((item) => item.gameId == gameId)
        .toList(growable: false);
    return MissionExposureHistory(
      activityKeys:
          relevant.map((item) => item.activityKey).toList(growable: false),
      // Visible wording is intentionally class-wide. If the same authored
      // prompt is reachable through Skill Studio and a World game, the child
      // should still receive a fresh alternative before that wording returns.
      contentFingerprints: memory.recent
          .map((item) => item.contentFingerprint)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      topicIds: relevant
          .map((item) => item.topicId)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      competencyIds: relevant
          .map((item) => item.competencyId)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      archetypeIds:
          relevant.map((item) => item.archetypeId).toList(growable: false),
      mechanics: relevant
          .map(_mechanicFor)
          .whereType<LearningGameMechanic>()
          .toList(growable: false),
    );
  }

  /// Class-wide history used by cross-surface practice planners. Activity keys
  /// remain ordered most-recent-first and advisory metadata is compact/bounded.
  MissionExposureHistory historyForClass(int classNumber) {
    final memory = byClass[classNumber];
    if (memory == null) return const MissionExposureHistory();
    return MissionExposureHistory(
      activityKeys:
          memory.recent.map((item) => item.activityKey).toList(growable: false),
      contentFingerprints: memory.recent
          .map((item) => item.contentFingerprint)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      topicIds: memory.recent
          .map((item) => item.topicId)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      competencyIds: memory.recent
          .map((item) => item.competencyId)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      archetypeIds:
          memory.recent.map((item) => item.archetypeId).toList(growable: false),
      mechanics: memory.recent
          .map(_mechanicFor)
          .whereType<LearningGameMechanic>()
          .toList(growable: false),
    );
  }

  /// Records a completed/attempted run once. Returns true only when persistent
  /// state changed, allowing crash-recovery callers to invoke it idempotently.
  bool recordPlan({
    required MissionRunPlan plan,
    required String runId,
    required DateTime seenAt,
  }) {
    if (plan.classNumber < 3 || plan.classNumber > 5 || runId.trim().isEmpty) {
      return false;
    }
    final memory = byClass.putIfAbsent(
      plan.classNumber,
      MissionClassExposureMemory.new,
    );
    if (memory.recordedRunIds.contains(runId)) return false;

    memory.recordedRunIds.insert(0, runId);
    if (memory.recordedRunIds.length > maxRecordedRunIdsPerClass) {
      memory.recordedRunIds.removeRange(
        maxRecordedRunIdsPerClass,
        memory.recordedRunIds.length,
      );
    }

    final items = <PlannedMissionItem>[
      ...plan.trainingItems,
      ...plan.gameItems,
    ];
    var offset = 0;
    for (final item in items) {
      final candidate = item.candidate;
      memory.recent.removeWhere(
        (existing) => existing.activityKey == candidate.stableKey,
      );
      final timestamp = seenAt.subtract(
        Duration(microseconds: items.length - 1 - offset),
      );
      memory.recent.insert(
        0,
        MissionExposureRecord(
          classNumber: plan.classNumber,
          levelId: plan.levelId,
          gameId: plan.gameId,
          activityKey: candidate.stableKey,
          archetypeId: candidate.archetypeId,
          mechanicName: candidate.mechanic.name,
          roleName: item.role.name,
          runSeed: plan.runSeed,
          seenAtIso: timestamp.toUtc().toIso8601String(),
          contentFingerprint: candidate.contentFingerprint,
          topicId: candidate.topicId,
          competencyId: candidate.competencyId,
          difficulty: candidate.difficulty,
        ),
      );
      offset += 1;
    }
    if (memory.recent.length > maxRecentItemsPerClass) {
      memory.recent.removeRange(
        maxRecentItemsPerClass,
        memory.recent.length,
      );
    }
    return true;
  }

  /// Records a non-World practice surface (for example Skill Studio) through
  /// the same bounded, profile-owned anti-repeat memory. The caller supplies
  /// only selection metadata; no answer payload or score is persisted here.
  bool recordRecords({
    required int classNumber,
    required String runId,
    required Iterable<MissionExposureRecord> records,
  }) {
    if (classNumber < 3 || classNumber > 5 || runId.trim().isEmpty) {
      return false;
    }
    final values = records
        .where((record) => record.classNumber == classNumber)
        .toList(growable: false);
    if (values.isEmpty) return false;
    final memory = byClass.putIfAbsent(
      classNumber,
      MissionClassExposureMemory.new,
    );
    if (memory.recordedRunIds.contains(runId)) return false;

    memory.recordedRunIds.insert(0, runId);
    if (memory.recordedRunIds.length > maxRecordedRunIdsPerClass) {
      memory.recordedRunIds.removeRange(
        maxRecordedRunIdsPerClass,
        memory.recordedRunIds.length,
      );
    }

    for (final record in values) {
      memory.recent.removeWhere(
        (existing) => existing.activityKey == record.activityKey,
      );
      memory.recent.insert(0, record);
    }
    if (memory.recent.length > maxRecentItemsPerClass) {
      memory.recent.removeRange(
        maxRecentItemsPerClass,
        memory.recent.length,
      );
    }
    return true;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'byClass': byClass.map(
          (key, value) => MapEntry<String, Object?>(
            key.toString(),
            value.toJson(),
          ),
        ),
      };

  factory MissionExposureMemory.fromJson(Map<String, Object?> json) {
    if ((json['schemaVersion'] as num?)?.toInt() != schemaVersion) {
      // Anti-repeat history is advisory rather than authoritative progress.
      // Future/corrupt nested schemas therefore fail closed to empty memory
      // instead of risking cross-version selection behavior.
      return MissionExposureMemory();
    }
    final byClass = <int, MissionClassExposureMemory>{};
    final rawByClass = json['byClass'];
    if (rawByClass is Map) {
      for (final entry in rawByClass.entries) {
        final classNumber = int.tryParse(entry.key.toString());
        if (classNumber == null ||
            classNumber < 3 ||
            classNumber > 5 ||
            entry.value is! Map) {
          continue;
        }
        final parsed = MissionClassExposureMemory.fromJson(
          Map<String, Object?>.from(entry.value as Map),
        );
        parsed.recent.removeWhere((item) => item.classNumber != classNumber);
        final seenActivityKeys = <String>{};
        parsed.recent.retainWhere(
          (item) => seenActivityKeys.add(item.activityKey),
        );
        final seenRunIds = <String>{};
        parsed.recordedRunIds.retainWhere(seenRunIds.add);
        if (parsed.recent.length > maxRecentItemsPerClass) {
          parsed.recent.removeRange(
            maxRecentItemsPerClass,
            parsed.recent.length,
          );
        }
        if (parsed.recordedRunIds.length > maxRecordedRunIdsPerClass) {
          parsed.recordedRunIds.removeRange(
            maxRecordedRunIdsPerClass,
            parsed.recordedRunIds.length,
          );
        }
        byClass[classNumber] = parsed;
      }
    }
    return MissionExposureMemory(byClass: byClass);
  }

  static LearningGameMechanic? _mechanicFor(MissionExposureRecord record) {
    for (final mechanic in LearningGameMechanic.values) {
      if (mechanic.name == record.mechanicName) return mechanic;
    }
    return null;
  }
}
