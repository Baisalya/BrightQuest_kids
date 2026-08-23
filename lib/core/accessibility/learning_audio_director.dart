import '../content/content_activity.dart';
import '../learning/gameplay_activity_models.dart';
import '../learning/mission_session_models.dart';
import 'learning_audio_models.dart';

/// Builds narration from already-authored learning text.
///
/// This layer never invents facts, answers or hints. Its job is only to choose
/// which existing visible/authored string should be read for the current UI
/// state and to keep the same material available as a visible transcript.
class LearningAudioDirector {
  const LearningAudioDirector();

  LearningNarrationCue forLessonStep({
    required MissionSessionStep sessionStep,
    ContentActivity? activity,
    LearningGameActivitySpec? activitySpec,
  }) {
    final step = sessionStep.lessonStep;
    final isInteractive = sessionStep.isInteractive && activity != null;
    final spoken = isInteractive
        ? _firstNonEmpty(<String>[
            activity.narrationText,
            activity.prompt,
            step.body,
          ])
        : _firstNonEmpty(<String>[step.body, step.title]);
    final visible = isInteractive
        ? _firstNonEmpty(<String>[activity.prompt, step.body])
        : step.body;
    final choices = isInteractive && activitySpec != null
        ? activitySpec.choiceValues.whereType<Object>().toList(growable: false)
        : const <Object>[];

    return LearningNarrationCue(
      id: 'lesson:${step.id}:${activity?.id ?? 'teaching'}',
      kind: isInteractive
          ? LearningNarrationKind.activityPrompt
          : LearningNarrationKind.lesson,
      visibleText: visible,
      spokenText: spoken,
      choices: choices,
      autoEligible: true,
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
    );
  }

  static String _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
