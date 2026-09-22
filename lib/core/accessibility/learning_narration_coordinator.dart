import 'dart:async';

import 'package:flutter/material.dart';

import '../models/progress_models.dart';
import '../services/bright_audio_service.dart';
import 'learning_audio_models.dart';

/// Route observer used only for narration ownership/lifecycle notifications.
///
/// The observer is intentionally independent from curriculum/navigation logic:
/// it never changes routes. Learning screens subscribe so a covered or popped
/// route cannot keep talking behind the next screen.
final LearningNarrationRouteObserver learningNarrationRouteObserver =
    LearningNarrationRouteObserver();

class LearningNarrationRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(LearningNarrationCoordinator.instance.stopAll());
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(LearningNarrationCoordinator.instance.stopAll());
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(LearningNarrationCoordinator.instance.stopAll());
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    unawaited(LearningNarrationCoordinator.instance.stopAll());
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// Coordinates all learning speech that needs screen/session ownership.
///
/// [BrightAudioService] remains the low-level playback engine. This coordinator
/// adds cancellation generations and ownership above it so an old screen,
/// delayed feedback callback, or replaced lesson step cannot start speaking
/// after the learner has already moved somewhere else.
class LearningNarrationCoordinator {
  LearningNarrationCoordinator._();

  static final LearningNarrationCoordinator instance =
      LearningNarrationCoordinator._();

  final BrightAudioService _audio = BrightAudioService.instance;
  int _nextSessionId = 0;
  int _operationSerial = 0;
  int _globalGeneration = 0;
  int? _activeSessionId;
  final Set<LearningNarrationSession> _sessions = <LearningNarrationSession>{};
  final Set<VoidCallback> _globalInvalidationListeners = <VoidCallback>{};

  LearningNarrationSession createSession({required String ownerLabel}) {
    final session = LearningNarrationSession._(
      coordinator: this,
      id: ++_nextSessionId,
      ownerLabel: ownerLabel,
    );
    _sessions.add(session);
    return session;
  }

  Future<void> _speak(
    LearningNarrationSession session,
    Future<void> Function(BrightAudioService audio) action,
  ) async {
    if (!session._canSpeak) return;
    final sessionGeneration = session._generation;
    final operation = ++_operationSerial;
    _activeSessionId = session._id;

    // Always replace the previous utterance before this owner starts a new one.
    // A later request can overtake this await; the serial/generation checks
    // below make that later request the only one allowed to continue.
    await _audio.stopVoice();
    if (!_requestIsCurrent(
      session: session,
      sessionGeneration: sessionGeneration,
      operation: operation,
    )) {
      return;
    }

    try {
      await action(_audio);
    } finally {
      if (_requestIsCurrent(
        session: session,
        sessionGeneration: sessionGeneration,
        operation: operation,
      )) {
        _activeSessionId = null;
      }
    }
  }

  Future<void> _invalidate(
    LearningNarrationSession session, {
    required bool stopVoice,
  }) async {
    session._generation += 1;
    _globalGeneration += 1;
    _notifyGlobalInvalidated();
    if (!stopVoice || _activeSessionId != session._id) return;

    _operationSerial += 1;
    _activeSessionId = null;
    await _audio.stopVoice();
  }

  /// Stops the utterance currently occupying the speech backend without
  /// invalidating this owner's scope generation.
  ///
  /// Feedback uses this to interrupt a still-speaking prompt immediately,
  /// while the guard captured at the moment of the answer/hint remains tied
  /// to the same visible lesson scope. A real scope change still invalidates
  /// that guard through [_invalidate].
  Future<void> _interruptCurrentSpeech(
    LearningNarrationSession session,
  ) async {
    if (!session._canSpeak) return;
    _operationSerial += 1;
    _activeSessionId = null;
    await _audio.stopVoice();
  }

  bool _requestIsCurrent({
    required LearningNarrationSession session,
    required int sessionGeneration,
    required int operation,
  }) {
    return session._canSpeak &&
        session._generation == sessionGeneration &&
        _operationSerial == operation &&
        _activeSessionId == session._id;
  }

  LearningNarrationGlobalGuard captureGlobalGuard() {
    return LearningNarrationGlobalGuard._(_globalGeneration);
  }

  bool isGlobalGuardCurrent(LearningNarrationGlobalGuard guard) {
    return guard._generation == _globalGeneration;
  }

