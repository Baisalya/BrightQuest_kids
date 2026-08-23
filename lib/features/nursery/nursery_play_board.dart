import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_spoken_labels.dart';

class NurseryPlayPortalStyle {
  const NurseryPlayPortalStyle({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
}

NurseryPlayPortalStyle nurseryPortalStyleFor(
  NurserySkill skill,
  NurseryActivity activity,
) {
  if (activity.isTrace) {
    return const NurseryPlayPortalStyle(
      title: 'Trace Trail',
      subtitle: 'Follow the glowing path',
      emoji: '✏️',
      icon: Icons.gesture_rounded,
    );
  }
  if (activity.interaction == 'pairMatch') {
    return const NurseryPlayPortalStyle(
      title: 'Match Magic',
      subtitle: 'Find the partners',
      emoji: '🪄',
      icon: Icons.join_inner_rounded,
    );
  }
  if (activity.interaction == 'sortBuckets') {
    return const NurseryPlayPortalStyle(
      title: 'Sort Safari',
      subtitle: 'Send each thing home',
      emoji: '🧺',
      icon: Icons.category_rounded,
    );
  }

  final phase = switch (activity.phase) {
    'guided' => 'Play together',
    'transfer' => 'Surprise challenge',
    'practice' => 'Practice playground',
    _ => 'My turn',
  };

  if (skill.domainId == 'alphabet') {
    return switch (skill.id) {
      'alpha_letter_sounds' => NurseryPlayPortalStyle(
          title:
              activity.phase == 'transfer' ? 'Sound Challenge' : 'Sound Safari',
          subtitle: phase,
          emoji: '🎧',
          icon: Icons.hearing_rounded,
        ),
      'alpha_beginning_sound' => NurseryPlayPortalStyle(
          title: activity.phase == 'transfer'
              ? 'Beginning-Sound Quest'
              : 'Sound Starter',
          subtitle: phase,
          emoji: '👂',
          icon: Icons.graphic_eq_rounded,
        ),
      'alpha_listen_select' => NurseryPlayPortalStyle(
          title: 'Listen & Find',
          subtitle: phase,
          emoji: '🔊',
          icon: Icons.record_voice_over_rounded,
        ),
      'alpha_word_picture' => NurseryPlayPortalStyle(
          title: activity.phase == 'transfer'
              ? 'Picture Challenge'
              : 'Picture Pairs',
          subtitle: phase,
          emoji: '🖼️',
          icon: Icons.photo_library_rounded,
        ),
      'alpha_uppercase' ||
      'alpha_lowercase' ||
      'alpha_visual_discrimination' =>
        NurseryPlayPortalStyle(
          title:
              activity.phase == 'transfer' ? 'Letter Challenge' : 'Letter Hunt',
          subtitle: phase,
          emoji: '🔤',
          icon: Icons.abc_rounded,
        ),
      _ => NurseryPlayPortalStyle(
          title: 'Letter Pop',
          subtitle: phase,
          emoji: '🎈',
          icon: Icons.abc_rounded,
        ),
    };
  }

  return switch (skill.domainId) {
    'math' => NurseryPlayPortalStyle(
        title: activity.phase == 'transfer' ? 'Math Mission' : 'Number Hunt',
        subtitle: phase,
        emoji: activity.phase == 'transfer' ? '🚀' : '🔢',
        icon: activity.phase == 'transfer'
            ? Icons.rocket_launch_rounded
            : Icons.calculate_rounded,
      ),
    'knowledge' => NurseryPlayPortalStyle(
        title: activity.phase == 'transfer' ? 'World Quest' : 'Picture Hunt',
        subtitle: phase,
        emoji: activity.phase == 'transfer' ? '🗺️' : '🌈',
        icon: activity.phase == 'transfer'
            ? Icons.explore_rounded
            : Icons.image_search_rounded,
      ),
    'thinking' => NurseryPlayPortalStyle(
        title: activity.phase == 'transfer' ? 'Brain Boost' : 'Puzzle Pop',
        subtitle: phase,
        emoji: activity.phase == 'transfer' ? '💡' : '🧩',
        icon: activity.phase == 'transfer'
            ? Icons.lightbulb_rounded
            : Icons.extension_rounded,
      ),
    _ => NurseryPlayPortalStyle(
        title: activity.phase == 'transfer' ? 'Sound Quest' : 'Letter Pop',
        subtitle: phase,
        emoji: activity.phase == 'transfer' ? '🎧' : '🔤',
        icon: activity.phase == 'transfer'
            ? Icons.hearing_rounded
            : Icons.abc_rounded,
      ),
  };
}

/// Picks the first unplayed activity so a Nursery child always has one obvious
/// "Play Now" action. If everything is complete, replay starts from the first
/// authored activity instead of inventing new content.
NurseryActivity? nurseryRecommendedActivity(
  List<NurseryActivity> activities,
  Set<String> completedActivityIds,
) {
  if (activities.isEmpty) return null;
  for (final activity in activities) {
    if (!completedActivityIds.contains(activity.id)) return activity;
  }
  return activities.first;
}

/// Returns the next still-unplayed authored activity after [current].
/// Completion state is read-only; this helper never mutates progress.
NurseryActivity? nurseryNextUnplayedActivity(
  List<NurseryActivity> activities,
  Set<String> completedActivityIds,
  NurseryActivity current,
) {
  if (activities.isEmpty) return null;
  final completed = <String>{...completedActivityIds, current.id};
  final currentIndex = activities.indexWhere((item) => item.id == current.id);
  for (var offset = 1; offset <= activities.length; offset += 1) {
    final index =
        ((currentIndex < 0 ? -1 : currentIndex) + offset) % activities.length;
    final candidate = activities[index];
    if (!completed.contains(candidate.id)) return candidate;
  }
  return null;
}

String nurserySimpleGameLabel(
  NurseryActivity activity,
  int index,
  int total,
) {
  if (activity.isTrace) return 'Trace';
  if (activity.phase == 'transfer') return 'Star Game';
  if (total <= 1) return 'Play';
  return 'Game ${index + 1}';
}

String nurserySimpleGameHint(NurseryActivity activity) {
  if (activity.isTrace) return 'Trace the dots';
  return switch (activity.interaction) {
    'pairMatch' => 'Find the pairs',
    'sortBuckets' => 'Put each one in its group',
    _ =>
      activity.phase == 'guided' ? 'Let’s do one together' : 'Tap the answer',
  };
}

class NurseryPlayBoard extends StatelessWidget {
  const NurseryPlayBoard({
    required this.skill,
    required this.activities,
    required this.completedActivityIds,
    required this.reducedMotion,
    required this.onDiscover,
    required this.onActivity,
    super.key,
  });

  final NurserySkill skill;
  final List<NurseryActivity> activities;
  final Set<String> completedActivityIds;
  final bool reducedMotion;
  final VoidCallback onDiscover;
  final ValueChanged<NurseryActivity> onActivity;

  @override
  Widget build(BuildContext context) {
    final completedCount = activities
        .where((activity) => completedActivityIds.contains(activity.id))
        .length;
    final recommended =
        nurseryRecommendedActivity(activities, completedActivityIds);
    final allDone =
        activities.isNotEmpty && completedCount == activities.length;
    final theme = Theme.of(context);

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
                const SizedBox(height: 14),
                _SimpleProgress(
                    completed: completedCount, total: activities.length),
                const SizedBox(height: 18),
                _PlayNowCard(
                  skill: skill,
                  recommended: recommended,
                  allDone: allDone,
                  reducedMotion: reducedMotion,
                  onPlay: recommended == null
                      ? null
                      : () => onActivity(recommended),
                  onLearn: onDiscover,
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
                      subtitle: const Text('Pick a different game'),
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

class _PlayNowCard extends StatelessWidget {
  const _PlayNowCard({
    required this.skill,
    required this.recommended,
    required this.allDone,
    required this.reducedMotion,
    required this.onPlay,
    required this.onLearn,
  });

  final NurserySkill skill;
  final NurseryActivity? recommended;
  final bool allDone;
  final bool reducedMotion;
  final VoidCallback? onPlay;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    final style = recommended == null
        ? const NurseryPlayPortalStyle(
            title: 'Play',
            subtitle: 'Tap to play',
            emoji: '⭐',
            icon: Icons.play_circle_fill_rounded,
          )
        : nurseryPortalStyleFor(skill, recommended!);
    final child = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;
          final picture = Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(style.emoji, style: const TextStyle(fontSize: 54)),
          );
          final actions = Column(
            crossAxisAlignment:
                wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Text(
                allDone ? 'Play it again!' : 'Ready?',
                textAlign: wide ? TextAlign.left : TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                recommended == null
                    ? 'This game is not ready yet.'
                    : nurserySimpleGameHint(recommended!),
                textAlign: wide ? TextAlign.left : TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(allDone ? 'Play Again' : 'Play Now'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 56),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onLearn,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Learn First'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 50),
                ),
              ),
            ],
          );

          if (!wide) {
            return Column(
              children: [
                picture,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }
          return Row(
            children: [
              picture,
              const SizedBox(width: 20),
              Expanded(child: actions),
            ],
          );
        },
      ),
    );

    if (reducedMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: .96, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, animatedChild) => Transform.scale(
        scale: value,
        child: animatedChild,
      ),
      child: child,
    );
  }
}

