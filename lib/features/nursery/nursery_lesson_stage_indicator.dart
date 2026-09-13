import 'package:flutter/material.dart';

import 'nursery_lesson_journey.dart';

class NurseryLessonStageIndicator extends StatelessWidget {
  const NurseryLessonStageIndicator({
    required this.stage,
    this.subtitle,
    this.compact = false,
    super.key,
  });

  final NurseryLessonJourneyStage stage;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = nurseryJourneyStageTitle(stage);
    final number = nurseryJourneyStageNumber(stage);
    return Semantics(
      header: true,
      label:
          'Step $number of 3. $title${subtitle == null ? '' : '. $subtitle'}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            CircleAvatar(
              radius: compact ? 13 : 15,
              backgroundColor: scheme.tertiary,
              foregroundColor: scheme.onTertiary,
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onTertiaryContainer,
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null)
              Text(
                '· $subtitle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
