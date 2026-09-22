import 'dart:async';

import 'package:flutter/material.dart';

import '../app/brightquest_scope.dart';
import '../core/accessibility/learning_audio_models.dart';
import '../core/accessibility/learning_narration_coordinator.dart';
import '../core/services/bright_audio_service.dart';
import '../core/theme/app_theme.dart';

/// Headless automatic narrator for learning surfaces that already own a
/// [LearningNarrationSession] through [LearningNarrationBoundary].
///
/// This keeps auto-speech out of build methods and lets Nursery, lessons and
/// future learning surfaces share the same audio-preference checks and
/// cancellation semantics without duplicating route/app lifecycle ownership.
class LearningAutomaticNarrator extends StatefulWidget {
  const LearningAutomaticNarrator({
    required this.cue,
    required this.narrationSession,
    required this.child,
    this.triggerKey,
    super.key,
  });

  final LearningNarrationCue cue;
  final LearningNarrationSession narrationSession;
  final Widget child;

  /// Stable identity for automatic narration. When omitted, [cue.id] is used.
  /// A surface may keep this stable while interactive details inside the same
  /// visible stage change and are read only after an explicit learner action.
  final Object? triggerKey;

  @override
  State<LearningAutomaticNarrator> createState() =>
      _LearningAutomaticNarratorState();
}

class _LearningAutomaticNarratorState extends State<LearningAutomaticNarrator> {
  static const _policy = LearningAudioAccessibilityPolicy();

  Object? _autoNarratedKey;
  bool _autoNarrationScheduled = false;

  @override
  void initState() {
    super.initState();
    BrightAudioService.instance.addListener(_handleAudioStateChanged);
    _requestAutoNarration();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestAutoNarration();
  }

  @override
  void didUpdateWidget(covariant LearningAutomaticNarrator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTriggerKey = oldWidget.triggerKey ?? oldWidget.cue.id;
    final newTriggerKey = widget.triggerKey ?? widget.cue.id;
    if (oldTriggerKey != newTriggerKey ||
        !identical(
          oldWidget.narrationSession,
          widget.narrationSession,
        )) {
      _autoNarratedKey = null;
    }
    _requestAutoNarration();
  }

  @override
  void dispose() {
    BrightAudioService.instance.removeListener(_handleAudioStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _handleAudioStateChanged() {
    _requestAutoNarration();
  }

  void _requestAutoNarration() {
    final triggerKey = widget.triggerKey ?? widget.cue.id;
    if (_autoNarratedKey == triggerKey || _autoNarrationScheduled) {
      return;
    }
    _autoNarrationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoNarrationScheduled = false;
      final currentTriggerKey = widget.triggerKey ?? widget.cue.id;
      if (!mounted || _autoNarratedKey == currentTriggerKey) return;
      final audio = BrightAudioService.instance;
      final controller = BrightQuestScope.of(context);
      final shouldNarrate = audio.initialized &&
          _policy.shouldAutoNarrate(
            cue: widget.cue,
            soundEnabled: controller.soundEnabled && audio.appAudioEnabled,
            voiceEnabled: audio.voiceEnabled,
            voiceAvailable: audio.voiceAvailable,
            autoNarrationEnabled: audio.autoNarrationEnabled,
          );
      if (!shouldNarrate) return;
      _autoNarratedKey = currentTriggerKey;
      unawaited(
        widget.narrationSession.speakCue(
          widget.cue,
          manual: false,
        ),
      );
    });
  }
}

/// A single accessible boundary for visible narration text + manual read aloud.
///
/// Automatic narration is opt-in through the existing audio preference and is
/// performed once per cue instance. Captions never depend on the speech engine,
/// so the learning meaning remains visible when audio is muted/unavailable.
class LearningNarrationBar extends StatefulWidget {
  const LearningNarrationBar({
    required this.cue,
    this.autoNarrate = false,
    this.compact = false,
    this.denseTranscript = false,
    this.narrationSession,
    super.key,
  });

  final LearningNarrationCue cue;
  final bool autoNarrate;
  final bool compact;

  /// Optional screen-owned narration session. When omitted, this bar owns a
  /// route-aware session for its own lifetime.
  final LearningNarrationSession? narrationSession;

  /// Single-row transcript treatment for wide but vertically constrained
  /// interactive lessons. The full cue remains available through Semantics.
  final bool denseTranscript;

  @override
  State<LearningNarrationBar> createState() => _LearningNarrationBarState();
}

