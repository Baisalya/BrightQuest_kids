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
    final theme = Theme.of(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final boardWidth = maxWidth > 1050 ? 1050.0 : maxWidth;
          final columns = boardWidth >= 1000
              ? 3
              : boardWidth >= 620
                  ? 2
                  : 1;
          final gap = 14.0;
          final tileWidth = columns == 1
              ? boardWidth
              : (boardWidth - (gap * (columns - 1))) / columns;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: maxWidth >= 760 ? 42 : 18,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Choose your adventure',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap a game world. You can come back here and choose another one.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    _ProgressTrail(
                      completed: completedCount,
                      total: activities.length,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: _PortalCard(
                            index: 0,
                            reducedMotion: reducedMotion,
                            completed: false,
                            title: 'Discover Zone',
                            subtitle: 'Tap, watch, listen and explore the idea',
                            emoji: _domainEmoji(skill.domainId),
                            icon: Icons.auto_awesome_rounded,
                            semanticsLabel:
                                'Discover ${skill.title}. Open discovery zone.',
                            onTap: onDiscover,
                          ),
                        ),
                        for (var index = 0;
                            index < activities.length;
                            index += 1)
                          SizedBox(
                            width: tileWidth,
                            child: _activityPortal(
                              activity: activities[index],
                              index: index + 1,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Text('🌟', style: TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                completedCount == activities.length &&
                                        activities.isNotEmpty
                                    ? 'You explored every game here. Later review will check what you remember.'
                                    : 'No rush. Choose a game, play it, then come back to this board.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
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
            ),
          );
        },
      ),
    );
  }

  Widget _activityPortal({
    required NurseryActivity activity,
    required int index,
  }) {
    final style = nurseryPortalStyleFor(skill, activity);
    final completed = completedActivityIds.contains(activity.id);
    return _PortalCard(
      index: index,
      reducedMotion: reducedMotion,
      completed: completed,
      title: style.title,
      subtitle: '${style.subtitle} • ${_phaseLabel(activity.phase)}',
      emoji: style.emoji,
      icon: style.icon,
      semanticsLabel:
          '${style.title}. ${nurserySpeakableText(activity.prompt)}. ${completed ? 'Completed.' : 'Ready to play.'}',
      onTap: () => onActivity(activity),
    );
  }

  static String _phaseLabel(String phase) => switch (phase) {
        'guided' => 'with a hint',
        'independent' => 'play by myself',
        'transfer' => 'new challenge',
        'practice' => 'practice',
        _ => phase,
      };

  static String _domainEmoji(String domainId) => switch (domainId) {
        'math' => '🎡',
        'knowledge' => '🌍',
        'thinking' => '🧠',
        _ => '🎈',
      };
}

class _ProgressTrail extends StatelessWidget {
  const _ProgressTrail({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final progress = (completed / safeTotal).clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: '$completed of $total play activities completed',
      child: Row(
        children: [
          const Text('🏁'),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$completed/$total',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.index,
    required this.reducedMotion,
    required this.completed,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final int index;
  final bool reducedMotion;
  final bool completed;
  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final child = Semantics(
      button: true,
      label: semanticsLabel,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 155),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: completed
                          ? scheme.primaryContainer
                          : scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 20),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(subtitle),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              completed
                                  ? Icons.check_circle_rounded
                                  : Icons.play_circle_fill_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                completed ? 'Played' : 'Tap to play',
                                softWrap: true,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (reducedMotion) return child;
    final begin = (0.92 + (index % 3) * 0.015).clamp(0.90, 0.98).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: 1),
      duration: Duration(milliseconds: 300 + (index % 4) * 70),
      curve: Curves.easeOutBack,
      builder: (context, value, animatedChild) => Opacity(
        opacity: value.clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(scale: value, child: animatedChild),
      ),
      child: child,
    );
  }
}
