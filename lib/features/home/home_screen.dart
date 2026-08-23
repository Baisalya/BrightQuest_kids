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
import '../learning/applied_missions_screen.dart';
import '../learning/class_skill_studio_screen.dart';
import '../learning/diagnostic_screen.dart';
import '../learning/power_review_screen.dart';
import '../nursery/nursery_home_screen.dart';

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
              builder: (context, breakpoint) =>
                  _HeroMission(controller: controller, breakpoint: breakpoint),
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
                    Expanded(
                        child: _LearningPathSnapshot(controller: controller)),
                    const SizedBox(width: 14),
                    Expanded(child: _DailyQuestPanel(controller: controller)),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              builder: (context, _) =>
                  _LearningToolsPanel(controller: controller),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              builder: (context, _) => BrightSectionTitle(
                title: 'Explore by Subject / World',
                subtitle: 'Pick a colorful world and follow its learning path.',
                icon: Icons.explore_rounded,
                trailing: BrightPill(
                    icon: Icons.school_rounded,
                    label: 'Class ${controller.selectedClass}'),
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
                      completed:
                          controller.completedLevelsForSubject(world.subject),
                      total: controller.totalLevelsForSubject(world.subject),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => LearningWorldScreen(world: world)),
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
                trailing: Text('View All • ${games.length} games',
                    style: const TextStyle(
                        color: AppTheme.inkMuted, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              builder: (context, _) => BrightAdaptiveGrid(
                minChildWidth: 245,
                maxColumns: 5,
                children: [
                  for (final game in games)
                    SizedBox(
                      height: 226,
                      child: AdventureCard(
                        game: game,
                        progress: controller.progressFor(game.id),
                        badgeText: game.id == 'rewards_room'
                            ? 'Rewards'
                            : 'Adaptive D${controller.recommendedDifficulty(game.id)}',
                        onTap: () => openGame(context, game.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningToolsPanel extends StatelessWidget {
  const _LearningToolsPanel({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final diagnostic = controller.diagnosticProgress;
    final due = controller.dueReviewTasks(limit: 10).length;
    final diagnosticLabel = diagnostic.completed &&
            diagnostic.classNumber == controller.selectedClass
        ? 'Starting trail ready'
        : diagnostic.started &&
                diagnostic.classNumber == controller.selectedClass
            ? 'Continue discovery check'
            : 'Discovery check';

    final tools = <Widget>[
      if (BrightQuestScope.contentOf(context).nurseryPack != null)
        _LearningToolCard(
          emoji: '🌱',
          title: 'Nursery Garden',
          subtitle: 'Picture-first early learning',
          color: const Color(0xFF46B86B),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NurseryHomeScreen()),
          ),
        ),
      _LearningToolCard(
        emoji: '🧭',
        title: diagnosticLabel,
        subtitle: 'Find the best starting trail',
        color: const Color(0xFF4A9CEB),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DiagnosticScreen()),
        ),
      ),
      _LearningToolCard(
        emoji: '🎓',
        title: 'Class Skill Studio',
        subtitle: 'Build one school skill at a time',
        color: const Color(0xFF7A58E8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => const ClassSkillStudioScreen()),
        ),
      ),
      _LearningToolCard(
        emoji: '⚡',
        title: due == 0 ? 'Power Review' : 'Power Review · $due due',
        subtitle: due == 0
            ? 'Keep strong skills fresh'
            : 'Quick wins waiting for you',
        color: const Color(0xFFF29B32),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PowerReviewScreen()),
        ),
      ),
      _LearningToolCard(
        emoji: '🚀',
        title: 'Applied missions',
        subtitle: 'Use ideas in mini challenges',
        color: const Color(0xFFE85C9E),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => const AppliedMissionsScreen()),
        ),
      ),
    ];

    return BrightSurface(
      padding: const EdgeInsets.all(16),
      tint: AppTheme.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrightSectionTitle(
            title: 'Explorer shortcuts',
            subtitle:
                'Pick a focused learning path whenever you want a different kind of quest.',
            icon: Icons.rocket_launch_rounded,
            accent: AppTheme.sky,
          ),
          const SizedBox(height: 14),
          BrightAdaptiveGrid(
            minChildWidth: 190,
            maxColumns: 5,
            spacing: 10,
            runSpacing: 10,
            children: tools,
          ),
        ],
      ),
    );
  }
}

class _LearningToolCard extends StatefulWidget {
  const _LearningToolCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_LearningToolCard> createState() => _LearningToolCardState();
}

