import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/learning/learning_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_learning_models.dart';
import '../../core/nursery/nursery_practice_generator.dart';
import '../../core/nursery/nursery_review_seed_planner.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_response_evaluator.dart';
import '../../core/services/bright_audio_service.dart';
import 'nursery_asset_reaction.dart';
import 'nursery_interactions.dart';
import 'nursery_play_board.dart';

class NurseryLessonScreen extends StatefulWidget {
  const NurseryLessonScreen({
    required this.skillId,
    this.reviewMode = false,
    super.key,
  });

  final String skillId;
  final bool reviewMode;

  @override
  State<NurseryLessonScreen> createState() => _NurseryLessonScreenState();
}

class _NurseryLessonScreenState extends State<NurseryLessonScreen> {
  static const NurseryResponseEvaluator _evaluator = NurseryResponseEvaluator();
  static const NurseryPracticeGenerator _generator = NurseryPracticeGenerator();
  static const NurseryReviewSeedPlanner _reviewSeedPlanner =
      NurseryReviewSeedPlanner();

  int _pageIndex = -1;
  int _hintLevel = 0;
  int _retries = 0;
  DateTime _startedAt = DateTime.now();
  bool _answerLocked = false;
  bool _correct = false;
  String? _feedback;
  NurseryGeneratedPractice? _generatedReview;
  String? _lastAnnouncementKey;
  int _discoveryLetterIndex = 0;
  int _discoveryExampleIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.reviewMode && _generatedReview == null) {
      final pack = BrightQuestScope.contentOf(context).nurseryPack;
      final skill = pack?.skillById(widget.skillId);
      if (pack != null && skill != null) {
        final controller = BrightQuestScope.of(context);
        final reviewSeed = _reviewSeedPlanner.nextSeed(
          skillId: skill.id,
          evidence: controller.nurseryAttemptEvidence,
        );
        _generatedReview = _generator.generate(
          pack: pack,
          skill: skill,
          seed: reviewSeed,
        );
      }
    }
    _announceCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final pack = BrightQuestScope.contentOf(context).nurseryPack;
    final skill = pack?.skillById(widget.skillId);
    if (pack == null || skill == null) {
      return const Scaffold(
        body: Center(child: Text('Nursery content is unavailable.')),
      );
    }
    if (widget.reviewMode) {
      final review = _generatedReview;
      return Scaffold(
        appBar: AppBar(title: const Text('Memory Game')),
        body: review == null
            ? const Center(child: CircularProgressIndicator())
            : _ReviewBody(
                skill: skill,
                practice: review,
                enabled: !_correct && !_answerLocked,
                feedback: _feedback,
                correct: _correct,
                hintVisible: _hintLevel > 0,
                onRead: () => _readGenerated(review),
                onHint: () => _useGeneratedHint(review),
                onSubmit: (response) =>
                    _submitGenerated(skill, review, response),
                onDone: _correct ? () => Navigator.of(context).pop() : null,
              ),
      );
    }

    final activities = pack.activitiesForSkill(skill.id);
    final controller = BrightQuestScope.of(context);
    final completedActivityIds = controller.nurseryAttemptEvidence
        .where((evidence) => evidence.skillId == skill.id && evidence.correct)
        .map((evidence) => evidence.itemId)
        .toSet();
    final completedCount = activities
        .where((activity) => completedActivityIds.contains(activity.id))
        .length;
    final progress = activities.isEmpty
        ? 0.0
        : (completedCount / activities.length).clamp(0.0, 1.0).toDouble();

    if (_pageIndex < 0) {
      return Scaffold(
        appBar: AppBar(
          title: Text(skill.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(5),
            child: LinearProgressIndicator(value: progress, minHeight: 5),
          ),
        ),
        body: NurseryPlayBoard(
          skill: skill,
          activities: activities,
          completedActivityIds: completedActivityIds,
          reducedMotion: controller.reducedMotionEnabled,
          onDiscover: () => _openTeachingPage(2),
          onActivity: (activity) =>
              _openActivity(activities: activities, activity: activity),
        ),
      );
    }

    final activityIndex = _pageIndex - 3;
    final content = _pageIndex < 3
        ? _buildTeachingPage(
            skill,
            activities,
            completedActivityIds,
          )
        : activityIndex >= 0 && activityIndex < activities.length
            ? _buildActivityPage(
                skill,
                activities[activityIndex],
                activities,
                completedActivityIds,
              )
            : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: Text(skill.title),
        leading: IconButton(
          tooltip: 'Back to games',
          onPressed: _returnToBoard,
          icon: const Icon(Icons.grid_view_rounded),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: LinearProgressIndicator(value: progress, minHeight: 5),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal ? 48 : 18,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeachingPage(
    NurserySkill skill,
    List<NurseryActivity> activities,
    Set<String> completedActivityIds,
  ) {
    final controller = BrightQuestScope.of(context);
    final reducedMotion = controller.reducedMotionEnabled;
    final recommended = nurseryRecommendedActivity(
      activities,
      completedActivityIds,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '👀 Look & listen',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
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
                  if (skill.domainId == 'alphabet') ...[
                    const Text(
                      'Explore letter words',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLetterDiscovery(reducedMotion),
                  ] else
                    _WorkedExampleVisual(
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
                  onPressed: () => _readTeaching(skill, 2),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Hear it'),
                ),
                FilledButton.icon(
                  onPressed: recommended == null
                      ? _returnToBoard
                      : () => _openActivity(
                            activities: activities,
                            activity: recommended,
                          ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play Now'),
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

  Widget _buildLetterDiscovery(bool reducedMotion) {
    final pack = BrightQuestScope.contentOf(context).nurseryPack;
    if (pack == null || pack.letterAssociations.isEmpty) {
      return const SizedBox.shrink();
    }
    final letter = pack.letterAssociations[
        _discoveryLetterIndex % pack.letterAssociations.length];
    final example =
        letter.examples[_discoveryExampleIndex % letter.examples.length];
    return _LetterDiscoveryShowcase(
      letter: letter,
      example: example,
      reducedMotion: reducedMotion,
      onHear: () => _readLetterDiscovery(letter, example),
      onAnotherWord: () {
        setState(() {
          _discoveryExampleIndex =
              (_discoveryExampleIndex + 1) % letter.examples.length;
        });
        final next = letter.examples[_discoveryExampleIndex];
        unawaited(_readLetterDiscovery(letter, next));
      },
      onNextLetter: () {
        setState(() {
          _discoveryLetterIndex =
              (_discoveryLetterIndex + 1) % pack.letterAssociations.length;
          _discoveryExampleIndex = 0;
        });
        final nextLetter = pack.letterAssociations[_discoveryLetterIndex];
        unawaited(_readLetterDiscovery(nextLetter, nextLetter.examples.first));
      },
    );
  }

  Future<void> _readLetterDiscovery(
    NurseryLetterAssociation letter,
    NurseryLetterExample example,
  ) =>
      BrightAudioService.instance.speak(
        '${letter.uppercase}, ${letter.lowercase}. '
        '${example.displayPhrase}. ${example.soundCue}.',
        manual: true,
      );

  Widget _buildActivityPage(
    NurserySkill skill,
    NurseryActivity activity,
    List<NurseryActivity> activities,
    Set<String> completedActivityIds,
  ) {
    final activityIndex =
        activities.indexWhere((item) => item.id == activity.id);
    final safeIndex = activityIndex < 0 ? 0 : activityIndex;
    final simpleTitle = nurserySimpleGameLabel(
      activity,
      safeIndex,
      activities.length,
    );
    final portalStyle = nurseryPortalStyleFor(skill, activity);
    final nextActivity = nurseryNextUnplayedActivity(
      activities,
      completedActivityIds,
      activity,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GameSceneBanner(
              title: simpleTitle,
              subtitle: nurserySimpleGameHint(activity),
              emoji: portalStyle.emoji,
              reducedMotion: BrightQuestScope.of(context).reducedMotionEnabled,
            ),
            const SizedBox(height: 14),
            Text(
              activity.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Center(
              child: IconButton.filledTonal(
                tooltip: 'Hear the question',
                onPressed: () => _readActivity(activity),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ),
            const SizedBox(height: 16),
            NurseryActivityInteraction(
              key: ValueKey('${activity.id}:$_retries:$_hintLevel'),
              activity: activity,
              enabled: !_correct,
              reducedMotion: BrightQuestScope.of(context).reducedMotionEnabled,
              onSubmitted: (response) =>
                  _submitActivity(skill, activity, response),
            ),
            const SizedBox(height: 14),
            if (_feedback != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _correct
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _feedback!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            if (_correct) ...[
              const SizedBox(height: 10),
              _NurseryCheerBurst(
                reducedMotion:
                    BrightQuestScope.of(context).reducedMotionEnabled,
              ),
            ],
            if (_hintLevel > 0 && !_correct) ...[
              const SizedBox(height: 10),
              Text(
                '💡 ${activity.hint}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (_correct && !activity.isTrace) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final explanation = _evaluator.explanationFor(activity);
                  return _AnswerExplanation(
                    answer: _evaluator.correctResponseLabel(activity),
                    explanation: explanation.text,
                    visuals: explanation.visualTokens,
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            if (!_correct)
              Center(
                child: TextButton.icon(
                  onPressed: () => _useHint(activity),
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('Help'),
                ),
              )
            else
              FilledButton.icon(
                onPressed: nextActivity == null
                    ? _returnToBoard
                    : () => _openActivity(
                          activities: activities,
                          activity: nextActivity,
                        ),
                icon: Icon(
                  nextActivity == null
                      ? Icons.celebration_rounded
                      : Icons.navigate_next_rounded,
                ),
                label: Text(nextActivity == null ? 'Done!' : 'Next Game'),
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

  Future<void> _submitActivity(
    NurserySkill skill,
    NurseryActivity activity,
    Object? response,
  ) async {
    if (_correct || _answerLocked) return;
    _answerLocked = true;
    final evaluation = _evaluator.evaluate(activity, response);
    final now = DateTime.now();
    final controller = BrightQuestScope.of(context);
    controller.recordNurseryEvidence(
      NurseryAttemptEvidence(
        id: 'nursery-e:${controller.activeProfileId}:${now.microsecondsSinceEpoch}',
        profileId: controller.activeProfileId,
        packId: NurseryContentPack.nurseryPackId,
        skillId: skill.id,
        itemId: activity.id,
        kind: _kindForPhase(activity.phase),
        correct: evaluation.correct,
        hintLevel: _hintLevel,
        retries: _retries,
        responseTimeMs:
            now.difference(_startedAt).inMilliseconds.clamp(0, 3600000).toInt(),
        recordedAtIso: now.toIso8601String(),
        contributesToMastery: activity.masteryEligible,
        misconceptionId: evaluation.misconceptionId,
      ),
    );

    if (evaluation.correct) {
      unawaited(BrightAudioService.instance.playSfx(BrightSfx.correct));
      unawaited(
        BrightAudioService.instance.speakCorrect(
          answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
          detail: nurserySpeakableText(activity.successFeedback),
        ),
      );
      if (mounted) {
        setState(() {
          _correct = true;
          _feedback = 'Great job! ⭐';
          _answerLocked = false;
        });
      }
    } else {
      unawaited(BrightAudioService.instance.playSfx(BrightSfx.wrong));
      unawaited(
        BrightAudioService.instance.speakWrong(
          answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
          guidance: nurserySpeakableText(
            '${activity.wrongFeedback} ${activity.hint}',
          ),
        ),
      );
      if (mounted) {
        setState(() {
          _retries += 1;
          _feedback = 'Almost! Try again.';
          _answerLocked = false;
        });
      }
    }
  }

  Future<void> _submitGenerated(
    NurserySkill skill,
    NurseryGeneratedPractice practice,
    Object? response,
  ) async {
    if (_correct || _answerLocked) return;
    _answerLocked = true;
    final evaluation = _evaluator.evaluateGenerated(practice, response);
    final now = DateTime.now();
    final controller = BrightQuestScope.of(context);
    controller.recordNurseryEvidence(
      NurseryAttemptEvidence(
        id: 'nursery-e:${controller.activeProfileId}:${now.microsecondsSinceEpoch}',
        profileId: controller.activeProfileId,
        packId: NurseryContentPack.nurseryPackId,
        skillId: skill.id,
        itemId: practice.id,
        kind: LearningAttemptKind.review,
        correct: evaluation.correct,
        hintLevel: _hintLevel,
        retries: _retries,
        responseTimeMs:
            now.difference(_startedAt).inMilliseconds.clamp(0, 3600000).toInt(),
        recordedAtIso: now.toIso8601String(),
        contributesToMastery: true,
        misconceptionId: evaluation.misconceptionId,
        generatedSeed: practice.seed,
      ),
    );
    if (evaluation.correct) {
      unawaited(BrightAudioService.instance.playSfx(BrightSfx.correct));
      unawaited(
        BrightAudioService.instance.speakCorrect(
          answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
          detail: nurserySpeakableText(practice.explanation),
        ),
      );
      if (mounted) {
        setState(() {
          _correct = true;
          _feedback = 'Great remembering! ⭐';
          _answerLocked = false;
        });
      }
    } else {
      unawaited(BrightAudioService.instance.playSfx(BrightSfx.wrong));
      unawaited(
        BrightAudioService.instance.speakWrong(
          answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
          guidance: 'Look or listen once more, then try again.',
        ),
      );
      if (mounted) {
        setState(() {
          _retries += 1;
          _feedback = 'Almost! Try again.';
          _answerLocked = false;
        });
      }
    }
  }

  void _openTeachingPage(int page) {
    setState(() {
      _pageIndex = page.clamp(0, 2).toInt();
      _resetAttemptState();
    });
    _announceCurrent();
  }

  void _openActivity({
    required List<NurseryActivity> activities,
    required NurseryActivity activity,
  }) {
    final index =
        activities.indexWhere((candidate) => candidate.id == activity.id);
    if (index < 0) return;
    setState(() {
      _pageIndex = index + 3;
      _resetAttemptState();
    });
    _announceCurrent();
  }

  void _returnToBoard() {
    setState(() {
      _pageIndex = -1;
      _resetAttemptState();
    });
    _announceCurrent();
  }

  void _resetAttemptState() {
    _hintLevel = 0;
    _retries = 0;
    _startedAt = DateTime.now();
    _answerLocked = false;
    _correct = false;
    _feedback = null;
  }

  void _announceCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pack = BrightQuestScope.contentOf(context).nurseryPack;
      final skill = pack?.skillById(widget.skillId);
      if (pack == null || skill == null) return;
      if (widget.reviewMode) {
        final review = _generatedReview;
        if (review == null) return;
        final key = 'review:${review.id}';
        if (_lastAnnouncementKey == key) return;
        _lastAnnouncementKey = key;
        unawaited(
          BrightAudioService.instance.speak(
            nurserySpeakableText(review.narration),
          ),
        );
        return;
      }
      final key = 'lesson:${skill.id}:$_pageIndex';
      if (_lastAnnouncementKey == key) return;
      _lastAnnouncementKey = key;
      if (_pageIndex < 0) {
        unawaited(
          BrightAudioService.instance.speak(
            'Let’s play. Tap Play Now, or tap Learn First.',
          ),
        );
      } else if (_pageIndex == 0) {
        unawaited(BrightAudioService.instance.speak(skill.objective));
      } else if (_pageIndex == 1) {
        unawaited(BrightAudioService.instance.speak(skill.explanation));
      } else if (_pageIndex == 2) {
        unawaited(
          BrightAudioService.instance.speak(
            nurserySpeakableText(_teachingNarration(skill, 2)),
          ),
        );
      } else {
        final activities = pack.activitiesForSkill(skill.id);
        final index = _pageIndex - 3;
        if (index >= 0 && index < activities.length) {
          unawaited(
            BrightAudioService.instance.speak(
              nurserySpeakableText(activities[index].narration),
            ),
          );
        }
      }
    });
  }

  String _teachingNarration(NurserySkill skill, int page) {
    if (page == 0) return skill.objective;
    if (page == 1) return skill.explanation;
    if (skill.domainId == 'alphabet') {
      final pack = BrightQuestScope.contentOf(context).nurseryPack;
      if (pack != null && pack.letterAssociations.isNotEmpty) {
        final letter = pack.letterAssociations[
            _discoveryLetterIndex % pack.letterAssociations.length];
        final example =
            letter.examples[_discoveryExampleIndex % letter.examples.length];
        return '${letter.uppercase}, ${letter.lowercase}. '
            '${example.displayPhrase}. ${example.soundCue}';
      }
    }
    return '${skill.workedExample.headline}. ${skill.workedExample.caption}';
  }

  Future<void> _readTeaching(NurserySkill skill, int page) =>
      BrightAudioService.instance.speak(
        nurserySpeakableText(_teachingNarration(skill, page)),
        manual: true,
      );

  Future<void> _readActivity(NurseryActivity activity) =>
      BrightAudioService.instance.speakPrompt(
        nurserySpeakableText(activity.narration),
        choices: activity.options.map(
          (option) => nurserySpokenLabel(option.label),
        ),
      );

  Future<void> _readGenerated(NurseryGeneratedPractice practice) =>
      BrightAudioService.instance.speakPrompt(
        nurserySpeakableText(practice.narration),
        choices: practice.options.map(
          (option) => nurserySpokenLabel(option.label),
        ),
      );

  Future<void> _useHint(NurseryActivity activity) async {
    if (_correct) return;
    setState(() => _hintLevel = (_hintLevel + 1).clamp(0, 2).toInt());
    await BrightAudioService.instance.playSfx(BrightSfx.hint);
    await BrightAudioService.instance.speak(
      nurserySpeakableText(activity.hint),
      manual: true,
    );
  }

  Future<void> _useGeneratedHint(NurseryGeneratedPractice practice) async {
    if (_correct) return;
    setState(() => _hintLevel = (_hintLevel + 1).clamp(0, 2).toInt());
    await BrightAudioService.instance.playSfx(BrightSfx.hint);
    await BrightAudioService.instance.speak(
      nurserySpeakableText(
        'Look at the choices carefully. ${practice.explanation}',
      ),
      manual: true,
    );
  }

  static LearningAttemptKind _kindForPhase(String phase) => switch (phase) {
        'guided' => LearningAttemptKind.guided,
        'practice' => LearningAttemptKind.guided,
        'transfer' => LearningAttemptKind.transfer,
        'review' => LearningAttemptKind.review,
        _ => LearningAttemptKind.independent,
      };
}

class _GameSceneBanner extends StatelessWidget {
  const _GameSceneBanner({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.reducedMotion,
  });

  final String title;
  final String subtitle;
  final String emoji;
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
          Text(emoji, style: const TextStyle(fontSize: 46)),
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
    if (reducedMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.90, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, animatedChild) => Transform.scale(
        scale: value,
        child: Opacity(
          opacity: value.clamp(0.0, 1.0).toDouble(),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.skill,
    required this.practice,
    required this.enabled,
    required this.feedback,
    required this.correct,
    required this.hintVisible,
    required this.onRead,
    required this.onHint,
    required this.onSubmit,
    required this.onDone,
  });

  final NurserySkill skill;
  final NurseryGeneratedPractice practice;
  final bool enabled;
  final String? feedback;
  final bool correct;
  final bool hintVisible;
  final VoidCallback onRead;
  final VoidCallback onHint;
  final ValueChanged<Object?> onSubmit;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      '⭐ Memory Game',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      practice.prompt,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    if (practice.visualTokens.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final token in practice.visualTokens)
                            _VisualToken(token: token),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onRead,
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Hear it'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final option in practice.options)
                          FilledButton.tonal(
                            onPressed:
                                enabled ? () => onSubmit(option.id) : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(92, 56),
                            ),
                            child: Text(
                              option.label,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                    if (feedback != null) ...[
                      const SizedBox(height: 14),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          feedback!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                    if (hintVisible && !correct) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💡 ${practice.explanation}',
                        textAlign: TextAlign.center,
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

class _NurseryCheerBurst extends StatelessWidget {
  const _NurseryCheerBurst({required this.reducedMotion});

  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Correct answer celebration',
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: reducedMotion ? 1 : 0, end: 1),
          duration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 520),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Opacity(
            opacity: reducedMotion ? 1 : value.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: reducedMotion ? 1 : 0.72 + (0.28 * value),
              child: child,
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: const [
              Text('⭐', style: TextStyle(fontSize: 28)),
              Text('🎉', style: TextStyle(fontSize: 34)),
              Text('⭐', style: TextStyle(fontSize: 28)),
            ],
          ),
        ),
      );
}

class _LetterDiscoveryShowcase extends StatelessWidget {
  const _LetterDiscoveryShowcase({
    required this.letter,
    required this.example,
    required this.reducedMotion,
    required this.onHear,
    required this.onAnotherWord,
    required this.onNextLetter,
  });

  final NurseryLetterAssociation letter;
  final NurseryLetterExample example;
  final bool reducedMotion;
  final VoidCallback onHear;
  final VoidCallback onAnotherWord;
  final VoidCallback onNextLetter;

  @override
  Widget build(BuildContext context) {
    final animationDuration =
        reducedMotion ? Duration.zero : const Duration(milliseconds: 420);
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
              if (reducedMotion) return child;
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
                            'asset:${letter.uppercase}:${example.word}'),
                        assetPath: example.assetPath,
                        word: example.word,
                        reducedMotion: reducedMotion,
                        fallback: _LetterAssetFallback(
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

class _LetterAssetFallback extends StatelessWidget {
  const _LetterAssetFallback({
    required this.letter,
    required this.example,
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
              Text(example.picture, style: const TextStyle(fontSize: 92)),
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

class _WorkedExampleVisual extends StatelessWidget {
  const _WorkedExampleVisual({
    required this.skill,
    required this.reducedMotion,
  });

  final NurserySkill skill;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final tokens = skill.workedExample.visuals;
    final addition = skill.id.startsWith('math_add_');
    return Semantics(
      label: 'Worked visual example: ${tokens.join(' ')}',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: reducedMotion ? 1 : 0, end: 1),
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var index = 0; index < tokens.length; index += 1)
              Transform.translate(
                offset: addition
                    ? Offset(
                        (1 - value) * (index < tokens.length / 2 ? -28 : 28),
                        0,
                      )
                    : Offset(0, (1 - value) * 10),
                child: Transform.scale(
                  scale: reducedMotion ? 1 : 0.82 + (0.18 * value),
                  child: Opacity(
                    opacity: reducedMotion ? 1 : 0.35 + (0.65 * value),
                    child: _VisualToken(token: tokens[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VisualToken extends StatelessWidget {
  const _VisualToken({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(
          token,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      );
}

class _AnswerExplanation extends StatelessWidget {
  const _AnswerExplanation({
    required this.answer,
    required this.explanation,
    required this.visuals,
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
              'Why: $answer',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(explanation, textAlign: TextAlign.center),
            if (visuals.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final token in visuals)
                    Text(token, style: const TextStyle(fontSize: 22))
                ],
              ),
            ],
          ],
        ),
      );
}
