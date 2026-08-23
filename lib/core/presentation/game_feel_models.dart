import 'package:flutter/foundation.dart';

/// Visual-emotional states used by BrightQuest's mascot and finite reaction
/// animations. These are presentation only; they never carry correctness or
/// reward authority.
enum BrightMascotMood {
  cheerful,
  focused,
  thinking,
  encouraging,
  celebrating,
  heroic,
}

/// A finite, child-facing moment cue. Widgets can turn this into a safe visual
/// reaction while respecting reduced-motion and Windows semantics isolation.
enum BrightMomentKind {
  calm,
  focus,
  selection,
  hint,
  success,
  retry,
  powerUp,
  unlock,
  bossClear,
  worldClear,
}

@immutable
class BrightGameFeelMoment {
  const BrightGameFeelMoment({
    required this.kind,
    required this.mood,
    required this.emoji,
    required this.semanticLabel,
  });

  final BrightMomentKind kind;
  final BrightMascotMood mood;
  final String emoji;
  final String semanticLabel;

  bool get celebratory => switch (kind) {
        BrightMomentKind.success ||
        BrightMomentKind.unlock ||
        BrightMomentKind.bossClear ||
        BrightMomentKind.worldClear =>
          true,
        _ => false,
      };
}
