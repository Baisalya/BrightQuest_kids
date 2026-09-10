import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import 'nursery_choice_game.dart';
import 'nursery_match_game.dart';
import 'nursery_sort_game.dart';
import 'nursery_trace_game.dart';

/// Stable interaction dispatcher for authored Nursery activities.
///
/// Each interaction type lives in its own presentation module so game upgrades
/// do not turn this boundary into another monolithic lesson file. Every game
/// submits the original response shape expected by the learning model.
class NurseryActivityInteraction extends StatelessWidget {
  const NurseryActivityInteraction({
    required this.activity,
    required this.onSubmitted,
    required this.enabled,
    required this.reducedMotion,
    super.key,
  });

  final NurseryActivity activity;
  final ValueChanged<Object?> onSubmitted;
  final bool enabled;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return switch (activity.interaction) {
      'choice' => NurseryChoiceGame(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
          reducedMotion: reducedMotion,
        ),
      'pairMatch' => NurseryPairMatchGame(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
          reducedMotion: reducedMotion,
        ),
      'sortBuckets' => NurserySortBucketsGame(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
          reducedMotion: reducedMotion,
        ),
      'trace' => NurseryTraceGame(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
          reducedMotion: reducedMotion,
        ),
      _ => const Text('This Nursery interaction is not available.'),
    };
  }
}
