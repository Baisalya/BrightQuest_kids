import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/brightquest_scope.dart';

bool brightReduceMotion(BuildContext context) {
  final controller = BrightQuestScope.maybeOf(context);
  final media = MediaQuery.maybeOf(context);
  return (controller?.reducedMotionEnabled ?? false) ||
      (media?.disableAnimations ?? false);
}

/// Windows Flutter's accessibility bridge is sensitive to semantics nodes whose
/// geometry is continuously changed by reveal/scale transforms during startup.
/// Keep non-geometric polish (progress, glints, particles) enabled, but avoid
/// transform-driven semantics churn on Windows. Android keeps the full motion.
bool brightAvoidGeometryMotion(BuildContext context) {
  return brightReduceMotion(context) || Platform.isWindows;
}

class BrightReveal extends StatelessWidget {
  const BrightReveal({
    required this.child,
    this.duration = const Duration(milliseconds: 360),
    this.offset = const Offset(0, 0.045),
    this.beginScale = 0.97,
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Offset offset;
  final double beginScale;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (brightAvoidGeometryMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      child: child,
      builder: (context, value, child) {
        final opacityValue = value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: opacityValue,
          alwaysIncludeSemantics: true,
          child: FractionalTranslation(
            translation:
                Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
            child: Transform.scale(
              scale: beginScale + ((1 - beginScale) * value),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class BrightPressableScale extends StatefulWidget {
  const BrightPressableScale({
    required this.child,
    this.hoverScale = 1.018,
    this.pressedScale = 0.985,
    this.duration = const Duration(milliseconds: 150),
    super.key,
  });

  final Widget child;
  final double hoverScale;
  final double pressedScale;
  final Duration duration;

  @override
  State<BrightPressableScale> createState() => _BrightPressableScaleState();
}

class _BrightPressableScaleState extends State<BrightPressableScale> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = brightAvoidGeometryMotion(context);
    if (reduceMotion) return widget.child;
    final scale = _pressed
        ? widget.pressedScale
        : _hovered
            ? widget.hoverScale
            : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: reduceMotion ? Duration.zero : widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class BrightGlint extends StatelessWidget {
  const BrightGlint({
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 850),
    this.delay = const Duration(milliseconds: 120),
    super.key,
  });

  final Color color;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (brightReduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 240.0;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: -0.45, end: 1.25),
            duration: duration + delay,
            curve: Curves.easeInOutCubic,
            builder: (context, value, _) {
              final progress = value < -0.2 ? -0.45 : value;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: width * progress,
                    top: -60,
                    bottom: -60,
                    width: math.max(36.0, width * 0.16),
                    child: Transform.rotate(
                      angle: -0.32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0),
                              color.withValues(alpha: 0.28),
                              color.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class BrightAnimatedProgress extends StatelessWidget {
  const BrightAnimatedProgress({
    required this.value,
    this.minHeight = 8,
    this.backgroundColor,
    this.color = const Color(0xFF72CE36),
    this.duration = const Duration(milliseconds: 520),
    super.key,
  });

  final double value;
  final double minHeight;
  final Color? backgroundColor;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0).toDouble();
    if (brightReduceMotion(context)) {
      return LinearProgressIndicator(
        value: target,
        minHeight: minHeight,
        borderRadius: BorderRadius.circular(99),
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => LinearProgressIndicator(
        value: animatedValue,
        minHeight: minHeight,
        borderRadius: BorderRadius.circular(99),
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class BrightValuePop extends StatelessWidget {
  const BrightValuePop({required this.value, required this.child, super.key});

  final Object value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (brightAvoidGeometryMotion(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.72, end: 1).animate(animation),
        child: FadeTransition(
            opacity: animation, alwaysIncludeSemantics: true, child: child),
      ),
      child: KeyedSubtree(key: ValueKey<Object>(value), child: child),
    );
  }
}

class BrightCelebrationBurst extends StatelessWidget {
  const BrightCelebrationBurst({
    this.color = const Color(0xFFFFC928),
    this.particleCount = 14,
    this.size = const Size(220, 130),
    super.key,
  });

  final Color color;
  final int particleCount;
  final Size size;

  @override
  Widget build(BuildContext context) {
    if (brightReduceMotion(context)) return SizedBox.fromSize(size: size);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 780),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => CustomPaint(
          size: size,
          painter: _CelebrationPainter(
              progress: progress, color: color, particleCount: particleCount),
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter(
      {required this.progress,
      required this.color,
      required this.particleCount});

  final double progress;
  final Color color;
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final fade = (1 - ((progress - 0.58).clamp(0.0, 0.42) / 0.42))
        .clamp(0.0, 1.0)
        .toDouble();
    for (var i = 0; i < particleCount; i++) {
      final angle = (-math.pi * 0.88) +
          (math.pi * 0.76 * (i / math.max(1, particleCount - 1)));
      final distance =
          (42.0 + (i % 4) * 13.0) * Curves.easeOutCubic.transform(progress);
      final point = Offset(center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance);
      final radius = 3.0 + (i % 3).toDouble();
      final paint = Paint()
        ..color = Color.lerp(color, const Color(0xFFFF7B42), (i % 4) / 4)!
            .withValues(alpha: fade);
      if (i.isEven) {
        _drawStar(canvas, point, radius + 2, paint);
      } else {
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + progress * 1.8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero,
                  width: radius * 1.4,
                  height: radius * 3.2),
              const Radius.circular(2)),
          paint,
        );
        canvas.restore();
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * 0.46;
      final point = Offset(
          center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.particleCount != particleCount;
  }
}
