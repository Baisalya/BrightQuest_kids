import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/models/game_models.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import '../adventures/learning_world_screen.dart';
import '../games/game_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    return BrightPageBackground(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: BrightHeader()),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              builder: (context, breakpoint) => _HeroMission(controller: controller, breakpoint: breakpoint),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              builder: (context, breakpoint) {
                final compact = breakpoint == BrightBreakpoint.compact;
                if (compact) {
                  return Column(
                    children: [
                      _LearningPathSnapshot(controller: controller),
                      const SizedBox(height: 12),
                      _DailyQuestPanel(controller: controller),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _LearningPathSnapshot(controller: controller)),
                    const SizedBox(width: 14),
                    Expanded(child: _DailyQuestPanel(controller: controller)),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              builder: (context, _) => BrightSectionTitle(
                title: 'Explore by Subject / World',
                subtitle: 'Pick a colorful world and follow its learning path.',
                icon: Icons.explore_rounded,
                trailing: BrightPill(icon: Icons.school_rounded, label: 'Class ${controller.selectedClass}'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              builder: (context, breakpoint) => SizedBox(
                height: breakpoint == BrightBreakpoint.compact ? 190 : 205,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: learningWorlds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final world = learningWorlds[index];
                    return _WorldMiniCard(
                      world: world,
                      progress: controller.progressForSubject(world.subject),
                      completed: controller.completedLevelsForSubject(world.subject),
                      total: controller.totalLevelsForSubject(world.subject),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => LearningWorldScreen(world: world)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              builder: (context, _) => BrightSectionTitle(
                title: 'All Adventures',
                subtitle: 'Choose a short practice game anytime.',
                icon: Icons.sports_esports_rounded,
                trailing: Text('View All • ${games.length} games', style: const TextStyle(color: AppTheme.inkMuted, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final compactCards = constraints.crossAxisExtent < 420;
                return SliverGrid(
                  gridDelegate: compactCards
                      ? const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisExtent: 224,
                          mainAxisSpacing: 14,
                        )
                      : const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 224,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = games[index];
                      return AdventureCard(
                        game: game,
                        progress: controller.progressFor(game.id),
                        badgeText: game.id == 'rewards_room' ? 'Rewards' : 'Adaptive D${controller.recommendedDifficulty(game.id)}',
                        onTap: () => openGame(context, game.id),
                      );
                    },
                    childCount: games.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMission extends StatelessWidget {
  const _HeroMission({required this.controller, required this.breakpoint});
  final GameController controller;
  final BrightBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final recommendedLevel = controller.nextRecommendedLearningLevel();
    final recommendedGame = recommendedLevel == null ? null : games.firstWhere((game) => game.id == recommendedLevel.gameId);
    final goalProgress = controller.dailyMinutesGoal == 0
        ? 0.0
        : (controller.studyMinutesToday / controller.dailyMinutesGoal).clamp(0.0, 1.0).toDouble();
    final compact = breakpoint == BrightBreakpoint.compact;
    final veryCompact = MediaQuery.sizeOf(context).width < 420;

    final continueCard = _ContinueAdventureCard(
      controller: controller,
      level: recommendedLevel,
      game: recommendedGame,
      goalProgress: goalProgress,
    );
    final streakCard = _StreakCard(controller: controller);

    return BrightAdventureLandscape(
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 440 : 390),
        padding: EdgeInsets.fromLTRB(compact ? 15 : 22, compact ? 16 : 20, compact ? 15 : 22, compact ? 18 : 22),
        child: Column(
          children: [
            if (compact) ...[
              if (veryCompact)
                Column(
                  children: [
                    const SizedBox(
                      width: double.infinity,
                      child: BrightWoodenSign(
                        title: 'Choose Your Adventure!',
                        subtitle: 'Learn • Play • Earn • Grow',
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrightLionMascot(size: 96),
                    ),
                  ],
                )
              else
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(width: 115, child: BrightLionMascot(size: 112)),
                    SizedBox(width: 6),
                    Expanded(
                      child: BrightWoodenSign(
                        title: 'Choose Your Adventure!',
                        subtitle: 'Learn • Play • Earn • Grow',
                        compact: true,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              continueCard,
              const SizedBox(height: 10),
              streakCard,
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 170, child: BrightLionMascot(size: 166)),
                  const SizedBox(width: 12),
                  const Expanded(child: BrightWoodenSign(title: 'Choose Your Adventure!', subtitle: 'Learn • Play • Earn • Grow')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: continueCard),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: streakCard),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContinueAdventureCard extends StatelessWidget {
  const _ContinueAdventureCard({required this.controller, required this.level, required this.game, required this.goalProgress});

  final GameController controller;
  final LearningLevel? level;
  final AdventureGame? game;
  final double goalProgress;

  @override
  Widget build(BuildContext context) {
    final currentGame = game;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x2B163A55), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Continue Your Adventure', style: TextStyle(color: AppTheme.purpleDeep, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 9),
          if (level == null)
            const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 36)),
                SizedBox(width: 10),
                Expanded(child: Text('Class path complete! Replay missions and collect every star.', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navy))),
              ],
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 470;
                final extraNarrow = constraints.maxWidth < 300;
                final scene = Container(
                  width: extraNarrow ? double.infinity : (narrow ? 92 : 128),
                  height: extraNarrow ? 92 : (narrow ? 84 : 92),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), border: Border.all(color: currentGame!.color.withValues(alpha: .25))),
                  child: BrightGameScene(gameId: currentGame.id, compact: true),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentGame.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navy)),
                    Text(level!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.inkMuted, fontSize: 11)),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: goalProgress, minHeight: 8, backgroundColor: const Color(0xFFE8EDF2), valueColor: const AlwaysStoppedAnimation(Color(0xFF65C72C)))),
                    const SizedBox(height: 4),
                    Text('Today ${controller.studyMinutesToday.floor()} / ${controller.dailyMinutesGoal} min', style: const TextStyle(color: AppTheme.inkMuted, fontWeight: FontWeight.w800, fontSize: 10)),
                  ],
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (extraNarrow) ...[
                        scene,
                        const SizedBox(height: 10),
                        details,
                      ] else
                        Row(children: [scene, const SizedBox(width: 10), Expanded(child: details)]),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => openLearningLevel(context, level!), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Continue'))),
                    ],
                  );
                }
                return Row(
                  children: [
                    scene,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                    const SizedBox(width: 10),
                    FilledButton.icon(onPressed: () => openLearningLevel(context, level!), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Continue')),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFF8E6), Color(0xFFFFEDC1)]),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x24163A55), blurRadius: 16, offset: Offset(0, 7))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 7, children: [const Text('🔥', style: TextStyle(fontSize: 30)), Text('${controller.streak}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF7A3715)))]),
            const Text('Day Streak!', style: TextStyle(color: Color(0xFF7A3715), fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Divider(color: Color(0x22A66B1E)),
            const Text('Keep it up!', style: TextStyle(color: Color(0xFF7A3715), fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 5),
            FittedBox(child: Text(List<String>.filled(controller.streak.clamp(1, 5).toInt(), '⭐').join(), style: const TextStyle(fontSize: 21))),
          ],
        ),
      );
}

