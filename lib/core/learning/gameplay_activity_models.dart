/// Presentation families supported by the reusable BrightQuest learning-game
/// layer. These values describe interaction capability only; correctness and
/// progress remain owned by the existing learning/evidence engines.
enum LearningGameActivityKind {
  themedChoice,
  fractionBuilder,
  sentenceBuilder,
  grammarSort,
  robotRoute,
  experimentMixer,
  recyclingSort,
  unsupported,
}

/// The underlying play mechanic. Keeping this separate from the visual world
/// means a renderer can share interaction rules while each world still has its
/// own identity.
enum LearningGameMechanic {
  decision,
  construction,
  sorting,
  navigation,
  simulation,
  unavailable,
}

/// Visual treatment used when an authored activity is a single-answer choice.
/// These are presentation styles only; they do not change the authored answer
/// or infer facts that are not present in the content pack.
enum LearningGameChoicePresentation {
  marketStalls,
  storyTrail,
  labScanner,
  ecoTrail,
  mapExpedition,
  robotConsole,
  questCards,
}

/// Visual identity used by the presentation layer. It is intentionally free of
/// Flutter types so content resolution stays testable outside the widget tree.
enum LearningGameTheme {
  maths,
  story,
  science,
  nature,
  map,
  coding,
  neutral,
}

class LearningGameActivitySpec {
  const LearningGameActivitySpec({
    required this.kind,
    required this.mechanic,
    required this.theme,
    required this.sceneGameId,
    required this.choiceValues,
    required this.choicePresentation,
    this.unsupportedReason,
  });

  final LearningGameActivityKind kind;
  final LearningGameMechanic mechanic;
  final LearningGameTheme theme;
  final String sceneGameId;
  final List<Object?> choiceValues;
  final LearningGameChoicePresentation choicePresentation;
  final String? unsupportedReason;

  bool get isSupported => kind != LearningGameActivityKind.unsupported;
  bool get usesAuthoredChoices => choiceValues.isNotEmpty;
  bool get usesDirectManipulation => switch (mechanic) {
        LearningGameMechanic.construction ||
        LearningGameMechanic.sorting ||
        LearningGameMechanic.navigation ||
        LearningGameMechanic.simulation =>
          true,
        LearningGameMechanic.decision ||
        LearningGameMechanic.unavailable =>
          false,
      };
}
