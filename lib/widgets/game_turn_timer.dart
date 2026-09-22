import 'package:flutter/material.dart';

/// A per-question countdown that uses Flutter's ticker lifecycle instead of a
/// raw Timer. It can therefore pause/resume with answer state and is always
/// disposed with the game surface without leaving delayed callbacks behind.
class GameTurnTimer extends StatefulWidget {
  const GameTurnTimer({
    required this.duration,
    required this.resetKey,
    required this.paused,
    required this.onExpired,
    super.key,
  });

  final Duration duration;
  final Object resetKey;
  final bool paused;
  final VoidCallback onExpired;

  @override
  State<GameTurnTimer> createState() => _GameTurnTimerState();
}

class _GameTurnTimerState extends State<GameTurnTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _expiryDelivered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    )..addListener(_handleTick);
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant GameTurnTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey ||
        oldWidget.duration != widget.duration) {
      _controller
        ..stop()
        ..duration = widget.duration
        ..value = 1;
      _expiryDelivered = false;
    }
    _syncPlayback();
  }

  void _syncPlayback() {
    if (widget.paused || _expiryDelivered || _controller.value <= 0) {
      _controller.stop();
      return;
    }
    _controller.reverse(from: _controller.value);
  }

  void _handleTick() {
    // AnimationController's dismissed status is finalized on the frame after
    // the interpolation reaches its lower bound in widget tests. The visible
    // countdown, however, has already reached zero at that boundary. Deliver
    // expiry from the value itself so the game turn ends exactly when the
    // countdown reaches zero, while [_expiryDelivered] keeps it one-shot.
    if (_controller.value > 0 || _expiryDelivered || !mounted || widget.paused) {
      return;
    }
    _expiryDelivered = true;
    _controller.stop();
    widget.onExpired();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final totalSeconds = widget.duration.inSeconds.clamp(1, 3600);
        final remainingSeconds =
            (totalSeconds * _controller.value).ceil().clamp(0, totalSeconds);
        final urgent = remainingSeconds <= 5;
        final accent = urgent ? scheme.error : scheme.primary;
        final stateLabel = widget.paused && remainingSeconds > 0
            ? 'Paused'
            : '$remainingSeconds seconds left';
        return Semantics(
          container: true,
          liveRegion: urgent,
          label: 'Question timer. $stateLabel.',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: .22)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 19, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      minHeight: 8,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: .14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.paused && remainingSeconds > 0
                      ? 'Paused'
                      : '${remainingSeconds}s',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
