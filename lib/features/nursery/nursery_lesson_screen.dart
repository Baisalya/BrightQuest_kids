import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/accessibility/learning_audio_director.dart';
import '../../core/accessibility/learning_audio_models.dart';
import '../../core/accessibility/learning_narration_coordinator.dart';
import '../../core/learning/learning_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_learning_models.dart';
import '../../core/nursery/nursery_practice_generator.dart';
import '../../core/nursery/nursery_review_seed_planner.dart';
import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_response_evaluator.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/services/feedback_service.dart';
import '../../widgets/learning_accessibility_widgets.dart';
import 'nursery_lesson_activity.dart';
import 'nursery_lesson_journey.dart';
import 'nursery_lesson_journey_board.dart';
import 'nursery_lesson_narration.dart';
import 'nursery_lesson_review.dart';
import 'nursery_lesson_teaching.dart';
import 'nursery_play_board.dart';
import 'nursery_sound.dart';

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
  @override
  void initState() {
    super.initState();
    playNurseryStartSound();
    unawaited(BrightAudioService.instance.playNurseryMusic(restart: true));
  }

  @override
  void dispose() {
    // Nursery lessons own a gentle play theme. Return to the existing Home
    // explorer mix when the lesson route closes, while preserving all parent
    // mute/volume preferences inside BrightAudioService.
    unawaited(BrightAudioService.instance.playMenuMusic(restart: true));
    super.dispose();
  }

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

    const narration = NurseryLessonNarration();
    final narrationScopeKey = narration.scopeKey(
      reviewMode: widget.reviewMode,
      generatedReview: _generatedReview,
      pageIndex: _pageIndex,
      pack: pack,
      skill: skill,
    );
    final narrationCue = narration.currentCue(
      reviewMode: widget.reviewMode,
      generatedReview: _generatedReview,
      pageIndex: _pageIndex,
      pack: pack,
      skill: skill,
      teachingText: _pageIndex >= 0 && _pageIndex < 3
          ? _teachingNarration(skill, _pageIndex)
          : null,
    );

    return LearningNarrationBoundary(
      ownerLabel: 'NurseryLessonScreen:${skill.id}',
      scopeKey: narrationScopeKey,
      builder: (context, narrationSession) => LearningAutomaticNarrator(
        key: ValueKey<String>('nursery_auto:${skill.id}'),
        cue: narrationCue,
        triggerKey: narrationScopeKey,
        narrationSession: narrationSession,
        child: _buildNurserySurface(
          pack: pack,
          skill: skill,
          narrationSession: narrationSession,
        ),
      ),
    );
  }

  Widget _buildNurserySurface({
    required NurseryContentPack pack,
    required NurserySkill skill,
    required LearningNarrationSession narrationSession,
  }) {
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
                onRead: () => _readGenerated(
                  review,
                  narrationSession: narrationSession,
                ),
                onHint: () => _useGeneratedHint(
                  review,
                  narrationSession: narrationSession,
                ),
                onSubmit: (response) => _submitGenerated(
                  skill,
                  review,
                  response,
                  narrationSession: narrationSession,
                ),
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
            narrationSession: narrationSession,
          )
        : activityIndex >= 0 && activityIndex < activities.length
            ? _buildActivityPage(
                skill,
                activities[activityIndex],
                activities,
                completedActivityIds,
                narrationSession: narrationSession,
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
    Set<String> completedActivityIds, {
    required LearningNarrationSession narrationSession,
  }) {
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
      letter =
          letterAssociations[_discoveryLetterIndex % letterAssociations.length];
      example =
          letter.examples[_discoveryExampleIndex % letter.examples.length];
    }

    VoidCallback onHearLetter = () {};
    VoidCallback onAnotherWord = () {};
    if (letter != null && example != null) {
      final selectedLetter = letter;
      final selectedExample = example;
      onHearLetter = () {
        unawaited(_readLetterDiscovery(
          selectedLetter,
          selectedExample,
          narrationSession: narrationSession,
        ));
      };
      onAnotherWord = () {
        playNurseryOptionSound();
        setState(() {
          _discoveryExampleIndex =
              (_discoveryExampleIndex + 1) % selectedLetter.examples.length;
        });
        final next = selectedLetter.examples[_discoveryExampleIndex];
        unawaited(_readLetterDiscovery(
          selectedLetter,
          next,
          narrationSession: narrationSession,
        ));
      };
    }

    final VoidCallback onNextLetter = letterAssociations.isEmpty
        ? () {}
        : () {
            playNurseryNextSound();
            setState(() {
              _discoveryLetterIndex =
                  (_discoveryLetterIndex + 1) % letterAssociations.length;
              _discoveryExampleIndex = 0;
            });
            final nextLetter = letterAssociations[_discoveryLetterIndex];
            unawaited(
              _readLetterDiscovery(
                nextLetter,
                nextLetter.examples.first,
                narrationSession: narrationSession,
              ),
            );
          };

    return NurseryTeachingStage(
      skill: skill,
      reducedMotion: reducedMotion,
      letter: letter,
      letterExample: example,
      onHearTeaching: () => unawaited(
        _readTeaching(
          skill,
          2,
          narrationSession: narrationSession,
        ),
      ),
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
    NurseryLetterExample example, {
    required LearningNarrationSession narrationSession,
  }) {
    final text = '${letter.uppercase}, ${letter.lowercase}. '
        '${example.displayPhrase}. ${example.soundCue}.';
    final cue = const LearningAudioDirector().forNurseryStatement(
      ownerId: 'letter:${letter.uppercase}:${example.word}',
      kind: LearningNarrationKind.workedExample,
      visibleText: text,
      spokenText: nurserySpeakableText(text),
      autoEligible: false,
    );
    return narrationSession.speakCue(cue, manual: true);
  }

  Widget _buildActivityPage(
    NurserySkill skill,
    NurseryActivity activity,
    List<NurseryActivity> activities,
    Set<String> completedActivityIds, {
    required LearningNarrationSession narrationSession,
  }) {
    final activityIndex =
        activities.indexWhere((item) => item.id == activity.id);
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
      onRead: () => _readActivity(
        activity,
        narrationSession: narrationSession,
      ),
      onSubmit: (response) => _submitActivity(
        skill,
        activity,
        response,
        narrationSession: narrationSession,
      ),
      onHint: () => _useHint(
        activity,
        narrationSession: narrationSession,
      ),
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
    Object? response, {
    required LearningNarrationSession narrationSession,
  }) async {
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
      FeedbackService.correct(
        controller,
        answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
        detail: nurserySpeakableText(activity.successFeedback),
        narrationSession: narrationSession,
        soundProfile: BrightSfxProfile.nursery,
      );
      if (mounted) {
        setState(() {
          _correct = true;
          _feedback = 'Great job!';
          _answerLocked = false;
        });
      }
    } else {
      FeedbackService.wrong(
        controller,
        answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
        guidance: nurserySpeakableText(
          '${activity.wrongFeedback} ${activity.hint}',
        ),
        narrationSession: narrationSession,
        soundProfile: BrightSfxProfile.nursery,
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
    Object? response, {
    required LearningNarrationSession narrationSession,
  }) async {
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
      FeedbackService.correct(
        controller,
        answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
        detail: nurserySpeakableText(practice.explanation),
        narrationSession: narrationSession,
        soundProfile: BrightSfxProfile.nursery,
      );
      if (mounted) {
        setState(() {
          _correct = true;
          _feedback = 'Great remembering!';
          _answerLocked = false;
        });
      }
    } else {
      FeedbackService.wrong(
        controller,
        answer: nurserySpokenLabel(_evaluator.responseLabel(response)),
        guidance: 'Look or listen once more, then try again.',
        narrationSession: narrationSession,
        soundProfile: BrightSfxProfile.nursery,
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
    playNurseryNextSound();
    setState(() {
      _studyVisited = true;
      _pageIndex = page.clamp(0, 2).toInt();
      _resetAttemptState();
    });
  }

  void _openActivity({
    required List<NurseryActivity> activities,
    required NurseryActivity activity,
  }) {
    final index =
        activities.indexWhere((candidate) => candidate.id == activity.id);
    if (index < 0) return;
    playNurseryNextSound();
    setState(() {
      _pageIndex = index + 3;
      _resetAttemptState();
    });
  }

  void _returnToBoard() {
    playNurseryTapSound();
    setState(() {
      _pageIndex = -1;
      _resetAttemptState();
    });
  }

  void _resetAttemptState() {
    _hintLevel = 0;
    _retries = 0;
    _startedAt = DateTime.now();
    _answerLocked = false;
    _correct = false;
    _feedback = null;
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

  Future<void> _readTeaching(
    NurserySkill skill,
    int page, {
    required LearningNarrationSession narrationSession,
  }) {
    final text = _teachingNarration(skill, page);
    final cue = const LearningAudioDirector().forNurseryStatement(
      ownerId: 'teaching:${skill.id}:$page',
      kind: switch (page) {
        0 => LearningNarrationKind.missionGoal,
        1 => LearningNarrationKind.conceptTeaching,
        _ => LearningNarrationKind.workedExample,
      },
      visibleText: text,
      spokenText: nurserySpeakableText(text),
      autoEligible: false,
    );
    return narrationSession.speakCue(cue, manual: true);
  }

  Future<void> _readActivity(
    NurseryActivity activity, {
    required LearningNarrationSession narrationSession,
  }) {
    final cue = const LearningAudioDirector().forNurseryPrompt(
      ownerId: 'activity:${activity.id}',
      visibleText: activity.prompt,
      spokenText: nurserySpeakableText(activity.narration),
      choices: activity.options.map(
        (option) => nurserySpokenLabel(option.label),
      ),
      autoEligible: false,
    );
    return narrationSession.speakCue(cue, manual: true);
  }

  Future<void> _readGenerated(
    NurseryGeneratedPractice practice, {
    required LearningNarrationSession narrationSession,
  }) {
    final cue = const LearningAudioDirector().forNurseryPrompt(
      ownerId: 'review:${practice.id}',
      visibleText: practice.prompt,
      spokenText: nurserySpeakableText(practice.narration),
      choices: practice.options.map(
        (option) => nurserySpokenLabel(option.label),
      ),
      autoEligible: false,
    );
    return narrationSession.speakCue(cue, manual: true);
  }

  void _useHint(
    NurseryActivity activity, {
    required LearningNarrationSession narrationSession,
  }) {
    if (_correct) return;
    setState(() => _hintLevel = (_hintLevel + 1).clamp(0, 2).toInt());
    final hintText = nurserySpeakableText(activity.hint);
    final cue = const LearningAudioDirector().forHint(
      ownerId: 'nursery:${activity.id}:$_hintLevel',
      text: hintText,
    );
    FeedbackService.hint(
      BrightQuestScope.of(context),
      hintText,
      narrationSession: narrationSession,
      narrationCue: cue,
      soundProfile: BrightSfxProfile.nursery,
    );
  }

  void _useGeneratedHint(
    NurseryGeneratedPractice practice, {
    required LearningNarrationSession narrationSession,
  }) {
    if (_correct) return;
    setState(() => _hintLevel = (_hintLevel + 1).clamp(0, 2).toInt());
    final hintText = nurserySpeakableText(
      'Look at the choices carefully. ${practice.explanation}',
    );
    final cue = const LearningAudioDirector().forHint(
      ownerId: 'nursery:${practice.id}:$_hintLevel',
      text: hintText,
    );
    FeedbackService.hint(
      BrightQuestScope.of(context),
      hintText,
      narrationSession: narrationSession,
      narrationCue: cue,
      soundProfile: BrightSfxProfile.nursery,
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
