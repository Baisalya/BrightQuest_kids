import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_visuals.dart';

class NurseryPlayPortalStyle {
  const NurseryPlayPortalStyle({
    required this.title,
    required this.subtitle,
    required this.visual,
  });

  final String title;
  final String subtitle;
  final NurseryVisualSpec visual;
}

NurseryPlayPortalStyle _portalStyle({
  required String title,
  required String subtitle,
  required NurserySkill skill,
  required NurseryActivity activity,
}) =>
    NurseryPlayPortalStyle(
      title: title,
      subtitle: subtitle,
      visual: NurseryVisualResolver.forActivity(
        skill,
        activity,
        semanticLabel: title,
      ),
    );

NurseryPlayPortalStyle nurseryPortalStyleFor(
  NurserySkill skill,
  NurseryActivity activity,
) {
  if (activity.isTrace) {
    return _portalStyle(
      title: 'Trace Trail',
      subtitle: 'Follow the glowing path',
      skill: skill,
      activity: activity,
    );
  }
  if (activity.interaction == 'pairMatch') {
    return _portalStyle(
      title: 'Match Magic',
      subtitle: 'Find the partners',
      skill: skill,
      activity: activity,
    );
  }
  if (activity.interaction == 'sortBuckets') {
    return _portalStyle(
      title: 'Sort Safari',
      subtitle: 'Send each thing home',
      skill: skill,
      activity: activity,
    );
  }

  final phase = switch (activity.phase) {
    'guided' => 'Play together',
    'transfer' => 'Surprise challenge',
    'practice' => 'Practice playground',
    _ => 'My turn',
  };

  if (skill.domainId == 'alphabet') {
    final title = switch (skill.id) {
      'alpha_letter_sounds' =>
        activity.phase == 'transfer' ? 'Sound Challenge' : 'Sound Safari',
      'alpha_beginning_sound' => activity.phase == 'transfer'
          ? 'Beginning-Sound Quest'
          : 'Sound Starter',
      'alpha_listen_select' => 'Listen & Find',
      'alpha_word_picture' =>
        activity.phase == 'transfer' ? 'Picture Challenge' : 'Picture Pairs',
      'alpha_uppercase' ||
      'alpha_lowercase' ||
      'alpha_visual_discrimination' => activity.phase == 'transfer'
          ? 'Letter Challenge'
          : 'Letter Hunt',
      _ => 'Letter Pop',
    };
    return _portalStyle(
      title: title,
      subtitle: phase,
      skill: skill,
      activity: activity,
    );
  }

  final title = switch (skill.domainId) {
    'math' => activity.phase == 'transfer' ? 'Math Mission' : 'Number Hunt',
    'knowledge' =>
      activity.phase == 'transfer' ? 'World Quest' : 'Picture Hunt',
    'thinking' =>
      activity.phase == 'transfer' ? 'Brain Boost' : 'Puzzle Pop',
    _ => activity.phase == 'transfer' ? 'Sound Quest' : 'Letter Pop',
  };
  return _portalStyle(
    title: title,
    subtitle: phase,
    skill: skill,
    activity: activity,
  );
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
    final index = ((currentIndex < 0 ? -1 : currentIndex) + offset) % activities.length;
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
    _ => activity.phase == 'guided' ? 'Let’s do one together' : 'Tap the answer',
  };
}

