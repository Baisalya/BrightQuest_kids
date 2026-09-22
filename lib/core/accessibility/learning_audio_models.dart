/// Pedagogical role of a narration cue.
///
/// These roles are presentation/accessibility metadata only. They never alter
/// curriculum, correctness, evidence, mastery or rewards. Keeping them explicit
/// lets the narration layer speak a mission goal differently from teaching,
/// worked reasoning, a question prompt, or optional help.
enum LearningNarrationKind {
  missionGoal,
  conceptTeaching,
  workedExample,
  activityPrompt,
  gamePrompt,
  hint,
  feedback,
  completion,
}

/// How the existing speech backend should deliver a cue.
///
/// [statement] reads exactly the authored narration text. [prompt] may append
/// the authored visible answer choices; it never adds correctness information.
enum LearningNarrationDelivery {
  statement,
  prompt,
}

class LearningNarrationCue {
  const LearningNarrationCue({
    required this.id,
    required this.kind,
    required this.visibleText,
    required this.spokenText,
    this.choices = const <Object>[],
    this.autoEligible = true,
    this.delivery = LearningNarrationDelivery.statement,
  });

  final String id;
  final LearningNarrationKind kind;

  /// Text that must remain available visually when captions are enabled.
  final String visibleText;

  /// Authored text sent to the existing device narration backend.
  final String spokenText;

  /// Authored answer/input choices. They are spoken only for [prompt] delivery;
  /// no answer key or correctness information is added here.
  final Iterable<Object> choices;

  /// Whether the global automatic-narration preference is allowed to trigger
  /// this cue. Manual Read again remains available separately.
  final bool autoEligible;

  final LearningNarrationDelivery delivery;

  bool get hasText =>
      spokenText.trim().isNotEmpty || visibleText.trim().isNotEmpty;

  bool get hasSpokenText => spokenText.trim().isNotEmpty;

  bool get speaksChoices =>
      delivery == LearningNarrationDelivery.prompt && choices.isNotEmpty;

  String get transcriptText {
    final visible = visibleText.trim();
    return visible.isNotEmpty ? visible : spokenText.trim();
  }

  /// Stable text-only identity used to prevent adjacent auto-narration from
  /// repeating the same authored sentence under a different page/cue id.
  String get automaticRepeatKey {
    const policy = LearningNarrationSequencePolicy();
    final base = policy.fingerprint(spokenText);
    if (!speaksChoices) return base;
    final readableChoices = choices
        .map((choice) => policy.fingerprint('$choice'))
        .where((choice) => choice.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (readableChoices.isEmpty) return base;
    return '$base|choices:${readableChoices.join('|')}';
  }

  String get semanticLabel {
    final label = switch (kind) {
      LearningNarrationKind.missionGoal => 'Mission goal narration',
      LearningNarrationKind.conceptTeaching => 'Teaching narration',
      LearningNarrationKind.workedExample => 'Worked example narration',
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

/// Text continuity policy shared by the director/session and directly testable
/// without a platform speech engine.
class LearningNarrationSequencePolicy {
  const LearningNarrationSequencePolicy();

  String fingerprint(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool isAutomaticRepeat({
    required LearningNarrationCue cue,
    required String? previousFingerprint,
  }) {
    final current = cue.automaticRepeatKey;
    return current.isNotEmpty &&
        previousFingerprint != null &&
        current == previousFingerprint;
  }

  /// Whether this request should be suppressed by adjacent-content continuity.
  ///
  /// Manual Read again is a learner action, so it always bypasses automatic
  /// repeat suppression. Keeping that exception in this pure policy prevents
  /// UI/session code from accidentally applying different rules before and
  /// after speech-backend arbitration.
  bool shouldSuppress({
    required LearningNarrationCue cue,
    required String? previousFingerprint,
    required bool manual,
  }) {
    if (manual) return false;
    return isAutomaticRepeat(
      cue: cue,
      previousFingerprint: previousFingerprint,
    );
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
