import 'package:flutter/foundation.dart';

/// Escalation level for feedback after an activity attempt.
///
/// This is deliberately separate from correctness. A first miss gets a small
/// nudge, repeated misses get a clearer strategy, and only then do we invite a
/// child to use an authored hint/reteach power-up.
enum ContextualFeedbackStage {
  success,
  nudge,
  strategy,
  powerUp,
}

/// Presentation cue for the feedback surface. It contains no answer data and
/// can safely drive icons/illustrations without changing learning semantics.
enum ContextualFeedbackCue {
  celebration,
  calculate,
  equalParts,
  wordRoles,
  sequence,
  investigate,
  ecoSort,
  mapTrace,
  robotTrace,
  compare,
}

@immutable
class ContextualAttemptFeedback {
  const ContextualAttemptFeedback({
    required this.correct,
    required this.stage,
    required this.cue,
    required this.headline,
    required this.message,
    required this.strategy,
    required this.worldEmoji,
    required this.suggestHint,
    required this.suggestRescue,
    this.misconceptionId,
  });

  final bool correct;
  final ContextualFeedbackStage stage;
  final ContextualFeedbackCue cue;
  final String headline;

  /// Child-facing result copy. Incorrect feedback intentionally does not expose
  /// the authored explanation/correct response; that information is reserved
  /// for success or an explicit authored clue.
  final String message;

  /// Process coaching based on the known response rule/mechanic or an authored
  /// misconception id. It never invents subject facts.
  final String strategy;
  final String worldEmoji;
  final bool suggestHint;
  final bool suggestRescue;
  final String? misconceptionId;

  String get semanticLabel => [
        correct ? 'Correct' : 'Try again',
        headline,
        message,
        if (strategy.trim().isNotEmpty) strategy,
      ].join('. ');
}