class _SmallGameButton extends StatelessWidget {
  const _SmallGameButton({
    required this.activity,
    required this.index,
    required this.total,
    required this.completed,
    required this.onTap,
  });

  final NurseryActivity activity;
  final int index;
  final int total;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = nurserySimpleGameLabel(activity, index, total);
    final style = activity.isTrace
        ? const NurseryPlayPortalStyle(
            title: 'Trace Trail',
            subtitle: 'Trace the dots',
            emoji: '✏️',
            icon: Icons.gesture_rounded,
          )
        : switch (activity.interaction) {
            'pairMatch' => const NurseryPlayPortalStyle(
                title: 'Match Magic',
                subtitle: 'Find the pairs',
                emoji: '🪄',
                icon: Icons.join_inner_rounded,
              ),
            'sortBuckets' => const NurseryPlayPortalStyle(
                title: 'Sort Safari',
                subtitle: 'Put each one in a group',
                emoji: '🧺',
                icon: Icons.category_rounded,
              ),
            _ => NurseryPlayPortalStyle(
                title: label,
                subtitle: nurserySimpleGameHint(activity),
                emoji: activity.phase == 'transfer' ? '⭐' : '🎈',
                icon: Icons.play_circle_fill_rounded,
              ),
          };
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
              Text(style.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  completed ? '$label ✓' : label,
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
          for (var index = 0; index < total; index += 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                index < completed ? '⭐' : '☆',
                style: const TextStyle(fontSize: 24),
              ),
            ),
        ],
      ),
    );
  }
}
