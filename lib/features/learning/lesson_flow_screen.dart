import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/accessibility/learning_audio_director.dart';
import '../../core/content/content_activity.dart';
import '../../core/content/content_repository.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/world_mission_catalog.dart';
import '../../core/curriculum/world_mission_models.dart';
import '../../core/learning/activity_response_evaluator.dart';
import '../../core/learning/adaptive_difficulty_engine.dart';
import '../../core/learning/adaptive_difficulty_models.dart';
import '../../core/learning/contextual_feedback_engine.dart';
import '../../core/learning/gameplay_activity_resolver.dart';
import '../../core/learning/learning_models.dart';
import '../../core/learning/lesson_engine.dart';
import '../../core/learning/mission_run_models.dart';
import '../../core/learning/mission_run_session_coordinator.dart';
import '../../core/learning/mission_session_engine.dart';
import '../../core/learning/mission_session_models.dart';
import '../../core/learning/skill_studio_practice_planner.dart';
import '../../core/services/feedback_service.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/adaptive_difficulty_widgets.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/learning_accessibility_widgets.dart';
import '../../widgets/mission_session_widgets.dart';
import '../../widgets/world_mission_widgets.dart';
import 'gameplay/learning_game_guidance.dart';
import 'lesson_activity_interaction.dart';

class LessonFlowScreen extends StatefulWidget {
  const LessonFlowScreen({
    required this.level,
    super.key,
  })  : classNumber = null,
        competencyId = null,
        title = null;

  const LessonFlowScreen.forCompetency({
    required this.classNumber,
    required this.competencyId,
    required this.title,
    super.key,
  }) : level = null;

  final LearningLevel? level;
  final int? classNumber;
  final String? competencyId;
  final String? title;

