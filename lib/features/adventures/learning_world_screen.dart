import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/world_mission_catalog.dart';
import '../../core/curriculum/world_mission_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/learning/mission_mastery_models.dart';
import '../../core/learning/world_progression_policy.dart';
import '../../core/rewards/adventure_reward_engine.dart';
import '../../core/rewards/adventure_reward_models.dart';
import '../../core/session/game_session_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import '../games/game_router.dart';

class LearningWorldScreen extends StatelessWidget {
  const LearningWorldScreen({required this.world, super.key});

  final LearningWorld world;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final levels = levelsForSubject(controller.selectedClass, world.subject);
    final journey = AdventureRewardEngine.worldProgress(
      levels: levels,
      progressFor: controller.levelStatsFor,
    );
    final palette = paletteForSubject(world.subject);
    final identity = WorldMissionCatalog.identityFor(world.subject);
    const progressionPolicy = WorldProgressionPolicy();
    final encounterJourney = progressionPolicy.progressForLevels(
      levels: levels,
      progressFor: controller.levelStatsFor,
    );
    final nextLevel = controller.nextLongTermWorldLevelForSubject(
      repository,
      world.subject,
    );
    final nextPlan =
        nextLevel == null ? null : WorldMissionCatalog.planForLevel(nextLevel);
    final zones = _groupLevelsByTopic(levels);

