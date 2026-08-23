import 'lesson_engine.dart';

/// Child-facing phases used by the full Practice session. Challenge and Mastery
/// may intentionally use only a subset; [MissionSession.activePhases] keeps the
/// progress UI truthful when phases are compressed.
enum MissionSessionPhase {
  seeIt,
  tryWithHelp,
  tryYourself,
  applyInGame,
}

/// How much learning support the play surface may expose for a session step.
enum MissionSupportMode {
  observe,
  coached,
  independent,
  transfer,
  checkpoint,
  challenge,
  mastery,
}

class MissionSessionStep {
  const MissionSessionStep({
    required this.lessonStep,
    required this.phase,
    required this.supportMode,
    required this.phaseIndex,
    required this.phaseStepIndex,
    required this.phaseStepCount,
  });

  final LessonStep lessonStep;
  final MissionSessionPhase phase;
  final MissionSupportMode supportMode;

  /// Zero-based position inside the phases that are active for this session.
  final int phaseIndex;

  /// Zero-based authored step position within the current major phase.
  final int phaseStepIndex;
  final int phaseStepCount;

  bool get isInteractive => switch (supportMode) {
        MissionSupportMode.coached ||
        MissionSupportMode.independent ||
        MissionSupportMode.transfer ||
        MissionSupportMode.checkpoint ||
        MissionSupportMode.challenge ||
        MissionSupportMode.mastery =>
          lessonStep.activityId != null,
        MissionSupportMode.observe => false,
      };

  bool get allowsPreAttemptCoaching =>
      supportMode == MissionSupportMode.coached;
  bool get requiresIndependentWork => switch (supportMode) {
        MissionSupportMode.independent ||
        MissionSupportMode.transfer ||
        MissionSupportMode.checkpoint ||
        MissionSupportMode.challenge ||
        MissionSupportMode.mastery =>
          true,
        MissionSupportMode.observe || MissionSupportMode.coached => false,
      };
}

class MissionSession {
  const MissionSession({
    required this.flow,
    required this.steps,
    required this.activePhases,
    required this.reteachStep,
    required this.reviewStep,
  });

  final LessonFlow flow;

  /// Steps the child completes in the current session.
  ///
  /// Reteach and spaced review remain authored in [LessonFlow], but are not
  /// forced as unconditional pages at the end of every successful mission.
  final List<MissionSessionStep> steps;

  /// Only phases that are actually present in this session. Practice normally
  /// uses all four. Challenge and Mastery may compress the route while keeping
  /// the authored support/review material available outside the active path.
  final List<MissionSessionPhase> activePhases;

  /// Optional rescue teaching used only when the child asks for a power-up or
  /// needs support after an unsuccessful attempt.
  final LessonStep? reteachStep;

  /// Authored delayed-review guidance. It is surfaced as a future review note,
  /// not as another mandatory page in the current mission.
  final LessonStep? reviewStep;

  static const int fullPhaseCount = 4;

  int get phaseCount => activePhases.length;

  MissionSessionStep stepAt(int index) => steps[index];

  bool isLastStep(int index) => index == steps.length - 1;
}

extension MissionSessionPhaseCopy on MissionSessionPhase {
  String get label => switch (this) {
        MissionSessionPhase.seeIt => 'See it',
        MissionSessionPhase.tryWithHelp => 'Try with help',
        MissionSessionPhase.tryYourself => 'Try yourself',
        MissionSessionPhase.applyInGame => 'Apply in game',
      };

  String get shortLabel => switch (this) {
        MissionSessionPhase.seeIt => 'SEE IT',
        MissionSessionPhase.tryWithHelp => 'WITH HELP',
        MissionSessionPhase.tryYourself => 'SOLO',
        MissionSessionPhase.applyInGame => 'APPLY',
      };

  String get emoji => switch (this) {
        MissionSessionPhase.seeIt => '👀',
        MissionSessionPhase.tryWithHelp => '🦁',
        MissionSessionPhase.tryYourself => '🚀',
        MissionSessionPhase.applyInGame => '🏁',
      };
}
