import 'package:flutter/material.dart';

class NumberLinePrimitive extends StatelessWidget {
  const NumberLinePrimitive({
    required this.min,
    required this.max,
    required this.value,
    super.key,
  });

  final int min;
  final int max;
  final int value;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= min ? min + 1 : max;
    final fraction = ((value - min) / (safeMax - min)).clamp(0.0, 1.0);
    return Semantics(
      label: 'Number line from $min to $safeMax. Marker at $value.',
      child: Column(
        children: [
          LinearProgressIndicator(value: fraction.toDouble(), minHeight: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('$min'), Text('$value'), Text('$safeMax')],
          ),
        ],
      ),
    );
  }
}

class BaseTenBlocksPrimitive extends StatelessWidget {
  const BaseTenBlocksPrimitive({required this.value, super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    final safe = value.clamp(0, 999).toInt();
    final hundreds = safe ~/ 100;
    final tens = (safe % 100) ~/ 10;
    final ones = safe % 10;
    return Semantics(
      label:
          '$safe represented as $hundreds hundreds, $tens tens and $ones ones.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PlaceChip(label: 'Hundreds', value: hundreds),
          _PlaceChip(label: 'Tens', value: tens),
          _PlaceChip(label: 'Ones', value: ones),
        ],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label: $value'));
}

class FractionStripPrimitive extends StatelessWidget {
  const FractionStripPrimitive({
    required this.numerator,
    required this.denominator,
    super.key,
  });

  final int numerator;
  final int denominator;

  @override
  Widget build(BuildContext context) {
    final safeDenominator = denominator.clamp(1, 12).toInt();
    final safeNumerator = numerator.clamp(0, safeDenominator).toInt();
    return Semantics(
      label: 'Fraction $safeNumerator out of $safeDenominator equal parts.',
      child: Row(
        children: List<Widget>.generate(
          safeDenominator,
          (index) => Expanded(
            child: Container(
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary),
                color: index < safeNumerator
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccessibleOrderPrimitive extends StatelessWidget {
  const AccessibleOrderPrimitive({
    required this.items,
    required this.onMove,
    super.key,
  });

  final List<String> items;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) => Column(
        children: List<Widget>.generate(items.length, (index) {
          return Card(
            child: ListTile(
              title: Text(items[index]),
              leading: const Icon(Icons.drag_indicator_rounded),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Move up',
                    onPressed:
                        index == 0 ? null : () => onMove(index, index - 1),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    onPressed: index == items.length - 1
                        ? null
                        : () => onMove(index, index + 1),
                    icon: const Icon(Icons.arrow_downward_rounded),
                  ),
                ],
              ),
            ),
          );
        }),
      );
}

class EvidenceHighlighterPrimitive extends StatelessWidget {
  const EvidenceHighlighterPrimitive({
    required this.sentences,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<String> sentences;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) => Column(
        children: List<Widget>.generate(sentences.length, (index) {
          final active = selected.contains(index);
          return Semantics(
            selected: active,
            button: true,
            label: 'Evidence sentence ${index + 1}. ${sentences[index]}',
            child: ListTile(
              selected: active,
              title: Text(sentences[index]),
              leading: Icon(
                active ? Icons.highlight_rounded : Icons.article_outlined,
              ),
              onTap: () => onToggle(index),
            ),
          );
        }),
      );
}

class DiagramClassifierPrimitive extends StatelessWidget {
  const DiagramClassifierPrimitive({
    required this.labels,
    required this.selectedLabel,
    required this.onSelected,
    super.key,
  });

  final List<String> labels;
  final String? selectedLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: labels
            .map(
              (label) => ChoiceChip(
                label: Text(label),
                selected: selectedLabel == label,
                onSelected: (_) => onSelected(label),
              ),
            )
            .toList(growable: false),
      );
}

class PredictObserveExplainPrimitive extends StatelessWidget {
  const PredictObserveExplainPrimitive({
    required this.prediction,
    required this.observation,
    required this.explanation,
    super.key,
  });

  final String prediction;
  final String observation;
  final String explanation;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EvidenceCard(title: 'Predict', body: prediction),
          _EvidenceCard(title: 'Observe', body: observation),
          _EvidenceCard(title: 'Explain', body: explanation),
        ],
      );
}

class MapPathPrimitive extends StatelessWidget {
  const MapPathPrimitive({required this.steps, super.key});
  final List<String> steps;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Map path: ${steps.join(', ')}',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: steps
              .asMap()
              .entries
              .map((entry) =>
                  Chip(label: Text('${entry.key + 1}. ${entry.value}')))
              .toList(growable: false),
        ),
      );
}

class CodingTracePrimitive extends StatelessWidget {
  const CodingTracePrimitive({
    required this.commands,
    required this.activeIndex,
    super.key,
  });

  final List<String> commands;
  final int activeIndex;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List<Widget>.generate(commands.length, (index) {
          final active = index == activeIndex;
          return ListTile(
            selected: active,
            leading: Text('${index + 1}'),
            title: Text(commands[index]),
            trailing: active ? const Icon(Icons.play_arrow_rounded) : null,
          );
        }),
      );
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
        ),
      );
}