  bool get isDirectCompetency => level == null;

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen>
    with WidgetsBindingObserver {
  int index = 0;
  final Set<int> _shownHints = <int>{};
  final Set<String> _completedInteractiveSteps = <String>{};
  int _attemptSerial = 0;
  bool _attemptInFlight = false;
  bool _sessionRestored = false;
  MissionRunPlan? _missionRunPlan;
  SkillStudioPracticePlan? _skillStudioPlan;
  final Set<String> _recordedSkillActivityIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || state == AppLifecycleState.resumed) return;
    final controller = BrightQuestScope.of(context);
    unawaited(controller.flush());
    unawaited(controller.flushGameSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionRestored) return;
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    if (widget.level == null) {
      _createSkillStudioPlan(
        controller: controller,
        repository: repository,
      );
      _sessionRestored = true;
      return;
    }
    final level = widget.level!;
    final policy = const AdaptiveDifficultyEngine().forLevel(
      level: level,
      levelProgress: controller.levelStatsFor(level.id),
      gameProgress: controller.statsFor(level.gameId),
    );
    final existingCheckpoint = controller.gameSessionFor(
      gameId: level.gameId,
      classNumber: level.classNumber,
      learningLevelId: level.id,
    );
    _missionRunPlan =
        const MissionRunSessionCoordinator().createOrRestoreForWorldLevel(
      repository: repository,
      level: level,
      checkpoint: existingCheckpoint,
      history: controller.missionExposureHistoryFor(level),
      learningState: controller.learningState,
      levelProgress: controller.levelStatsFor(level.id),
      gameProgress: controller.statsFor(level.gameId),
    );
    if (_missionRunPlan!.hasContentShortfall ||
        _missionRunPlan!.hasTrainingGameOverlap ||
        _missionRunPlan!.hasVisibleContentOverlap ||
        _missionRunPlan!.hasInternalContentRepeat) {
      throw StateError(
        'Mission allocation is invalid for ${level.id}: '
        'training shortfall ${_missionRunPlan!.trainingShortfall}, '
        'game shortfall ${_missionRunPlan!.gameShortfall}.',
      );
    }
    final authoredFlow = const LessonEngine().buildForLevel(
      repository: repository,
      level: level,
      missionRunPlan: _missionRunPlan,
    );
    final session = const MissionSessionEngine().build(
      authoredFlow,
      policy: policy,
    );
    final checkpoint = controller.beginLessonSession(
      level: level,
      totalSteps: session.steps.length,
      sessionData: _missionRunPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(
              _missionRunPlan!,
            ),
    );
    index = checkpoint.cursor.clamp(0, session.steps.length - 1).toInt();
    _shownHints
      ..clear()
      ..addAll(checkpoint.shownHintIndices);
    _completedInteractiveSteps
      ..clear()
      ..addAll(checkpoint.completedInteractiveStepIds);
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    _sessionRestored = true;
  }

  @override
  Widget build(BuildContext context) {
    final repository = BrightQuestScope.contentOf(context);
    final controller = BrightQuestScope.of(context);
    final level = widget.level;
    final adaptivePolicy = level == null
        ? null
        : const AdaptiveDifficultyEngine().forLevel(
            level: level,
            levelProgress: controller.levelStatsFor(level.id),
            gameProgress: controller.statsFor(level.gameId),
          );
    final missionPlan =
        level == null ? null : WorldMissionCatalog.planForLevel(level);
    final authoredFlow = level != null
        ? const LessonEngine().buildForLevel(
            repository: repository,
            level: level,
            missionRunPlan: _missionRunPlan,
          )
        : const LessonEngine().buildForCompetency(
            repository: repository,
            classNumber: widget.classNumber!,
            competencyId: widget.competencyId!,
            practicePlan: _skillStudioPlan,
          );
    final session = const MissionSessionEngine().build(
      authoredFlow,
      policy: adaptivePolicy,
    );
    final safeIndex = index.clamp(0, session.steps.length - 1).toInt();
    final sessionStep = session.stepAt(safeIndex);
    final step = sessionStep.lessonStep;
    final activity = step.activityId == null
        ? null
        : repository.activityById(step.activityId!);
    final activitySpec = activity == null
        ? null
        : const GameplayActivityResolver().resolve(activity);
    if (widget.isDirectCompetency && activity != null) {
      _recordSkillStudioActivitySeen(
        controller: controller,
        repository: repository,
        activity: activity,
      );
    }
    final narrationCue = const LearningAudioDirector().forLessonStep(
      sessionStep: sessionStep,
      activity: activity,
      activitySpec: activitySpec,
    );
    final needsResponse = sessionStep.isInteractive && activity != null;
    final canContinue =
        !needsResponse || _completedInteractiveSteps.contains(step.id);
    final mediaSize = MediaQuery.sizeOf(context);
    final shortWideInteractive =
        needsResponse && mediaSize.width >= 600 && mediaSize.height < 820;
    final palette = missionPlan == null
        ? null
        : paletteForSubject(missionPlan.identity.subject);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          missionPlan?.identity.worldTitle ?? widget.title ?? level!.title,
        ),
      ),
      body: SafeArea(
        child: BrightPageBackground(
          primary: palette == null
              ? const Color(0xFFF3F7FF)
              : Color.lerp(palette.secondary, Colors.white, .72)!,
          secondary: const Color(0xFFFFFAE9),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: shortWideInteractive ? 12 : 20,
                ),
                children: [
                  if (missionPlan != null) ...[
                    WorldMissionRibbon(plan: missionPlan),
                    if (safeIndex == 0) ...[
                      const SizedBox(height: 12),
                      WorldMissionBriefingCard(plan: missionPlan),
                    ],
                    const SizedBox(height: 16),
                  ],
                  if (adaptivePolicy != null) ...[
                    AdaptiveDifficultyBanner(policy: adaptivePolicy),
                    const SizedBox(height: 12),
                  ],
                  if (_skillStudioPlan != null) ...[
                    _SkillStudioFreshPracticeBanner(
                      plan: _skillStudioPlan!,
                      compact: shortWideInteractive,
                    ),
                    SizedBox(height: shortWideInteractive ? 8 : 12),
                  ],
                  if (shortWideInteractive)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: MissionSessionProgress(
                            step: sessionStep,
                            session: session,
                            plan: missionPlan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: LearningNarrationBar(
                            key: ValueKey<String>(
                              'lesson_audio:${narrationCue.id}',
                            ),
                            cue: narrationCue,
                            autoNarrate: true,
                            compact: true,
                            denseTranscript: true,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    MissionSessionProgress(
                      step: sessionStep,
                      session: session,
                      plan: missionPlan,
                    ),
                    const SizedBox(height: 12),
                    LearningNarrationBar(
                      key: ValueKey<String>('lesson_audio:${narrationCue.id}'),
                      cue: narrationCue,
                      autoNarrate: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (!needsResponse)
                    MissionTeachingStage(
                      sessionStep: sessionStep,
                      lessonStep: step,
                      activity: activity,
                      plan: missionPlan,
                      onShowWhy: step.kind == LessonStepKind.explanation ||
                              step.kind == LessonStepKind.workedExample
                          ? () => _showWhy(context, step.body)
                          : null,
                    )
                  else ...[
                    _MissionPlayBrief(
                      sessionStep: sessionStep,
                      step: step,
                      activity: activity,
                      plan: missionPlan,
                    ),
                    if (activity.payload['masteryEligible'] == false) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        label:
                            'Practice only. Secure mastery needs an adult-reviewed constructed response.',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE8C78D),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.edit_note_rounded),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Practice only — this activity builds the skill, but it does not award secure mastery. A constructed response still needs adult review.',
                                  style: TextStyle(
                                    color: AppTheme.inkMuted,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    LessonActivityInteraction(
                      key: ValueKey(step.id),
                      activity: activity,
                      experimentChoices:
                          _experimentChoices(repository, activity),
                      guidance: _guidanceFor(
                        context: context,
                        session: session,
                        sessionStep: sessionStep,
                        activity: activity,
                        policy: adaptivePolicy,
                      ),
                      onAttempt: (evaluation, retries, responseTimeMs) =>
                          _recordAttempt(
                        context: context,
                        sessionStep: sessionStep,
                        activity: activity,
                        evaluation: evaluation,
                        retries: retries,
                        responseTimeMs: responseTimeMs,
                      ),
                    ),
                  ],
                  if (session.isLastStep(safeIndex) &&
                      canContinue &&
                      session.reviewStep != null) ...[
                    const SizedBox(height: 14),
                    MissionFutureReviewNote(
                      reviewText: session.reviewStep!.body,
                      plan: missionPlan,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SessionNavigation(
                    canContinue: canContinue,
                    isFirst: safeIndex == 0,
                    isLast: session.isLastStep(safeIndex),
                    nextLabel: _nextLabel(
                      session: session,
                      currentIndex: safeIndex,
                      missionPlan: missionPlan,
                    ),
                    finalIcon: missionPlan?.isBoss == true
                        ? Icons.workspace_premium_rounded
                        : Icons.sports_esports_rounded,
                    onBack: safeIndex == 0 ? null : _goBack,
                    onNext: !canContinue
                        ? null
                        : session.isLastStep(safeIndex)
                            ? _finishLesson
                            : _goNext,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authoredFlow.reviewStatus == 'approved'
                        ? 'Content reviewed.'
                        : 'Draft learning support — teacher review is still pending.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LearningGameGuidance _guidanceFor({
    required BuildContext context,
    required MissionSession session,
    required MissionSessionStep sessionStep,
    required ContentActivity activity,
    required AdaptiveMissionPolicy? policy,
  }) {
    final step = sessionStep.lessonStep;
    final mode = switch (sessionStep.supportMode) {
      MissionSupportMode.coached => LearningGamePlayMode.coached,
      MissionSupportMode.independent => LearningGamePlayMode.solo,
      MissionSupportMode.transfer => LearningGamePlayMode.transfer,
      MissionSupportMode.checkpoint => LearningGamePlayMode.checkpoint,
      MissionSupportMode.challenge => LearningGamePlayMode.challenge,
      MissionSupportMode.mastery => LearningGamePlayMode.mastery,
      MissionSupportMode.observe => throw StateError(
          'Observe-only session steps do not build gameplay guidance.',
        ),
    };
    final authoredHints = <String>[];
    for (final text in <String>[
      ...step.hints,
      ...activity.hints.toList(growable: false).map((hint) => hint.text),
    ]) {
      final normalized = text.trim();
      if (normalized.isEmpty || authoredHints.contains(normalized)) continue;
      authoredHints.add(normalized);
    }
    final hintsEnabled = policy?.hintsEnabled ?? true;
    final rescueEnabled = policy?.rescueEnabled ?? true;
    return LearningGameGuidance(
      mode: mode,
      hints: hintsEnabled
          ? List<String>.unmodifiable(authoredHints)
          : const <String>[],
      rescueText: rescueEnabled ? session.reteachStep?.body : null,
      allowPreAttemptHints:
          policy?.allowPreAttemptHints ?? sessionStep.allowsPreAttemptCoaching,
      hintsEnabled: hintsEnabled,
      hintUnlockAfterMisses: policy?.hintUnlockAfterMisses ?? 1,
      rescueEnabled: rescueEnabled,
      rescueUnlockAfterMisses: policy?.rescueUnlockAfterMisses ?? 2,
      onHintRevealed: (hintIndex, text) => _recordHintReveal(
        context: context,
        hintIndex: hintIndex,
        text: text,
      ),
    );
  }

  void _recordHintReveal({
    required BuildContext context,
    required int hintIndex,
    required String text,
  }) {
    if (_shownHints.contains(hintIndex)) return;
    setState(() => _shownHints.add(hintIndex));
    _persistLessonState();
    if (text.trim().isNotEmpty) {
      FeedbackService.hint(BrightQuestScope.of(context), text);
    }
  }

  List<String> _experimentChoices(
    ContentRepository repository,
    ContentActivity activity,
  ) {
    if (activity.correctResponseRule['type'] != 'experimentOutcome') {
      return const <String>[];
    }
    final choices = <String>{};
    for (final candidate
        in repository.packForClass(activity.classNumber).activities) {
      if (candidate.gameId != 'science_lab') continue;
      final required = candidate.payload['requiredIngredients'];
      if (required is List) choices.addAll(required.whereType<String>());
    }
    return choices.toList()..sort();
  }

  void _recordAttempt({
    required BuildContext context,
    required MissionSessionStep sessionStep,
    required ContentActivity activity,
    required ActivityEvaluation evaluation,
    required int retries,
    required int responseTimeMs,
  }) {
    if (_attemptInFlight) return;
    _attemptInFlight = true;
    unawaited(
      _recordAttemptSafely(
        context: context,
        sessionStep: sessionStep,
        activity: activity,
        evaluation: evaluation,
        retries: retries,
        responseTimeMs: responseTimeMs,
      ),
    );
  }

  Future<void> _recordAttemptSafely({
    required BuildContext context,
    required MissionSessionStep sessionStep,
    required ContentActivity activity,
    required ActivityEvaluation evaluation,
    required int retries,
    required int responseTimeMs,
  }) async {
    try {
      final controller = BrightQuestScope.of(context);
      final now = DateTime.now();
      final step = sessionStep.lessonStep;
      final kind = sessionStep.supportMode == MissionSupportMode.mastery
          ? LearningAttemptKind.transfer
          : switch (step.kind) {
              LessonStepKind.guidedTry => LearningAttemptKind.guided,
              LessonStepKind.transfer => LearningAttemptKind.transfer,
              _ => LearningAttemptKind.independent,
            };
      const evaluator = ActivityResponseEvaluator();
      final responseLabel = evaluator.responseLabel(evaluation.response);
      final masteryEligible = activity.payload['masteryEligible'] != false;
      if (masteryEligible) {
        final evidenceId = controller.activeSessionEvidenceId(
              gameId: activity.gameId,
              learningLevel: widget.level,
              marker: 'lesson:${step.id}:$_attemptSerial:$responseLabel',
            ) ??
            'lesson:${controller.activeProfileId}:${now.microsecondsSinceEpoch}';
        await controller.recordLearningEvidenceSafely(
          AttemptEvidence(
            id: evidenceId,
            profileId: controller.activeProfileId,
            classNumber: activity.classNumber,
            competencyId: activity.competencyId,
            itemId: activity.id,
            kind: kind,
            correct: evaluation.correct,
            hintLevel: _shownHints.length.clamp(0, 2).toInt(),
            retries: retries.clamp(0, 99).toInt(),
            responseTimeMs: responseTimeMs.clamp(0, 3600000).toInt(),
            confidence:
                evaluation.correct ? (retries == 0 ? 0.88 : 0.68) : 0.45,
            recordedAtIso: now.toIso8601String(),
            misconceptionId: evaluation.misconceptionId,
            sourceGameId: activity.gameId,
          ),
        );
      } else {
        await controller.flush();
      }
      if (!mounted) return;
      _attemptSerial += 1;

      const resolver = GameplayActivityResolver();
      const feedbackEngine = ContextualFeedbackEngine();
      final feedback = feedbackEngine.build(
        activity: activity,
        spec: resolver.resolve(activity),
        evaluation: evaluation,
        attemptNumber: retries + 1,
        revealedHintCount: _shownHints.length,
        hasUnrevealedHint: false,
        rescueAvailable: sessionStep.supportMode != MissionSupportMode.mastery,
      );
      if (evaluation.correct) {
        FeedbackService.correct(
          controller,
          answer: responseLabel,
          detail: activity.explanation,
        );
        setState(() => _completedInteractiveSteps.add(step.id));
      } else {
        FeedbackService.wrong(
          controller,
          answer: responseLabel,
          guidance: '${feedback.message} ${feedback.strategy}',
        );
      }
      _persistLessonState();
    } finally {
      _attemptInFlight = false;
    }
  }

  void _goBack() {
    setState(() {
      index -= 1;
      _shownHints.clear();
    });
    _persistLessonState();
  }

  void _goNext() {
    setState(() {
      index += 1;
      _shownHints.clear();
    });
    _persistLessonState();
  }

  void _finishLesson() {
    final level = widget.level;
    if (level != null) {
      BrightQuestScope.of(context).transitionActiveSessionToGame(level: level);
      Navigator.of(context).pop(true);
      return;
    }
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    _createSkillStudioPlan(
      controller: controller,
      repository: repository,
    );
    setState(() {
      index = 0;
      _recordedSkillActivityIds.clear();
      _shownHints.clear();
      _completedInteractiveSteps.clear();
      _attemptSerial = 0;
    });
  }

  void _createSkillStudioPlan({
    required GameController controller,
    required ContentRepository repository,
  }) {
    final classNumber = widget.classNumber!;
    final competencyId = widget.competencyId!;
    const planner = SkillStudioPracticePlanner();
    final plan = planner.plan(
      repository: repository,
      classNumber: classNumber,
      competencyId: competencyId,
      history: controller.missionExposureHistoryForGame(
        classNumber: classNumber,
        gameId: 'skill_studio',
      ),
      learningState: controller.learningState,
    );
    _skillStudioPlan = plan;
  }

  void _recordSkillStudioActivitySeen({
    required GameController controller,
    required ContentRepository repository,
    required ContentActivity activity,
  }) {
    final plan = _skillStudioPlan;
    if (plan == null || _recordedSkillActivityIds.contains(activity.id)) return;
    _recordedSkillActivityIds.add(activity.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _skillStudioPlan?.runId != plan.runId) return;
      const planner = SkillStudioPracticePlanner();
      final records = planner
          .exposureRecords(
            repository: repository,
            plan: plan,
            seenAt: DateTime.now().toUtc(),
          )
          .where((record) => record.activityKey.endsWith('|${activity.id}'));
      if (controller.recordMissionExposureRecords(
        classNumber: plan.classNumber,
        runId: '${plan.runId}:seen:${activity.id}',
        records: records,
      )) {
        unawaited(controller.flush());
      }
    });
  }

  void _persistLessonState() {
    final level = widget.level;
    if (level == null || !_sessionRestored) return;
    final repository = BrightQuestScope.contentOf(context);
    final controller = BrightQuestScope.of(context);
    final policy = const AdaptiveDifficultyEngine().forLevel(
      level: level,
      levelProgress: controller.levelStatsFor(level.id),
      gameProgress: controller.statsFor(level.gameId),
    );
    final authoredFlow = const LessonEngine().buildForLevel(
      repository: repository,
      level: level,
      missionRunPlan: _missionRunPlan,
    );
    final session = const MissionSessionEngine().build(
      authoredFlow,
      policy: policy,
    );
    controller.checkpointLessonSession(
      level: level,
      stepIndex: index,
      totalSteps: session.steps.length,
      completedInteractiveStepIds: _completedInteractiveSteps,
      shownHintIndices: _shownHints,
      attemptSerial: _attemptSerial,
    );
  }

  String _nextLabel({
    required MissionSession session,
    required int currentIndex,
    required WorldMissionPlan? missionPlan,
  }) {
    if (session.isLastStep(currentIndex)) {
      if (widget.isDirectCompetency) return 'Practice another fresh set';
      if (missionPlan == null) return 'Enter main mission';
      return missionPlan.isBoss
          ? 'Face ${missionPlan.phaseLabel}'
          : 'Play ${missionPlan.phaseLabel}';
    }
    if (widget.isDirectCompetency) return 'Continue';
    final current = session.stepAt(currentIndex);
    final next = session.stepAt(currentIndex + 1);
    if (current.phase != next.phase) return 'Next: ${next.phase.label}';
    return 'Continue ${current.phase.label}';
  }

  void _showWhy(BuildContext context, String text) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Why this works\n\n$text\n\nSay the rule in your own words, then change one part of the example and check whether the same reasoning still works.',
            style: const TextStyle(height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SkillStudioFreshPracticeBanner extends StatelessWidget {
  const _SkillStudioFreshPracticeBanner({
    required this.plan,
    this.compact = false,
  });

  final SkillStudioPracticePlan plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final title = plan.freshCandidateCount > 0
        ? 'Fresh practice set'
        : 'Spaced review set';
    if (compact) {
      return Semantics(
        container: true,
        label: '$title. ${plan.selectionReason}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: .16)),
          ),
          child: Row(
            children: [
              Icon(Icons.autorenew_rounded, color: color, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.autorenew_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  plan.selectionReason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionPlayBrief extends StatelessWidget {
  const _MissionPlayBrief({
    required this.sessionStep,
    required this.step,
    required this.activity,
    required this.plan,
  });

  final MissionSessionStep sessionStep;
  final LessonStep step;
  final ContentActivity activity;
  final WorldMissionPlan? plan;

  @override
  Widget build(BuildContext context) {
    final palette =
        plan == null ? null : paletteForSubject(plan!.identity.subject);
    final accent = palette?.primary ?? Theme.of(context).colorScheme.primary;
    final deep = palette?.deep ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: .10),
            Colors.white.withValues(alpha: .96),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sessionStep.phase.emoji, style: const TextStyle(fontSize: 27)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionStep.phase.shortLabel,
                  style: TextStyle(
                    color: deep,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: .65,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (step.body.trim() != activity.prompt.trim()) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.body,
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionNavigation extends StatelessWidget {
  const _SessionNavigation({
    required this.canContinue,
    required this.isFirst,
    required this.isLast,
    required this.nextLabel,
    required this.finalIcon,
    required this.onBack,
    required this.onNext,
  });

  final bool canContinue;
  final bool isFirst;
  final bool isLast;
  final String nextLabel;
  final IconData finalIcon;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          OutlinedButton(
            onPressed: isFirst ? null : onBack,
            child: const Text('Back'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: canContinue ? onNext : null,
                icon: Icon(
                  !canContinue
                      ? Icons.lock_outline_rounded
                      : isLast
                          ? finalIcon
                          : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  !canContinue ? 'Complete the play step' : nextLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      );
}
