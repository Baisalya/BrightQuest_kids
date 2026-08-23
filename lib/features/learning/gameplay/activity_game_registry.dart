import 'package:flutter/material.dart';

import '../../../core/content/content_activity.dart';
import '../../../core/learning/gameplay_activity_models.dart';
import '../../../core/theme/app_theme.dart';
import 'activities/experiment_mixer_activity.dart';
import 'activities/fraction_builder_activity.dart';
import 'activities/grammar_sort_activity.dart';
import 'activities/recycling_sort_activity.dart';
import 'activities/robot_route_activity.dart';
import 'activities/sentence_builder_activity.dart';
import 'activities/themed_choice_activity.dart';
import 'activity_game_contract.dart';

/// Registry for the reusable mini-game interaction families.
///
/// Adding a new mechanic no longer requires putting state/evaluation/rendering
/// into one monolithic widget. The registry owns presentation dispatch only;
/// correctness is still evaluated by ActivityResponseEvaluator in the parent.
class ActivityGameRegistry {
  const ActivityGameRegistry._();

  static const Set<LearningGameActivityKind> supportedKinds = {
    LearningGameActivityKind.themedChoice,
    LearningGameActivityKind.fractionBuilder,
    LearningGameActivityKind.sentenceBuilder,
    LearningGameActivityKind.grammarSort,
    LearningGameActivityKind.robotRoute,
    LearningGameActivityKind.experimentMixer,
    LearningGameActivityKind.recyclingSort,
  };

  static Widget build({
    required Key key,
    required ContentActivity activity,
    required LearningGameActivitySpec spec,
    required bool locked,
    required GameActivityResponseChanged onResponseChanged,
    List<String> experimentChoices = const <String>[],
  }) =>
      switch (spec.kind) {
        LearningGameActivityKind.themedChoice => ThemedChoiceActivity(
            key: key,
            values: spec.choiceValues,
            presentation: spec.choicePresentation,
            locked: locked,
            onResponseChanged: onResponseChanged,
          ),
        LearningGameActivityKind.fractionBuilder => FractionBuilderActivity(
            key: key,
            activity: activity,
            locked: locked,
            onResponseChanged: onResponseChanged,
          ),
        LearningGameActivityKind.sentenceBuilder => SentenceBuilderActivity(
            key: key,
            activity: activity,
            locked: locked,
            onResponseChanged: onResponseChanged,
          ),
        LearningGameActivityKind.grammarSort => GrammarSortActivity(
            key: key,
            activity: activity,
            locked: locked,
            onResponseChanged: onResponseChanged,
          ),
        LearningGameActivityKind.robotRoute => RobotRouteActivity(
            key: key,
            activity: activity,
            locked: locked,
            onResponseChanged: onResponseChanged,
          ),
        LearningGameActivityKind.experimentMixer => ExperimentMixerActivity(
            key: key,
            choices: experimentChoices,
            locked: locked,
            onResponseChanged: onResponseChanged,
          ),
        LearningGameActivityKind.recyclingSort => RecyclingSortActivity(
            key: key,
            activity: activity,
            choices: spec.choiceValues,
            locked: locked,
            onResponseChanged: onResponseChanged,
          ),
        LearningGameActivityKind.unsupported => _UnsupportedActivity(
            key: key,
            reason: spec.unsupportedReason ??
                'This activity needs an interactive renderer.',
          ),
      };
}

class _UnsupportedActivity extends StatelessWidget {
  const _UnsupportedActivity({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E7),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFF1C28F)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.extension_off_rounded, color: Color(0xFFB55A13)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This mission needs a compatible game mechanic.',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
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
