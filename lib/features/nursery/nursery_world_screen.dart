import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/learning/learning_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_learning_models.dart';
import '../../core/nursery/nursery_visuals.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import 'nursery_domain_presentation.dart';
import 'nursery_lesson_screen.dart';
import 'nursery_visual.dart';
import 'nursery_world_plan.dart';

class NurseryWorldScreen extends StatelessWidget {
  const NurseryWorldScreen({required this.pack, required this.domain, super.key});

  final NurseryContentPack pack;
  final NurseryDomain domain;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final dueSkillIds = controller
        .dueNurseryReviewTasks(limit: 20)
        .map((task) => task.skillId);
    final worldPlan = NurseryWorldPlanner.build(
      pack: pack,
      domainId: domain.id,
      masteryFor: controller.nurseryMasteryFor,
      dueSkillIds: dueSkillIds,
    );
    final recommended = worldPlan.pathById(worldPlan.recommendedPathId)!;
    return Scaffold(
      body: BrightPageBackground(
        primary: const Color(0xFFF4FFF7),
        secondary: const Color(0xFFFFFAE8),
        child: Column(
          children: [
            BrightHeader(
              showBack: true,
              title: nurseryDomainTitle(domain),
            ),
            Expanded(
              child: ListView(
                key: PageStorageKey<String>('nursery-world-${domain.id}-paths'),
                children: [
                  BrightResponsive(
                    maxWidth: 980,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    builder: (context, _) => _WorldNextPathCard(
                      pack: pack,
                      domain: domain,
                      path: recommended,
                    ),
                  ),
                  if (domain.id == 'alphabet')
                    BrightResponsive(
                      maxWidth: 980,
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                      builder: (context, _) => _LetterBook(pack: pack),
                    ),
                  BrightResponsive(
                    maxWidth: 980,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                    builder: (context, _) => _LearningPathSection(
                      pack: pack,
                      domain: domain,
                      plan: worldPlan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldNextPathCard extends StatelessWidget {
  const _WorldNextPathCard({
    required this.pack,
    required this.domain,
    required this.path,
  });

  final NurseryContentPack pack;
  final NurseryDomain domain;
  final NurseryLearningPathPlan path;

  @override
  Widget build(BuildContext context) {
    final color = nurseryDomainColor(domain.id);
    return Container(
      key: const Key('nursery-world-next-path'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 560;
          final visual = Container(
            width: horizontal ? 92 : 76,
            height: horizontal ? 92 : 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: NurseryVisual(
              spec: NurseryVisualResolver.forLearningPath(
                path.definition.id,
                domain.id,
                semanticLabel: path.definition.title,
              ),
              size: horizontal ? 62 : 52,
              decorative: true,
            ),
          );
          final details = Column(
            crossAxisAlignment:
                horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text(
                path.recommendedReviewMode ? 'Ready to play again' : 'Your next path',
                textAlign: horizontal ? TextAlign.left : TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                path.definition.title,
                textAlign: horizontal ? TextAlign.left : TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                path.definition.subtitle,
                textAlign: horizontal ? TextAlign.left : TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('nursery-world-play-next'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                onPressed: () => _openLearningPath(
                  context,
                  pack: pack,
                  domain: domain,
                  path: path,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Play next',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
          if (!horizontal) {
            return Column(
              children: [visual, const SizedBox(height: 12), details],
            );
          }
          return Row(
            children: [
              visual,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _LearningPathSection extends StatelessWidget {
  const _LearningPathSection({
    required this.pack,
    required this.domain,
    required this.plan,
  });

  final NurseryContentPack pack;
  final NurseryDomain domain;
  final NurseryWorldPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = nurseryDomainColor(domain.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pick a learning path',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          'Small steps make learning easy',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .66),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            final gap = 12.0;
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var index = 0; index < plan.paths.length; index += 1)
                  SizedBox(
                    width: width,
                    child: _LearningPathCard(
                      pack: pack,
                      domain: domain,
                      path: plan.paths[index],
                      step: index + 1,
                      recommended:
                          plan.paths[index].definition.id == plan.recommendedPathId,
                      color: color,
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

class _LearningPathCard extends StatelessWidget {
  const _LearningPathCard({
    required this.pack,
    required this.domain,
    required this.path,
    required this.step,
    required this.recommended,
    required this.color,
  });

  final NurseryContentPack pack;
  final NurseryDomain domain;
  final NurseryLearningPathPlan path;
  final int step;
  final bool recommended;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final status = path.complete
        ? 'All done'
        : path.startedSkills == 0
            ? 'Ready to start'
            : '${path.startedSkills} of ${path.totalSkills} played';
    return Semantics(
      button: true,
      label: 'Step $step. ${path.definition.title}. $status. Tap to open.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('nursery-path-${path.definition.id}'),
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openLearningPath(
            context,
            pack: pack,
            domain: domain,
            path: path,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 142),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: recommended ? .42 : .15),
                width: recommended ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: recommended ? .10 : .045),
                  blurRadius: recommended ? 16 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: NurseryVisual(
                        spec: NurseryVisualResolver.forLearningPath(
                          path.definition.id,
                          domain.id,
                          semanticLabel: path.definition.title,
                        ),
                        size: 48,
                        decorative: true,
                      ),
                    ),
                    Positioned(
                      left: -6,
                      top: -8,
                      child: Container(
                        width: 27,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '$step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recommended)
                        Text(
                          'NEXT',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                        ),
                      Text(
                        path.definition.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        path.definition.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: path.progress,
                                minHeight: 6,
                                backgroundColor: color.withValues(alpha: .10),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            status,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openLearningPath(
  BuildContext context, {
  required NurseryContentPack pack,
  required NurseryDomain domain,
  required NurseryLearningPathPlan path,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _NurseryLearningPathScreen(
        pack: pack,
        domain: domain,
        pathId: path.definition.id,
      ),
    ),
  );
}

class _NurseryLearningPathScreen extends StatelessWidget {
  const _NurseryLearningPathScreen({
    required this.pack,
    required this.domain,
    required this.pathId,
  });

  final NurseryContentPack pack;
  final NurseryDomain domain;
  final String pathId;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final plan = NurseryWorldPlanner.build(
      pack: pack,
      domainId: domain.id,
      masteryFor: controller.nurseryMasteryFor,
      dueSkillIds: controller
          .dueNurseryReviewTasks(limit: 20)
          .map((task) => task.skillId),
    );
    final path = plan.pathById(pathId) ?? plan.paths.first;
    final color = nurseryDomainColor(domain.id);
    return Scaffold(
      body: BrightPageBackground(
        primary: const Color(0xFFF4FFF7),
        secondary: const Color(0xFFFFFAE8),
        child: Column(
          children: [
            BrightHeader(showBack: true, title: path.definition.title),
            Expanded(
              child: ListView(
                children: [
                  BrightResponsive(
                    maxWidth: 900,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PathHero(
                          path: path,
                          color: color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose a little game',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 12),
                        BrightAdaptiveGrid(
                          minChildWidth: 220,
                          maxColumns: 3,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final skill in path.skills)
                              _SkillCard(
                                color: color,
                                skill: skill,
                                mastery: controller.nurseryMasteryFor(skill.id),
                                recommended: skill.id == path.recommendedSkill.id,
                                reviewMode: path.recommendedReviewMode &&
                                    skill.id == path.recommendedSkill.id,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathHero extends StatelessWidget {
  const _PathHero({required this.path, required this.color});

  final NurseryLearningPathPlan path;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: color.withValues(alpha: .14)),
        ),
        child: Row(
          children: [
            NurseryVisual(
              spec: NurseryVisualResolver.forLearningPath(
                path.definition.id,
                path.definition.domainId,
                semanticLabel: path.definition.title,
              ),
              size: 66,
              decorative: true,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.definition.subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    path.complete
                        ? 'Great job — this path is remembered.'
                        : 'Next: ${path.recommendedSkill.title}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SkillCard extends StatefulWidget {
  const _SkillCard({
    required this.color,
    required this.skill,
    required this.mastery,
    this.recommended = false,
    this.reviewMode = false,
  });

  final Color color;
  final NurserySkill skill;
  final NurserySkillMastery mastery;
  final bool recommended;
  final bool reviewMode;

  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.mastery.state;
    final color = widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: BrightPressableScale(
        hoverScale: 1.012,
        child: Semantics(
          button: true,
          label: '${widget.skill.title}. ${_stateSemantics(state)}. Tap to play.',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('nursery-skill-${widget.skill.id}'),
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NurseryLessonScreen(
                    skillId: widget.skill.id,
                    reviewMode: widget.reviewMode,
                  ),
                ),
              ),
              child: AnimatedContainer(
                duration: brightReduceMotion(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 170),
                constraints: const BoxConstraints(minHeight: 132),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: hovered ? .18 : .12),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: color.withValues(
                      alpha: widget.recommended ? .42 : .18,
                    ),
                    width: widget.recommended ? 2 : 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: hovered ? .15 : .07),
                      blurRadius: hovered ? 16 : 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withValues(alpha: .13),
                        ),
                      ),
                      child: NurseryVisual(
                        spec: NurseryVisualResolver.forSkill(widget.skill),
                        size: 44,
                        decorative: true,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.recommended)
                            Text(
                              widget.reviewMode ? 'PLAY AGAIN' : 'PLAY NEXT',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .6,
                                  ),
                            ),
                          Text(
                            widget.skill.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              NurseryProgressStars(
                                filled: _stateStarCount(state),
                                size: 19,
                              ),
                              const Spacer(),
                              Icon(
                                Icons.play_circle_fill_rounded,
                                color: color,
                                size: 28,
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _LetterBook extends StatefulWidget {
  const _LetterBook({required this.pack});

  final NurseryContentPack pack;

  @override
  State<_LetterBook> createState() => _LetterBookState();
}

class _LetterBookState extends State<_LetterBook> {
  final Map<String, int> _exampleIndexByLetter = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final reducedMotion = BrightQuestScope.of(context).reducedMotionEnabled ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    return BrightSurface(
      tint: AppTheme.purple,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: const PageStorageKey<String>('nursery-letter-book'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: NurseryVisual(
          spec: NurseryVisualResolver.forDomainId('alphabet'),
          size: 34,
          decorative: true,
        ),
        title: const Text(
          'ABC Picture Book',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text('Tap to open A–Z pictures'),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final letter in widget.pack.letterAssociations)
                _buildLetterCard(context, letter, reducedMotion),
            ],
          ),
        ],
      ),
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
    final semanticsLabel =
        '${letter.uppercase}, ${letter.lowercase}. ${example.displayPhrase}. ${example.soundCue}.';
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
          width: 112,
          constraints: const BoxConstraints(minHeight: 118),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration:
                    reducedMotion ? Duration.zero : const Duration(milliseconds: 300),
                child: ClipRRect(
                  key: ValueKey('${letter.uppercase}:${example.word}'),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 58,
                    child: NurseryVisual(
                      spec: NurseryVisualResolver.forLetterExample(
                        letter,
                        example,
                      ),
                      size: 58,
                      reducedMotion: reducedMotion,
                      decorative: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                example.word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


int _stateStarCount(LearningEvidenceState state) => switch (state) {
      LearningEvidenceState.notStarted => 0,
      LearningEvidenceState.introduced ||
      LearningEvidenceState.practising ||
      LearningEvidenceState.needsSupport => 1,
      LearningEvidenceState.masteredNow || LearningEvidenceState.reviewDue => 2,
      LearningEvidenceState.secure => 3,
    };

String _stateSemantics(LearningEvidenceState state) => switch (state) {
      LearningEvidenceState.notStarted => 'New game',
      LearningEvidenceState.introduced => 'Started',
      LearningEvidenceState.practising => 'Playing',
      LearningEvidenceState.masteredNow => 'Learned',
      LearningEvidenceState.reviewDue => 'Ready to play again',
      LearningEvidenceState.secure => 'Remembered',
      LearningEvidenceState.needsSupport => 'Ready to try together',
    };

