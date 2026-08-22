import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/learning/learning_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_learning_models.dart';
import '../../core/services/bright_audio_service.dart';
import 'nursery_lesson_screen.dart';

class NurseryHomeScreen extends StatelessWidget {
  const NurseryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = BrightQuestScope.contentOf(context);
    final pack = repository.nurseryPack;
    final controller = BrightQuestScope.of(context);
    if (pack == null) {
      return const Scaffold(
        body: Center(child: Text('Nursery Learning Garden is unavailable.')),
      );
    }
    final due = controller.dueNurseryReviewTasks(limit: 10);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nursery Learning Garden'),
        actions: [
          IconButton(
            tooltip: 'Read page introduction',
            onPressed: () => unawaited(
              BrightAudioService.instance.speak(
                'Welcome to the Nursery Learning Garden. Choose a skill to learn, try, practise, and remember.',
                manual: true,
              ),
            ),
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            _WelcomeCard(pack: pack, dueCount: due.length),
            if (due.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ReviewSection(pack: pack, due: due),
            ],
            const SizedBox(height: 20),
            for (final domain in pack.domains) ...[
              _DomainSection(pack: pack, domain: domain),
              const SizedBox(height: 22),
            ],
            _LetterGarden(pack: pack),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tracing is guide-path practice only. BrightQuest does not claim to score handwriting correctness. Learning progress comes from independent answers, transfer tasks, and later review.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.pack, required this.dueCount});

  final NurseryContentPack pack;
  final int dueCount;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn • Try • Use • Remember',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pack.skills.length} small skills with spoken instructions, worked examples, guided practice, independent activities and delayed review.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dueCount == 0
                        ? 'No review is due right now.'
                        : '$dueCount ${dueCount == 1 ? 'skill is' : 'skills are'} ready for a memory review.',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              );
              if (!wide) {
                return Column(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 58)),
                    const SizedBox(height: 8),
                    text,
                  ],
                );
              }
              return Row(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 68)),
                  const SizedBox(width: 20),
                  Expanded(child: text),
                ],
              );
            },
          ),
        ),
      );
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.pack, required this.due});

  final NurseryContentPack pack;
  final List<NurseryReviewTask> due;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to remember',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                  'These short checks appear later, after earlier learning evidence.'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final task in due)
                    if (pack.skillById(task.skillId) case final skill?)
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NurseryLessonScreen(
                              skillId: skill.id,
                              reviewMode: true,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(skill.title),
                      ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _DomainSection extends StatelessWidget {
  const _DomainSection({required this.pack, required this.domain});

  final NurseryContentPack pack;
  final NurseryDomain domain;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final skills = pack.skillsForDomain(domain.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${domain.emoji} ${domain.title}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(domain.description),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1000
                ? 4
                : width >= 700
                    ? 3
                    : width >= 440
                        ? 2
                        : 1;
            final gap = 12.0;
            final cardWidth = (width - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final skill in skills)
                  SizedBox(
                    width: cardWidth,
                    child: _SkillCard(
                      skill: skill,
                      mastery: controller.nurseryMasteryFor(skill.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill, required this.mastery});

  final NurserySkill skill;
  final NurserySkillMastery mastery;

  @override
  Widget build(BuildContext context) {
    final state = mastery.state;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NurseryLessonScreen(skillId: skill.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_stateIcon(state)),
                  const Spacer(),
                  Text(
                    _stateLabel(state),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                skill.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                skill.objective,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _stateProgress(state),
                minHeight: 7,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _stateLabel(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.notStarted => 'New',
        LearningEvidenceState.introduced => 'Started',
        LearningEvidenceState.practising => 'Practising',
        LearningEvidenceState.masteredNow => 'Learned',
        LearningEvidenceState.reviewDue => 'Review due',
        LearningEvidenceState.secure => 'Remembered',
        LearningEvidenceState.needsSupport => 'Try together',
      };

  static IconData _stateIcon(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.notStarted => Icons.spa_outlined,
        LearningEvidenceState.introduced => Icons.lightbulb_outline_rounded,
        LearningEvidenceState.practising => Icons.school_rounded,
        LearningEvidenceState.masteredNow => Icons.star_rounded,
        LearningEvidenceState.reviewDue => Icons.refresh_rounded,
        LearningEvidenceState.secure => Icons.verified_rounded,
        LearningEvidenceState.needsSupport => Icons.favorite_outline_rounded,
      };

  static double _stateProgress(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.notStarted => 0,
        LearningEvidenceState.introduced => 0.18,
        LearningEvidenceState.practising => 0.48,
        LearningEvidenceState.needsSupport => 0.36,
        LearningEvidenceState.masteredNow => 0.78,
        LearningEvidenceState.reviewDue => 0.86,
        LearningEvidenceState.secure => 1,
      };
}

class _LetterGarden extends StatefulWidget {
  const _LetterGarden({required this.pack});

  final NurseryContentPack pack;

  @override
  State<_LetterGarden> createState() => _LetterGardenState();
}

class _LetterGardenState extends State<_LetterGarden> {
  final Map<String, int> _exampleIndexByLetter = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final reducedMotion = BrightQuestScope.of(context).reducedMotionEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔤 A–Z Letter Garden',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap a letter to hear it. Tap again for another picture word. BrightQuest rotates through fresh examples before repeating.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final letter in widget.pack.letterAssociations)
              _buildLetterCard(context, letter, reducedMotion),
          ],
        ),
      ],
    );
  }

  Widget _buildLetterCard(
    BuildContext context,
    NurseryLetterAssociation letter,
    bool reducedMotion,
  ) {
    final index =
        (_exampleIndexByLetter[letter.uppercase] ?? 0) % letter.examples.length;
    final example = letter.examples[index];
    final semanticsLabel = '${letter.uppercase}, ${letter.lowercase}. '
        '${example.displayPhrase}. ${example.soundCue}.';
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final nextIndex = (index + 1) % letter.examples.length;
          final nextExample = letter.examples[nextIndex];
          setState(() {
            _exampleIndexByLetter[letter.uppercase] = nextIndex;
          });
          unawaited(
            BrightAudioService.instance.speak(
              '${letter.uppercase}, ${letter.lowercase}. '
              '${nextExample.displayPhrase}. ${nextExample.soundCue}.',
              manual: true,
            ),
          );
        },
        child: Container(
          width: 116,
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${letter.uppercase} ${letter.lowercase}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutBack,
                child: ClipRRect(
                  key: ValueKey('${letter.uppercase}:${example.word}'),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 64,
                    child: example.assetPath.isEmpty
                        ? Center(
                            child: Text(
                              example.picture,
                              style: const TextStyle(fontSize: 34),
                            ),
                          )
                        : Image.asset(
                            example.assetPath,
                            fit: BoxFit.cover,
                            cacheWidth: 128,
                            cacheHeight: 128,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                              child: Text(
                                example.picture,
                                style: const TextStyle(fontSize: 34),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                example.word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${index + 1}/${letter.examples.length}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
