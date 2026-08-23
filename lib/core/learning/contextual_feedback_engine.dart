import '../content/content_activity.dart';
import 'activity_response_evaluator.dart';
import 'contextual_feedback_models.dart';
import 'gameplay_activity_models.dart';

/// Builds deterministic, activity-aware coaching around an evaluated response.
///
/// Correctness remains owned by [ActivityResponseEvaluator]. This engine only
/// decides how to explain the result and what kind of support to offer next.
/// It uses authored explanations, authored misconception ids and known gameplay
/// mechanics; it never synthesizes a new curriculum fact or response rule.
class ContextualFeedbackEngine {
  const ContextualFeedbackEngine();

  ContextualAttemptFeedback build({
    required ContentActivity activity,
    required LearningGameActivitySpec spec,
    required ActivityEvaluation evaluation,
    required int attemptNumber,
    required int revealedHintCount,
    required bool hasUnrevealedHint,
    required bool rescueAvailable,
  }) {
    if (evaluation.correct) {
      return ContextualAttemptFeedback(
        correct: true,
        stage: ContextualFeedbackStage.success,
        cue: ContextualFeedbackCue.celebration,
        headline: _successHeadline(spec.theme),
        // Keep the established "Yes." contract used by accessibility/UI tests,
        // while retaining the authored explanation as the source of truth.
        message: 'Yes. ${activity.explanation}'.trim(),
        strategy: _successStrategy(spec.mechanic),
        worldEmoji: _worldEmoji(spec.theme),
        suggestHint: false,
        suggestRescue: false,
        misconceptionId: null,
      );
    }

    final normalizedAttempt = attemptNumber < 1 ? 1 : attemptNumber;
    final supportAvailable = hasUnrevealedHint || rescueAvailable;
    final stage = normalizedAttempt == 1
        ? ContextualFeedbackStage.nudge
        : normalizedAttempt == 2 || !supportAvailable
            ? ContextualFeedbackStage.strategy
            : ContextualFeedbackStage.powerUp;
    final misconception = evaluation.misconceptionId;
    final strategy = _strategyFor(
      misconceptionId: misconception,
      mechanic: spec.mechanic,
      ruleType: '${activity.correctResponseRule['type'] ?? ''}',
    );

    return ContextualAttemptFeedback(
      correct: false,
      stage: stage,
      cue: _cueFor(
        misconceptionId: misconception,
        mechanic: spec.mechanic,
        ruleType: '${activity.correctResponseRule['type'] ?? ''}',
      ),
      headline: _retryHeadline(spec.theme, stage),
      message: _retryMessage(stage),
      strategy: strategy,
      worldEmoji: _worldEmoji(spec.theme),
      suggestHint: hasUnrevealedHint,
      suggestRescue: !hasUnrevealedHint &&
          rescueAvailable &&
          (stage == ContextualFeedbackStage.strategy ||
              stage == ContextualFeedbackStage.powerUp),
      misconceptionId: misconception,
    );
  }

  String _successHeadline(LearningGameTheme theme) => switch (theme) {
        LearningGameTheme.maths => 'Kingdom gate cleared!',
        LearningGameTheme.story => 'Story trail unlocked!',
        LearningGameTheme.science => 'Experiment confirmed!',
        LearningGameTheme.nature => 'Eco mission cleared!',
        LearningGameTheme.map => 'Explorer checkpoint cleared!',
        LearningGameTheme.coding => 'Robot mission executed!',
        LearningGameTheme.neutral => 'Mission move cleared!',
      };

  String _retryHeadline(
    LearningGameTheme theme,
    ContextualFeedbackStage stage,
  ) {
    if (stage == ContextualFeedbackStage.powerUp) {
      return switch (theme) {
        LearningGameTheme.maths => 'Call in a strategy power-up',
        LearningGameTheme.story => 'Ask Leo for a story clue',
        LearningGameTheme.science => 'Open a lab hint',
        LearningGameTheme.nature => 'Use an eco clue',
        LearningGameTheme.map => 'Check the explorer clue',
        LearningGameTheme.coding => 'Debug with a robot hint',
        LearningGameTheme.neutral => 'Use a learning power-up',
      };
    }
    return switch (theme) {
      LearningGameTheme.maths => 'The gate needs another move',
      LearningGameTheme.story => 'The story trail has a twist',
      LearningGameTheme.science => 'The lab result needs another check',
      LearningGameTheme.nature => 'The planet needs one more fix',
      LearningGameTheme.map => 'Recheck the route',
      LearningGameTheme.coding => 'The robot hit a snag',
      LearningGameTheme.neutral => 'That move needs another check',
    };
  }

  String _retryMessage(ContextualFeedbackStage stage) => switch (stage) {
        ContextualFeedbackStage.nudge =>
          'Not yet. Keep the answer hidden and inspect the part of your move that does not match the mission rule.',
        ContextualFeedbackStage.strategy =>
          'You are close to useful evidence. Slow the move down and check it one step at a time before trying again.',
        ContextualFeedbackStage.powerUp =>
          'This is a good moment to use an authored clue or the mission power-up, then make the move yourself.',
        ContextualFeedbackStage.success => '',
      };