class _LearningToolCardState extends State<_LearningToolCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: BrightPressableScale(
        hoverScale: 1.015,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 92),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: hovered ? .18 : .12),
                    widget.color.withValues(alpha: .045),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.color.withValues(alpha: .14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: .13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 25)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.inkMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            height: 1.18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 17, color: widget.color),
                ],
              ),
            ),
          ),
        ),
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
    final recommendedGame = recommendedLevel == null
        ? null
        : games.firstWhere((game) => game.id == recommendedLevel.gameId);
    final goalProgress = controller.dailyMinutesGoal == 0
        ? 0.0
        : (controller.studyMinutesToday / controller.dailyMinutesGoal)
            .clamp(0.0, 1.0)
            .toDouble();
    final compact = breakpoint == BrightBreakpoint.compact;

    final continueCard = _ContinueAdventureCard(
      controller: controller,
      level: recommendedLevel,
      game: recommendedGame,
      goalProgress: goalProgress,
    );
    final streakCard = _StreakCard(controller: controller);

    return BrightAdventureLandscape(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktopComposition = constraints.maxWidth >= 1040;
          final narrowPhone = constraints.maxWidth < 390;
          final padding = EdgeInsets.fromLTRB(
            compact ? 14 : 22,
            compact ? 15 : 20,
            compact ? 14 : 22,
            compact ? 18 : 22,
          );

          if (desktopComposition) {
            return SizedBox(
              height: 340,
              child: Padding(
                padding: padding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 2,
                            bottom: -4,
                            child: BrightLionMascot(size: 178),
                          ),
                          Positioned(
                            left: 132,
                            right: 0,
                            top: 10,
                            child: const BrightWoodenSign(
                              title: 'Choose Your Adventure!',
                              subtitle: 'Learn • Play • Earn • Grow',
                            ),
                          ),
                          Positioned(
                            left: 145,
                            right: 8,
                            bottom: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .88),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('✨', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      'One small quest today can unlock a whole new world.',
                                      style: TextStyle(
                                        color: AppTheme.navy,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          continueCard,
                          const SizedBox(height: 12),
                          _HeroQuestRibbon(controller: controller),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 164, child: streakCard),
                  ],
                ),
              ),
            );
          }

          return Container(
            constraints: BoxConstraints(minHeight: compact ? 450 : 390),
            padding: padding,
            child: Column(
              children: [
                if (compact) ...[
                  if (narrowPhone)
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
                          child: BrightLionMascot(size: 94),
                        ),
                      ],
                    )
                  else
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                            width: 112, child: BrightLionMascot(size: 108)),
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
                  const SizedBox(height: 13),
                  continueCard,
                  const SizedBox(height: 10),
                  _HeroQuestRibbon(controller: controller),
                  const SizedBox(height: 10),
                  streakCard,
                ] else ...[
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 154, child: BrightLionMascot(size: 150)),
                      SizedBox(width: 12),
                      Expanded(
                        child: BrightWoodenSign(
                          title: 'Choose Your Adventure!',
                          subtitle: 'Learn • Play • Earn • Grow',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: continueCard),
                      const SizedBox(width: 12),
                      Expanded(child: streakCard),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroQuestRibbon extends StatelessWidget {
  const _HeroQuestRibbon({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final complete = controller.dailyChallenges
        .where((challenge) => controller.isDailyChallengeClaimed(challenge.id))
        .length;
    final total = controller.dailyChallenges.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .91),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8A6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🏁', style: TextStyle(fontSize: 21)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today’s quest trail',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                BrightAnimatedProgress(
                  value: total == 0 ? 0 : complete / total,
                  minHeight: 7,
                  color: const Color(0xFF58BF5F),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$complete/$total',
            style: const TextStyle(
              color: AppTheme.purpleDeep,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueAdventureCard extends StatelessWidget {
  const _ContinueAdventureCard(
      {required this.controller,
      required this.level,
      required this.game,
      required this.goalProgress});

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
        boxShadow: const [
          BoxShadow(
              color: Color(0x2B163A55), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Continue Your Adventure',
              style: TextStyle(
                  color: AppTheme.purpleDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 14)),
          const SizedBox(height: 9),
          if (level == null)
            const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 36)),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Class path complete! Replay missions and collect every star.',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy))),
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
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                          color: currentGame!.color.withValues(alpha: .25))),
                  child: BrightGameScene(gameId: currentGame.id, compact: true),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentGame.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy)),
                    Text(level!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkMuted,
                            fontSize: 11)),
                    const SizedBox(height: 8),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                            value: goalProgress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE8EDF2),
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF65C72C)))),
                    const SizedBox(height: 4),
                    Text(
                        'Today ${controller.studyMinutesToday.floor()} / ${controller.dailyMinutesGoal} min',
                        style: const TextStyle(
                            color: AppTheme.inkMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 10)),
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
                        Row(children: [
                          scene,
                          const SizedBox(width: 10),
                          Expanded(child: details)
                        ]),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              onPressed: () =>
                                  openLearningLevel(context, level!),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Continue'))),
                    ],
                  );
                }
                return Row(
                  children: [
                    scene,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                        onPressed: () => openLearningLevel(context, level!),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Continue')),
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
          gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E6), Color(0xFFFFEDC1)]),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x24163A55), blurRadius: 16, offset: Offset(0, 7))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 7,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 30)),
                  Text('${controller.streak}',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7A3715)))
                ]),
            const Text('Day Streak!',
                style: TextStyle(
                    color: Color(0xFF7A3715), fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Divider(color: Color(0x22A66B1E)),
            const Text('Keep it up!',
                style: TextStyle(
                    color: Color(0xFF7A3715),
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
            const SizedBox(height: 5),
            FittedBox(
                child: Text(
                    List<String>.filled(
                            controller.streak.clamp(1, 5).toInt(), '⭐')
                        .join(),
                    style: const TextStyle(fontSize: 21))),
          ],
        ),
      );
}

