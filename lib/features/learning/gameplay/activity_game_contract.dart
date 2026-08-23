import 'package:flutter/foundation.dart';

/// Snapshot emitted by an individual mini-game interaction.
///
/// The value is passed unchanged to ActivityResponseEvaluator by the parent
/// renderer. Mini-games are responsible only for collecting a response and
/// reporting when that response is ready to check.
@immutable
class GameActivityResponseSnapshot {
  const GameActivityResponseSnapshot({
    required this.value,
    required this.ready,
  });

  const GameActivityResponseSnapshot.empty()
      : value = null,
        ready = false;

  final Object? value;
  final bool ready;
}

typedef GameActivityResponseChanged = void Function(
  GameActivityResponseSnapshot snapshot,
);