class _LearningNarrationBarState extends State<LearningNarrationBar>
    with RouteAware {
  static const _policy = LearningAudioAccessibilityPolicy();
  String? _autoNarratedCueId;
  bool _autoNarrationScheduled = false;
  LearningNarrationSession? _ownedSession;
  ModalRoute<dynamic>? _route;

  LearningNarrationSession get _narrationSession =>
      widget.narrationSession ?? _ownedSession!;

  bool get _ownsSession => widget.narrationSession == null;

  @override
  void initState() {
    super.initState();
    _ensureOwnedSession();
    BrightAudioService.instance.addListener(_handleAudioStateChanged);
    _requestAutoNarration();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteSubscription();
    _requestAutoNarration();
  }

  @override
  void didUpdateWidget(covariant LearningNarrationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ownerChanged =
        !identical(oldWidget.narrationSession, widget.narrationSession);
    if (ownerChanged) {
      unawaited(_ownedSession?.dispose());
      _ownedSession = null;
      _unsubscribeRoute();
      _ensureOwnedSession();
      _syncRouteSubscription();
    }
    if (oldWidget.cue.id != widget.cue.id) {
      _autoNarratedCueId = null;
      if (_ownsSession) {
        unawaited(_narrationSession.advanceScope());
      }
    }
    _requestAutoNarration();
  }

  @override
  void dispose() {
    BrightAudioService.instance.removeListener(_handleAudioStateChanged);
    _unsubscribeRoute();
    unawaited(_ownedSession?.dispose());
    super.dispose();
  }

  @override
  void didPushNext() {
    if (_ownsSession) unawaited(_narrationSession.suspend());
  }

  @override
  void didPopNext() {
    if (_ownsSession) _narrationSession.resume();
  }

  @override
  void didPop() {
    if (_ownsSession) unawaited(_narrationSession.stop());
  }

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    return AnimatedBuilder(
      animation: BrightAudioService.instance,
      builder: (context, _) {
        final audio = BrightAudioService.instance;

        final showTranscript = _policy.shouldShowTranscript(
          captionsEnabled: controller.captionsEnabled,
          readingFocusEnabled: controller.readingFocusEnabled,
        );
        final canRead = widget.cue.hasSpokenText &&
            controller.soundEnabled &&
            audio.appAudioEnabled &&
            audio.initialized &&
            audio.voiceAvailable &&
            audio.voiceEnabled;
        final accent = controller.readingFocusEnabled
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF4169A8);
        final choices = _visibleChoices(widget.cue.choices);

        // When this explorer has explicitly turned audio off and neither
        // captions nor Reading Focus is enabled, this control has no active
        // affordance. Collapsing the otherwise-disabled narration chrome keeps
        // short lesson viewports focused on the response interaction. Captions
        // and Reading Focus still render the full transcript even with audio off.
        if ((!controller.soundEnabled || !audio.appAudioEnabled) &&
            !showTranscript) {
          return const SizedBox.shrink();
        }

        if (widget.denseTranscript && showTranscript) {
          return _buildDenseTranscript(
            accent: accent,
            readingFocusEnabled: controller.readingFocusEnabled,
            canRead: canRead,
          );
        }

        return Container(
          key: Key('learning_narration_${widget.cue.id}'),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: controller.readingFocusEnabled
                ? Colors.white
                : accent.withValues(alpha: .055),
            borderRadius: BorderRadius.circular(widget.compact ? 14 : 17),
            border: Border.all(
              color: accent.withValues(
                alpha: controller.readingFocusEnabled ? .42 : .16,
              ),
              width: controller.readingFocusEnabled ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  showTranscript
                      ? Icons.subtitles_rounded
                      : Icons.record_voice_over_rounded,
                  size: widget.compact ? 19 : 21,
                  color: accent,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Semantics(
                  container: true,
                  label: widget.cue.semanticLabel,
                  excludeSemantics: true,
                  child: showTranscript
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.readingFocusEnabled
                                  ? 'READING FOCUS'
                                  : 'NARRATION TRANSCRIPT',
                              style: TextStyle(
                                color: accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .55,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.cue.transcriptText,
                              style: TextStyle(
                                color: AppTheme.navy,
                                fontSize: widget.compact ? 11.5 : 12.5,
                                height: controller.readingFocusEnabled
                                    ? 1.55
                                    : 1.35,
                                fontWeight: controller.readingFocusEnabled
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                            ),
                            if (choices.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Choices: ${choices.join(' • ')}',
                                key: const Key('learning_narration_choices'),
                                style: const TextStyle(
                                  color: AppTheme.inkMuted,
                                  fontSize: 10.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        )
                      : const Text(
                          'Read this learning prompt aloud',
                          style: TextStyle(
                            color: AppTheme.inkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: canRead
                    ? (_autoNarratedCueId == widget.cue.id
                        ? 'Read again'
                        : 'Read aloud')
                    : !audio.appAudioEnabled
                        ? 'App audio is muted by a parent'
                        : !controller.soundEnabled
                            ? 'Audio is off for this explorer'
                            : !audio.voiceEnabled
                                ? 'Narration voice is turned off'
                                : 'Narration voice is unavailable',
                child: IconButton(
                  key: const Key('learning_read_aloud_button'),
                  onPressed: canRead ? _readAloud : null,
                  icon: const Icon(Icons.volume_up_rounded),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
              if (canRead)
                Tooltip(
                  message: 'Stop narration',
                  child: IconButton(
                    key: const Key('learning_stop_narration_button'),
                    onPressed: () =>
                        unawaited(_narrationSession.stop()),
                    icon: const Icon(Icons.stop_circle_outlined),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDenseTranscript({
    required Color accent,
    required bool readingFocusEnabled,
    required bool canRead,
  }) {
    return Semantics(
      container: true,
      label: widget.cue.semanticLabel,
      child: Container(
        key: Key('learning_narration_${widget.cue.id}'),
        padding: const EdgeInsets.fromLTRB(9, 6, 4, 6),
        decoration: BoxDecoration(
          color: readingFocusEnabled
              ? Colors.white
              : accent.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(
              alpha: readingFocusEnabled ? .42 : .16,
            ),
            width: readingFocusEnabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.subtitles_rounded,
                size: 17,
                color: accent,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readingFocusEnabled
                          ? 'READING FOCUS'
                          : 'NARRATION TRANSCRIPT',
                      style: TextStyle(
                        color: accent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .45,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Tooltip(
                      message: widget.cue.semanticLabel,
                      child: Text(
                        widget.cue.transcriptText,
                        maxLines: readingFocusEnabled ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.navy,
                          fontSize: 10.5,
                          height: readingFocusEnabled ? 1.4 : 1.2,
                          fontWeight: readingFocusEnabled
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              key: const Key('learning_read_aloud_button'),
              tooltip: canRead
                  ? (_autoNarratedCueId == widget.cue.id
                      ? 'Read again'
                      : 'Read aloud')
                  : 'Narration is unavailable',
              onPressed: canRead ? _readAloud : null,
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
            ),
            if (canRead)
              IconButton(
                key: const Key('learning_stop_narration_button'),
                tooltip: 'Stop narration',
                onPressed: () => unawaited(_narrationSession.stop()),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 48, height: 48),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  void _ensureOwnedSession() {
    if (!_ownsSession || _ownedSession != null) return;
    _ownedSession = LearningNarrationCoordinator.instance.createSession(
      ownerLabel: 'LearningNarrationBar',
    );
  }

  void _syncRouteSubscription() {
    if (!_ownsSession) {
      _unsubscribeRoute();
      return;
    }
    final nextRoute = ModalRoute.of(context);
    if (identical(nextRoute, _route)) return;
    _unsubscribeRoute();
    if (nextRoute == null) return;
    _route = nextRoute;
    learningNarrationRouteObserver.subscribe(this, nextRoute);
  }

  void _unsubscribeRoute() {
    if (_route == null) return;
    learningNarrationRouteObserver.unsubscribe(this);
    _route = null;
  }

  void _handleAudioStateChanged() {
    _requestAutoNarration();
  }

  /// Requests automatic narration from widget lifecycle callbacks/listeners.
  /// No speech side effect is initiated from build().
  void _requestAutoNarration() {
    if (!widget.autoNarrate ||
        _autoNarratedCueId == widget.cue.id ||
        _autoNarrationScheduled) {
      return;
    }
    _autoNarrationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoNarrationScheduled = false;
      if (!mounted || _autoNarratedCueId == widget.cue.id) return;
      final audio = BrightAudioService.instance;
      final controller = BrightQuestScope.of(context);
      final shouldNarrate = audio.initialized &&
          _policy.shouldAutoNarrate(
            cue: widget.cue,
            soundEnabled: controller.soundEnabled && audio.appAudioEnabled,
            voiceEnabled: audio.voiceEnabled,
            voiceAvailable: audio.voiceAvailable,
            autoNarrationEnabled: audio.autoNarrationEnabled,
          );
      if (!shouldNarrate) return;
      _autoNarratedCueId = widget.cue.id;
      _narrate(manual: false);
    });
  }

  void _readAloud() => _narrate(manual: true);

  void _narrate({required bool manual}) {
    unawaited(
      _narrationSession.speakCue(
        widget.cue,
        manual: manual,
      ),
    );
  }

  static List<String> _visibleChoices(Iterable<Object> choices) {
    final result = <String>[];
    for (final choice in choices) {
      final value = '$choice'.trim();
      if (value.isEmpty || result.contains(value)) continue;
      result.add(value);
    }
    return result;
  }
}