class _LearningPathSnapshot extends StatelessWidget {
  const _LearningPathSnapshot({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.learningPathProgress.clamp(0.0, 1.0).toDouble();
    return BrightSurface(
      tint: AppTheme.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrightSectionTitle(
            title: 'Class adventure map',
            subtitle:
                '${controller.completedLearningLevels}/${controller.totalLearningLevels} levels cleared',
            icon: Icons.route_rounded,
            trailing: BrightPill(
              icon: Icons.flag_rounded,
              label: '${(progress * 100).round()}% explored',
              color: AppTheme.purple,
            ),
          ),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: BrightAnimatedProgress(
                    value: progress,
                    minHeight: 9,
                    color: AppTheme.purple,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List<Widget>.generate(5, (index) {
                  final reached = progress >= index / 4;
                  return Container(
                    width: 31,
                    height: 31,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: reached ? const Color(0xFFFFE36F) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: reached
                            ? const Color(0xFFE5B922)
                            : AppTheme.purple.withValues(alpha: .18),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x170C3356),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      reached ? Icons.star_rounded : Icons.circle,
                      size: reached ? 18 : 7,
                      color:
                          reached ? const Color(0xFF8A6100) : AppTheme.purple,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BrightPill(
                icon: Icons.star_rounded,
                label:
                    '${controller.learningPathStars}/${controller.totalLearningLevels * 3} stars',
                color: const Color(0xFFB97800),
                background: const Color(0xFFFFF2BD),
              ),
              BrightPill(
                icon: Icons.workspace_premium_rounded,
                label: '${controller.level} player level',
                color: AppTheme.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyQuestPanel extends StatelessWidget {
  const _DailyQuestPanel({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return BrightSurface(
      tint: AppTheme.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrightSectionTitle(
            title: 'Daily learning quests',
            subtitle: 'Three small wins. No endless feed.',
            icon: Icons.flag_circle_rounded,
            accent: AppTheme.orange,
          ),
          const SizedBox(height: 12),
          ...controller.dailyChallenges.map((challenge) {
            final value = controller.dailyChallengeValue(challenge);
            final ready = controller.isDailyChallengeReady(challenge);
            final claimed = controller.isDailyChallengeClaimed(challenge.id);
            final ratio = (value / challenge.target).clamp(0.0, 1.0).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: claimed
                      ? const Color(0xFFEAF8EC)
                      : const Color(0xFFF9F7FF),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: claimed
                        ? const Color(0xFFBEE5C4)
                        : AppTheme.purple.withValues(alpha: .06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: claimed
                            ? const Color(0xFFD9F2DE)
                            : const Color(0xFFFFEAC2),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        claimed ? Icons.check_rounded : Icons.bolt_rounded,
                        color: claimed ? Colors.green : const Color(0xFFB56A00),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          BrightAnimatedProgress(
                            value: ratio,
                            minHeight: 6,
                            color: claimed ? AppTheme.green : AppTheme.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (ready && !claimed)
                      FilledButton.tonal(
                        onPressed: () {
                          final claimedNow =
                              controller.claimDailyChallenge(challenge.id);
                          if (claimedNow) {
                            unawaited(BrightAudioService.instance
                                .playSfx(BrightSfx.coin));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '+${challenge.rewardCoins} coins earned!',
                                ),
                              ),
                            );
                          }
                        },
                        child: Text('+${challenge.rewardCoins}'),
                      )
                    else
                      Text(
                        claimed
                            ? 'Done!'
                            : '${value.clamp(0, challenge.target)}/${challenge.target}',
                        style: TextStyle(
                          color:
                              claimed ? Colors.green.shade700 : AppTheme.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WorldMiniCard extends StatefulWidget {
  const _WorldMiniCard(
      {required this.world,
      required this.progress,
      required this.completed,
      required this.total,
      required this.onTap});
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
                  boxShadow: [
                    BoxShadow(
                        color: palette.primary.withValues(alpha: .22),
                        blurRadius: 18,
                        offset: const Offset(0, 8))
                  ],
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
                            BrightGameScene(
                                gameId: _worldSceneId(widget.world.subject)),
                            const Positioned.fill(child: BrightGlint()),
                            Positioned(
                              left: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .92),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Text(widget.world.emoji,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            const Positioned(
                                right: 10,
                                top: 10,
                                child: Icon(Icons.arrow_circle_right_rounded,
                                    color: Colors.white, size: 27)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(13, 10, 13, 9),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [palette.primary, palette.deep])),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.world.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(widget.world.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: .90),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Row(
                                children: [
                                  Text('${widget.completed}/${widget.total}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: BrightAnimatedProgress(
                                      value: widget.progress,
                                      minHeight: 7,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: .25),
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
