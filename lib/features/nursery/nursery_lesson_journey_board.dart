import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_visuals.dart';
import 'nursery_lesson_journey.dart';
import 'nursery_lesson_stage_indicator.dart';
import 'nursery_motion.dart';
import 'nursery_play_board.dart';
import 'nursery_visual.dart';

class NurseryPlayBoard extends StatelessWidget {
  const NurseryPlayBoard({
    required this.skill,
    required this.activities,
    required this.completedActivityIds,
    required this.reducedMotion,
    required this.studyVisited,
    required this.onDiscover,
    required this.onActivity,
    super.key,
  });

  final NurserySkill skill;
  final List<NurseryActivity> activities;
  final Set<String> completedActivityIds;
  final bool reducedMotion;
  final bool studyVisited;
  final VoidCallback onDiscover;
  final ValueChanged<NurseryActivity> onActivity;

  @override
  Widget build(BuildContext context) {
    final completedCount = activities
        .where((activity) => completedActivityIds.contains(activity.id))
        .length;
    final plan = NurseryLessonJourneyPlanner.build(
      activities: activities,
      completedActivityIds: completedActivityIds,
      studyVisited: studyVisited,
    );
    final guided = plan.guidedActivity;
    final independent = plan.recommendedIndependentActivity;
    final theme = Theme.of(context);
    final studyDone = studyVisited || completedCount > 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width >= 760 ? 42 : 18,
          vertical: 18,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Let’s play!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skill.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '3 easy steps',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _SimpleProgress(
                  completed: completedCount,
                  total: activities.length,
                ),
                const SizedBox(height: 18),
                _JourneyStepCard(
                  key: const Key('nursery-stage-study'),
                  stage: NurseryLessonJourneyStage.study,
                  description: 'See the idea with pictures and sound.',
                  actionLabel: 'Learn First',
                  actionIcon: Icons.visibility_rounded,
                  visual: NurseryVisualResolver.forSkillId(
                    skill.id,
                    skill.domainId,
                    semanticLabel: 'Study ${skill.title}',
                  ),
                  recommended:
                      plan.recommendedStage == NurseryLessonJourneyStage.study,
                  completed: studyDone,
                  reducedMotion: reducedMotion,
                  onTap: onDiscover,
                ),
                const SizedBox(height: 12),
                _JourneyConnector(
                  complete: studyDone,
                  label: 'then',
                ),
                const SizedBox(height: 12),
                _JourneyStepCard(
                  key: const Key('nursery-stage-guided'),
                  stage: NurseryLessonJourneyStage.guidedPlay,
                  description: 'Try one together. Help stays close.',
                  actionLabel: 'Play Now',
                  actionIcon: Icons.favorite_outline_rounded,
                  visual: guided == null
                      ? NurseryVisualResolver.play()
                      : NurseryVisualResolver.forActivity(
                          skill,
                          guided,
                          semanticLabel: 'Guided Play',
                        ),
                  recommended: plan.recommendedStage ==
                      NurseryLessonJourneyStage.guidedPlay,
                  completed: plan.guidedComplete,
                  reducedMotion: reducedMotion,
                  onTap: guided == null ? null : () => onActivity(guided),
                ),
                const SizedBox(height: 12),
                _JourneyConnector(
                  complete: plan.guidedComplete,
                  label: 'then',
                ),
                const SizedBox(height: 12),
                _JourneyStepCard(
                  key: const Key('nursery-stage-independent'),
                  stage: NurseryLessonJourneyStage.independentGame,
                  description: plan.allActivitiesComplete
                      ? 'You did it. Pick a favourite and play again.'
                      : 'Now try the picture games on your own.',
                  actionLabel:
                      plan.allActivitiesComplete ? 'Play Again' : 'Play Game',
                  actionIcon: plan.allActivitiesComplete
                      ? Icons.replay_rounded
                      : Icons.stars_rounded,
                  visual: independent == null
                      ? NurseryVisualResolver.play()
                      : NurseryVisualResolver.forActivity(
                          skill,
                          independent,
                          semanticLabel: 'Independent Game',
                        ),
                  recommended: plan.recommendedStage ==
                      NurseryLessonJourneyStage.independentGame,
                  completed: plan.independentComplete,
                  progressLabel: plan.independentActivities.isEmpty
                      ? null
                      : '${plan.independentCompletedCount} of '
                          '${plan.independentActivities.length} played',
                  reducedMotion: reducedMotion,
                  onTap:
                      independent == null ? null : () => onActivity(independent),
                ),
                if (activities.length > 1) ...[
                  const SizedBox(height: 14),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      key: const PageStorageKey<String>('nursery-more-games'),
                      leading: const Icon(Icons.grid_view_rounded),
                      title: const Text(
                        'More games',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text('Pick any game you already know'),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var index = 0;
                                index < activities.length;
                                index += 1)
                              _SmallGameButton(
                                skill: skill,
                                activity: activities[index],
                                index: index,
                                total: activities.length,
                                completed: completedActivityIds.contains(
                                  activities[index].id,
                                ),
                                onTap: () => onActivity(activities[index]),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyStepCard extends StatelessWidget {
  const _JourneyStepCard({
    required this.stage,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.visual,
    required this.recommended,
    required this.completed,
    required this.reducedMotion,
    required this.onTap,
    this.progressLabel,
    super.key,
  });

  final NurseryLessonJourneyStage stage;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final NurseryVisualSpec visual;
  final bool recommended;
  final bool completed;
  final bool reducedMotion;
  final VoidCallback? onTap;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: recommended
            ? scheme.primaryContainer
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: recommended ? scheme.primary : scheme.outlineVariant,
          width: recommended ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;
          final picture = Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: NurseryVisual(
              spec: visual,
              size: 64,
              reducedMotion: reducedMotion,
              decorative: true,
            ),
          );
          final content = Column(
            crossAxisAlignment:
                wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              NurseryLessonStageIndicator(
                stage: stage,
                compact: true,
              ),
              const SizedBox(height: 9),
              Text(
                description,
                textAlign: wide ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (progressLabel != null) ...[
                const SizedBox(height: 5),
                Text(
                  progressLabel!,
                  textAlign: wide ? TextAlign.left : TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onTap,
                icon: Icon(actionIcon),
                label: Text(actionLabel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 52),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
          final status = Align(
            alignment: wide ? Alignment.topRight : Alignment.center,
            child: _JourneyStatus(
              recommended: recommended,
              completed: completed,
            ),
          );

          if (!wide) {
            return Column(
              children: [
                status,
                const SizedBox(height: 8),
                picture,
                const SizedBox(height: 12),
                content,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              picture,
              const SizedBox(width: 18),
              Expanded(child: content),
              const SizedBox(width: 12),
              status,
            ],
          );
        },
      ),
    );

    if (!recommended) return card;
    return NurseryMotionReveal(
      reducedMotion: reducedMotion,
      duration: const Duration(milliseconds: 280),
      beginScale: .97,
      verticalOffset: 2,
      curve: Curves.easeOutBack,
      child: card,
    );
  }
}

class _JourneyStatus extends StatelessWidget {
  const _JourneyStatus({
    required this.recommended,
    required this.completed,
  });

  final bool recommended;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    if (recommended) {
      return const Chip(
        avatar: Icon(Icons.arrow_forward_rounded, size: 18),
        label: Text(
          'NEXT',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }
    if (completed) {
      return const Chip(
        avatar: Icon(Icons.check_circle_rounded, size: 18),
        label: Text(
          'DONE',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _JourneyConnector extends StatelessWidget {
  const _JourneyConnector({required this.complete, required this.label});

  final bool complete;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: complete ? 'Step completed. $label' : label,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}

class _SmallGameButton extends StatelessWidget {
  const _SmallGameButton({
    required this.skill,
    required this.activity,
    required this.index,
    required this.total,
    required this.completed,
    required this.onTap,
  });

  final NurserySkill skill;
  final NurseryActivity activity;
  final int index;
  final int total;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = nurserySimpleGameLabel(activity, index, total);
    final visual = NurseryVisualResolver.forActivity(
      skill,
      activity,
      semanticLabel: label,
    );
    return Semantics(
      button: true,
      label:
          '$label. ${nurserySpeakableText(activity.prompt)}. ${completed ? 'Played.' : 'Ready to play.'}',
      child: SizedBox(
        width: 180,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            minimumSize: const Size(160, 68),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NurseryVisual(
                spec: visual,
                size: 30,
                decorative: true,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  completed ? '$label · Played' : label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleProgress extends StatelessWidget {
  const _SimpleProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    return Semantics(
      label: '$completed of $total games played',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NurseryProgressStars(
            filled: completed,
            total: total,
            size: 24,
          ),
        ],
      ),
    );
  }
}
