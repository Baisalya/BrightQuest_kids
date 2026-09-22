import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import 'nursery_game_chrome.dart';
import 'nursery_game_value.dart';
import 'nursery_sound.dart';

class NurserySortBucketsGame extends StatefulWidget {
  const NurserySortBucketsGame({
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
  State<NurserySortBucketsGame> createState() => _NurserySortBucketsGameState();
}

class _NurserySortBucketsGameState extends State<NurserySortBucketsGame> {
  String? selectedItem;
  final Map<String, String> assignments = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final items = List<String>.from(widget.activity.payload['items'] as List);
    final buckets =
        List<String>.from(widget.activity.payload['buckets'] as List);

    return Column(
      children: [
        const NurseryKidInstruction(
          icon: Icons.category_rounded,
          title: 'Pick a picture',
          subtitle: 'Then choose its group.',
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(
                width: 126,
                child: NurserySelectionCard(
                  value: item,
                  activity: widget.activity,
                  reducedMotion: widget.reducedMotion,
                  selected: selectedItem == item,
                  completed: assignments.containsKey(item),
                  enabled: widget.enabled,
                  semanticsLabel: 'Pick ${nurserySpokenLabel(item)}',
                  footer: assignments[item] == null
                      ? null
                      : 'In ${assignments[item]}',
                  onTap: () => setState(() => selectedItem = item),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Choose a group',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final bucket in buckets)
              Semantics(
                container: true,
                excludeSemantics: true,
                button: true,
                enabled: widget.enabled && selectedItem != null,
                label: 'Put in ${nurserySpokenLabel(bucket)}',
                child: FilledButton.tonal(
                  onPressed: !widget.enabled || selectedItem == null
                      ? null
                      : () {
                          playNurseryActionSound();
                          _assign(bucket, items.length);
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(132, 92),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: NurseryGameValue(
                    value: bucket,
                    skillId: widget.activity.skillId,
                    prompt: widget.activity.prompt,
                    visualSize: 48,
                    reducedMotion: widget.reducedMotion,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        NurseryGameProgressMessage(
          icon: assignments.isEmpty
              ? Icons.touch_app_rounded
              : assignments.length < items.length
                  ? Icons.inventory_2_rounded
                  : Icons.check_circle_rounded,
          text: assignments.isEmpty
              ? 'Choose a picture to start.'
              : assignments.length < items.length
                  ? '${items.length - assignments.length} ${items.length - assignments.length == 1 ? 'picture needs' : 'pictures need'} a group.'
                  : 'Everything has a home!',
        ),
      ],
    );
  }

  void _assign(String bucket, int itemCount) {
    final item = selectedItem;
    if (item == null) return;
    final nextAssignments = Map<String, String>.from(assignments);
    nextAssignments[item] = bucket;
    setState(() {
      assignments
        ..clear()
        ..addAll(nextAssignments);
      selectedItem = null;
    });
    if (nextAssignments.length == itemCount) {
      widget.onSubmitted(nextAssignments);
    }
  }
}
