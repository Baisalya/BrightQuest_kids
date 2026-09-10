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
import 'nursery_lesson_activity.dart';
import 'nursery_lesson_journey.dart';
import 'nursery_lesson_journey_board.dart';
import 'nursery_lesson_review.dart';
import 'nursery_lesson_teaching.dart';
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
  bool _studyVisited = false;

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

  bool get _reduceMotion =>
      BrightQuestScope.of(context).reducedMotionEnabled ||
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

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
            : NurseryReviewStage(
                practice: review,
                enabled: !_correct && !_answerLocked,
                feedback: _feedback,
                correct: _correct,
                hintVisible: _hintLevel > 0,
                reducedMotion: _reduceMotion,
                onRead: () => _readGenerated(review),
                onHint: () => _useGeneratedHint(review),
                onSubmit: (response) => _submitGenerated(skill, review, response),
                onDone: _correct ? () => Navigator.of(context).pop() : null,
              ),
      );
    }

    final activities = pack.activitiesForSkill(skill.id);
    final controller = BrightQuestScope.of(context);
    final completedActivityIds = controller.nurseryAttemptEvidence
        .where((evidence) =>
            evidence.skillId == skill.id && evidence.correct)
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
          reducedMotion: _reduceMotion,
          studyVisited: _studyVisited,
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
    final reducedMotion = _reduceMotion;
    final journey = NurseryLessonJourneyPlanner.build(
      activities: activities,
      completedActivityIds: completedActivityIds,
      studyVisited: true,
    );
    final guided = journey.guidedActivity;
    final pack = BrightQuestScope.contentOf(context).nurseryPack;
    final letterAssociations =
        pack?.letterAssociations ?? const <NurseryLetterAssociation>[];
    NurseryLetterAssociation? letter;
    NurseryLetterExample? example;
    if (skill.domainId == 'alphabet' && letterAssociations.isNotEmpty) {
      letter = letterAssociations[
        _discoveryLetterIndex % letterAssociations.length
      ];
      example = letter.examples[
        _discoveryExampleIndex % letter.examples.length
      ];
    }

    VoidCallback onHearLetter = () {};
    VoidCallback onAnotherWord = () {};
    if (letter != null && example != null) {
      final selectedLetter = letter;
      final selectedExample = example;
      onHearLetter = () {
        unawaited(_readLetterDiscovery(selectedLetter, selectedExample));
      };
      onAnotherWord = () {
        setState(() {
          _discoveryExampleIndex =
              (_discoveryExampleIndex + 1) % selectedLetter.examples.length;
        });
        final next = selectedLetter.examples[_discoveryExampleIndex];
        unawaited(_readLetterDiscovery(selectedLetter, next));
      };
    }

    final VoidCallback onNextLetter = letterAssociations.isEmpty
        ? () {}
        : () {
            setState(() {
              _discoveryLetterIndex =
                  (_discoveryLetterIndex + 1) % letterAssociations.length;
              _discoveryExampleIndex = 0;
            });
            final nextLetter = letterAssociations[_discoveryLetterIndex];
            unawaited(
              _readLetterDiscovery(nextLetter, nextLetter.examples.first),
            );
          };

    return NurseryTeachingStage(
      skill: skill,
      reducedMotion: reducedMotion,
      letter: letter,
      letterExample: example,
      onHearTeaching: () => unawaited(_readTeaching(skill, 2)),
      onHearLetter: onHearLetter,
      onAnotherWord: onAnotherWord,
      onNextLetter: onNextLetter,
      onPlay: guided == null
          ? _returnToBoard
          : () => _openActivity(
                activities: activities,
                activity: guided,
              ),
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
    final activityIndex = activities.indexWhere((item) => item.id == activity.id);
    final safeIndex = activityIndex < 0 ? 0 : activityIndex;
    final nextActivity = nurseryNextUnplayedActivity(
      activities,
      completedActivityIds,
      activity,
    );
    final explanation = _evaluator.explanationFor(activity);

    return NurseryActivityStage(
      skill: skill,
      activity: activity,
      activityIndex: safeIndex,
      activityCount: activities.length,
      retries: _retries,
      hintLevel: _hintLevel,
      correct: _correct,
      feedback: _feedback,
      reducedMotion: _reduceMotion,
      answerLabel: _evaluator.correctResponseLabel(activity),
      answerExplanation: explanation.text,
      answerVisuals: explanation.visualTokens,
      hasNextActivity: nextActivity != null,
      onRead: () => _readActivity(activity),
      onSubmit: (response) => _submitActivity(skill, activity, response),
      onHint: () => _useHint(activity),
      onContinue: nextActivity == null
          ? _returnToBoard
          : () => _openActivity(
                activities: activities,
                activity: nextActivity,
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
        responseTimeMs: now.difference(_startedAt).inMilliseconds.clamp(0, 3600000).toInt(),
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
          _feedback = 'Great job!';
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
        responseTimeMs: now.difference(_startedAt).inMilliseconds.clamp(0, 3600000).toInt(),
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
          _feedback = 'Great remembering!';
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
      _studyVisited = true;
      _pageIndex = page.clamp(0, 2).toInt();
      _resetAttemptState();
    });
    _announceCurrent();
  }

  void _openActivity({
    required List<NurseryActivity> activities,
    required NurseryActivity activity,
  }) {
    final index = activities.indexWhere((candidate) => candidate.id == activity.id);
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
            'Three easy steps. Study first, then Guided Play, then Independent Game.',
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
          _discoveryLetterIndex % pack.letterAssociations.length
        ];
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
