import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/models/game_models.dart';
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
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              builder: (context, _) => const BrightSectionTitle(
                title: 'Choose a world',
                subtitle:
                    'Practice → Challenge → Mastery. Follow the glowing path and collect every star.',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 390,
                mainAxisExtent: 230,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final world = learningWorlds[index];
                  return _WorldCard(
                    world: world,
                    completed:
                        controller.completedLevelsForSubject(world.subject),
                    total: controller.totalLevelsForSubject(world.subject),
                    stars: controller.starsForSubject(world.subject),
                    progress: controller.progressForSubject(world.subject),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => LearningWorldScreen(world: world))),
                  );
                },
                childCount: learningWorlds.length,
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisExtent: 198,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final game = games[index];
                  return AdventureCard(
                    game: game,
                    progress: controller.progressFor(game.id),
                    badgeText: game.id == 'rewards_room'
                        ? 'Rewards'
                        : 'Adaptive D${controller.recommendedDifficulty(game.id)}',
                    onTap: () => openGame(context, game.id),
                  );
                },
                childCount: games.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathOverview extends StatelessWidget {
  const _PathOverview(
      {required this.classNumber,
      required this.completed,
      required this.total,
      required this.stars,
      required this.progress});
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
            gradient: const LinearGradient(colors: [
              Color(0xFF4D67DB),
              Color(0xFF45A8EE),
              Color(0xFF62CA9C)
            ]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x244D67DB),
                  blurRadius: 26,
                  offset: Offset(0, 10))
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrightPill(
                      icon: Icons.school_rounded,
                      label: 'CLASS $classNumber MAP',
                      color: const Color(0xFF765500),
                      background: const Color(0xFFFFE898)),
                  const SizedBox(height: 10),
                  Text('Your Adventure Map',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 25 : 31,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      'Clear stages, earn stars and unlock mastery checkpoints.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  BrightAnimatedProgress(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                      color: Colors.white),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _WhiteChip(
                          icon: Icons.flag_rounded,
                          text: '$completed/$total levels'),
                      _WhiteChip(
                          icon: Icons.star_rounded,
                          text: '$stars/${total * 3} stars'),
                    ],
                  ),
                ],
              );
              if (compact) return details;
              return Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 18),
                  const Text('🦁🗺️', style: TextStyle(fontSize: 78)),
                ],
              );
            },
          ),
        ),
      );
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
