import '../models/game_models.dart';

enum WorldMissionPhase { training, challenge, boss }

/// Presentation-only identity for one BrightQuest learning world.
///
/// These values never change curriculum correctness, unlock order, rewards or
/// persistence. They provide a deterministic story/gameplay vocabulary around
/// the existing learning levels.
class WorldMissionIdentity {
  const WorldMissionIdentity({
    required this.subject,
    required this.worldTitle,
    required this.worldEmoji,
    required this.journeyTitle,
    required this.journeySubtitle,
    required this.heroCallout,
    required this.sceneGameId,
  });

  final SubjectWorld subject;
  final String worldTitle;
  final String worldEmoji;
  final String journeyTitle;
  final String journeySubtitle;
  final String heroCallout;
  final String sceneGameId;
}

/// Deterministic mission presentation derived from an existing LearningLevel.
///
/// [levelId] and all progress positions come from the existing curriculum
/// catalog. The remaining strings are child-facing world flavor only.
class WorldMissionPlan {
  const WorldMissionPlan({
    required this.identity,
    required this.levelId,
    required this.gameId,
    required this.topicTitle,
    required this.topicSummary,
    required this.zoneTitle,
    required this.phase,
    required this.phaseLabel,
    required this.stageTitle,
    required this.briefing,
    required this.actionLabel,
    required this.completionHeadline,
    required this.nextUnlockLabel,
    required this.stageEmoji,
    required this.stageNumber,
    required this.stageCount,
    required this.zoneNumber,
    required this.zoneCount,
  });

  final WorldMissionIdentity identity;
  final String levelId;
  final String gameId;
  final String topicTitle;
  final String topicSummary;
  final String zoneTitle;
  final WorldMissionPhase phase;
  final String phaseLabel;
  final String stageTitle;
  final String briefing;
  final String actionLabel;
  final String completionHeadline;
  final String nextUnlockLabel;
  final String stageEmoji;
  final int stageNumber;
  final int stageCount;
  final int zoneNumber;
  final int zoneCount;

  bool get isBoss => phase == WorldMissionPhase.boss;

  double get journeyProgress =>
      stageCount <= 0 ? 0 : stageNumber.clamp(0, stageCount) / stageCount;

  String get breadcrumb => '${identity.worldTitle} • $zoneTitle';
}
