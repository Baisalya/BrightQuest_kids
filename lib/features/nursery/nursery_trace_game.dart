import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import 'nursery_game_chrome.dart';
import 'nursery_motion.dart';

class NurseryTraceGame extends StatefulWidget {
  const NurseryTraceGame({
    required this.activity,
    required this.enabled,
    required this.onSubmitted,
    required this.reducedMotion,
    super.key,
  });

  final NurseryActivity activity;
  final bool enabled;
  final ValueChanged<Object?> onSubmitted;
  final bool reducedMotion;

  @override
  State<NurseryTraceGame> createState() => _NurseryTraceGameState();
}

class _NurseryTraceGameState extends State<NurseryTraceGame> {
  final List<int> reached = <int>[];
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    final points = (widget.activity.payload['checkpoints'] as List)
        .whereType<Map>()
        .map(
          (raw) => Offset(
            (raw['x'] as num).toDouble(),
            (raw['y'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
    final tolerance =
        (widget.activity.payload['tolerance'] as num?)?.toDouble() ?? 0.14;
    final label = widget.activity.payload['label'] as String? ?? '';
    final nextNumber = points.isEmpty ? 0 : math.min(reached.length + 1, points.length);

    return Column(
      children: [
        NurseryKidInstruction(
          icon: Icons.gesture_rounded,
          title: reached.length == points.length
              ? 'Trace complete!'
              : reached.isEmpty
                  ? 'Start at 1'
                  : 'Now find $nextNumber',
          subtitle: 'Follow the dots in order.',
        ),
        const SizedBox(height: 12),
        Semantics(
          label:
              'Tracing practice for $label. Touch or drag through numbered guide dots in order.',
          child: AspectRatio(
            aspectRatio: 1.35,
            child: LayoutBuilder(
              builder: (context, constraints) {
                void visit(Offset local) {
                  if (!widget.enabled ||
                      submitted ||
                      reached.length >= points.length) {
                    return;
                  }
                  final normalized = Offset(
                    local.dx / constraints.maxWidth,
                    local.dy / constraints.maxHeight,
                  );
                  final next = points[reached.length];
                  if ((normalized - next).distance <= tolerance) {
                    setState(() => reached.add(reached.length));
                    if (reached.length == points.length) {
                      submitted = true;
                      widget.onSubmitted(List<int>.from(reached));
                    }
                  }
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => visit(details.localPosition),
                  onPanUpdate: (details) => visit(details.localPosition),
                  onTapDown: (details) => visit(details.localPosition),
                  child: CustomPaint(
                    painter: _TraceGuidePainter(
                      label: label,
                      points: points,
                      reachedCount: reached.length,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        NurseryMotionReaction(
          trigger: reached.length,
          cue: reached.length == points.length
              ? NurseryMotionCue.success
              : NurseryMotionCue.progress,
          reducedMotion: widget.reducedMotion,
          animateOnMount: false,
          child: NurseryGameProgressMessage(
            icon: reached.length == points.length
                ? Icons.check_circle_rounded
                : Icons.gesture_rounded,
            text: reached.length == points.length
                ? 'Trace complete!'
                : '${reached.length} of ${points.length} dots done',
          ),
        ),
        if (reached.isNotEmpty && reached.length < points.length)
          TextButton.icon(
            onPressed: !widget.enabled ? null : _reset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Start Again'),
          ),
      ],
    );
  }

  void _reset() => setState(() {
        reached.clear();
        submitted = false;
      });
}

class _TraceGuidePainter extends CustomPainter {
  const _TraceGuidePainter({
    required this.label,
    required this.points,
    required this.reachedCount,
    required this.colorScheme,
  });

  final String label;
  final List<Offset> points;
  final int reachedCount;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = colorScheme.surfaceContainerHighest;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.drawRRect(rect, background);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: size.shortestSide * .55,
          fontWeight: FontWeight.w900,
          color: colorScheme.primary.withValues(alpha: .15),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    if (points.length > 1) {
      final guide = Paint()
        ..color = colorScheme.outline.withValues(alpha: .34)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_pathFor(points, size, points.length), guide);

      if (reachedCount > 1) {
        final completed = Paint()
          ..color = colorScheme.primary
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(_pathFor(points, size, reachedCount), completed);
      }
    }

    for (var index = 0; index < points.length; index += 1) {
      final point = Offset(
        points[index].dx * size.width,
        points[index].dy * size.height,
      );
      final isReached = index < reachedCount;
      final isNext = index == reachedCount;
      if (isNext) {
        canvas.drawCircle(
          point,
          20,
          Paint()..color = colorScheme.primary.withValues(alpha: .18),
        );
      }
      canvas.drawCircle(
        point,
        isNext ? 16 : 14,
        Paint()
          ..color = isReached ? colorScheme.primary : colorScheme.surface,
      );
      if (!isReached) {
        canvas.drawCircle(
          point,
          isNext ? 16 : 14,
          Paint()
            ..color = isNext ? colorScheme.primary : colorScheme.outlineVariant
            ..style = PaintingStyle.stroke
            ..strokeWidth = isNext ? 3 : 2,
        );
      }
      final number = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: isReached ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      number.paint(
        canvas,
        Offset(point.dx - number.width / 2, point.dy - number.height / 2),
      );
    }
  }

  static Path _pathFor(List<Offset> points, Size size, int count) {
    final path = Path();
    final safeCount = count.clamp(0, points.length).toInt();
    for (var index = 0; index < safeCount; index += 1) {
      final point = Offset(
        points[index].dx * size.width,
        points[index].dy * size.height,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _TraceGuidePainter oldDelegate) =>
      oldDelegate.reachedCount != reachedCount ||
      oldDelegate.label != label ||
      oldDelegate.colorScheme != colorScheme;
}