class _LearningPathSnapshot extends StatelessWidget {
  const _LearningPathSnapshot({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => BrightSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrightSectionTitle(
              title: 'Class adventure map',
              subtitle: '${controller.completedLearningLevels}/${controller.totalLearningLevels} levels cleared',
              icon: Icons.route_rounded,
              trailing: Text('${(controller.learningPathProgress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.purple)),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BrightAnimatedProgress(value: controller.learningPathProgress, minHeight: 10, color: AppTheme.purple),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BrightPill(icon: Icons.star_rounded, label: '${controller.learningPathStars}/${controller.totalLearningLevels * 3} stars', color: const Color(0xFFB97800), background: const Color(0xFFFFF2BD)),
                BrightPill(icon: Icons.workspace_premium_rounded, label: '${controller.level} player level', color: AppTheme.purple),
              ],
            ),
          ],
        ),
      );
}

class _DailyQuestPanel extends StatelessWidget {
  const _DailyQuestPanel({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return BrightSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrightSectionTitle(title: 'Daily learning quests', subtitle: 'Three small wins. No endless feed.', icon: Icons.flag_circle_rounded),
          const SizedBox(height: 12),
          ...controller.dailyChallenges.map((challenge) {
            final value = controller.dailyChallengeValue(challenge);
            final ready = controller.isDailyChallengeReady(challenge);
            final claimed = controller.isDailyChallengeClaimed(challenge.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: claimed ? const Color(0xFFE2F7E5) : AppTheme.purple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11)),
                    child: Icon(claimed ? Icons.check_rounded : Icons.bolt_rounded, color: claimed ? Colors.green : AppTheme.purple, size: 18),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(challenge.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: (value / challenge.target).clamp(0.0, 1.0).toDouble(), minHeight: 6, borderRadius: BorderRadius.circular(99)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (ready && !claimed)
                    FilledButton.tonal(
                      onPressed: () {
                        final claimedNow = controller.claimDailyChallenge(challenge.id);
                        if (claimedNow) {
                          unawaited(BrightAudioService.instance.playSfx(BrightSfx.coin));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+${challenge.rewardCoins} coins earned!')));
                        }
                      },
                      child: Text('+${challenge.rewardCoins}'),
                    )
                  else
                    Text('${value.clamp(0, challenge.target)}/${challenge.target}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WorldMiniCard extends StatefulWidget {
  const _WorldMiniCard({required this.world, required this.progress, required this.completed, required this.total, required this.onTap});
  final LearningWorld world;
  final double progress;
  final int completed;
  final int total;
  final VoidCallback onTap;

  @override
  State<_WorldMiniCard> createState() => _WorldMiniCardState();
}

class _WorldMiniCardState extends State<_WorldMiniCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForSubject(widget.world.subject);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: BrightPressableScale(
        hoverScale: 1.02,
        child: SizedBox(
          width: 245,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: widget.onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: palette.primary.withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            BrightGameScene(gameId: _worldSceneId(widget.world.subject)),
                            const Positioned.fill(child: BrightGlint()),
                            Positioned(
                              left: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(14)),
                                child: Text(widget.world.emoji, style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            const Positioned(right: 10, top: 10, child: Icon(Icons.arrow_circle_right_rounded, color: Colors.white, size: 27)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(13, 10, 13, 9),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [palette.primary, palette.deep])),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.world.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(widget.world.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .90), fontSize: 10.5, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Row(
                                children: [
                                  Text('${widget.completed}/${widget.total}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: BrightAnimatedProgress(
                                      value: widget.progress,
                                      minHeight: 7,
                                      backgroundColor: Colors.white.withValues(alpha: .25),
                                      color: const Color(0xFFB8FF7A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _worldSceneId(SubjectWorld subject) => switch (subject) {
      SubjectWorld.maths => 'math_market',
      SubjectWorld.english => 'story_builder',
      SubjectWorld.science => 'science_lab',
      SubjectWorld.evs => 'recycling_challenge',
      SubjectWorld.social => 'map_quest',
      SubjectWorld.coding => 'coding_maze',
      SubjectWorld.art => 'rewards_room',
    };
