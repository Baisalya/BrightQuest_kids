import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/world_mission_catalog.dart';
import '../../core/models/game_models.dart';
import '../../core/session/game_session_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import '../games/game_router.dart';
import 'learning_world_screen.dart';

class AdventuresScreen extends StatelessWidget {
  const AdventuresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);

    return BrightPageBackground(
      primary: const Color(0xFFF1F8FF),
      secondary: const Color(0xFFFFF8E7),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
              child: BrightHeader(title: 'Learning Worlds')),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              builder: (context, _) => _PathOverview(
                classNumber: controller.selectedClass,
                completed: controller.completedLearningLevels,
                total: controller.totalLearningLevels,
                stars: controller.learningPathStars,
                progress: controller.learningPathProgress,
              ),
            ),
          ),
          if (controller.resumableGameSessions.isNotEmpty)
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                builder: (context, _) {
                  final sessions = controller.resumableGameSessions;
                  final recent = sessions.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BrightSectionTitle(
                        title: 'Recent saved mission',
                        subtitle: sessions.length == 1
                            ? 'Continue where you stopped.'
                            : 'Your latest save stays here. ${sessions.length - 1} more ${sessions.length - 1 == 1 ? 'save is' : 'saves are'} grouped inside their games.',
                        icon: Icons.restore_rounded,
                        trailing: sessions.length > 1
                            ? OutlinedButton.icon(
                                key: const Key('show_all_saved_missions'),
                                onPressed: () => _showAllSavedMissions(
                                  context,
                                  sessions,
                                ),
                                icon: const Icon(Icons.list_alt_rounded),
                                label: Text('Show all (${sessions.length})'),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _ResumeMissionCard(
                        key: const Key('recent_saved_mission_card'),
                        session: recent,
                        onResume: () => resumeGameSession(context, recent),
                        onDiscard: () => controller.discardGameSession(recent),
                      ),
                    ],
                  );
                },
              ),
            ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              builder: (context, _) => const BrightSectionTitle(
                title: 'Choose a world',
                subtitle:
                    'Each world has its own mission route, challenge trials and a mastery boss.',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              builder: (context, _) => BrightAdaptiveGrid(
                minChildWidth: 300,
                maxColumns: 4,
                children: [
                  for (final world in learningWorlds)
                    SizedBox(
                      height: 238,
                      child: _WorldCard(
                        world: world,
                        completed:
                            controller.completedLevelsForSubject(world.subject),
                        total: controller.totalLevelsForSubject(world.subject),
                        stars: controller.starsForSubject(world.subject),
                        progress: controller.progressForSubject(world.subject),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LearningWorldScreen(world: world),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              builder: (context, _) => const BrightSectionTitle(
                title: 'Quick Play',
                subtitle:
                    'Jump into a short practice game without changing roadmap unlock order.',
                icon: Icons.sports_esports_rounded,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              builder: (context, _) => BrightAdaptiveGrid(
                minChildWidth: 235,
                maxColumns: 5,
                children: [
                  for (final game in games)
                    SizedBox(
                      height: 214,
                      child: AdventureCard(
                        game: game,
                        progress: controller.progressFor(game.id),
                        badgeText: game.id == 'rewards_room'
                            ? 'Rewards'
                            : controller.gameSessionFor(
                                      gameId: game.id,
                                      classNumber: controller.selectedClass,
                                    ) !=
                                    null
                                ? 'Resume D${controller.gameSessionFor(
                                      gameId: game.id,
                                      classNumber: controller.selectedClass,
                                    )!.difficulty}'
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

Future<void> _showAllSavedMissions(
  BuildContext context,
  List<GameSessionCheckpoint> sessions,
) async {
  final controller = BrightQuestScope.of(context);
  final compact = MediaQuery.sizeOf(context).width < 700;

  Widget overlay(BuildContext overlayContext) => _SavedMissionsOverlay(
        sessions: sessions,
        onResume: (session) {
          Navigator.of(overlayContext).pop();
          resumeGameSession(context, session);
        },
        onDiscard: (session) {
          controller.discardGameSession(session);
          Navigator.of(overlayContext).pop();
        },
        onClose: () => Navigator.of(overlayContext).pop(),
      );

  if (compact) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (overlayContext) => SizedBox(
        height: MediaQuery.sizeOf(overlayContext).height * .82,
        child: overlay(overlayContext),
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (overlayContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 760,
        height: MediaQuery.sizeOf(overlayContext).height * .78,
        child: overlay(overlayContext),
      ),
    ),
  );
}

class _SavedMissionsOverlay extends StatelessWidget {
  const _SavedMissionsOverlay({
    required this.sessions,
    required this.onResume,
    required this.onDiscard,
    required this.onClose,
  });

  final List<GameSessionCheckpoint> sessions;
  final ValueChanged<GameSessionCheckpoint> onResume;
  final ValueChanged<GameSessionCheckpoint> onDiscard;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All saved missions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Recent first. You can also find each save inside its own game.',
                        style: TextStyle(
                          color: AppTheme.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('all_saved_missions_close'),
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                key: const Key('all_saved_missions_list'),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _ResumeMissionCard(
                    key: Key('all_saved_mission_${session.slotKey}'),
                    session: session,
                    onResume: () => onResume(session),
                    onDiscard: () => onDiscard(session),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _ResumeMissionCard extends StatelessWidget {
  const _ResumeMissionCard({
    required this.session,
    super.key,
    required this.onResume,
    required this.onDiscard,
  });

  final GameSessionCheckpoint session;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final level = session.learningLevelId == null
        ? null
        : learningLevelById(session.learningLevelId!);
    final stageLabel = switch (session.stage) {
      GameSessionStage.lesson => 'Learning mission',
      GameSessionStage.game => 'Game in progress',
      GameSessionStage.completing => 'Finishing safely',
      GameSessionStage.result => 'Mission result saved',
    };
    final title = level?.title ?? _friendlyGameName(session.gameId);
    final progress =
        session.maxScore <= 0 ? null : '${session.score}/${session.maxScore}';
    return Semantics(
      container: true,
      label: 'Resume $title. $stageLabel.',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFE8FBF2)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFB9C8F6)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrightPill(
                    icon: Icons.restore_rounded,
                    label: 'MISSION SAVED',
                    color: Color(0xFF3151B8),
                    background: Color(0xFFDCE5FF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress == null
                        ? '$stageLabel • Continue where you stopped.'
                        : '$stageLabel • Saved score $progress',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onDiscard,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Discard'),
                ),
                FilledButton.icon(
                  key: Key('resume_saved_mission_${session.slotKey}'),
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyGameName(String gameId) => switch (gameId) {
        'math_market' => 'Math Market',
        'fraction_pizza' => 'Fraction Pizza',
        'science_lab' => 'Science Lab',
        'story_builder' => 'Story Builder',
        'grammar_puzzle' => 'Grammar Puzzle',
        'map_quest' => 'Map Quest',
        'coding_maze' => 'Coding Maze',
        'recycling_challenge' => 'Recycling Challenge',
        _ => 'Saved mission',
      };
}

class _PathOverview extends StatelessWidget {
  const _PathOverview({
    required this.classNumber,
    required this.completed,
    required this.total,
    required this.stars,
    required this.progress,
  });
  final int classNumber;
  final int completed;
  final int total;
  final int stars;
  final double progress;

  @override
  Widget build(BuildContext context) => BrightReveal(
        duration: const Duration(milliseconds: 420),
        beginScale: 0.975,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4D67DB),
                Color(0xFF5C63E8),
                Color(0xFF42A8E9),
                Color(0xFF63C99D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: Colors.white.withValues(alpha: .55), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x284D67DB),
                blurRadius: 28,
                offset: Offset(0, 11),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -18,
                top: -24,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 120, color: Color(0x12FFFFFF)),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 680;
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrightPill(
                        icon: Icons.school_rounded,
                        label: 'CLASS $classNumber ADVENTURE',
                        color: const Color(0xFF765500),
                        background: const Color(0xFFFFE898),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your Adventure Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 25 : 31,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clear stages, earn stars and unlock mastery checkpoints.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _JourneyProgress(progress: progress),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _WhiteChip(
                            icon: Icons.flag_rounded,
                            text: '$completed/$total levels',
                          ),
                          _WhiteChip(
                            icon: Icons.star_rounded,
                            text: '$stars/${total * 3} stars',
                          ),
                        ],
                      ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        details,
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text('🦁🗺️✨', style: TextStyle(fontSize: 42)),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 7, child: details),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 150,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .14),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🦁', style: TextStyle(fontSize: 62)),
                              SizedBox(height: 2),
                              Text(
                                'Follow the glowing trail!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: BrightAnimatedProgress(
            value: value,
            minHeight: 11,
            backgroundColor: Colors.white.withValues(alpha: .22),
            color: const Color(0xFFFFE36F),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: List<Widget>.generate(5, (index) {
            final threshold = index / 4;
            final reached = value >= threshold;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: reached
                          ? const Color(0xFFFFE36F)
                          : Colors.white.withValues(alpha: .22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: Icon(
                      reached ? Icons.star_rounded : Icons.circle,
                      color: reached
                          ? const Color(0xFF7B5600)
                          : Colors.white.withValues(alpha: .72),
                      size: reached ? 12 : 6,
                    ),
                  ),
                  if (index != 4)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _WhiteChip extends StatelessWidget {
  const _WhiteChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12))
        ]),
      );
}

class _WorldCard extends StatefulWidget {
  const _WorldCard(
      {required this.world,
      required this.completed,
      required this.total,
      required this.stars,
      required this.progress,
      required this.onTap});
  final LearningWorld world;
  final int completed;
  final int total;
  final int stars;
  final double progress;
  final VoidCallback onTap;

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForSubject(widget.world.subject);
    final identity = WorldMissionCatalog.identityFor(widget.world.subject);
    final complete = widget.total > 0 && widget.completed == widget.total;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: BrightPressableScale(
        hoverScale: 1.015,
        child: BrightWorldBackdrop(
          palette: palette,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(18)),
                            child: Text(widget.world.emoji,
                                style: const TextStyle(fontSize: 30))),
                        const Spacer(),
                        if (complete)
                          const BrightPill(
                              icon: Icons.workspace_premium_rounded,
                              label: 'Complete',
                              color: Color(0xFF176E33),
                              background: Color(0xFFE3F8E7))
                        else
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      identity.journeyTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .76),
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(widget.world.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(widget.world.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    BrightAnimatedProgress(
                        value: widget.progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.27),
                        color: Colors.white),
                    const SizedBox(height: 7),
                    Row(children: [
                      Expanded(
                          child: Text(
                              '${widget.completed}/${widget.total} levels',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11))),
                      Text('⭐ ${widget.stars}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11))
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
