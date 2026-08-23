import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/learning/learning_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_learning_models.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
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
      body: BrightPageBackground(
        primary: const Color(0xFFF0FFF4),
        secondary: const Color(0xFFFFF7D9),
        child: Column(
          children: [
            BrightHeader(
              showBack: true,
              title: 'Nursery Learning Garden',
              trailing: IconButton(
                tooltip: 'Hear welcome',
                onPressed: () => unawaited(
                  BrightAudioService.instance.speak(
                    'Welcome to Nursery Play. Pick a picture and play.',
                    manual: true,
                  ),
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  BrightResponsive(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    builder: (context, _) => _WelcomeCard(dueCount: due.length),
                  ),
                  if (due.isNotEmpty)
                    BrightResponsive(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                      builder: (context, _) =>
                          _ReviewSection(pack: pack, due: due),
                    ),
                  BrightResponsive(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    builder: (context, _) => _WorldPicker(pack: pack),
                  ),
                  BrightResponsive(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    builder: (context, _) => _LetterBook(pack: pack),
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.dueCount});

  final int dueCount;

  @override
  Widget build(BuildContext context) => BrightReveal(
        duration: const Duration(milliseconds: 320),
        beginScale: .98,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF66D889),
                Color(0xFF7DDDBD),
                Color(0xFF79CFF5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2450B978),
                blurRadius: 24,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              final message = Column(
                crossAxisAlignment:
                    wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Text(
                    'Pick a picture and play!',
                    textAlign: wide ? TextAlign.left : TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Big pictures • big buttons • spoken help',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (dueCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '⭐ $dueCount ${dueCount == 1 ? 'game' : 'games'} ready to play again',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final mascot = Container(
                width: wide ? 130 : 104,
                height: wide ? 130 : 104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .28),
                  ),
                ),
                child: const Text('🌱🐝', style: TextStyle(fontSize: 48)),
              );

              if (!wide) {
                return Column(
                  children: [
                    mascot,
                    const SizedBox(height: 12),
                    message,
                  ],
                );
              }
              return Row(
                children: [
                  mascot,
                  const SizedBox(width: 22),
                  Expanded(child: message),
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
  Widget build(BuildContext context) => BrightSurface(
        tint: AppTheme.orange,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrightSectionTitle(
              title: '⭐ Play again',
              subtitle: 'A tiny game to help you remember.',
              icon: Icons.replay_circle_filled_rounded,
              accent: AppTheme.orange,
            ),
            const SizedBox(height: 12),
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
                      icon: Text(
                        _skillEmoji(skill.id, skill.domainId),
                        style: const TextStyle(fontSize: 20),
                      ),
                      label: Text(skill.title),
                    ),
              ],
            ),
          ],
        ),
      );
}

class _WorldPicker extends StatelessWidget {
  const _WorldPicker({required this.pack});

