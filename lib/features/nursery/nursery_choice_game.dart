import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import 'nursery_game_value.dart';

class NurseryChoiceGame extends StatelessWidget {
  const NurseryChoiceGame({
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.hasBoundedWidth ? constraints.maxWidth : 680.0;
        final hasLongAnswer = activity.options.any(
          (option) => nurserySpokenLabel(option.label).length > 28,
        );
        final columns = hasLongAnswer
            ? 1
            : width < 280
                ? 1
                : width < 620
                    ? math.min(2, activity.options.length)
                    : math.min(3, activity.options.length);
        const gap = 12.0;
        final available = math.max(0.0, width - gap * (columns - 1));
        final cardWidth =
            columns <= 1 ? math.min(width, 520.0) : available / columns;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < activity.options.length; index += 1)
              SizedBox(
                width: cardWidth,
                child: NurseryGameAnswerCard(
                  value: activity.options[index].label,
                  skillId: activity.skillId,
                  prompt: activity.prompt,
                  index: index,
                  enabled: enabled,
                  reducedMotion: reducedMotion,
                  minHeight: hasLongAnswer ? 104 : 122,
                  onTap: () => onSubmitted(activity.options[index].id),
                ),
              ),
          ],
        );
      },
    );
  }
}
