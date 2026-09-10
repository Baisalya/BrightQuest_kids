import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/nursery/nursery_practice_generator.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_visuals.dart';
import 'nursery_game_value.dart';
import 'nursery_lesson_feedback.dart';

class NurseryReviewStage extends StatelessWidget {
  const NurseryReviewStage({
    required this.practice,
    required this.enabled,
    required this.feedback,
    required this.correct,
    required this.hintVisible,
    required this.reducedMotion,
    required this.onRead,
    required this.onHint,
    required this.onSubmit,
    required this.onDone,
    super.key,
  });

  final NurseryGeneratedPractice practice;
  final bool enabled;
  final String? feedback;
  final bool correct;
  final bool hintVisible;
  final bool reducedMotion;
  final VoidCallback onRead;
  final VoidCallback onHint;
  final ValueChanged<Object?> onSubmit;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final displayTokens = NurseryVisualResolver.compactVisualTokens(
      practice.visualTokens,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, size: 24),
                        SizedBox(width: 6),
                        Text(
                          'Memory Game',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (displayTokens.isNotEmpty) ...[
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final token in displayTokens)
                            NurseryVisualTokenCard(token: token),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      nurseryVisualFreeText(practice.prompt),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onRead,
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Hear it'),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.hasBoundedWidth
                            ? constraints.maxWidth
                            : 680.0;
                        final hasLongAnswer = practice.options.any(
                          (option) =>
                              nurserySpokenLabel(option.label).length > 28,
                        );
                        final columns = hasLongAnswer
                            ? 1
                            : width < 280
                                ? 1
                                : width < 620
                                    ? math.min(2, practice.options.length)
                                    : math.min(3, practice.options.length);
                        const gap = 12.0;
                        final cardWidth = columns <= 1
                            ? math.min(width, 520.0)
                            : (width - gap * (columns - 1)) / columns;
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (var index = 0;
                                index < practice.options.length;
                                index += 1)
                              SizedBox(
                                width: cardWidth,
                                child: NurseryGameAnswerCard(
                                  value: practice.options[index].label,
                                  skillId: practice.skillId,
                                  prompt: practice.prompt,
                                  index: index,
                                  enabled: enabled,
                                  reducedMotion: reducedMotion,
                                  minHeight: hasLongAnswer ? 104 : 116,
                                  onTap: () =>
                                      onSubmit(practice.options[index].id),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    if (feedback != null) ...[
                      const SizedBox(height: 14),
                      NurseryLessonFeedbackPanel(
                        message: feedback!,
                        correct: correct,
                        reducedMotion: reducedMotion,
                      ),
                    ],
                    if (correct) ...[
                      const SizedBox(height: 10),
                      NurseryCheerBurst(reducedMotion: reducedMotion),
                    ],
                    if (hintVisible && !correct) ...[
                      const SizedBox(height: 8),
                      NurseryHintPanel(
                        text: practice.explanation,
                        emphasized: false,
                        reducedMotion: reducedMotion,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: correct ? null : onHint,
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: const Text('Help'),
                        ),
                        FilledButton(
                          onPressed: onDone,
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
