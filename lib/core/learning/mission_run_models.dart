import 'gameplay_activity_models.dart';
import 'mission_variety_models.dart';

/// Where a mission candidate comes from.
///
/// Generated candidates are still backed by BrightQuest's existing,
/// deterministic content generators. This model does not create or infer
/// educational content.
enum MissionContentSource { authored, generated }

/// The two allocation boundaries the mission planner owns.
///
/// Detailed lesson support phases remain owned by [MissionSessionEngine]. The
/// planner only guarantees that content reserved for teaching can be kept out
/// of the real game run.
enum MissionRunRole { training, game }

/// Immutable, renderer-neutral reference to one valid gameplay activity.
///
/// Both [activityId] and [legacyContentId] are retained because authored
/// activities are looked up by activity id while the existing generated
/// practice bridge resolves deterministic variants by legacy content id.
class MissionCandidate {
  const MissionCandidate({
    required this.activityId,
    required this.legacyContentId,
    required this.classNumber,
    required this.gameId,
    required this.topicId,
    required this.competencyId,
    this.relatedCompetencyIds = const <String>[],
    required this.difficulty,
    required this.activityType,
    required this.responseRuleType,
    required this.source,
    required this.mechanic,
    required this.archetypeId,
    required this.contentFingerprint,
  });

  final String activityId;
  final String legacyContentId;
  final int classNumber;
  final String gameId;
  final String topicId;
  final String competencyId;
  final List<String> relatedCompetencyIds;
  final int difficulty;
  final String activityType;
  final String responseRuleType;
  final MissionContentSource source;
  final LearningGameMechanic mechanic;

  /// Structural mission family derived only from authored metadata and the
  /// existing gameplay resolver. Prompt text is deliberately not inspected.
  final String archetypeId;

  /// Stable fingerprint of the child-visible prompt. It is used only for
  /// duplicate suppression; correctness still comes from the activity rule.
  final String contentFingerprint;

  String get stableKey => '$classNumber|$gameId|$legacyContentId';

  bool get isGenerated => source == MissionContentSource.generated;

  Set<String> get allCompetencyIds => <String>{
        if (competencyId.isNotEmpty) competencyId,
        ...relatedCompetencyIds.where((id) => id.isNotEmpty),
      };

  Map<String, Object?> toJson() => <String, Object?>{
        'activityId': activityId,
        'legacyContentId': legacyContentId,
        'classNumber': classNumber,
        'gameId': gameId,
        'topicId': topicId,
        'competencyId': competencyId,
        'relatedCompetencyIds': relatedCompetencyIds,
        'difficulty': difficulty,
        'activityType': activityType,
        'responseRuleType': responseRuleType,
        'source': source.name,
        'mechanic': mechanic.name,
        'archetypeId': archetypeId,
        'contentFingerprint': contentFingerprint,
      };

