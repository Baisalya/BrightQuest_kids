import 'adaptive_difficulty_models.dart';
import 'lesson_engine.dart';
import 'mission_session_models.dart';

/// Converts the complete authored LessonFlow into the mission session a child
/// plays right now.
///
/// With no adaptive policy this preserves the Step 5 four-phase session. A
/// Learning World level may provide an [AdaptiveMissionPolicy] so Practice,
/// Challenge and Mastery use different amounts of teaching/support without
/// changing authored curriculum content or answer rules.
class MissionSessionEngine {
  const MissionSessionEngine();

  MissionSession build(
    LessonFlow flow, {
    AdaptiveMissionPolicy? policy,
  }) {
    LessonStep? reteach;
    LessonStep? review;
    final active = <LessonStep>[];

    for (final step in flow.steps) {
      switch (step.kind) {
        case LessonStepKind.reteach:
          reteach ??= step;
          break;
        case LessonStepKind.review:
          review ??= step;
          break;
        case LessonStepKind.objective ||
              LessonStepKind.explanation ||
              LessonStepKind.workedExample ||
              LessonStepKind.guidedTry ||
              LessonStepKind.independentPractice ||
              LessonStepKind.transfer ||
              LessonStepKind.exitTicket:
          if (_included(step.kind, policy)) active.add(step);
          break;
      }
    }

    final activePhases = <MissionSessionPhase>[];
    for (final step in active) {
      final phase = _phaseFor(step.kind);
      if (!activePhases.contains(phase)) activePhases.add(phase);
    }

    final phaseCounts = <MissionSessionPhase, int>{};
    for (final step in active) {
      final phase = _phaseFor(step.kind);
      phaseCounts[phase] = (phaseCounts[phase] ?? 0) + 1;
    }

    final phasePositions = <MissionSessionPhase, int>{};
    final sessionSteps = <MissionSessionStep>[];
    for (final step in active) {
      final phase = _phaseFor(step.kind);
      final position = phasePositions[phase] ?? 0;
      sessionSteps.add(
        MissionSessionStep(
          lessonStep: step,
          phase: phase,
          supportMode: _supportFor(step.kind, policy),
          phaseIndex: activePhases.indexOf(phase),
          phaseStepIndex: position,
          phaseStepCount: phaseCounts[phase] ?? 1,
        ),
      );
      phasePositions[phase] = position + 1;
    }

    if (sessionSteps.isEmpty) {
      throw StateError('Mission session cannot be empty.');
    }

    return MissionSession(
      flow: flow,
      steps: List<MissionSessionStep>.unmodifiable(sessionSteps),
      activePhases: List<MissionSessionPhase>.unmodifiable(activePhases),
      reteachStep: reteach,
      reviewStep: review,
    );
  }

  bool _included(
    LessonStepKind kind,
    AdaptiveMissionPolicy? policy,
  ) {
    if (policy == null) return true;
    return switch (kind) {
      LessonStepKind.objective => true,
      LessonStepKind.explanation => policy.includeExplanation,
      LessonStepKind.workedExample => policy.includeWorkedExample,
      LessonStepKind.guidedTry => policy.includeGuidedTry,
      LessonStepKind.independentPractice => policy.includeIndependentPractice,
      LessonStepKind.transfer => policy.includeTransfer,
      LessonStepKind.exitTicket => policy.includeExitTicket,
      LessonStepKind.reteach || LessonStepKind.review => false,
    };
  }

  MissionSessionPhase _phaseFor(LessonStepKind kind) => switch (kind) {
        LessonStepKind.objective ||
        LessonStepKind.explanation ||
        LessonStepKind.workedExample =>
          MissionSessionPhase.seeIt,
        LessonStepKind.guidedTry => MissionSessionPhase.tryWithHelp,
        LessonStepKind.independentPractice => MissionSessionPhase.tryYourself,
        LessonStepKind.transfer ||
        LessonStepKind.exitTicket =>
          MissionSessionPhase.applyInGame,
        LessonStepKind.reteach || LessonStepKind.review => throw StateError(
            '$kind is support/review, not an active session phase.'),
      };

  MissionSupportMode _supportFor(
    LessonStepKind kind,
    AdaptiveMissionPolicy? policy,
  ) {
    if (policy?.isMasteryProof == true && kind == LessonStepKind.exitTicket) {
      return MissionSupportMode.mastery;
    }

    if (policy?.isChallenge == true) {
      return switch (kind) {
        LessonStepKind.objective ||
        LessonStepKind.explanation ||
        LessonStepKind.workedExample =>
          MissionSupportMode.observe,
        LessonStepKind.guidedTry => policy!.guidedIsCoached
            ? MissionSupportMode.coached
            : MissionSupportMode.challenge,
        LessonStepKind.independentPractice ||
        LessonStepKind.transfer ||
        LessonStepKind.exitTicket =>
          MissionSupportMode.challenge,
        LessonStepKind.reteach ||
        LessonStepKind.review =>
          throw StateError('$kind is not an active mission-play step.'),
      };
    }

    return switch (kind) {
      LessonStepKind.objective ||
      LessonStepKind.explanation ||
      LessonStepKind.workedExample =>
        MissionSupportMode.observe,
      LessonStepKind.guidedTry => MissionSupportMode.coached,
      LessonStepKind.independentPractice => MissionSupportMode.independent,
      LessonStepKind.transfer => MissionSupportMode.transfer,
      LessonStepKind.exitTicket => MissionSupportMode.checkpoint,
      LessonStepKind.reteach ||
      LessonStepKind.review =>
        throw StateError('$kind is not an active mission-play step.'),
    };
  }
}