  /// Registers short-lived work that must be cancelled immediately whenever
  /// narration ownership crosses a real scope/route boundary.
  ///
  /// The returned callback unregisters the listener. Feedback sequencing uses
  /// this to cancel its own delay timer instead of leaving a stale Timer alive
  /// until its nominal timeout after the learning surface has already gone.
  VoidCallback addGlobalInvalidationListener(VoidCallback listener) {
    _globalInvalidationListeners.add(listener);
    return () => _globalInvalidationListeners.remove(listener);
  }

  void _notifyGlobalInvalidated() {
    if (_globalInvalidationListeners.isEmpty) return;
    for (final listener in
        List<VoidCallback>.of(_globalInvalidationListeners)) {
      listener();
    }
  }

  Future<void> _disposeSession(LearningNarrationSession session) async {
    await _invalidate(session, stopVoice: true);
    _sessions.remove(session);
  }

  /// Emergency/global boundary used when the learner changes top-level areas.
  /// It also stops speech started by legacy callers that have not yet migrated
  /// to an owned learning session and invalidates every delayed owned callback.
  Future<void> stopAll() async {
    _operationSerial += 1;
    _globalGeneration += 1;
    _notifyGlobalInvalidated();
    _activeSessionId = null;
    for (final session in _sessions) {
      if (!session._disposed) session._generation += 1;
    }
    await _audio.stopVoice();
  }
}

/// A narration owner tied to one learning screen/session.
///
/// The session is deliberately small: it does not know curriculum or widget
/// state. Screens advance its scope whenever visible learning context changes,
/// suspend it while covered by another route, and dispose it with the screen.
class LearningNarrationSession {
  LearningNarrationSession._({
    required LearningNarrationCoordinator coordinator,
    required int id,
    required this.ownerLabel,
  })  : _coordinator = coordinator,
        _id = id;

  final LearningNarrationCoordinator _coordinator;
  final int _id;
  final String ownerLabel;

  static const _sequencePolicy = LearningNarrationSequencePolicy();

  int _generation = 0;
  bool _suspended = false;
  bool _disposed = false;
  String? _lastAutomaticNarrationFingerprint;

  bool get _canSpeak => !_disposed && !_suspended;
  bool get isSuspended => _suspended;
  bool get isDisposed => _disposed;

  /// Captures the current ownership generation for delayed work such as
  /// feedback that waits for a sound effect before speaking.
  LearningNarrationGuard captureGuard() {
    return LearningNarrationGuard._(
      sessionId: _id,
      generation: _generation,
    );
  }

  bool isGuardCurrent(LearningNarrationGuard guard) {
    return _canSpeak &&
        guard._sessionId == _id &&
        guard._generation == _generation;
  }

  /// Invalidates pending narration and stops speech owned by this session.
  /// Call this before changing the visible lesson/activity step.
  Future<void> advanceScope() {
    return _coordinator._invalidate(this, stopVoice: true);
  }

  Future<void> stop() {
    return _coordinator._invalidate(this, stopVoice: true);
  }

  /// Immediately interrupts the current prompt/utterance but keeps the
  /// current scope generation valid. This is intentionally narrower than
  /// [stop]: answer and hint feedback can take the audio channel without
  /// making their own pre-captured ownership guard stale.
  Future<void> interruptCurrentSpeech() {
    return _coordinator._interruptCurrentSpeech(this);
  }

  Future<void> suspend() async {
    if (_disposed || _suspended) return;
    _suspended = true;
    await _coordinator._invalidate(this, stopVoice: true);
  }

  void resume() {
    if (_disposed) return;
    _suspended = false;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _coordinator._disposeSession(this);
  }

