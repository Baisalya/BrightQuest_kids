import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/content/content_activity.dart';
import '../../../../core/theme/app_theme.dart';
import '../activity_game_contract.dart';

class FractionBuilderActivity extends StatefulWidget {
  const FractionBuilderActivity({
    required this.activity,
    required this.locked,
    required this.onResponseChanged,
    super.key,
  });

  final ContentActivity activity;
  final bool locked;
  final GameActivityResponseChanged onResponseChanged;

  @override
  State<FractionBuilderActivity> createState() =>
      _FractionBuilderActivityState();
}

class _FractionBuilderActivityState extends State<FractionBuilderActivity> {
  final Set<int> _selected = <int>{};

  int get _total => widget.activity.payload['totalSlices'] as int;

  void _toggle(int index) {
    if (widget.locked) return;
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
    widget.onResponseChanged(
      GameActivityResponseSnapshot(
        value: _selected.length,
        ready: _selected.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numerator = widget.activity.payload['numerator'];
    final denominator = widget.activity.payload['denominator'];
    final target = numerator is int && denominator is int
        ? '$numerator/$denominator'
        : 'target fraction';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF1C8), Color(0xFFFFFAEE)],
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              const Text('🍕', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pizza order: $target',
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap pizza slices to build the exact order.',
                      style: TextStyle(
                        color: AppTheme.inkMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              _CountBadge(selected: _selected.length, total: _total),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Semantics(
            label:
                'Interactive pizza with $_total slices. ${_selected.length} selected.',
            child: SizedBox.square(
              dimension: 210,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: widget.locked
                    ? null
                    : (details) {
                        final index = _sliceAt(details.localPosition, 210);
                        if (index != null) _toggle(index);
                      },
                child: CustomPaint(
                  painter: _PizzaPainter(
                    total: _total,
                    selected: Set<int>.unmodifiable(_selected),
                  ),
                  child: Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        _selected.isEmpty
                            ? 'TAP'
                            : '${_selected.length}/$_total',
                        style: const TextStyle(
                          color: Color(0xFF9C5B25),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Slice controls',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.inkMuted,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          alignment: WrapAlignment.center,
          children: [
            for (var index = 0; index < _total; index += 1)
              _SliceControl(
                index: index,
                selected: _selected.contains(index),
                enabled: !widget.locked,
                onTap: () => _toggle(index),
              ),
          ],
        ),
      ],
    );
  }

  int? _sliceAt(Offset point, double dimension) {
    final center = Offset(dimension / 2, dimension / 2);
    final vector = point - center;
    final radius = dimension / 2;
    if (vector.distance < 34 || vector.distance > radius) return null;
    var angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    final sliceAngle = (math.pi * 2) / _total;
    return (angle / sliceAngle).floor().clamp(0, _total - 1).toInt();
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.selected, required this.total});

  final int selected;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFE7CF98)),
        ),
        child: Text(
          '$selected/$total',
          style: const TextStyle(
            color: Color(0xFF9C5B25),
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _SliceControl extends StatelessWidget {
  const _SliceControl({
    required this.index,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: 'Fraction slice ${index + 1}',
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFFFFC447) : const Color(0xFFFFF7DF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? const Color(0xFFB96C1B)
                    : const Color(0xFFE8D6A8),
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              selected ? '🍕' : '${index + 1}',
              style: TextStyle(
                fontSize: selected ? 20 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
}

class _PizzaPainter extends CustomPainter {
  const _PizzaPainter({required this.total, required this.selected});

  final int total;
  final Set<int> selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final slice = math.pi * 2 / total;
    const start = -math.pi / 2;

    final crust = Paint()
      ..color = const Color(0xFFC77A2D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 4, crust);

    for (var index = 0; index < total; index += 1) {
      final fill = Paint()
        ..color = selected.contains(index)
            ? const Color(0xFFFFC447)
            : const Color(0xFFFFE7A3)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        rect,
        start + index * slice,
        slice,
        true,
        fill,
      );
    }

    final lines = Paint()
      ..color = const Color(0xFFB96C1B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, lines);
    for (var index = 0; index < total; index += 1) {
      final angle = start + index * slice;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        lines,
      );
    }

    final pepperoni = Paint()..color = const Color(0xFFD65339);
    for (var index = 0; index < total; index += 1) {
      final angle = start + (index + .5) * slice;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * .63);
      canvas.drawCircle(point, math.max(3, radius * .045), pepperoni);
    }
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.selected.length != selected.length ||
      !oldDelegate.selected.containsAll(selected);
}