  factory MissionCandidate.fromJson(Map<String, Object?> json) {
    final sourceName = json['source'] as String?;
    final mechanicName = json['mechanic'] as String?;
    MissionContentSource? source;
    for (final candidate in MissionContentSource.values) {
      if (candidate.name == sourceName) {
        source = candidate;
        break;
      }
    }
    LearningGameMechanic? mechanic;
    for (final candidate in LearningGameMechanic.values) {
      if (candidate.name == mechanicName) {
        mechanic = candidate;
        break;
      }
    }
    if (source == null || mechanic == null) {
      throw const FormatException('Invalid mission candidate enum value.');
    }
    final classNumber = (json['classNumber'] as num?)?.toInt() ?? 0;
    final difficulty = (json['difficulty'] as num?)?.toInt() ?? 0;
    final activityId = json['activityId'] as String? ?? '';
    final legacyContentId = json['legacyContentId'] as String? ?? '';
    final gameId = json['gameId'] as String? ?? '';
    if (activityId.isEmpty ||
        legacyContentId.isEmpty ||
        gameId.isEmpty ||
        (json['contentFingerprint'] as String? ?? '').isEmpty ||
        classNumber < 3 ||
        classNumber > 5 ||
        difficulty < 1 ||
        difficulty > 3) {
      throw const FormatException('Invalid mission candidate identity.');
    }
    return MissionCandidate(
      activityId: activityId,
      legacyContentId: legacyContentId,
      classNumber: classNumber,
      gameId: gameId,
      topicId: json['topicId'] as String? ?? '',
      competencyId: json['competencyId'] as String? ?? '',
      relatedCompetencyIds: (json['relatedCompetencyIds'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      difficulty: difficulty,
      activityType: json['activityType'] as String? ?? '',
      responseRuleType: json['responseRuleType'] as String? ?? '',
      source: source,
      mechanic: mechanic,
      archetypeId: json['archetypeId'] as String? ?? '',
      contentFingerprint: json['contentFingerprint'] as String? ?? '',
    );
  }
}

class PlannedMissionItem {
  const PlannedMissionItem({
    required this.candidate,
    required this.role,
    required this.position,
  });

  final MissionCandidate candidate;
  final MissionRunRole role;
  final int position;

  Map<String, Object?> toJson() => <String, Object?>{
        'candidate': candidate.toJson(),
        'role': role.name,
        'position': position,
      };

  factory PlannedMissionItem.fromJson(Map<String, Object?> json) {
    final roleName = json['role'] as String?;
    MissionRunRole? role;
    for (final candidate in MissionRunRole.values) {
      if (candidate.name == roleName) {
        role = candidate;
        break;
      }
    }
    final rawCandidate = json['candidate'];
    if (role == null || rawCandidate is! Map) {
      throw const FormatException('Invalid planned mission item.');
    }
    return PlannedMissionItem(
      candidate: MissionCandidate.fromJson(
        Map<String, Object?>.from(rawCandidate),
      ),
      role: role,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Ordered recent-exposure data supplied by the caller.
///
/// Lists are most-recent-first. Persistence is owned by the active child
/// profile through MissionExposureMemory; the planner remains storage-agnostic.
class MissionExposureHistory {
  const MissionExposureHistory({
    this.activityKeys = const <String>[],
    this.contentFingerprints = const <String>[],
    this.topicIds = const <String>[],
    this.competencyIds = const <String>[],
    this.archetypeIds = const <String>[],
    this.mechanics = const <LearningGameMechanic>[],
  });

  /// Exact persisted activity identities for this game/surface.
  final List<String> activityKeys;

  /// Child-visible prompt fingerprints. The persistence layer can supply these
  /// class-wide so the same wording is not immediately recycled through a
  /// different surface or generated identity.
  final List<String> contentFingerprints;

  /// Most-recent-first authored topic/competency metadata. These are soft
  /// diversity signals only and never change curriculum correctness.
  final List<String> topicIds;
  final List<String> competencyIds;
  final List<String> archetypeIds;
  final List<LearningGameMechanic> mechanics;
}

/// Explicit run-shape policy. Counts are intentionally supplied by the caller
/// rather than guessed from a game id or class number.
class MissionRunRequest {
  const MissionRunRequest({
    required this.runSeed,
    required this.trainingItemCount,
    required this.gameItemCount,
    this.history = const MissionExposureHistory(),
    this.includeGeneratedPractice = true,
    this.allowTrainingReuseWhenExhausted = false,
    this.trainingMechanics = const <LearningGameMechanic>{},
    this.gameMechanics = const <LearningGameMechanic>{},
    this.selectionProfile = AdaptiveMissionSelectionProfile.neutral,
  })  : assert(trainingItemCount >= 0),
        assert(gameItemCount >= 0);

  final int runSeed;
  final int trainingItemCount;
  final int gameItemCount;
  final MissionExposureHistory history;

  /// Only existing deterministic generator families are eligible. Unsupported
  /// games simply contribute authored candidates.
  final bool includeGeneratedPractice;

  /// Strictly false by default so a small content pool is reported as a
  /// shortfall instead of silently replaying a training activity in the game.
  final bool allowTrainingReuseWhenExhausted;

  /// Empty means any supported mechanic. These role filters let a mixed game
  /// family such as Science Lab keep experiment activities in Training while
  /// reserving choice activities for its existing real-game quiz renderer.
  final Set<LearningGameMechanic> trainingMechanics;
  final Set<LearningGameMechanic> gameMechanics;

  /// Read-only evidence-derived preference profile. It changes candidate
  /// ranking only; correctness and numeric curriculum difficulty stay fixed.
  final AdaptiveMissionSelectionProfile selectionProfile;
}

class MissionRunPlan {
  const MissionRunPlan({
    required this.levelId,
    required this.classNumber,
    required this.gameId,
    required this.difficulty,
    required this.runSeed,
    required this.requestedTrainingItemCount,
    required this.requestedGameItemCount,
    required this.trainingItems,
    required this.gameItems,
    required this.availableCandidateCount,
    this.selectionDemand = 'balanced',
    this.selectionReason = '',
  });

  final String levelId;
  final int classNumber;
  final String gameId;
  final int difficulty;
  final int runSeed;
  final int requestedTrainingItemCount;
  final int requestedGameItemCount;
  final List<PlannedMissionItem> trainingItems;
  final List<PlannedMissionItem> gameItems;
  final int availableCandidateCount;
  final String selectionDemand;
  final String selectionReason;

  int get trainingShortfall =>
      requestedTrainingItemCount - trainingItems.length;
  int get gameShortfall => requestedGameItemCount - gameItems.length;
  bool get hasContentShortfall => trainingShortfall > 0 || gameShortfall > 0;

  Set<String> get trainingActivityKeys =>
      trainingItems.map((item) => item.candidate.stableKey).toSet();

  Set<String> get gameActivityKeys =>
      gameItems.map((item) => item.candidate.stableKey).toSet();

  bool get hasTrainingGameOverlap =>
      trainingActivityKeys.intersection(gameActivityKeys).isNotEmpty;

  Set<String> get trainingContentFingerprints =>
      trainingItems.map((item) => item.candidate.contentFingerprint).toSet();

  Set<String> get gameContentFingerprints =>
      gameItems.map((item) => item.candidate.contentFingerprint).toSet();

  bool get hasVisibleContentOverlap => trainingContentFingerprints
      .intersection(gameContentFingerprints)
      .isNotEmpty;

  bool get hasInternalContentRepeat =>
      trainingContentFingerprints.length != trainingItems.length ||
      gameContentFingerprints.length != gameItems.length;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'levelId': levelId,
        'classNumber': classNumber,
        'gameId': gameId,
        'difficulty': difficulty,
        'runSeed': runSeed,
        'requestedTrainingItemCount': requestedTrainingItemCount,
        'requestedGameItemCount': requestedGameItemCount,
        'availableCandidateCount': availableCandidateCount,
        'selectionDemand': selectionDemand,
        'selectionReason': selectionReason,
        'trainingItems': trainingItems.map((item) => item.toJson()).toList(),
        'gameItems': gameItems.map((item) => item.toJson()).toList(),
      };

  factory MissionRunPlan.fromJson(Map<String, Object?> json) {
    if ((json['schemaVersion'] as num?)?.toInt() != 1) {
      throw const FormatException('Unsupported mission run plan schema.');
    }
    final rawTraining = json['trainingItems'];
    final rawGame = json['gameItems'];
    if (rawTraining is! List || rawGame is! List) {
      throw const FormatException('Invalid mission run plan items.');
    }
    final plan = MissionRunPlan(
      levelId: json['levelId'] as String? ?? '',
      classNumber: (json['classNumber'] as num?)?.toInt() ?? 0,
      gameId: json['gameId'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 0,
      runSeed: (json['runSeed'] as num?)?.toInt() ?? 0,
      requestedTrainingItemCount:
          (json['requestedTrainingItemCount'] as num?)?.toInt() ?? 0,
      requestedGameItemCount:
          (json['requestedGameItemCount'] as num?)?.toInt() ?? 0,
      trainingItems: List<PlannedMissionItem>.unmodifiable(
        rawTraining.map(
          (value) => PlannedMissionItem.fromJson(
            Map<String, Object?>.from(value as Map),
          ),
        ),
      ),
      gameItems: List<PlannedMissionItem>.unmodifiable(
        rawGame.map(
          (value) => PlannedMissionItem.fromJson(
            Map<String, Object?>.from(value as Map),
          ),
        ),
      ),
      availableCandidateCount:
          (json['availableCandidateCount'] as num?)?.toInt() ?? 0,
      selectionDemand: json['selectionDemand'] as String? ?? 'balanced',
      selectionReason: json['selectionReason'] as String? ?? '',
    );
    final invalidTraining = _hasInvalidItems(
      plan.trainingItems,
      role: MissionRunRole.training,
      plan: plan,
    );
    final invalidGame = _hasInvalidItems(
      plan.gameItems,
      role: MissionRunRole.game,
      plan: plan,
    );
    if (plan.levelId.isEmpty ||
        plan.gameId.isEmpty ||
        plan.classNumber < 3 ||
        plan.classNumber > 5 ||
        plan.difficulty < 1 ||
        plan.difficulty > 3 ||
        plan.requestedTrainingItemCount < 0 ||
        plan.requestedGameItemCount < 0 ||
        plan.availableCandidateCount < 0 ||
        plan.trainingItems.length > plan.requestedTrainingItemCount ||
        plan.gameItems.length > plan.requestedGameItemCount ||
        invalidTraining ||
        invalidGame) {
      throw const FormatException('Invalid mission run plan identity.');
    }
    return plan;
  }

  static bool _hasInvalidItems(
    List<PlannedMissionItem> items, {
    required MissionRunRole role,
    required MissionRunPlan plan,
  }) {
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      final endlessMixedDifficulty = plan.levelId.startsWith('endless:c') &&
          plan.requestedTrainingItemCount == 0;
      final invalidDifficulty = endlessMixedDifficulty
          ? item.candidate.difficulty > plan.difficulty
          : item.candidate.difficulty != plan.difficulty;
      if (item.role != role ||
          item.position != index ||
          item.candidate.classNumber != plan.classNumber ||
          item.candidate.gameId != plan.gameId ||
          invalidDifficulty) {
        return true;
      }
    }
    return false;
  }
}
