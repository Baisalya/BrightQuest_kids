import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import 'nursery_game_chrome.dart';

class NurseryPairMatchGame extends StatefulWidget {
  const NurseryPairMatchGame({
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
  State<NurseryPairMatchGame> createState() => _NurseryPairMatchGameState();
}

class _NurseryPairMatchGameState extends State<NurseryPairMatchGame> {
  String? selectedLeft;
  final Map<String, String> matches = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final left = List<String>.from(widget.activity.payload['left'] as List);
    final right = List<String>.from(widget.activity.payload['right'] as List);
    final usedRight = matches.values.toSet();

    return Column(
      children: [
        const NurseryKidInstruction(
          icon: Icons.touch_app_rounded,
          title: 'Pick a card',
          subtitle: 'Then tap its partner.',
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MatchColumn(
                heading: '1. Pick',
                values: left,
                activity: widget.activity,
                reducedMotion: widget.reducedMotion,
                selectedValue: selectedLeft,
                matchedValues: matches.keys.toSet(),
                semanticPrefix: 'Pick',
                enabledFor: (_) => widget.enabled,
                onTap: (value) => setState(() => selectedLeft = value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MatchColumn(
                heading: '2. Match',
                values: right,
                activity: widget.activity,
                reducedMotion: widget.reducedMotion,
                selectedValue: matches[selectedLeft],
                matchedValues: usedRight,
                semanticPrefix: 'Match',
                enabledFor: (value) {
                  if (!widget.enabled || selectedLeft == null) return false;
                  final ownedBySelected = matches[selectedLeft] == value;
                  return !usedRight.contains(value) || ownedBySelected;
                },
                onTap: _matchRight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NurseryGameProgressMessage(
          icon: matches.isEmpty
              ? Icons.touch_app_rounded
              : matches.length < left.length
                  ? Icons.link_rounded
                  : Icons.check_circle_rounded,
          text: matches.isEmpty
              ? 'Choose the first card.'
              : matches.length < left.length
                  ? '${left.length - matches.length} ${left.length - matches.length == 1 ? 'pair' : 'pairs'} left.'
                  : 'All partners are connected!',
        ),
      ],
    );
  }

  void _matchRight(String value) {
    final left = List<String>.from(widget.activity.payload['left'] as List);
    final chosenLeft = selectedLeft;
    if (chosenLeft == null) return;
    final nextMatches = Map<String, String>.from(matches);
    nextMatches[chosenLeft] = value;
    setState(() {
      matches
        ..clear()
        ..addAll(nextMatches);
      selectedLeft = null;
    });
    if (nextMatches.length == left.length) {
      widget.onSubmitted(nextMatches);
    }
  }
}

class _MatchColumn extends StatelessWidget {
  const _MatchColumn({
    required this.heading,
    required this.values,
    required this.activity,
    required this.reducedMotion,
    required this.selectedValue,
    required this.matchedValues,
    required this.semanticPrefix,
    required this.enabledFor,
    required this.onTap,
  });

  final String heading;
  final List<String> values;
  final NurseryActivity activity;
  final bool reducedMotion;
  final String? selectedValue;
  final Set<String> matchedValues;
  final String semanticPrefix;
  final bool Function(String value) enabledFor;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          heading,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: NurserySelectionCard(
              value: value,
              activity: activity,
              reducedMotion: reducedMotion,
              selected: selectedValue == value,
              completed: matchedValues.contains(value),
              enabled: enabledFor(value),
              semanticsLabel: '$semanticPrefix ${nurserySpokenLabel(value)}',
              onTap: () => onTap(value),
            ),
          ),
      ],
    );
  }
}