  String _successStrategy(LearningGameMechanic mechanic) => switch (mechanic) {
        LearningGameMechanic.decision =>
          'You matched the clue to the right decision.',
        LearningGameMechanic.construction =>
          'Your pieces combine in the required structure.',
        LearningGameMechanic.sorting =>
          'Your groups match the required roles or categories.',
        LearningGameMechanic.navigation =>
          'Your route reaches the mission goal.',
        LearningGameMechanic.simulation =>
          'Your tested combination matches the required outcome.',
        LearningGameMechanic.unavailable => '',
      };

  String _strategyFor({
    required String? misconceptionId,
    required LearningGameMechanic mechanic,
    required String ruleType,
  }) {
    final id = (misconceptionId ?? '').toLowerCase();
    if (id.contains('arithmetic')) {
      return 'Check the operation first, then recompute one place or group at a time. Use the inverse relationship when it helps you verify the result.';
    }
    if (id.contains('fraction') || ruleType == 'selectedSlices') {
      return 'Check that the whole is split into equal parts, then compare how many equal parts the mission asks you to select.';
    }
    if (id.contains('grammar') || ruleType == 'grammarParts') {
      return 'Read the sentence again and ask what each word does: names something, shows an action, or describes something.';
    }
    if (id.contains('sentence') || ruleType == 'orderedWords') {
      return 'Read your built sentence from start to finish. Check whether the word order makes one clear, complete idea.';
    }
    if (id.contains('direction') ||
        id.contains('algorithm') ||
        ruleType == 'reachGridGoal') {
      return 'Start from the robot’s shown direction and trace one command at a time. Check the position after every move or turn.';
    }
    if (id.contains('science') || ruleType == 'experimentOutcome') {
      return 'Compare what you selected with the experiment goal. Change one part at a time so you can tell which choice affects the result.';
    }
    if (id.contains('waste')) {
      return 'Look at what the object is made from or how it is used, then compare that property with the bin or group label.';
    }
    if (id.contains('map')) {
      return 'Find the reference point first, then check the place, direction, or map clue from that reference.';
    }

    return switch (mechanic) {
      LearningGameMechanic.decision =>
        'Compare each option with the exact clue in the mission. Eliminate any choice that breaks part of the rule.',
      LearningGameMechanic.construction =>
        'Inspect the order, count, and relationship of the pieces you built. Change the smallest part that breaks the rule.',
      LearningGameMechanic.sorting =>
        'Check one item at a time against the label of the group you placed it in.',
      LearningGameMechanic.navigation =>
        'Trace the route from the start one command at a time instead of jumping straight to the goal.',
      LearningGameMechanic.simulation =>
        'Compare the selected parts with the mission goal and change one variable at a time.',
      LearningGameMechanic.unavailable =>
        'Re-read the mission clue and check each part of your response against it.',
    };
  }

  ContextualFeedbackCue _cueFor({
    required String? misconceptionId,
    required LearningGameMechanic mechanic,
    required String ruleType,
  }) {
    final id = (misconceptionId ?? '').toLowerCase();
    if (id.contains('arithmetic')) return ContextualFeedbackCue.calculate;
    if (id.contains('fraction') || ruleType == 'selectedSlices') {
      return ContextualFeedbackCue.equalParts;
    }
    if (id.contains('grammar') || ruleType == 'grammarParts') {
      return ContextualFeedbackCue.wordRoles;
    }
    if (id.contains('sentence') || ruleType == 'orderedWords') {
      return ContextualFeedbackCue.sequence;
    }
    if (id.contains('science') || ruleType == 'experimentOutcome') {
      return ContextualFeedbackCue.investigate;
    }
    if (id.contains('waste')) return ContextualFeedbackCue.ecoSort;
    if (id.contains('map')) return ContextualFeedbackCue.mapTrace;
    if (id.contains('direction') ||
        id.contains('algorithm') ||
        ruleType == 'reachGridGoal') {
      return ContextualFeedbackCue.robotTrace;
    }
    return switch (mechanic) {
      LearningGameMechanic.sorting => ContextualFeedbackCue.compare,
      LearningGameMechanic.navigation => ContextualFeedbackCue.robotTrace,
      LearningGameMechanic.simulation => ContextualFeedbackCue.investigate,
      LearningGameMechanic.construction => ContextualFeedbackCue.sequence,
      LearningGameMechanic.decision ||
      LearningGameMechanic.unavailable =>
        ContextualFeedbackCue.compare,
    };
  }

  String _worldEmoji(LearningGameTheme theme) => switch (theme) {
        LearningGameTheme.maths => '🏰',
        LearningGameTheme.story => '🌲',
        LearningGameTheme.science => '🔬',
        LearningGameTheme.nature => '🌱',
        LearningGameTheme.map => '🗺️',
        LearningGameTheme.coding => '🤖',
        LearningGameTheme.neutral => '🦁',
      };
}
