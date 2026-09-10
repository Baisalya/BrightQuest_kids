import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Finite, child-friendly motion policy for Nursery presentation.
///
/// Motion is disabled when either the app-level reduced-motion preference or
/// the operating-system accessibility preference requests fewer animations.
/// On Windows, geometry-changing transforms are avoided to keep semantics
/// nodes stable; a small opacity reaction is used instead.
class NurseryMotionPolicy {
  const NurseryMotionPolicy._();

  static bool reduce(BuildContext context, bool reducedMotion) =>
      reducedMotion || (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  static bool avoidGeometry(BuildContext context, bool reducedMotion) =>
      reduce(context, reducedMotion) || Platform.isWindows;

  static Duration duration(NurseryMotionCue cue) => switch (cue) {
        NurseryMotionCue.selection => const Duration(milliseconds: 220),
        NurseryMotionCue.retry => const Duration(milliseconds: 420),
        NurseryMotionCue.hint => const Duration(milliseconds: 460),
        NurseryMotionCue.progress => const Duration(milliseconds: 300),
        NurseryMotionCue.success => const Duration(milliseconds: 560),
        NurseryMotionCue.reveal => const Duration(milliseconds: 380),
      };
}

enum NurseryMotionCue {
  reveal,
  selection,
  success,
  retry,
  hint,
  progress,
}

/// Plays one finite reaction when [trigger] changes.
///
/// There are deliberately no repeat/reverse loops or timers here. This keeps
/// Nursery feedback calm and guarantees widget tests can settle.
class NurseryMotionReaction extends StatefulWidget {
  const NurseryMotionReaction({
    required this.trigger,
    required this.cue,
    required this.child,
    required this.reducedMotion,
    this.animateOnMount = true,
    this.duration,
    super.key,
  });

  final Object trigger;
  final NurseryMotionCue cue;
  final Widget child;
  final bool reducedMotion;
  final bool animateOnMount;
  final Duration? duration;

  @override
  State<NurseryMotionReaction> createState() => _NurseryMotionReactionState();
}

class _NurseryMotionReactionState extends State<NurseryMotionReaction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _dependenciesReady = false;
  bool _systemReducedMotion = false;

  bool get _reduceMotion => widget.reducedMotion || _systemReducedMotion;

  Duration get _duration =>
      widget.duration ?? NurseryMotionPolicy.duration(widget.cue);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_dependenciesReady) {
      _syncMotion();
      return;
    }
    _dependenciesReady = true;
    if (_reduceMotion || !widget.animateOnMount) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant NurseryMotionReaction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger || oldWidget.cue != widget.cue) {
      _controller.duration = _duration;
      _play();
    } else if (oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.duration != widget.duration) {
      _controller.duration = _duration;
      _syncMotion();
    }
  }

  void _syncMotion() {
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
      return;
    }
    if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  void _play() {
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (NurseryMotionPolicy.reduce(context, widget.reducedMotion)) {
      return widget.child;
    }
    final avoidGeometry =
        NurseryMotionPolicy.avoidGeometry(context, widget.reducedMotion);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        final pulse = math.sin(math.pi * t).clamp(0.0, 1.0).toDouble();
        final opacity = (0.88 + (0.12 * t)).clamp(0.0, 1.0).toDouble();
        if (avoidGeometry) {
          return Opacity(
            opacity: opacity,
            alwaysIncludeSemantics: true,
            child: child,
          );
        }

        final retryWave = widget.cue == NurseryMotionCue.retry
            ? math.sin(t * math.pi * 4) * 3.0 * (1 - t)
            : 0.0;
        final lift = switch (widget.cue) {
          NurseryMotionCue.success => -5.0 * pulse,
          NurseryMotionCue.hint => -2.0 * pulse,
          NurseryMotionCue.selection => -1.5 * pulse,
          NurseryMotionCue.progress => -1.0 * pulse,
          _ => 0.0,
        };
        final scale = switch (widget.cue) {
          NurseryMotionCue.success => 1 + (0.055 * pulse),
          NurseryMotionCue.hint => 1 + (0.025 * pulse),
          NurseryMotionCue.selection => 1 + (0.018 * pulse),
          NurseryMotionCue.progress => 1 + (0.015 * pulse),
          _ => 1.0,
        };
        return Opacity(
          opacity: opacity,
          alwaysIncludeSemantics: true,
          child: Transform.translate(
            offset: Offset(retryWave, lift),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

/// A one-shot entrance reveal that becomes static under reduced motion and
/// avoids geometry-changing transforms on Windows.
class NurseryMotionReveal extends StatelessWidget {
  const NurseryMotionReveal({
    required this.child,
    required this.reducedMotion,
    this.duration,
    this.beginScale = .96,
    this.verticalOffset = 6,
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  final Widget child;
  final bool reducedMotion;
  final Duration? duration;
  final double beginScale;
  final double verticalOffset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (NurseryMotionPolicy.reduce(context, reducedMotion)) return child;
    final avoidGeometry = NurseryMotionPolicy.avoidGeometry(
      context,
      reducedMotion,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration ?? NurseryMotionPolicy.duration(NurseryMotionCue.reveal),
      curve: curve,
      child: child,
      builder: (context, value, animatedChild) {
        final opacity = value.clamp(0.0, 1.0).toDouble();
        if (avoidGeometry) {
          return Opacity(
            opacity: opacity,
            alwaysIncludeSemantics: true,
            child: animatedChild,
          );
        }
        return Opacity(
          opacity: opacity,
          alwaysIncludeSemantics: true,
          child: Transform.translate(
            offset: Offset(0, verticalOffset * (1 - value)),
            child: Transform.scale(
              scale: beginScale + ((1 - beginScale) * value),
              child: animatedChild,
            ),
          ),
        );
      },
    );
  }
}
