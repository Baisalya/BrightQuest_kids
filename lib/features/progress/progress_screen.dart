import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_adaptive.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_widgets.dart';
import 'child_journey_presentation.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final journey = describeChildJourney(
      completed: controller.completedLearningLevels,
      total: controller.totalLearningLevels,
    );

    return BrightPageBackground(
      primary: const Color(0xFFF2F8FF),
      secondary: const Color(0xFFFFFBEC),
      child: Column(
        children: [
          const BrightHeader(title: 'My Journey'),
          Expanded(
            child: ListView(
              key: const Key('child_journey_scroll'),
              padding: EdgeInsets.zero,
              children: [
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  builder: (context, _) => _JourneyHero(
                    classNumber: controller.selectedClass,
                    completed: controller.completedLearningLevels,
                    total: controller.totalLearningLevels,
                    stars: controller.learningPathStars,
                    progress: controller.learningPathProgress,
                    journey: journey,
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  builder: (context, _) => const BrightSectionTitle(
                    title: 'Your worlds',
                    subtitle:
                        'Each world gets brighter as you explore its quests.',
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  builder: (context, _) => BrightAdaptiveGrid(
                    minChildWidth: 280,
                    maxColumns: 3,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final world in learningWorlds)
                        _JourneyWorldCard(
                          key: Key('journey_world_${world.subject.name}'),
                          emoji: world.emoji,
                          title: world.title,
                          completed: controller
                              .completedLevelsForSubject(world.subject),
                          total:
                              controller.totalLevelsForSubject(world.subject),
                          stars: controller.starsForSubject(world.subject),
                          progress:
                              controller.progressForSubject(world.subject),
                          color: paletteForSubject(world.subject).primary,
                        ),
                    ],
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                  builder: (context, _) => const InfoBanner(
                    icon: Icons.explore_rounded,
                    text:
                        'Your next recommended quest is always waiting on Today. Journey is just your map of how far you have explored.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.classNumber,
    required this.completed,
    required this.total,
    required this.stars,
    required this.progress,
    required this.journey,
  });

  final int classNumber;
  final int completed;
  final int total;
  final int stars;
  final double progress;
  final ChildJourneyPresentation journey;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('journey_hero'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5D4CE7),
              Color(0xFF3EA4EA),
              Color(0xFF5ACB9A),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x245D4CE7),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = brightShouldStackForReadability(
              context: context,
              availableWidth: constraints.maxWidth,
              compactWidth: 620,
            );
            final copy = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                const BrightMascotBubble(
                  message: 'Look how far you have travelled!',
                  compact: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'Class $classNumber Journey',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  journey.label,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .92),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  journey.message,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: Colors.white.withValues(alpha: .24),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment:
                      compact ? WrapAlignment.center : WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _JourneyChip(
                      icon: Icons.flag_rounded,
                      label: '$completed of $total quests explored',
                    ),
                    _JourneyChip(
                      icon: Icons.star_rounded,
                      label: '$stars stars collected',
                    ),
                  ],
                ),
              ],
            );

            if (compact) return copy;
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 18),
                const Text('🗺️✨', style: TextStyle(fontSize: 60)),
              ],
            );
          },
        ),
      );
}

class _JourneyChip extends StatelessWidget {
  const _JourneyChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFFE36F), size: 18),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
}

class _JourneyWorldCard extends StatelessWidget {
  const _JourneyWorldCard({
    required this.emoji,
    required this.title,
    required this.completed,
    required this.total,
    required this.stars,
    required this.progress,
    required this.color,
    super.key,
  });

  final String emoji;
  final String title;
  final int completed;
  final int total;
  final int stars;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final journey = describeChildJourney(completed: completed, total: total);

    return BrightSurface(
      borderColor: color.withValues(alpha: .16),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 31)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (stars > 0)
                      Text(
                        '⭐ $stars',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  journey.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                  color: color,
                  backgroundColor: color.withValues(alpha: .10),
                ),
                const SizedBox(height: 6),
                Text(
                  completed <= 0
                      ? 'Ready for your first quest'
                      : '$completed of $total quests explored',
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