    return Scaffold(
      body: BrightPageBackground(
        primary: Color.lerp(palette.secondary, Colors.white, 0.72)!,
        secondary: const Color(0xFFFFFAE9),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BrightHeader(showBack: true, title: world.title),
            ),
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                builder: (context, _) => _WorldHero(
                  world: world,
                  identity: identity,
                  palette: palette,
                  classNumber: controller.selectedClass,
                  journey: journey,
                  encounterJourney: encounterJourney,
                  nextPlan: nextPlan,
                  onContinue: nextLevel == null
                      ? null
                      : () => openLearningLevel(context, nextLevel),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
                builder: (context, _) => _AdventureRewardTrail(
                  journey: journey,
                  palette: palette,
                  identity: identity,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                builder: (context, _) => BrightSectionTitle(
                  title: identity.journeyTitle,
                  subtitle: identity.journeySubtitle,
                  icon: Icons.route_rounded,
                  trailing: Text(
                    '${journey.completedMissions}/${journey.totalMissions} quests cleared',
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                builder: (context, _) => Column(
                  children: [
                    for (var zoneIndex = 0;
                        zoneIndex < zones.length;
                        zoneIndex++) ...[
                      _WorldZone(
                        zoneIndex: zoneIndex,
                        levels: zones[zoneIndex],
                        palette: palette,
                        currentLevelId: nextLevel?.id,
                        progressFor: controller.levelStatsFor,
                        isUnlocked: controller.isLevelUnlocked,
                        recommendedEncountersFor:
                            controller.recommendedEncountersFor,
                        completedEncountersFor:
                            controller.completedRecommendedEncountersFor,
                        masteryInsightFor: (level) =>
                            controller.masteryInsightForLevel(
                          repository,
                          level,
                        ),
                        onPlay: (level) => openLearningLevel(context, level),
                        savedSessions: controller.resumableGameSessions
                            .where(
                              (session) =>
                                  session.gameId ==
                                  zones[zoneIndex].first.gameId,
                            )
                            .toList(growable: false),
                        onResumeSaved: (session) =>
                            resumeGameSession(context, session),
                        onDiscardSaved: controller.discardGameSession,
                        onEndlessPractice: () => openEndlessPractice(
                          context,
                          zones[zoneIndex].first.gameId,
                        ),
                      ),
                      if (zoneIndex != zones.length - 1)
                        _ZoneConnector(
                          palette: palette,
                          unlocked: zones[zoneIndex + 1]
                              .any(controller.isLevelUnlocked),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<List<LearningLevel>> _groupLevelsByTopic(List<LearningLevel> levels) {
  final order = <String>[];
  final grouped = <String, List<LearningLevel>>{};
  for (final level in levels) {
    if (!grouped.containsKey(level.curriculumTopicId)) {
      order.add(level.curriculumTopicId);
      grouped[level.curriculumTopicId] = <LearningLevel>[];
    }
    grouped[level.curriculumTopicId]!.add(level);
  }
  return [for (final id in order) grouped[id]!];
}

class _WorldHero extends StatelessWidget {
  const _WorldHero({
    required this.world,
    required this.identity,
    required this.palette,
    required this.classNumber,
    required this.journey,
    required this.encounterJourney,
    required this.nextPlan,
    required this.onContinue,
  });

  final LearningWorld world;
  final WorldMissionIdentity identity;
  final BrightWorldPalette palette;
  final int classNumber;
  final AdventureWorldProgress journey;
  final WorldEncounterProgress encounterJourney;
  final WorldMissionPlan? nextPlan;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final progress = journey.completionRatio;
    return BrightReveal(
      duration: const Duration(milliseconds: 420),
      beginScale: 0.97,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [palette.primary, palette.deep]),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: .26),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final scene = Container(
              height: compact ? 154 : 224,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .58),
                  width: 2,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BrightGameScene(gameId: identity.sceneGameId),
                  const BrightGlint(),
                  const BrightSparkles(),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: BrightPill(
                      icon: Icons.school_rounded,
                      label: 'CLASS $classNumber',
                      color: palette.deep,
                      background: Colors.white.withValues(alpha: .91),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 4,
                    child: Text(
                      world.emoji,
                      style: TextStyle(fontSize: compact ? 54 : 72),
                    ),
                  ),
                ],
              ),
            );
            final copy = Padding(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    world.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 26 : 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    identity.heroCallout,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .94),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrightAnimatedProgress(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: .24),
                    color: const Color(0xFFB8FF7A),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroChip(
                        text:
                            '🎯 ${encounterJourney.completedEncounters}/${encounterJourney.totalEncounters} encounters',
                      ),
                      _HeroChip(
                        text:
                            '${journey.completedMissions}/${journey.totalMissions} quests',
                      ),
                      _HeroChip(
                        text: '⭐ ${journey.earnedStars}/${journey.maxStars}',
                      ),
                      _HeroChip(
                        text:
                            '🏆 ${journey.completedZones}/${journey.totalZones} zones',
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (nextPlan != null)
                    _NextQuestCallout(
                      plan: nextPlan!,
                      onPressed: onContinue!,
                    )
                  else
                    const _WorldClearedCallout(),
                ],
              ),
            );
            if (compact) return Column(children: [scene, copy]);
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(flex: 5, child: scene),
                  Expanded(flex: 4, child: copy),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdventureRewardTrail extends StatelessWidget {
  const _AdventureRewardTrail({
    required this.journey,
    required this.palette,
    required this.identity,
  });

  final AdventureWorldProgress journey;
  final BrightWorldPalette palette;
  final WorldMissionIdentity identity;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.primary.withValues(alpha: .16)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final milestones = <Widget>[
              _RewardMilestone(
                emoji: '🚩',
                title: '${journey.completedMissions}/${journey.totalMissions}',
                subtitle: 'quests cleared',
                active: journey.completedMissions > 0,
                palette: palette,
              ),
              _RewardMilestone(
                emoji: '👑',
                title: '${journey.completedZones}/${journey.totalZones}',
                subtitle: 'zones conquered',
                active: journey.completedZones > 0,
                palette: palette,
              ),
              _RewardMilestone(
                emoji: journey.complete ? '🏆' : '⭐',
                title: journey.complete
                    ? 'World trophy earned'
                    : '${journey.earnedStars}/${journey.maxStars}',
                subtitle:
                    journey.complete ? identity.worldTitle : 'stars collected',
                active: journey.earnedStars > 0 || journey.complete,
                palette: palette,
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  for (var i = 0; i < milestones.length; i++) ...[
                    milestones[i],
                    if (i != milestones.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < milestones.length; i++) ...[
                  Expanded(child: milestones[i]),
                  if (i != milestones.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: palette.primary.withValues(alpha: .45),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      );
}

class _RewardMilestone extends StatelessWidget {
  const _RewardMilestone({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.palette,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool active;
  final BrightWorldPalette palette;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? palette.primary.withValues(alpha: .08)
              : const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: active
                ? palette.primary.withValues(alpha: .16)
                : const Color(0x12000000),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: active ? 25 : 22)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? palette.deep : AppTheme.inkMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _NextQuestCallout extends StatelessWidget {
  const _NextQuestCallout({required this.plan, required this.onPressed});

  final WorldMissionPlan plan;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Text(plan.stageEmoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT QUEST • ${plan.phaseLabel.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .78),
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.stageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: plan.isBoss
                    ? const Color(0xFF8A6000)
                    : const Color(0xFF244BB0),
                padding: const EdgeInsets.symmetric(horizontal: 13),
              ),
              onPressed: onPressed,
              child: Text(plan.isBoss ? 'BOSS' : 'PLAY'),
            ),
          ],
        ),
      );
}

class _WorldClearedCallout extends StatelessWidget {
  const _WorldClearedCallout();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 24)),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'World cleared! Replay missions to improve your stars.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );
}

class _WorldZone extends StatelessWidget {
  const _WorldZone({
    required this.zoneIndex,
    required this.levels,
    required this.palette,
    required this.currentLevelId,
    required this.progressFor,
    required this.isUnlocked,
    required this.recommendedEncountersFor,
    required this.completedEncountersFor,
    required this.masteryInsightFor,
    required this.onPlay,
    required this.savedSessions,
    required this.onResumeSaved,
    required this.onDiscardSaved,
    required this.onEndlessPractice,
  });

  final int zoneIndex;
  final List<LearningLevel> levels;
  final BrightWorldPalette palette;
  final String? currentLevelId;
  final LearningLevelProgress Function(String levelId) progressFor;
  final bool Function(LearningLevel level) isUnlocked;
  final int Function(LearningLevel level) recommendedEncountersFor;
  final int Function(LearningLevel level) completedEncountersFor;
  final LevelMasteryInsight Function(LearningLevel level) masteryInsightFor;
  final ValueChanged<LearningLevel> onPlay;
  final List<GameSessionCheckpoint> savedSessions;
  final ValueChanged<GameSessionCheckpoint> onResumeSaved;
  final ValueChanged<GameSessionCheckpoint> onDiscardSaved;
  final VoidCallback onEndlessPractice;

  @override
  Widget build(BuildContext context) {
    final firstPlan = WorldMissionCatalog.planForLevel(levels.first);
    final zoneProgress = AdventureRewardEngine.zoneProgress(
      levels: levels,
      progressFor: progressFor,
    );
    final zoneUnlocked = levels.any(isUnlocked);
    final encounterProgress = const WorldProgressionPolicy().progressForLevels(
      levels: levels,
      progressFor: progressFor,
    );
    final gameId = levels.first.gameId;

    return BrightReveal(
      duration: Duration(
        milliseconds: 320 + (zoneIndex * 45).clamp(0, 180).toInt(),
      ),
      beginScale: .985,
      offset: const Offset(0, .02),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .96),
              Color.lerp(Colors.white, palette.secondary, .24)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: zoneUnlocked
                ? palette.primary.withValues(alpha: .22)
                : const Color(0x18000000),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.deep.withValues(alpha: .08),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final copy = _ZoneHeaderCopy(
                  plan: firstPlan,
                  progress: zoneProgress,
                  encounterProgress: encounterProgress,
                  palette: palette,
                );
                final scene = _ZoneScene(
                  gameId: gameId,
                  plan: firstPlan,
                  palette: palette,
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [scene, const SizedBox(height: 12), copy],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 230, child: scene),
                    const SizedBox(width: 16),
                    Expanded(child: copy),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 930;
                final cards = [
                  for (final level in levels)
                    _MissionStageCard(
                      level: level,
                      plan: WorldMissionCatalog.planForLevel(level),
                      progress: progressFor(level.id),
                      unlocked: isUnlocked(level),
                      current: currentLevelId == level.id,
                      encounterTarget: recommendedEncountersFor(level),
                      completedEncounters: completedEncountersFor(level),
                      masteryInsight: masteryInsightFor(level),
                      palette: palette,
                      onPlay: isUnlocked(level) ? () => onPlay(level) : null,
                    ),
                ];
                if (!horizontal) {
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i != cards.length - 1)
                          _StageConnector(
                            palette: palette,
                            vertical: true,
                            active: progressFor(levels[i].id).completed,
                          ),
                      ],
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i != cards.length - 1)
                          _StageConnector(
                            palette: palette,
                            vertical: false,
                            active: progressFor(levels[i].id).completed,
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (savedSessions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SavedGameMissionsCard(
                gameId: gameId,
                sessions: savedSessions,
                palette: palette,
                onResume: onResumeSaved,
                onDiscard: onDiscardSaved,
              ),
            ],
            const SizedBox(height: 14),
            _EndlessPracticeCard(
              unlocked: zoneProgress.complete,
              gameId: gameId,
              palette: palette,
              onPressed: zoneProgress.complete ? onEndlessPractice : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedGameMissionsCard extends StatelessWidget {
  const _SavedGameMissionsCard({
    required this.gameId,
    required this.sessions,
    required this.palette,
    required this.onResume,
    required this.onDiscard,
  });

  final String gameId;
  final List<GameSessionCheckpoint> sessions;
  final BrightWorldPalette palette;
  final ValueChanged<GameSessionCheckpoint> onResume;
  final ValueChanged<GameSessionCheckpoint> onDiscard;

  @override
  Widget build(BuildContext context) => Container(
        key: Key('saved_missions_in_game_$gameId'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.secondary.withValues(alpha: .28),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: palette.primary.withValues(alpha: .22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bookmark_added_rounded, color: palette.deep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved in this game',
                    style: TextStyle(
                      color: palette.deep,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${sessions.length}',
                  style: TextStyle(
                    color: palette.deep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Continue a paused level here instead of searching a long global list.',
              style: TextStyle(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w700,
                height: 1.3,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < sessions.length; index++) ...[
              _SavedGameMissionRow(
                session: sessions[index],
                palette: palette,
                onResume: () => onResume(sessions[index]),
                onDiscard: () => onDiscard(sessions[index]),
              ),
              if (index != sessions.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );
}

class _SavedGameMissionRow extends StatelessWidget {
  const _SavedGameMissionRow({
    required this.session,
    required this.palette,
    required this.onResume,
    required this.onDiscard,
  });

  final GameSessionCheckpoint session;
  final BrightWorldPalette palette;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final level = session.learningLevelId == null
        ? null
        : learningLevelById(session.learningLevelId!);
    final title = level?.title ?? 'Quick Play / extra practice';
    final stage = switch (session.stage) {
      GameSessionStage.lesson => 'Lesson saved',
      GameSessionStage.game => 'Game saved',
      GameSessionStage.completing => 'Finishing safely',
      GameSessionStage.result => 'Result saved',
    };
    final score =
        session.maxScore > 0 ? ' • ${session.score}/${session.maxScore}' : '';

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          '$stage$score',
          style: const TextStyle(
            color: AppTheme.inkMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        TextButton.icon(
          onPressed: onDiscard,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Discard'),
        ),
        FilledButton.icon(
          key: Key('resume_game_saved_mission_${session.slotKey}'),
          onPressed: onResume,
          style: FilledButton.styleFrom(
            backgroundColor: palette.deep,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Resume'),
        ),
      ],
    );

    return Container(
      key: Key('game_saved_mission_${session.slotKey}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.primary.withValues(alpha: .14)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _EndlessPracticeCard extends StatelessWidget {
  const _EndlessPracticeCard({
    required this.unlocked,
    required this.gameId,
    required this.palette,
    required this.onPressed,
  });

  final bool unlocked;
  final String gameId;
  final BrightWorldPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
        key: Key('endless_practice_$gameId'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked
              ? palette.primary.withValues(alpha: .08)
              : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: unlocked
                ? palette.primary.withValues(alpha: .24)
                : const Color(0x18000000),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      color: unlocked ? palette.deep : AppTheme.inkMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Endless Practice',
                      style: TextStyle(
                        color: unlocked ? palette.deep : AppTheme.inkMuted,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  unlocked
                      ? 'Keep going in 10-mission adaptive rounds with recent-question rotation.'
                      : 'Clear Practice, Challenge and Mastery to unlock unlimited extra practice.',
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    fontSize: 11.5,
                  ),
                ),
              ],
            );
            final button = FilledButton.icon(
              key: Key('endless_practice_button_$gameId'),
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor:
                    unlocked ? palette.deep : const Color(0xFFD5D9E0),
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                unlocked ? Icons.all_inclusive_rounded : Icons.lock_rounded,
              ),
              label: Text(unlocked ? 'Practice More' : 'Locked'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [copy, const SizedBox(height: 10), button],
              );
            }
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 14),
                button,
              ],
            );
          },
        ),
      );
}

class _ZoneScene extends StatelessWidget {
  const _ZoneScene({
    required this.gameId,
    required this.plan,
    required this.palette,
  });

  final String gameId;
  final WorldMissionPlan plan;
  final BrightWorldPalette palette;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 118,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BrightGameScene(gameId: gameId, compact: true),
              const BrightGlint(),
              Positioned(
                left: 9,
                top: 9,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'ZONE ${plan.zoneNumber}/${plan.zoneCount}',
                    style: TextStyle(
                      color: palette.deep,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 6,
                child: Text(
                  plan.identity.worldEmoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ZoneHeaderCopy extends StatelessWidget {
  const _ZoneHeaderCopy({
    required this.plan,
    required this.progress,
    required this.encounterProgress,
    required this.palette,
  });

  final WorldMissionPlan plan;
  final AdventureZoneProgress progress;
  final WorldEncounterProgress encounterProgress;
  final BrightWorldPalette palette;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                plan.zoneTitle,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              BrightPill(
                icon: Icons.flag_rounded,
                label:
                    '${progress.completedMissions}/${progress.totalMissions} quests',
                color: palette.deep,
                background: palette.primary.withValues(alpha: .10),
              ),
              BrightPill(
                icon: Icons.autorenew_rounded,
                label:
                    '${encounterProgress.completedEncounters}/${encounterProgress.totalEncounters} encounters',
                color: palette.deep,
                background: palette.primary.withValues(alpha: .10),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            plan.topicTitle,
            style: TextStyle(
              color: palette.deep,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            plan.topicSummary,
            style: const TextStyle(
              color: AppTheme.inkMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: BrightAnimatedProgress(
                    value: progress.completionRatio,
                    minHeight: 7,
                    backgroundColor: palette.primary.withValues(alpha: .10),
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '⭐ ${progress.earnedStars}/${progress.maxStars}',
                style: const TextStyle(
                  color: AppTheme.inkMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          if (progress.complete) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: BrightPill(
                icon: Icons.workspace_premium_rounded,
                label: 'ZONE CLEARED',
                color: Color(0xFF208447),
                background: Color(0xFFE7F8EA),
              ),
            ),
          ],
        ],
      );
}

class _MissionStageCard extends StatelessWidget {
  const _MissionStageCard({
    required this.level,
    required this.plan,
    required this.progress,
    required this.unlocked,
    required this.current,
    required this.encounterTarget,
    required this.completedEncounters,
    required this.masteryInsight,
    required this.palette,
    required this.onPlay,
  });

  final LearningLevel level;
  final WorldMissionPlan plan;
  final LearningLevelProgress progress;
  final bool unlocked;
  final bool current;
  final int encounterTarget;
  final int completedEncounters;
  final LevelMasteryInsight masteryInsight;
  final BrightWorldPalette palette;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final stars = progress.earnedStars;
    final bestPercent = (progress.bestRatio * 100).round();
    final boss = plan.isBoss;
    final encounterSetComplete = completedEncounters >= encounterTarget;
    final statusLabel = !unlocked
        ? 'LOCKED'
        : current && !encounterSetComplete
            ? 'NEXT ENCOUNTER'
            : encounterSetComplete
                ? stars == 3
                    ? 'MISSION SET MASTERED'
                    : 'MISSION SET CLEARED'
                : progress.completed
                    ? 'FRESH ENCOUNTER READY'
                    : 'READY';
    final statusColor = encounterSetComplete
        ? const Color(0xFF208447)
        : current
            ? palette.deep
            : unlocked
                ? const Color(0xFF8A6400)
                : AppTheme.inkMuted;

    return BrightPressableScale(
      hoverScale: unlocked ? 1.008 : 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: boss
              ? const LinearGradient(
                  colors: [Color(0xFFFFF4BF), Color(0xFFFFE2A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    Color.lerp(Colors.white, palette.secondary, .12)!,
                  ],
                ),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: current
                ? palette.primary
                : boss
                    ? const Color(0xFFE0A52D)
                    : palette.primary.withValues(alpha: .16),
            width: current ? 2.2 : 1.2,
          ),
          boxShadow: current
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: unlocked
                        ? LinearGradient(
                            colors: boss
                                ? const [Color(0xFFFFC93C), Color(0xFFE59A14)]
                                : [palette.primary, palette.deep],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFD9DEE8), Color(0xFFB8C0CE)],
                          ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: (boss
                                      ? const Color(0xFFE59A14)
                                      : palette.primary)
                                  .withValues(alpha: .22),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    unlocked ? plan.stageEmoji : '🔒',
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.phaseLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: boss ? const Color(0xFF825600) : palette.deep,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: .7,
                        ),
                      ),
                    ],
                  ),
                ),
                if (boss) const Text('👑', style: TextStyle(fontSize: 21)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.stageTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              level.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            _MasteryReadinessPill(
              key: Key('world_mastery_${level.id}'),
              insight: masteryInsight,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BrightAnimatedProgress(
                    value: encounterTarget <= 0
                        ? 0
                        : (completedEncounters / encounterTarget)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                    minHeight: 6,
                    backgroundColor: palette.primary.withValues(alpha: .10),
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedEncounters/$encounterTarget encounters',
                  key: Key('world_encounters_${level.id}'),
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (progress.completed)
              Wrap(
                spacing: 7,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${List<String>.filled(stars, '⭐').join()}${List<String>.filled(3 - stars, '☆').join()}',
                    style: const TextStyle(fontSize: 17),
                  ),
                  Text(
                    'Best $bestPercent%',
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              )
            else
              Text(
                unlocked ? plan.briefing : 'Clear the previous mission first.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unlocked ? AppTheme.inkMuted : const Color(0xFF8A929F),
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPlay,
                style: FilledButton.styleFrom(
                  backgroundColor: boss
                      ? const Color(0xFFC88600)
                      : current
                          ? palette.deep
                          : palette.primary
                              .withValues(alpha: unlocked ? 1 : .25),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  progress.completed
                      ? Icons.replay_rounded
                      : boss
                          ? Icons.workspace_premium_rounded
                          : Icons.play_arrow_rounded,
                ),
                label: Text(
                  !unlocked
                      ? 'Locked'
                      : completedEncounters == 0
                          ? plan.actionLabel
                          : !encounterSetComplete
                              ? 'Fresh Encounter ${completedEncounters + 1}/$encounterTarget'
                              : stars < 3
                                  ? 'Fresh Replay for 3 Stars'
                                  : 'Replay Fresh Mission',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryReadinessPill extends StatelessWidget {
  const _MasteryReadinessPill({required this.insight, super.key});

  final LevelMasteryInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, foreground, background) = switch (insight.status) {
      LongTermMasteryStatus.secure => (
          Icons.verified_rounded,
          const Color(0xFF208447),
          const Color(0xFFE7F8EA),
        ),
      LongTermMasteryStatus.retentionDue => (
          Icons.schedule_rounded,
          const Color(0xFF8A6400),
          const Color(0xFFFFF2C7),
        ),
      LongTermMasteryStatus.needsPractice => (
          Icons.volunteer_activism_rounded,
          const Color(0xFFB33A3A),
          const Color(0xFFFFE8E8),
        ),
      LongTermMasteryStatus.demonstrated => (
          Icons.workspace_premium_rounded,
          const Color(0xFF244BB0),
          const Color(0xFFE9EEFF),
        ),
      LongTermMasteryStatus.improving => (
          Icons.trending_up_rounded,
          const Color(0xFF7352A8),
          const Color(0xFFF1EAFE),
        ),
      LongTermMasteryStatus.notStarted => (
          Icons.radio_button_unchecked_rounded,
          AppTheme.inkMuted,
          const Color(0xFFF0F2F5),
        ),
    };
    return Tooltip(
      message: insight.reason,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
            Text(
              insight.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageConnector extends StatelessWidget {
  const _StageConnector({
    required this.palette,
    required this.vertical,
    required this.active,
  });

  final BrightWorldPalette palette;
  final bool vertical;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? palette.primary : palette.primary.withValues(alpha: .18);
    if (vertical) {
      return SizedBox(
        height: 32,
        child: Center(
          child: Column(
            children: [
              Expanded(child: Container(width: 4, color: color)),
              Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 20),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: 40,
      child: Center(
        child: Row(
          children: [
            Expanded(child: Container(height: 4, color: color)),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ZoneConnector extends StatelessWidget {
  const _ZoneConnector({required this.palette, required this.unlocked});

  final BrightWorldPalette palette;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked
        ? palette.deep.withValues(alpha: .55)
        : palette.primary.withValues(alpha: .18);
    return SizedBox(
      height: 54,
      child: Center(
        child: Column(
          children: [
            Expanded(child: Container(width: 5, color: color)),
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked ? palette.deep : const Color(0xFFDDE2E9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
