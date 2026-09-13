import 'package:flutter/material.dart';

import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_visuals.dart';
import 'nursery_motion.dart';
import 'nursery_visual.dart';

class NurseryLessonFeedbackPanel extends StatelessWidget {
  const NurseryLessonFeedbackPanel({
    required this.message,
    required this.correct,
    required this.reducedMotion,
    super.key,
  });

  final String message;
  final bool correct;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final panel = Semantics(
      container: true,
      liveRegion: true,
      excludeSemantics: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: correct
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.refresh_rounded,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return NurseryMotionReaction(
      trigger: '$correct:$message',
      cue: correct ? NurseryMotionCue.success : NurseryMotionCue.retry,
      reducedMotion: reducedMotion,
      child: panel,
    );
  }
}

class NurseryHintPanel extends StatelessWidget {
  const NurseryHintPanel({
    required this.text,
    required this.reducedMotion,
    this.emphasized = true,
    super.key,
  });

  final String text;
  final bool emphasized;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final hint = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lightbulb_rounded, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            nurseryVisualFreeText(text),
            textAlign: TextAlign.center,
            style: emphasized
                ? const TextStyle(fontWeight: FontWeight.w800)
                : null,
          ),
        ),
      ],
    );
    return NurseryMotionReaction(
      trigger: text,
      cue: NurseryMotionCue.hint,
      reducedMotion: reducedMotion,
      child: hint,
    );
  }
}

class NurseryCheerBurst extends StatelessWidget {
  const NurseryCheerBurst({
    required this.reducedMotion,
    super.key,
  });

  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final cheer = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star_rounded, size: 28),
        const SizedBox(width: 8),
        NurseryVisual(
          spec: NurseryVisualResolver.celebration(),
          size: 42,
          decorative: true,
        ),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded, size: 28),
      ],
    );
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Correct answer celebration',
      child: NurseryMotionReaction(
        trigger: 'cheer',
        cue: NurseryMotionCue.success,
        reducedMotion: reducedMotion,
        child: cheer,
      ),
    );
  }
}

class NurseryAnswerExplanation extends StatelessWidget {
  const NurseryAnswerExplanation({
    required this.answer,
    required this.explanation,
    required this.visuals,
    super.key,
  });

  final String answer;
  final String explanation;
  final List<String> visuals;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              'Why: ${nurserySpokenLabel(answer)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              nurseryVisualFreeText(explanation),
              textAlign: TextAlign.center,
            ),
            if (visuals.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final token in visuals)
                    NurseryVisualTokenCard(token: token),
                ],
              ),
            ],
          ],
        ),
      );
}

class NurseryVisualTokenCard extends StatelessWidget {
  const NurseryVisualTokenCard({
    required this.token,
    super.key,
  });

  final String token;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: NurseryVisualToken(
          value: token,
          size: 46,
        ),
      );
}
