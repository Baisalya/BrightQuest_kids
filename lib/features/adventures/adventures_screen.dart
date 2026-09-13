import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/world_mission_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import 'learning_world_screen.dart';

class AdventuresScreen extends StatelessWidget {
  const AdventuresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final completedWorlds = learningWorlds
        .where(
          (world) =>
              controller.totalLevelsForSubject(world.subject) > 0 &&
              controller.completedLevelsForSubject(world.subject) ==
                  controller.totalLevelsForSubject(world.subject),
        )
        .length;

    return BrightPageBackground(
      primary: const Color(0xFFF1F8FF),
      secondary: const Color(0xFFFFF8E7),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: BrightHeader(title: 'Learning Worlds'),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              builder: (context, _) => _WorldsIntro(
                classNumber: controller.selectedClass,
                completedWorlds: completedWorlds,
                totalWorlds: learningWorlds.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              builder: (context, _) => const BrightSectionTitle(
                title: 'Choose a world',
                subtitle:
                    'Explore one subject world. Your next recommended quest stays on Today.',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              builder: (context, _) => BrightAdaptiveGrid(
                minChildWidth: 300,
                maxColumns: 4,
                children: [
                  for (final world in learningWorlds)
                    SizedBox(
                      height: 228,
                      child: _WorldCard(
                        world: world,
                        completed:
                            controller.completedLevelsForSubject(world.subject),
                        total: controller.totalLevelsForSubject(world.subject),
                        stars: controller.starsForSubject(world.subject),
                        progress: controller.progressForSubject(world.subject),
                        hasSavedMission: controller.resumableGameSessions.any(
                          (session) => levelsForSubject(
                            controller.selectedClass,
                            world.subject,
                          ).any((level) => level.gameId == session.gameId),
                        ),
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
        ],
      ),
    );
  }
}

class _WorldsIntro extends StatelessWidget {
  const _WorldsIntro({
    required this.classNumber,
    required this.completedWorlds,
    required this.totalWorlds,
  });

  final int classNumber;
  final int completedWorlds;
  final int totalWorlds;

  @override
  Widget build(BuildContext context) => BrightSurface(
        tint: AppTheme.sky,
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F5FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🗺️', style: TextStyle(fontSize: 31)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class $classNumber world map',
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$completedWorlds/$totalWorlds worlds complete. '
                    'Paused missions remain inside the world they belong to.',
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.completed,
    required this.total,
    required this.stars,
    required this.progress,
    required this.hasSavedMission,
    required this.onTap,
  });

  final LearningWorld world;
  final int completed;
  final int total;
  final int stars;
  final double progress;
  final bool hasSavedMission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForSubject(world.subject);
    final identity = WorldMissionCatalog.identityFor(world.subject);
    final complete = total > 0 && completed == total;

    return BrightPressableScale(
      hoverScale: 1.015,
      child: BrightWorldBackdrop(
        palette: palette,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('world_card_${world.subject.name}'),
            onTap: onTap,
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
                          color: Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          world.emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      const Spacer(),
                      if (hasSavedMission)
                        const BrightPill(
                          icon: Icons.restore_rounded,
                          label: 'Saved',
                          color: Color(0xFF3151B8),
                          background: Color(0xFFE4EAFF),
                        )
                      else if (complete)
                        const BrightPill(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Complete',
                          color: Color(0xFF176E33),
                          background: Color(0xFFE3F8E7),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
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
                  Text(
                    world.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    world.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .9),
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrightAnimatedProgress(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: .27),
                    color: Colors.white,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${completed}/${total} quests',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        '⭐ ${stars}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