  /// Speaks one director-produced cue using its declared delivery role.
  ///
  /// Automatic narration remembers the normalized authored sentence across
  /// lesson scope changes, so adjacent pages with duplicate copy do not read
  /// the same thing again merely because their cue ids differ. Manual Read
  /// again deliberately bypasses that continuity guard.
  Future<void> speakCue(
    LearningNarrationCue cue, {
    required bool manual,
  }) {
    if (!cue.hasSpokenText) return Future<void>.value();
    final fingerprint = cue.automaticRepeatKey;
    if (_sequencePolicy.shouldSuppress(
      cue: cue,
      previousFingerprint: _lastAutomaticNarrationFingerprint,
      manual: manual,
    )) {
      return Future<void>.value();
    }

    return _coordinator._speak(
      this,
      (audio) async {
        // Re-check after ownership arbitration in case two automatic requests
        // raced before either reached the speech backend.
        if (_sequencePolicy.shouldSuppress(
          cue: cue,
          previousFingerprint: _lastAutomaticNarrationFingerprint,
          manual: manual,
        )) {
          return;
        }
        if (!manual && fingerprint.isNotEmpty) {
          _lastAutomaticNarrationFingerprint = fingerprint;
        }
        if (cue.delivery == LearningNarrationDelivery.prompt) {
          await audio.speakPrompt(
            cue.spokenText,
            choices: cue.choices,
          );
          return;
        }
        await audio.speak(cue.spokenText, manual: manual);
      },
    );
  }

  Future<void> speak(String text, {bool manual = false}) {
    return _coordinator._speak(
      this,
      (audio) => audio.speak(text, manual: manual),
    );
  }

  Future<void> speakPrompt(
    String prompt, {
    Iterable<Object> choices = const <Object>[],
  }) {
    return _coordinator._speak(
      this,
      (audio) => audio.speakPrompt(prompt, choices: choices),
    );
  }

  Future<void> speakCorrect({String? answer, String? detail}) {
    return _coordinator._speak(
      this,
      (audio) => audio.speakCorrect(answer: answer, detail: detail),
    );
  }

  Future<void> speakWrong({
    String? answer,
    String? correctAnswer,
    String? guidance,
  }) {
    return _coordinator._speak(
      this,
      (audio) => audio.speakWrong(
        answer: answer,
        correctAnswer: correctAnswer,
        guidance: guidance,
      ),
    );
  }

  Future<void> speakComplete({MissionReward? reward}) {
    return _coordinator._speak(
      this,
      (audio) => audio.speakComplete(reward: reward),
    );
  }
}

/// Global cancellation marker for legacy delayed speech that has not yet been
/// assigned to a screen-owned session. Route and scope boundaries invalidate it.
class LearningNarrationGlobalGuard {
  const LearningNarrationGlobalGuard._(this._generation);

  final int _generation;
}

typedef LearningNarrationSessionBuilder = Widget Function(
  BuildContext context,
  LearningNarrationSession narrationSession,
);

/// Reusable route-aware owner for learning surfaces that need one narration
/// session shared by multiple controls. Changing [scopeKey] cancels speech from
/// the previous visible prompt before the new content becomes authoritative.
class LearningNarrationBoundary extends StatefulWidget {
  const LearningNarrationBoundary({
    required this.ownerLabel,
    required this.builder,
    this.scopeKey,
    super.key,
  });

  final String ownerLabel;
  final Object? scopeKey;
  final LearningNarrationSessionBuilder builder;

  @override
  State<LearningNarrationBoundary> createState() =>
      _LearningNarrationBoundaryState();
}

class _LearningNarrationBoundaryState extends State<LearningNarrationBoundary>
    with WidgetsBindingObserver, RouteAware {
  late final LearningNarrationSession _session;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _session = LearningNarrationCoordinator.instance.createSession(
      ownerLabel: widget.ownerLabel,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRoute = ModalRoute.of(context);
    if (identical(nextRoute, _route)) return;
    _unsubscribeRoute();
    if (nextRoute == null) return;
    _route = nextRoute;
    learningNarrationRouteObserver.subscribe(this, nextRoute);
  }

  @override
  void didUpdateWidget(covariant LearningNarrationBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scopeKey != widget.scopeKey) {
      unawaited(_session.advanceScope());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    unawaited(_session.advanceScope());
  }

  @override
  void didPushNext() {
    unawaited(_session.suspend());
  }

  @override
  void didPopNext() {
    _session.resume();
  }

  @override
  void didPop() {
    unawaited(_session.stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeRoute();
    unawaited(_session.dispose());
    super.dispose();
  }

  void _unsubscribeRoute() {
    if (_route == null) return;
    learningNarrationRouteObserver.unsubscribe(this);
    _route = null;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _session);
}

/// Immutable cancellation marker for delayed narration work.
class LearningNarrationGuard {
  const LearningNarrationGuard._({
    required int sessionId,
    required int generation,
  })  : _sessionId = sessionId,
        _generation = generation;

  final int _sessionId;
  final int _generation;
}
