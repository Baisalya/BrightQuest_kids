import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_visuals.dart';
import 'nursery_asset_reaction.dart';
import 'nursery_lesson_feedback.dart';
import 'nursery_lesson_journey.dart';
import 'nursery_lesson_stage_indicator.dart';
import 'nursery_motion.dart';
import 'nursery_visual.dart';

class NurseryTeachingStage extends StatelessWidget {
  const NurseryTeachingStage({
    required this.skill,
    required this.reducedMotion,
    required this.letter,
    required this.letterExample,
    required this.onHearTeaching,
    required this.onHearLetter,
    required this.onAnotherWord,
    required this.onNextLetter,
    required this.onPlay,
    super.key,
  });

  final NurserySkill skill;
  final bool reducedMotion;
  final NurseryLetterAssociation? letter;
  final NurseryLetterExample? letterExample;
  final VoidCallback onHearTeaching;
  final VoidCallback onHearLetter;
  final VoidCallback onAnotherWord;
  final VoidCallback onNextLetter;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.center,
                child: NurseryLessonStageIndicator(
                  stage: NurseryLessonJourneyStage.study,
                  subtitle: 'Look, listen, then try',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  NurseryVisual(
                    spec: NurseryVisualResolver.forSkillId(
                      'observation',
                      'thinking',
                      semanticLabel: 'Look and listen',
                    ),
                    size: 34,
                    decorative: true,
                  ),
                  const Text(
                    'Look & listen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                skill.explanation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      skill.workedExample.headline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 14),
                    if (skill.domainId == 'alphabet' &&
                        letter != null &&
                        letterExample != null) ...[
                      const Text(
                        'Explore letter words',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NurseryLetterDiscoveryShowcase(
                        letter: letter!,
                        example: letterExample!,
                        reducedMotion: reducedMotion,
                        onHear: onHearLetter,
                        onAnotherWord: onAnotherWord,
                        onNextLetter: onNextLetter,
                      ),
                    ] else
                      NurseryWorkedExampleVisual(
                        skill: skill,
                        reducedMotion: reducedMotion,
                      ),
                    if (skill.domainId != 'alphabet') ...[
                      const SizedBox(height: 12),
                      Text(
                        skill.workedExample.caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onHearTeaching,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Hear it'),
                  ),
                  FilledButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Go to Guided Play'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(150, 52),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class NurseryLetterDiscoveryShowcase extends StatelessWidget {
  const NurseryLetterDiscoveryShowcase({
    required this.letter,
    required this.example,
    required this.reducedMotion,
    required this.onHear,
    required this.onAnotherWord,
    required this.onNextLetter,
    super.key,
  });

  final NurseryLetterAssociation letter;
  final NurseryLetterExample example;
  final bool reducedMotion;
  final VoidCallback onHear;
  final VoidCallback onAnotherWord;
  final VoidCallback onNextLetter;

  @override
  Widget build(BuildContext context) {
    final calmMotion = NurseryMotionPolicy.reduce(context, reducedMotion);
    final avoidGeometry = NurseryMotionPolicy.avoidGeometry(
      context,
      reducedMotion,
    );
    final animationDuration =
        calmMotion ? Duration.zero : const Duration(milliseconds: 420);
    final theme = Theme.of(context);
    final key = ValueKey('${letter.uppercase}:${example.word}');
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label:
          '${letter.uppercase}, ${letter.lowercase}. ${example.displayPhrase}. ${example.soundCue}.',
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: animationDuration,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              if (calmMotion) return child;
              if (avoidGeometry) {
                return FadeTransition(opacity: animation, child: child);
              }
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              );
              final scale = Tween<double>(begin: 0.88, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              );
              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: Container(
              key: key,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: NurseryAnimatedAsset(
                        key: ValueKey(
                          'asset:${letter.uppercase}:${example.word}',
                        ),
                        assetPath: example.assetPath,
                        word: example.word,
                        reducedMotion: reducedMotion,
                        fallback: NurseryLetterAssetFallback(
                          letter: letter,
                          example: example,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    example.displayPhrase,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    example.soundCue,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onHear,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Hear it'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAnotherWord,
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Another word'),
              ),
              FilledButton.tonalIcon(
                onPressed: onNextLetter,
                icon: const Icon(Icons.navigate_next_rounded),
                label: const Text('Next letter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${letter.examples.length} picture words for ${letter.uppercase} • new ones first',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class NurseryLetterAssetFallback extends StatelessWidget {
  const NurseryLetterAssetFallback({
    required this.letter,
    required this.example,
    super.key,
  });

  final NurseryLetterAssociation letter;
  final NurseryLetterExample example;

  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${letter.uppercase} ${letter.lowercase}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                ),
              ),
              NurseryVisualToken(
                value: example.picture,
                size: 92,
              ),
              Text(
                example.word,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
}

class NurseryWorkedExampleVisual extends StatelessWidget {
  const NurseryWorkedExampleVisual({
    required this.skill,
    required this.reducedMotion,
    super.key,
  });

  final NurserySkill skill;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final tokens = NurseryVisualResolver.compactVisualTokens(
      skill.workedExample.visuals,
    );
    final addition = skill.id.startsWith('math_add_');
    final calmMotion = NurseryMotionPolicy.reduce(context, reducedMotion);
    final avoidGeometry = NurseryMotionPolicy.avoidGeometry(
      context,
      reducedMotion,
    );
    return Semantics(
      label: 'Worked visual example: ${tokens.join(' ')}',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: calmMotion ? 1 : 0, end: 1),
        duration: calmMotion
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var index = 0; index < tokens.length; index += 1)
              Opacity(
                opacity: calmMotion ? 1 : 0.35 + (0.65 * value),
                alwaysIncludeSemantics: true,
                child: avoidGeometry
                    ? NurseryVisualTokenCard(token: tokens[index])
                    : Transform.translate(
                        offset: addition
                            ? Offset(
                                (1 - value) *
                                    (index < tokens.length / 2 ? -28 : 28),
                                0,
                              )
                            : Offset(0, (1 - value) * 10),
                        child: Transform.scale(
                          scale: 0.82 + (0.18 * value),
                          child: NurseryVisualTokenCard(token: tokens[index]),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