  final NurseryContentPack pack;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick a game world',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          BrightAdaptiveGrid(
            minChildWidth: 220,
            maxColumns: 4,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final domain in pack.domains)
                _WorldCard(pack: pack, domain: domain),
            ],
          ),
        ],
      );
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.pack, required this.domain});

  final NurseryContentPack pack;
  final NurseryDomain domain;

  @override
  Widget build(BuildContext context) {
    final color = _nurseryDomainColor(domain.id);
    return Semantics(
      button: true,
      label:
          '${_childDomainTitle(domain)}. ${_childDomainSubtitle(domain.id)}. Tap to open.',
      child: BrightPressableScale(
        hoverScale: 1.012,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _NurseryDomainScreen(
                  pack: pack,
                  domain: domain,
                ),
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 170),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: .18),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: color.withValues(alpha: .20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(domain.emoji, style: const TextStyle(fontSize: 50)),
                  const SizedBox(height: 10),
                  Text(
                    _childDomainTitle(domain),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _childDomainSubtitle(domain.id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 9),
                  Icon(Icons.play_circle_fill_rounded, color: color, size: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NurseryDomainScreen extends StatelessWidget {
  const _NurseryDomainScreen({required this.pack, required this.domain});

  final NurseryContentPack pack;
  final NurseryDomain domain;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: BrightPageBackground(
          primary: const Color(0xFFF0FFF4),
          secondary: const Color(0xFFFFF7D9),
          child: Column(
            children: [
              BrightHeader(
                showBack: true,
                title: _childDomainTitle(domain),
              ),
              Expanded(
                child: ListView(
                  children: [
                    BrightResponsive(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      builder: (context, _) =>
                          _DomainSection(pack: pack, domain: domain),
                    ),
                  ],
                ),
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
    final color = _nurseryDomainColor(domain.id);
    return BrightSurface(
      tint: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrightSectionTitle(
            title: '${domain.emoji} ${_childDomainTitle(domain)}',
            subtitle: _childDomainSubtitle(domain.id),
            icon: _nurseryDomainIcon(domain.id),
            accent: color,
          ),
          const SizedBox(height: 14),
          BrightAdaptiveGrid(
            minChildWidth: 210,
            maxColumns: 4,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final skill in skills)
                _SkillCard(
                  color: color,
                  skill: skill,
                  mastery: controller.nurseryMasteryFor(skill.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatefulWidget {
  const _SkillCard({
    required this.color,
    required this.skill,
    required this.mastery,
  });

  final Color color;
  final NurserySkill skill;
  final NurserySkillMastery mastery;

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
          label:
              '${widget.skill.title}. ${_stateSemantics(state)}. Tap to play.',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NurseryLessonScreen(skillId: widget.skill.id),
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
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
                    color: color.withValues(alpha: .18),
                    width: 1.3,
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
                      child: Text(
                        _skillEmoji(widget.skill.id, widget.skill.domainId),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.skill.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Text(
                                _stateStars(state),
                                style: const TextStyle(fontSize: 18),
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
    final reducedMotion = BrightQuestScope.of(context).reducedMotionEnabled;
    return BrightSurface(
      tint: AppTheme.purple,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: const PageStorageKey<String>('nursery-letter-book'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Text('🔤', style: TextStyle(fontSize: 30)),
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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                child: ClipRRect(
                  key: ValueKey('${letter.uppercase}:${example.word}'),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 58,
                    child: example.assetPath.isEmpty
                        ? Center(
                            child: Text(
                              example.picture,
                              style: const TextStyle(fontSize: 32),
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
                                style: const TextStyle(fontSize: 32),
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
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _childDomainTitle(NurseryDomain domain) => switch (domain.id) {
      'alphabet' => 'ABC & Sounds',
      'math' => 'Numbers',
      'knowledge' => 'My World',
      'thinking' => 'Match & Think',
      _ => domain.title,
    };

String _childDomainSubtitle(String id) => switch (id) {
      'alphabet' => 'Letters, sounds and picture words',
      'math' => 'Count, match and easy sums',
      'knowledge' => 'Colours, shapes, animals and everyday things',
      'thinking' => 'Match, sort and spot patterns',
      _ => 'Tap a picture to play',
    };

String _skillEmoji(String id, String domainId) {
  if (id.contains('trace')) return '✏️';
  if (id.contains('sound') || id.contains('listen')) return '👂';
  if (id.contains('word_picture')) return '🖼️';
  if (id.contains('case_match')) return '🔠';
  if (id.contains('count')) return '🍎';
  if (id.contains('add')) return '➕';
  if (id.contains('number')) return '🔢';
  if (id.contains('colour')) return '🌈';
  if (id.contains('shape')) return '🔷';
  if (id.contains('animal')) return '🐶';
  if (id.contains('food')) return '🍎';
  if (id.contains('object')) return '🧸';
  if (id.contains('body')) return '🙋';
  if (id.contains('routine')) return '🌞';
  if (id.contains('pattern')) return '🧩';
  if (id.contains('matching')) return '🃏';
  if (id.contains('sorting')) return '🧺';
  if (id.contains('observation')) return '👀';
  return switch (domainId) {
    'alphabet' => '🔤',
    'math' => '🔢',
    'knowledge' => '🌍',
    'thinking' => '🧩',
    _ => '⭐',
  };
}

String _stateStars(LearningEvidenceState state) => switch (state) {
      LearningEvidenceState.notStarted => '○ ○ ○',
      LearningEvidenceState.introduced ||
      LearningEvidenceState.practising ||
      LearningEvidenceState.needsSupport =>
        '⭐ ○ ○',
      LearningEvidenceState.masteredNow ||
      LearningEvidenceState.reviewDue =>
        '⭐ ⭐ ○',
      LearningEvidenceState.secure => '⭐ ⭐ ⭐',
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

Color _nurseryDomainColor(String id) => switch (id) {
      'alphabet' => const Color(0xFF6B63E8),
      'math' => const Color(0xFF2E9EEB),
      'knowledge' => const Color(0xFF46B86B),
      'thinking' => const Color(0xFFF29B32),
      _ => AppTheme.purple,
    };

IconData _nurseryDomainIcon(String id) => switch (id) {
      'alphabet' => Icons.abc_rounded,
      'math' => Icons.calculate_rounded,
      'knowledge' => Icons.public_rounded,
      'thinking' => Icons.psychology_rounded,
      _ => Icons.spa_rounded,
    };
