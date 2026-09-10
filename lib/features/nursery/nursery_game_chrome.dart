import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import 'nursery_game_value.dart';
import 'nursery_motion.dart';

class NurseryKidInstruction extends StatelessWidget {
  const NurseryKidInstruction({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NurseryGameProgressMessage extends StatelessWidget {
  const NurseryGameProgressMessage({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
}

/// Shared picture-first selectable card for matching and sorting games.
class NurserySelectionCard extends StatelessWidget {
  const NurserySelectionCard({
    required this.value,
    required this.activity,
    required this.reducedMotion,
    required this.selected,
    required this.completed,
    required this.enabled,
    required this.semanticsLabel,
    required this.onTap,
    this.footer,
    super.key,
  });

  final String value;
  final NurseryActivity activity;
  final bool reducedMotion;
  final bool selected;
  final bool completed;
  final bool enabled;
  final String semanticsLabel;
  final VoidCallback onTap;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticsLabel,
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : completed
                ? scheme.secondaryContainer
                : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NurseryGameValue(
                      value: value,
                      skillId: activity.skillId,
                      prompt: activity.prompt,
                      visualSize: 54,
                      reducedMotion: reducedMotion,
                    ),
                    if (completed)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                      ),
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    footer!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return NurseryMotionReaction(
      trigger: '$selected:$completed',
      cue: completed
          ? NurseryMotionCue.success
          : NurseryMotionCue.selection,
      reducedMotion: reducedMotion,
      animateOnMount: false,
      child: card,
    );
  }
}
