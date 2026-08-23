import 'package:flutter/material.dart';

import '../../core/content/content_activity.dart';
import '../../core/learning/activity_response_evaluator.dart';
import '../../core/learning/gameplay_activity_resolver.dart';
import 'gameplay/activity_game_renderer.dart';
import 'gameplay/learning_game_guidance.dart';

typedef LessonAttemptCallback = void Function(
  ActivityEvaluation evaluation,
  int previousRetries,
  int responseTimeMs,
);

/// Compatibility boundary used by [LessonFlowScreen].
///
/// The previous implementation mixed rule discovery, temporary input state,
/// rendering, evaluation and feedback in one large widget. The new structure
/// resolves the authored activity into a presentation spec, then delegates the
/// actual play experience to [ActivityGameRenderer]. Progress/evidence remain
/// owned by the lesson flow exactly as before.
class LessonActivityInteraction extends StatelessWidget {
  const LessonActivityInteraction({
    required this.activity,
    required this.onAttempt,
    this.experimentChoices = const <String>[],
    this.guidance,
    super.key,
  });

  static const GameplayActivityResolver _resolver = GameplayActivityResolver();

  final ContentActivity activity;
  final LessonAttemptCallback onAttempt;
  final List<String> experimentChoices;
  final LearningGameGuidance? guidance;

  @override
  Widget build(BuildContext context) {
    final spec = _resolver.resolve(activity);
    return ActivityGameRenderer(
      activity: activity,
      spec: spec,
      experimentChoices: experimentChoices,
      guidance: guidance,
      onAttempt: onAttempt,
    );
  }
}
