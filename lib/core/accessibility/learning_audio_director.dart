import '../content/content_activity.dart';
import '../learning/gameplay_activity_models.dart';
import '../learning/lesson_engine.dart';
import '../learning/mission_session_models.dart';
import 'learning_audio_models.dart';

/// Converts already-authored learning material into pedagogically distinct
/// narration cues.
///
/// The director never invents curriculum facts, answers or hints. It chooses
/// the authored text appropriate to the current learning role:
/// mission framing, concept teaching, worked reasoning, or a question prompt.
/// Optional hints are deliberately excluded from lesson cues and are spoken
/// only when the learner explicitly reveals one.
class LearningAudioDirector {
  const LearningAudioDirector();

  LearningNarrationCue forLessonStep({
    required MissionSessionStep sessionStep,
    ContentActivity? activity,
    LearningGameActivitySpec? activitySpec,
  }) {
    final step = sessionStep.lessonStep;
    final isInteractive = sessionStep.isInteractive && activity != null;

    if (isInteractive) {
      final spoken = _firstNonEmpty(<String>[
        activity.narrationText,
        activity.prompt,
        step.body,
      ]);
      final visible = _firstNonEmpty(<String>[activity.prompt, step.body]);
      final choices = activitySpec == null
          ? const <Object>[]
          : activitySpec.choiceValues.whereType<Object>().toList(growable: false);
      return LearningNarrationCue(
        id: 'lesson:${step.id}:${activity.id}',
        kind: LearningNarrationKind.activityPrompt,
        visibleText: visible,
        spokenText: spoken,
        choices: choices,
        autoEligible: true,
        delivery: LearningNarrationDelivery.prompt,
      );
    }

    return LearningNarrationCue(
      id: 'lesson:${step.id}:teaching',
      kind: _kindForTeachingStep(step.kind),
      visibleText: step.body,
      spokenText: _teachingNarration(step),
      // Reteach/review are support material. If surfaced independently they
      // should wait for a learner action rather than interrupting the current
      // task automatically.
      autoEligible: step.kind != LessonStepKind.reteach &&
          step.kind != LessonStepKind.review,
      delivery: LearningNarrationDelivery.statement,
    );
  }

  LearningNarrationCue forHint({
    required String ownerId,
    required String text,
  }) {
    final authored = text.trim();
    return LearningNarrationCue(
      id: 'hint:$ownerId:${const LearningNarrationSequencePolicy().fingerprint(authored)}',
      kind: LearningNarrationKind.hint,
      visibleText: authored,
      spokenText: authored,
      autoEligible: false,
      delivery: LearningNarrationDelivery.statement,
    );
  }

  LearningNarrationCue forGamePrompt({
    required String gameId,
    required String prompt,
    Iterable<Object> choices = const <Object>[],
  }) {
    final normalizedPrompt = prompt.trim();
    return LearningNarrationCue(
      id: 'game:$gameId:$normalizedPrompt',
      kind: LearningNarrationKind.gamePrompt,
      visibleText: normalizedPrompt,
      spokenText: normalizedPrompt,
      choices: choices,
      // Game launch already has a dedicated guide introduction. Keep prompt
      // reading manual so intro and question narration cannot race each other.
      autoEligible: false,
      delivery: LearningNarrationDelivery.prompt,
    );
  }


  /// Builds a Nursery teaching/board cue from authored or already-normalized
  /// source text. The director does not synthesize child-facing content here;
  /// callers keep Nursery-specific spoken-label normalization in the Nursery
  /// domain and pass the exact visible/spoken forms.
  LearningNarrationCue forNurseryStatement({
    required String ownerId,
    required LearningNarrationKind kind,
    required String visibleText,
    required String spokenText,
    bool autoEligible = true,
  }) {
    final visible = visibleText.trim();
    final spoken = spokenText.trim();
    return LearningNarrationCue(
      id: 'nursery:$ownerId:${const LearningNarrationSequencePolicy().fingerprint(spoken)}',
      kind: kind,
      visibleText: visible,
      spokenText: spoken,
      autoEligible: autoEligible,
      delivery: LearningNarrationDelivery.statement,
    );
  }

  /// Builds a Nursery question/review cue. Authored choices stay separate from
  /// the prompt so the shared speech backend can read them as choices without
  /// exposing answer keys or optional hints.
  LearningNarrationCue forNurseryPrompt({
    required String ownerId,
    required String visibleText,
    required String spokenText,
    Iterable<Object> choices = const <Object>[],
    bool autoEligible = true,
  }) {
    final visible = visibleText.trim();
    final spoken = spokenText.trim();
    return LearningNarrationCue(
      id: 'nursery:$ownerId:${const LearningNarrationSequencePolicy().fingerprint(spoken)}',
      kind: LearningNarrationKind.activityPrompt,
      visibleText: visible,
      spokenText: spoken,
      choices: choices,
      autoEligible: autoEligible,
      delivery: LearningNarrationDelivery.prompt,
    );
  }

  static LearningNarrationKind _kindForTeachingStep(LessonStepKind kind) {
    return switch (kind) {
      LessonStepKind.objective => LearningNarrationKind.missionGoal,
      LessonStepKind.explanation || LessonStepKind.reteach =>
        LearningNarrationKind.conceptTeaching,
      LessonStepKind.workedExample => LearningNarrationKind.workedExample,
      // These kinds are normally interactive. If a capacity-aware lesson has
      // no allocated activity, their authored fallback instruction remains a
      // plain teaching statement rather than pretending there are choices.
      LessonStepKind.guidedTry ||
      LessonStepKind.independentPractice ||
      LessonStepKind.transfer ||
      LessonStepKind.exitTicket ||
      LessonStepKind.review =>
        LearningNarrationKind.conceptTeaching,
    };
  }

  static String _teachingNarration(LessonStep step) {
    // Step 2 already preserves role-specific authored bodies. Reading the body
    // here keeps goal, explanation and worked reasoning distinct without
    // synthesizing extra teaching language or accidentally reading hints.
    return _firstNonEmpty(<String>[step.body, step.title]);
  }

  static String _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
