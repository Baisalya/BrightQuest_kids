import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_spoken_labels.dart';

class NurseryActivityInteraction extends StatelessWidget {
  const NurseryActivityInteraction({
    required this.activity,
    required this.onSubmitted,
    required this.enabled,
    required this.reducedMotion,
    super.key,
  });

  final NurseryActivity activity;
  final ValueChanged<Object?> onSubmitted;
  final bool enabled;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return switch (activity.interaction) {
      'choice' => _ChoiceInteraction(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
          reducedMotion: reducedMotion,
        ),
      'pairMatch' => _PairMatchInteraction(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
        ),
      'sortBuckets' => _SortBucketsInteraction(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
        ),
      'trace' => _TraceInteraction(
          activity: activity,
          enabled: enabled,
          onSubmitted: onSubmitted,
        ),
      _ => const Text('This Nursery interaction is not available.'),
    };
  }
}

class _ChoiceInteraction extends StatelessWidget {
  const _ChoiceInteraction({
    required this.activity,
    required this.enabled,
    required this.onSubmitted,
    required this.reducedMotion,
  });

  final NurseryActivity activity;
  final bool enabled;
  final ValueChanged<Object?> onSubmitted;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var index = 0; index < activity.options.length; index += 1)
          _AnswerBubble(
            option: activity.options[index],
            index: index,
            enabled: enabled,
            reducedMotion: reducedMotion,
            onTap: () => onSubmitted(activity.options[index].id),
          ),
      ],
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({
    required this.option,
    required this.index,
    required this.enabled,
    required this.reducedMotion,
    required this.onTap,
  });

  final NurseryOption option;
  final int index;
  final bool enabled;
  final bool reducedMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: enabled,
      label: 'Answer ${nurserySpokenLabel(option.label)}',
      child: Material(
        color:
            enabled ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 112,
              minHeight: 82,
              maxWidth: 220,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    index.isEven ? '⭐' : '✨',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (reducedMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1),
      duration: Duration(milliseconds: 260 + index * 60),
      curve: Curves.easeOutBack,
      builder: (context, value, animatedChild) => Transform.scale(
        scale: value,
        child: animatedChild,
      ),
      child: child,
    );
  }
}

class _PairMatchInteraction extends StatefulWidget {
  const _PairMatchInteraction({
    required this.activity,
    required this.enabled,
    required this.onSubmitted,
  });

  final NurseryActivity activity;
  final bool enabled;
  final ValueChanged<Object?> onSubmitted;

  @override
  State<_PairMatchInteraction> createState() => _PairMatchInteractionState();
}

class _PairMatchInteractionState extends State<_PairMatchInteraction> {
  String? selectedLeft;
  final Map<String, String> matches = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final left = List<String>.from(widget.activity.payload['left'] as List);
    final right = List<String>.from(widget.activity.payload['right'] as List);
    return Column(
      children: [
        const Text(
          'Choose one item on the left, then its partner on the right.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final value in left)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: widget.enabled
                              ? () => setState(() => selectedLeft = value)
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(80, 54),
                            backgroundColor: selectedLeft == value
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                          ),
                          child: Text(
                            matches[value] == null
                                ? value
                                : '$value  →  ${matches[value]}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  for (final value in right)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: !widget.enabled || selectedLeft == null
                              ? null
                              : () {
                                  final nextMatches =
                                      Map<String, String>.from(matches);
                                  nextMatches[selectedLeft!] = value;
                                  setState(() {
                                    matches
                                      ..clear()
                                      ..addAll(nextMatches);
                                    selectedLeft = null;
                                  });
                                  if (nextMatches.length == left.length) {
                                    widget.onSubmitted(nextMatches);
                                  }
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(80, 54),
                          ),
                          child:
                              Text(value, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          matches.isEmpty
              ? 'Pick a card to begin the match.'
              : matches.length < left.length
                  ? 'Nice! ${left.length - matches.length} ${left.length - matches.length == 1 ? 'match' : 'matches'} to go.'
                  : 'All partners are connected!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _SortBucketsInteraction extends StatefulWidget {
  const _SortBucketsInteraction({
    required this.activity,
    required this.enabled,
    required this.onSubmitted,
  });

  final NurseryActivity activity;
  final bool enabled;
  final ValueChanged<Object?> onSubmitted;

  @override
  State<_SortBucketsInteraction> createState() =>
      _SortBucketsInteractionState();
}

class _SortBucketsInteractionState extends State<_SortBucketsInteraction> {
  String? selectedItem;
  final Map<String, String> assignments = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final items = List<String>.from(widget.activity.payload['items'] as List);
    final buckets =
        List<String>.from(widget.activity.payload['buckets'] as List);
    return Column(
      children: [
        const Text(
          'Choose an item, then choose the group where it belongs.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              OutlinedButton(
                onPressed: widget.enabled
                    ? () => setState(() => selectedItem = item)
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 54),
                  backgroundColor: selectedItem == item
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Text(
                  assignments[item] == null
                      ? item
                      : '$item → ${assignments[item]}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final bucket in buckets)
              FilledButton.tonalIcon(
                onPressed: !widget.enabled || selectedItem == null
                    ? null
                    : () {
                        final nextAssignments =
                            Map<String, String>.from(assignments);
                        nextAssignments[selectedItem!] = bucket;
                        setState(() {
                          assignments
                            ..clear()
                            ..addAll(nextAssignments);
                          selectedItem = null;
                        });
                        if (nextAssignments.length == items.length) {
                          widget.onSubmitted(nextAssignments);
                        }
                      },
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(bucket),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          assignments.isEmpty
              ? 'Choose a picture, then send it to a basket.'
              : assignments.length < items.length
                  ? '${items.length - assignments.length} ${items.length - assignments.length == 1 ? 'item' : 'items'} still need a home.'
                  : 'Everything is in a basket!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _TraceInteraction extends StatefulWidget {
  const _TraceInteraction({
    required this.activity,
    required this.enabled,
    required this.onSubmitted,
  });

  final NurseryActivity activity;
  final bool enabled;
  final ValueChanged<Object?> onSubmitted;

  @override
  State<_TraceInteraction> createState() => _TraceInteractionState();
}

class _TraceInteractionState extends State<_TraceInteraction> {
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

    return Column(
      children: [
        const Text(
          'Tracing practice follows broad guide dots only. It does not score handwriting correctness.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
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
        Text('${reached.length} of ${points.length} guide dots reached'),
        TextButton.icon(
          onPressed: !widget.enabled
              ? null
              : () => setState(() {
                    reached.clear();
                    submitted = false;
                  }),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Start tracing again'),
        ),
      ],
    );
  }
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
          fontSize: size.shortestSide * 0.55,
          fontWeight: FontWeight.w900,
          color: colorScheme.primary.withValues(alpha: 0.15),
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
        ..color = colorScheme.primary.withValues(alpha: 0.30)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var index = 0; index < points.length; index += 1) {
        final point = Offset(
            points[index].dx * size.width, points[index].dy * size.height);
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, guide);
    }

    for (var index = 0; index < points.length; index += 1) {
      final point =
          Offset(points[index].dx * size.width, points[index].dy * size.height);
      final reached = index < reachedCount;
      canvas.drawCircle(
        point,
        14,
        Paint()..color = reached ? colorScheme.primary : colorScheme.surface,
      );
      final number = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: reached ? colorScheme.onPrimary : colorScheme.onSurface,
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

  @override
  bool shouldRepaint(covariant _TraceGuidePainter oldDelegate) =>
      oldDelegate.reachedCount != reachedCount ||
      oldDelegate.label != label ||
      oldDelegate.colorScheme != colorScheme;
}
