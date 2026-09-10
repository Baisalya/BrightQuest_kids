import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'nursery_motion.dart';

enum NurseryAssetReactionKind {
  pop,
  wag,
  drumHit,
  fly,
  bounce,
  sway,
}

NurseryAssetReactionKind nurseryReactionForWord(String word) {
  final normalized = word.trim().toLowerCase();
  const wagWords = <String>{
    'dog',
    'cat',
    'rabbit',
    'fox',
    'goat',
    'horse',
    'deer',
    'lion',
    'monkey',
    'mouse',
    'tiger',
    'zebra',
  };
  const drumWords = <String>{'drum'};
  const flyWords = <String>{
    'aeroplane',
    'bird',
    'kite',
    'helicopter',
    'eagle',
    'jet',
    'butterfly',
    'balloon',
    'zeppelin',
  };
  const bounceWords = <String>{
    'ball',
    'orange',
    'yo-yo',
    'frog',
    'donut',
    'pumpkin',
    'yam',
  };
  const swayWords = <String>{
    'tree',
    'umbrella',
    'flower',
    'leaf',
    'lotus',
    'flag',
    'feather',
    'grass',
  };
  if (wagWords.contains(normalized)) {
    return NurseryAssetReactionKind.wag;
  }
  if (drumWords.contains(normalized)) {
    return NurseryAssetReactionKind.drumHit;
  }
  if (flyWords.contains(normalized)) {
    return NurseryAssetReactionKind.fly;
  }
  if (bounceWords.contains(normalized)) {
    return NurseryAssetReactionKind.bounce;
  }
  if (swayWords.contains(normalized)) {
    return NurseryAssetReactionKind.sway;
  }
  return NurseryAssetReactionKind.pop;
}

class NurseryAnimatedAsset extends StatefulWidget {
  const NurseryAnimatedAsset({
    required this.assetPath,
    required this.word,
    required this.reducedMotion,
    required this.fallback,
    super.key,
  });

  final String assetPath;
  final String word;
  final bool reducedMotion;
  final Widget fallback;

  @override
  State<NurseryAnimatedAsset> createState() => _NurseryAnimatedAssetState();
}

class _NurseryAnimatedAssetState extends State<NurseryAnimatedAsset>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _systemReducedMotion = false;
  bool _dependenciesReady = false;

  bool get _reduceMotion => widget.reducedMotion || _systemReducedMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextSystemReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final preferenceChanged =
        nextSystemReducedMotion != _systemReducedMotion;
    _systemReducedMotion = nextSystemReducedMotion;
    if (!_dependenciesReady || preferenceChanged) {
      _dependenciesReady = true;
      _playIfAllowed();
    }
  }

  @override
  void didUpdateWidget(covariant NurseryAnimatedAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.word != widget.word ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _playIfAllowed();
    }
  }

  void _playIfAllowed() {
    if (_reduceMotion) {
      _controller.value = 1;
      return;
    }
    _controller
      ..stop()
      ..value = 0
      ..forward();
  }

  void _replay() {
    if (_reduceMotion) return;
    _controller
      ..stop()
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = nurseryReactionForWord(widget.word);
    final calmMotion = NurseryMotionPolicy.reduce(context, widget.reducedMotion);
    final avoidGeometry =
        NurseryMotionPolicy.avoidGeometry(context, widget.reducedMotion);
    return Semantics(
      container: true,
      button: !calmMotion,
      label: calmMotion
          ? '${widget.word} picture'
          : '${widget.word} picture. Tap to animate.',
      child: GestureDetector(
        onTap: calmMotion ? null : _replay,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.assetPath.isEmpty
              ? widget.fallback
              : Image.asset(
                  widget.assetPath,
                  fit: BoxFit.cover,
                  cacheWidth: 128,
                  cacheHeight: 128,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => widget.fallback,
                ),
          builder: (context, child) {
            if (calmMotion) return child!;
            final t = Curves.easeOut.transform(_controller.value);
            if (avoidGeometry) {
              return Opacity(
                opacity: (0.88 + (0.12 * t)).clamp(0.0, 1.0).toDouble(),
                alwaysIncludeSemantics: true,
                child: child!,
              );
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                _applyTransform(kind, t, child!),
                if (kind == NurseryAssetReactionKind.pop)
                  _OneShotSparkle(progress: _controller.value),
                if (kind == NurseryAssetReactionKind.drumHit)
                  _DrumBeatLines(progress: _controller.value),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _applyTransform(
    NurseryAssetReactionKind kind,
    double t,
    Widget child,
  ) {
    double dx = 0;
    double dy = 0;
    double angle = 0;
    double scale = 1;
    switch (kind) {
      case NurseryAssetReactionKind.wag:
        final wave = math.sin(t * math.pi * 4) * (1 - t);
        dy = -8 * math.sin(t * math.pi);
        angle = wave * 0.10;
        scale = 1 + (0.035 * math.sin(t * math.pi));
        break;
      case NurseryAssetReactionKind.drumHit:
        final hit = math.sin(t * math.pi * 6) * (1 - t);
        dx = hit * 6;
        angle = hit * 0.045;
        scale = 1 + (0.06 * math.sin(t * math.pi));
        break;
      case NurseryAssetReactionKind.fly:
        final lift = math.sin(t * math.pi);
        dx = (1 - t) * -26;
        dy = -18 * lift;
        angle = -0.035 * (1 - t);
        scale = 0.90 + (0.10 * t);
        break;
      case NurseryAssetReactionKind.bounce:
        final bounce = math.sin(t * math.pi * 2).abs() * (1 - t);
        dy = -28 * bounce;
        scale = 0.94 + (0.06 * t);
        break;
      case NurseryAssetReactionKind.sway:
        final sway = math.sin(t * math.pi * 3) * (1 - t);
        angle = sway * 0.055;
        scale = 0.96 + (0.04 * t);
        break;
      case NurseryAssetReactionKind.pop:
        final pop = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
        scale = 0.78 + (0.22 * pop);
        break;
    }
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}

class _OneShotSparkle extends StatelessWidget {
  const _OneShotSparkle({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final visibility = math.sin(progress * math.pi).clamp(0.0, 1.0).toDouble();
    return IgnorePointer(
      child: Opacity(
        opacity: visibility,
        child: const Stack(
          children: [
            Positioned(
              top: 18,
              right: 28,
              child: Icon(Icons.auto_awesome_rounded, size: 26),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              child: Icon(Icons.star_rounded, size: 21),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrumBeatLines extends StatelessWidget {
  const _DrumBeatLines({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final visibility = math.sin(progress * math.pi).clamp(0.0, 1.0).toDouble();
    return IgnorePointer(
      child: Opacity(
        opacity: visibility,
        child: const Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note_rounded, size: 22),
                Icon(Icons.music_note_rounded, size: 28),
                Icon(Icons.music_note_rounded, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
