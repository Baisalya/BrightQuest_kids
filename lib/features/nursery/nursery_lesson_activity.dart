import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_visuals.dart';
import 'nursery_interactions.dart';
import 'nursery_lesson_feedback.dart';
import 'nursery_lesson_journey.dart';
import 'nursery_motion.dart';
import 'nursery_lesson_stage_indicator.dart';
import 'nursery_play_board.dart';
import 'nursery_visual.dart';

class NurseryActivityStage extends StatelessWidget {
  const NurseryActivityStage({
    required this.skill,
    required this.activity,
    required this.activityIndex,
    required this.activityCount,
    required this.retries,
    required this.hintLevel,
    required this.correct,
    required this.feedback,
    required this.reducedMotion,
    required this.answerLabel,
    required this.answerExplanation,
    required this.answerVisuals,
    required this.hasNextActivity,
    required this.onRead,
    required this.onSubmit,
    required this.onHint,
    required this.onContinue,
    super.key,
  });

  final NurserySkill skill;
  final NurseryActivity activity;
  final int activityIndex;
  final int activityCount;
  final int retries;
  final int hintLevel;
  final bool correct;
  final String? feedback;
  final bool reducedMotion;
  final String answerLabel;
  final String answerExplanation;
  final List<String> answerVisuals;
  final bool hasNextActivity;
  final VoidCallback onRead;
  final ValueChanged<Object?> onSubmit;
  final VoidCallback onHint;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final simpleTitle = nurserySimpleGameLabel(
      activity,
      activityIndex,
      activityCount,
    );
    final portalStyle = nurseryPortalStyleFor(skill, activity);
    final promptText = nurseryVisualFreeText(activity.prompt);
    final promptVisualTokens = activity.visualTokens;
    final hasPromptVisuals = promptVisualTokens.isNotEmpty ||
        NurseryVisualResolver.visualsInText(activity.prompt).isNotEmpty;
    final journeyStage = activity.phase == 'guided'
        ? NurseryLessonJourneyStage.guidedPlay
        : NurseryLessonJourneyStage.independentGame;
    final stageSubtitle = activity.phase == 'guided'
        ? 'We do this together'
        : activity.phase == 'transfer'
            ? 'Star challenge'
            : activity.phase == 'practice'
                ? 'Practice trail'
                : 'Your turn';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: NurseryLessonStageIndicator(
                stage: journeyStage,
                subtitle: stageSubtitle,
              ),
            ),
            const SizedBox(height: 14),
            NurseryGameSceneBanner(
              title: simpleTitle,
              subtitle: nurserySimpleGameHint(activity),
              visual: portalStyle.visual,
              reducedMotion: reducedMotion,
            ),
            const SizedBox(height: 14),
            if (hasPromptVisuals) ...[
              NurseryPromptVisuals(
                text: activity.prompt,
                tokens: promptVisualTokens,
                size: 92,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              promptText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Center(
              child: IconButton.filledTonal(
                tooltip: 'Hear the question',
                onPressed: onRead,
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (activity.phase == 'guided') ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Try it with me. You can tap Help anytime.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            NurseryActivityInteraction(
              key: ValueKey('${activity.id}:$retries:$hintLevel'),
              activity: activity,
              enabled: !correct,
              reducedMotion: reducedMotion,
              onSubmitted: onSubmit,
            ),
            const SizedBox(height: 14),
            if (feedback != null)
              NurseryLessonFeedbackPanel(
                message: feedback!,
                correct: correct,
                reducedMotion: reducedMotion,
              ),
            if (correct) ...[
              const SizedBox(height: 10),
              NurseryCheerBurst(reducedMotion: reducedMotion),
            ],
            if (hintLevel > 0 && !correct) ...[
              const SizedBox(height: 10),
              NurseryHintPanel(
                text: activity.hint,
                reducedMotion: reducedMotion,
              ),
            ],
            if (correct && !activity.isTrace) ...[
              const SizedBox(height: 12),
              NurseryAnswerExplanation(
                answer: answerLabel,
                explanation: answerExplanation,
                visuals: answerVisuals,
              ),
            ],
            const SizedBox(height: 16),
            if (!correct)
              Center(
                child: TextButton.icon(
                  onPressed: onHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('Help'),
                ),
              )
            else
              FilledButton.icon(
                onPressed: onContinue,
                icon: Icon(
                  hasNextActivity
                      ? Icons.navigate_next_rounded
                      : Icons.celebration_rounded,
                ),
                label: Text(hasNextActivity ? 'Next Game' : 'Done!'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NurseryGameSceneBanner extends StatelessWidget {
  const NurseryGameSceneBanner({
    required this.title,
    required this.subtitle,
    required this.visual,
    required this.reducedMotion,
    super.key,
  });

  final String title;
  final String subtitle;
  final NurseryVisualSpec visual;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          NurseryVisual(
            spec: visual,
            size: 52,
            reducedMotion: reducedMotion,
            decorative: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
    return NurseryMotionReveal(
      reducedMotion: reducedMotion,
      duration: const Duration(milliseconds: 420),
      beginScale: .90,
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}
