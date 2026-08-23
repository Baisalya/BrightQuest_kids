/// Roles for narration cues shown and spoken by the learning UI.
///
/// These roles are presentation metadata only. They do not change curriculum,
/// scoring, evidence, mastery or reward behaviour.
enum LearningNarrationKind {
  lesson,
  activityPrompt,
  gamePrompt,
  hint,
  feedback,
  completion,
}

class LearningNarrationCue {
  const LearningNarrationCue({
    required this.id,
    required this.kind,
    required this.visibleText,
    required this.spokenText,
    this.choices = const <Object>[],
    this.autoEligible = true,
  });

  final String id;
  final LearningNarrationKind kind;

  /// Text that must remain available visually when captions are enabled.
  final String visibleText;

  /// Authored text sent to the existing device narration backend.
  final String spokenText;

  /// Authored answer/input choices. These are read only when a cue explicitly
  /// represents a question; no correctness information is added here.
  final Iterable<Object> choices;

  /// Whether the global automatic-narration preference is allowed to trigger
  /// this cue. Manual read-aloud remains separate.
  final bool autoEligible;

  bool get hasText =>
      spokenText.trim().isNotEmpty || visibleText.trim().isNotEmpty;

  bool get hasSpokenText => spokenText.trim().isNotEmpty;

  String get transcriptText {
    final visible = visibleText.trim();
    return visible.isNotEmpty ? visible : spokenText.trim();
  }

  String get semanticLabel {
    final label = switch (kind) {
      LearningNarrationKind.lesson => 'Lesson narration',
      LearningNarrationKind.activityPrompt => 'Activity narration',
      LearningNarrationKind.gamePrompt => 'Game narration',
      LearningNarrationKind.hint => 'Hint narration',
      LearningNarrationKind.feedback => 'Feedback narration',
      LearningNarrationKind.completion => 'Completion narration',
    };
    final text = transcriptText;
    final readableChoices = choices
        .map((choice) => '$choice'.trim())
        .where((choice) => choice.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final details = <String>[
      if (text.isNotEmpty) text,
      if (readableChoices.isNotEmpty) 'Choices: ${readableChoices.join(', ')}',
    ].join(' ');
    return details.isEmpty ? label : '$label. $details';
  }
}

/// Pure policy used by widgets/tests before touching an optional speech engine.
class LearningAudioAccessibilityPolicy {
  const LearningAudioAccessibilityPolicy();

  bool shouldAutoNarrate({
    required LearningNarrationCue cue,
    required bool soundEnabled,
    required bool voiceEnabled,
    required bool voiceAvailable,
    required bool autoNarrationEnabled,
  }) {
    return cue.autoEligible &&
        cue.hasSpokenText &&
        soundEnabled &&
        voiceEnabled &&
        voiceAvailable &&
        autoNarrationEnabled;
  }

  bool shouldShowTranscript({
    required bool captionsEnabled,
    required bool readingFocusEnabled,
  }) {
    return captionsEnabled || readingFocusEnabled;
  }
}
