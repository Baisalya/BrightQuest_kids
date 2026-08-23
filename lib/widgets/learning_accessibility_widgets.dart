import 'dart:async';

import 'package:flutter/material.dart';

import '../app/brightquest_scope.dart';
import '../core/accessibility/learning_audio_models.dart';
import '../core/services/bright_audio_service.dart';
import '../core/theme/app_theme.dart';

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
    super.key,
  });

  final LearningNarrationCue cue;
  final bool autoNarrate;
  final bool compact;

  /// Single-row transcript treatment for wide but vertically constrained
  /// interactive lessons. The full cue remains available through Semantics.
  final bool denseTranscript;

  @override
  State<LearningNarrationBar> createState() => _LearningNarrationBarState();
}

class _LearningNarrationBarState extends State<LearningNarrationBar> {
  static const _policy = LearningAudioAccessibilityPolicy();
  String? _autoNarratedCueId;

  @override
  void didUpdateWidget(covariant LearningNarrationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cue.id != widget.cue.id) {
      _autoNarratedCueId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    return AnimatedBuilder(
      animation: BrightAudioService.instance,
      builder: (context, _) {
        final audio = BrightAudioService.instance;
        _scheduleAutoNarrationIfNeeded(
          controllerSoundEnabled: controller.soundEnabled,
          audio: audio,
        );

        final showTranscript = _policy.shouldShowTranscript(
          captionsEnabled: controller.captionsEnabled,
          readingFocusEnabled: controller.readingFocusEnabled,
        );
        final canRead = widget.cue.hasSpokenText &&
            controller.soundEnabled &&
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
        if (!controller.soundEnabled && !showTranscript) {
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
                    ? 'Read aloud'
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
                ),
              ),
              if (canRead)
                Tooltip(
                  message: 'Stop narration',
                  child: IconButton(
                    key: const Key('learning_stop_narration_button'),
                    onPressed: () => unawaited(
                      BrightAudioService.instance.stopVoice(),
                    ),
                    icon: const Icon(Icons.stop_circle_outlined),
                    visualDensity: VisualDensity.compact,
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
              tooltip: canRead ? 'Read aloud' : 'Narration is unavailable',
              onPressed: canRead ? _readAloud : null,
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
            ),
            if (canRead)
              IconButton(
                key: const Key('learning_stop_narration_button'),
                tooltip: 'Stop narration',
                onPressed: () => unawaited(
                  BrightAudioService.instance.stopVoice(),
                ),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 34, height: 34),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  void _scheduleAutoNarrationIfNeeded({
    required bool controllerSoundEnabled,
    required BrightAudioService audio,
  }) {
    if (!widget.autoNarrate || _autoNarratedCueId == widget.cue.id) return;
    final shouldNarrate = _policy.shouldAutoNarrate(
      cue: widget.cue,
      soundEnabled: controllerSoundEnabled,
      voiceEnabled: audio.voiceEnabled,
      voiceAvailable: audio.voiceAvailable,
      autoNarrationEnabled: audio.autoNarrationEnabled,
    );
    if (!audio.initialized || !shouldNarrate) return;

    _autoNarratedCueId = widget.cue.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.cue.id != _autoNarratedCueId) return;
      final latestAudio = BrightAudioService.instance;
      final controller = BrightQuestScope.of(context);
      final stillAllowed = _policy.shouldAutoNarrate(
        cue: widget.cue,
        soundEnabled: controller.soundEnabled,
        voiceEnabled: latestAudio.voiceEnabled,
        voiceAvailable: latestAudio.voiceAvailable,
        autoNarrationEnabled: latestAudio.autoNarrationEnabled,
      );
      if (!latestAudio.initialized || !stillAllowed) {
        _autoNarratedCueId = null;
        return;
      }
      _readAloud();
    });
  }

  void _readAloud() {
    unawaited(
      BrightAudioService.instance.speakPrompt(
        widget.cue.spokenText,
        choices: widget.cue.choices,
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
