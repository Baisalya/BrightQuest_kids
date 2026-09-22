import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/learning/game_turn_pacing.dart';
import '../../core/learning/endless_practice_coordinator.dart';
import '../../core/learning/mission_run_game_content.dart';
import '../../core/learning/mission_run_models.dart';
import '../../core/learning/mission_run_session_coordinator.dart';
import '../../core/learning/learning_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import '../../widgets/game_turn_timer.dart';

class ScienceLabScreen extends StatefulWidget {
  const ScienceLabScreen({
    this.learningLevel,
    this.endlessPractice = false,
    super.key,
  });
  final LearningLevel? learningLevel;
  final bool endlessPractice;

  @override
  State<ScienceLabScreen> createState() => _ScienceLabScreenState();
}

class _ScienceLabScreenState extends State<ScienceLabScreen> {
  static const BrightSfxProfile _soundProfile = BrightSfxProfile.scienceLab;

  void _playInteraction(BrightInteractionSfx effect) {
    unawaited(
      BrightAudioService.instance.playProfileSfx(_soundProfile, effect),
    );
  }

  final Set<String> ingredients = <String>{};
  int quizIndex = 0;
  int quizScore = 0;
  String? selectedQuiz;
  bool? quizCorrect;
  bool experimentRecorded = false;
  DateTime _quizStarted = DateTime.now();
  bool finished = false;
  MissionReward? missionReward;
  int _difficulty = 1;
  int _classNumber = 4;
  int _attemptSerial = 0;
  bool _answerInFlight = false;
  bool _timedOut = false;
  bool _sessionConfigured = false;
  MissionRunPlan? _missionRunPlan;
  List<ScienceQuizQuestion> _questions = const <ScienceQuizQuestion>[];

  bool get _experimentRequired => !widget.endlessPractice;

  int get _maxScore => _questions.length + (_experimentRequired ? 1 : 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionConfigured) return;
    final controller = BrightQuestScope.of(context);
    _classNumber =
        widget.learningLevel?.classNumber ?? controller.selectedClass;
    _difficulty = controller.resumableDifficulty(
      gameId: 'science_lab',
      classNumber: _classNumber,
      fallbackDifficulty: widget.endlessPractice
          ? 3
          : widget.learningLevel?.difficulty ??
              controller.recommendedDifficulty('science_lab'),
      learningLevelId: widget.learningLevel?.id,
    );
    final repository = BrightQuestScope.contentOf(context);
    final existingCheckpoint = controller.gameSessionFor(
      gameId: 'science_lab',
      classNumber: _classNumber,
      learningLevelId: widget.learningLevel?.id,
    );
    final level = widget.learningLevel;
    if (level != null) {
      _missionRunPlan = const MissionRunSessionCoordinator().restore(
        repository: repository,
        level: level,
        data: existingCheckpoint?.data ?? const <String, Object?>{},
      );
    } else if (widget.endlessPractice) {
      _missionRunPlan = const EndlessPracticeCoordinator().createOrRestore(
        repository: repository,
        classNumber: _classNumber,
        gameId: 'science_lab',
        checkpoint: existingCheckpoint,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'science_lab',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('science_lab'),
      );
    }
    _questions = _missionRunPlan == null
        ? repository.scienceQuestionsForClass(
            _classNumber,
            difficulty: _difficulty,
          )
        : const MissionRunGameContent().scienceQuestions(
            repository: repository,
            plan: _missionRunPlan!,
          );
    if (_questions.isEmpty) {
      throw StateError('Science Lab cannot start without quiz questions.');
    }
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'science_lab',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: _maxScore,
      learningLevel: widget.learningLevel,
      sessionData: _missionRunPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(
              _missionRunPlan!,
            ),
    );
    quizIndex = checkpoint.cursor.clamp(0, _questions.length - 1).toInt();
    quizScore = (checkpoint.data['quizScore'] as num?)?.toInt() ?? 0;
    ingredients
      ..clear()
      ..addAll((checkpoint.data['ingredients'] as List?)?.whereType<String>() ??
          const <String>[]);
    selectedQuiz = checkpoint.data['selectedQuiz'] as String?;
    quizCorrect = checkpoint.data['quizCorrect'] as bool?;
    _timedOut = checkpoint.data['timedOut'] as bool? ?? false;
    experimentRecorded =
        checkpoint.data['experimentRecorded'] as bool? ?? false;
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    if (checkpoint.stage == GameSessionStage.result &&
        checkpoint.reward != null) {
      finished = true;
      missionReward = checkpoint.reward!.toReward();
    }
    _sessionConfigured = true;
  }

  void _addIngredient(String ingredient) {
    if (finished) return;
    _playInteraction(BrightInteractionSfx.option);
    setState(() => ingredients.add(ingredient));
    final reaction = BrightQuestScope.contentOf(context)
        .scienceReactionForIngredients(_classNumber, ingredients);
    if (reaction.id == 'fizz' && !experimentRecorded) {
      if (_answerInFlight) return;
      _playInteraction(BrightInteractionSfx.action);
      _answerInFlight = true;
      unawaited(_recordExperimentSafely(reaction.title, reaction.explanation));
      return;
    }
    _checkpoint();
  }

  Future<void> _recordExperimentSafely(
    String reactionTitle,
    String reactionExplanation,
  ) async {
    try {
      final controller = BrightQuestScope.of(context);
      final activity =
          BrightQuestScope.contentOf(context).activityForScienceReaction(
        classNumber: _classNumber,
        reactionId: 'fizz',
      );
      await controller.recordAnswerSafely(
        gameId: 'science_lab',
        learningLevel: widget.learningLevel,
        correct: true,
        attemptMarker:
            'answer:$_attemptSerial:experiment:${(ingredients.toList()..sort()).join('|')}',
        topicId: activity?.topicId ?? 'reactions',
        difficulty: activity?.difficulty ?? _difficulty,
        masteryGain: 0.06,
        coinReward: 8,
        xpReward: 12,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: LearningAttemptKind.guided,
        responseTimeMs: DateTime.now().difference(_quizStarted).inMilliseconds,
        confidence: 0.8,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      FeedbackService.correct(
        controller,
        answer: reactionTitle,
        detail: reactionExplanation,
        soundProfile: _soundProfile,
      );
      setState(() => experimentRecorded = true);
      _checkpoint();
    } finally {
      _answerInFlight = false;
    }
  }

  void _clearExperiment() {
    if (finished || _answerInFlight) return;
    _playInteraction(BrightInteractionSfx.tap);
    setState(ingredients.clear);
    _checkpoint();
  }

  void _answerQuiz(ScienceQuizQuestion question, String value) {
    if (selectedQuiz != null || _timedOut || finished || _answerInFlight) return;
    _playInteraction(BrightInteractionSfx.option);
    setState(() => _answerInFlight = true);
    unawaited(_answerQuizSafely(question, value));
  }

  Future<void> _answerQuizSafely(
    ScienceQuizQuestion question,
    String value,
  ) async {
    final answeredIndex = quizIndex;
    try {
      final correct = value == question.answer;
      final controller = BrightQuestScope.of(context);
      final adapter = const GameEvidenceAdapter();
      final activity = adapter.resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'science_lab',
        legacyContentId: question.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'science_lab',
        learningLevel: widget.learningLevel,
        correct: correct,
        attemptMarker: 'answer:$_attemptSerial:$value',
        topicId: question.topicId,
        difficulty: question.difficulty,
        masteryGain: 0.05,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: adapter.kindFor(widget.learningLevel),
        responseTimeMs: DateTime.now().difference(_quizStarted).inMilliseconds,
        misconceptionId:
            correct ? null : adapter.misconceptionFor(activity, value),
        confidence: 0.84,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      setState(() {
        selectedQuiz = value;
        quizCorrect = correct;
        if (correct) quizScore += 1;
      });
      _checkpoint();

      final pacing = const GameTurnPacingPolicy().forGame(
        gameId: 'science_lab',
        learningLevel: widget.learningLevel,
        endlessPractice: widget.endlessPractice,
      );
      if (correct && pacing.autoAdvanceCorrect && controller.soundEnabled) {
        await FeedbackService.correctAndWait(
          controller,
          answer: value,
          detail: question.explanation,
          minimumDuration: const Duration(milliseconds: 1200),
          soundProfile: _soundProfile,
        );
        if (!mounted ||
            quizIndex != answeredIndex ||
            selectedQuiz != value ||
            quizCorrect != true) {
          return;
        }
        await _nextQuiz(_questions, _classNumber);
      } else if (correct) {
        FeedbackService.correct(
          controller,
          answer: value,
          detail: question.explanation,
          soundProfile: _soundProfile,
        );
      } else if (pacing.isTimed) {
        await FeedbackService.wrongAndWait(
          controller,
          answer: value,
          correctAnswer: question.answer,
          guidance: question.explanation,
          minimumDuration: const Duration(milliseconds: 1200),
          soundProfile: _soundProfile,
        );
      } else {
        FeedbackService.wrong(
          controller,
          answer: value,
          correctAnswer: question.answer,
          guidance: question.explanation,
          soundProfile: _soundProfile,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _answerInFlight = false);
      } else {
        _answerInFlight = false;
      }
    }
  }

  Future<void> _expireQuiz(ScienceQuizQuestion question) async {
    if (selectedQuiz != null || _timedOut || finished || _answerInFlight) return;
    setState(() => _answerInFlight = true);
    try {
      final controller = BrightQuestScope.of(context);
      final adapter = const GameEvidenceAdapter();
      final activity = adapter.resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'science_lab',
        legacyContentId: question.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'science_lab',
        learningLevel: widget.learningLevel,
        correct: false,
        attemptMarker: 'timeout:$_attemptSerial',
        topicId: question.topicId,
        difficulty: question.difficulty,
        masteryGain: 0.05,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: adapter.kindFor(widget.learningLevel),
        responseTimeMs: DateTime.now().difference(_quizStarted).inMilliseconds,
        misconceptionId: 'time_limit_exceeded',
        confidence: 0.35,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      setState(() {
        _timedOut = true;
        quizCorrect = false;
      });
      _checkpoint();
      await FeedbackService.wrongAndWait(
        controller,
        correctAnswer: question.answer,
        guidance: 'Time is up. ${question.explanation}',
        minimumDuration: const Duration(milliseconds: 1200),
        soundProfile: _soundProfile,
      );
    } finally {
      if (mounted) {
        setState(() => _answerInFlight = false);
      } else {
        _answerInFlight = false;
      }
    }
  }

  Future<void> _nextQuiz(
    List<ScienceQuizQuestion> questions,
    int classNumber,
  ) async {
    if (selectedQuiz == null && !_timedOut) return;
    if (quizIndex == questions.length - 1) {
      if (_experimentRequired && !experimentRecorded) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Complete the fizzing experiment before finishing the lab.')));
        return;
      }
      final totalScore =
          quizScore + (_experimentRequired && experimentRecorded ? 1 : 0);
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'science_lab',
        fallbackMissionId: widget.endlessPractice
            ? 'endless_practice:c$classNumber:science_lab'
            : 'science_lab:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        practiceOnly: widget.endlessPractice,
        score: totalScore,
        maxScore: questions.length + (_experimentRequired ? 1 : 0),
      );
      if (!mounted) return;
      FeedbackService.complete(
        controller,
        reward: reward,
        soundProfile: _soundProfile,
      );
      setState(() {
        finished = true;
        missionReward = reward;
      });
      return;
    }
    setState(() {
      quizIndex += 1;
      selectedQuiz = null;
      quizCorrect = null;
      _timedOut = false;
      _quizStarted = DateTime.now();
    });
    _checkpoint();
  }

  void _restart() {
    final repository = BrightQuestScope.contentOf(context);
    final controller = BrightQuestScope.of(context);
    var nextPlan = _missionRunPlan;
    var nextQuestions = _questions;
    final level = widget.learningLevel;
    if (level != null && _missionRunPlan != null) {
      nextPlan = const MissionRunSessionCoordinator().createWorldReplay(
        repository: repository,
        level: level,
        previousPlan: _missionRunPlan!,
        history: controller.missionExposureHistoryFor(level),
        learningState: controller.learningState,
        levelProgress: controller.levelStatsFor(level.id),
        gameProgress: controller.statsFor(level.gameId),
      );
      nextQuestions = const MissionRunGameContent().scienceQuestions(
        repository: repository,
        plan: nextPlan,
      );
    } else if (widget.endlessPractice && _missionRunPlan != null) {
      nextPlan = const EndlessPracticeCoordinator().createNextRound(
        repository: repository,
        previousPlan: _missionRunPlan!,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'science_lab',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('science_lab'),
      );
      nextQuestions = const MissionRunGameContent().scienceQuestions(
        repository: repository,
        plan: nextPlan,
      );
    } else {
      nextQuestions = repository.scienceQuestionsForClass(
        _classNumber,
        difficulty: _difficulty,
      );
    }
    controller.restartActiveGameSession(
      gameId: 'science_lab',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: nextQuestions.length + (_experimentRequired ? 1 : 0),
      learningLevel: widget.learningLevel,
      sessionData: nextPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(nextPlan),
    );
    setState(() {
      _missionRunPlan = nextPlan;
      _questions = nextQuestions;
      ingredients.clear();
      quizIndex = 0;
      quizScore = 0;
      _attemptSerial = 0;
      selectedQuiz = null;
      quizCorrect = null;
      _timedOut = false;
      _quizStarted = DateTime.now();
      experimentRecorded = false;
      finished = false;
      missionReward = null;
    });
  }

  void _checkpoint() {
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'science_lab',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: quizIndex,
      score: quizScore + (_experimentRequired && experimentRecorded ? 1 : 0),
      maxScore: _maxScore,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        'ingredients': ingredients.toList()..sort(),
        'quizScore': quizScore,
        if (selectedQuiz != null) 'selectedQuiz': selectedQuiz,
        if (quizCorrect != null) 'quizCorrect': quizCorrect,
        'timedOut': _timedOut,
        'experimentRecorded': experimentRecorded,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final questions = _questions;
    final reaction = BrightQuestScope.contentOf(context)
        .scienceReactionForIngredients(classNumber, ingredients);
    final question = questions[quizIndex];
    final pacing = const GameTurnPacingPolicy().forGame(
      gameId: 'science_lab',
      learningLevel: widget.learningLevel,
      endlessPractice: widget.endlessPractice,
    );
    final timedQuizReady = !_experimentRequired || experimentRecorded;

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Science Lab',
      subtitle: widget.endlessPractice
          ? 'Class $classNumber • ∞ Endless Practice • 10 rotating missions'
          : widget.learningLevel == null
              ? 'Class $classNumber • Adaptive level $_difficulty • Mix & Discover'
              : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF7B4EEB),
      voicePrompt: question.question,
      voiceChoices: question.choices,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          GameProgressStrip(
              current: quizIndex + 1,
              total: questions.length,
              score: quizScore),
          const SizedBox(height: 14),
          if (_experimentRequired) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final experiment = _ExperimentPanel(
                  ingredients: ingredients,
                  reactionEmoji: reaction.emoji,
                  recorded: experimentRecorded,
                  onAdd: _addIngredient,
                  onClear: _clearExperiment,
                );
                final result = _ExperimentResult(
                  title: reaction.title,
                  explanation: reaction.explanation,
                  emoji: reaction.emoji,
                  success: reaction.id == 'fizz',
                  recorded: experimentRecorded,
                );
                if (!wide) {
                  return Column(
                    children: [
                      experiment,
                      const SizedBox(height: 12),
                      result,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: experiment),
                    const SizedBox(width: 14),
                    Expanded(child: result),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          if (pacing.turnLimit != null && timedQuizReady) ...[
            GameTurnTimer(
              duration: pacing.turnLimit!,
              resetKey: 'science:$quizIndex:${question.id}',
              paused: selectedQuiz != null || _timedOut || _answerInFlight || finished,
              onExpired: () => _expireQuiz(question),
            ),
            const SizedBox(height: 12),
          ] else if (pacing.turnLimit != null && !timedQuizReady) ...[
            const InfoBanner(
              icon: Icons.science_rounded,
              text: 'Complete the experiment above to start the timed quiz.',
            ),
            const SizedBox(height: 12),
          ],
          BrightSurface(
            borderColor: const Color(0xFF7B4EEB).withValues(alpha: 0.16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrightPill(
                    icon: Icons.quiz_rounded,
                    label: 'QUICK QUIZ',
                    color: Color(0xFF5934C8),
                    background: Color(0xFFF0E9FF)),
                const SizedBox(height: 11),
                Text(question.question,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.navy)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = constraints.maxWidth < 520
                        ? (constraints.maxWidth - 10) / 2
                        : 150.0;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(question.choices.length, (index) {
                        final item = question.choices[index];
                        final selected = selectedQuiz == item;
                        final answerState = selected
                            ? quizCorrect == true
                                ? const Color(0xFFE5F8E7)
                                : const Color(0xFFFFE5E5)
                            : const Color(0xFFF8FAFF);
                        return SizedBox(
                          width: tileWidth,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: selectedQuiz == null &&
                                    !_timedOut &&
                                    !_answerInFlight &&
                                    !finished &&
                                    (pacing.turnLimit == null || timedQuizReady)
                                ? () => _answerQuiz(question, item)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                  color: answerState,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: selected
                                          ? const Color(0xFF55AE46)
                                          : const Color(0x16000000),
                                      width: selected ? 2 : 1),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x10000000),
                                        blurRadius: 9,
                                        offset: Offset(0, 4))
                                  ]),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: selected
                                                ? const Color(0xFF55AE46)
                                                : const Color(0xFF2E78D7),
                                            shape: BoxShape.circle),
                                        child: Text(
                                            String.fromCharCode(65 + index),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900))),
                                    const Spacer(),
                                    Text(_scienceChoiceEmoji(item),
                                        style: const TextStyle(fontSize: 31))
                                  ]),
                                  const SizedBox(height: 7),
                                  Text(item,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.navy)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
          if (quizCorrect != null) ...[
            const SizedBox(height: 12),
            quizCorrect == true
                ? SuccessBanner(text: 'Correct! ${question.explanation}')
                : ErrorBanner(
                    text: _timedOut
                        ? 'Time is up. The answer is ${question.answer}. ${question.explanation}'
                        : 'Not quite. ${question.explanation}',
                  ),
          ],
          const SizedBox(height: 16),
          if (finished)
            MissionSummaryCard(
              learningLevel: widget.learningLevel,
              score: quizScore +
                  (_experimentRequired && experimentRecorded ? 1 : 0),
              maxScore: questions.length + (_experimentRequired ? 1 : 0),
              reward: missionReward,
              onReplay: _restart,
              replayLabel: widget.endlessPractice ? 'Next 10 Missions' : null,
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    (selectedQuiz == null && !_timedOut) || _answerInFlight
                        ? null
                        : () {
                            _playInteraction(BrightInteractionSfx.next);
                            unawaited(_nextQuiz(questions, classNumber));
                          },
                icon: Icon(quizIndex == questions.length - 1
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_rounded),
                label: Text(quizIndex == questions.length - 1
                    ? 'Finish Lab'
                    : 'Next Question'),
              ),
            ),
        ],
      ),
    );
  }
}

String _scienceChoiceEmoji(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('wood') || lower.contains('log')) return '🪵';
  if (lower.contains('rock') || lower.contains('stone')) return '🪨';
  if (lower.contains('apple') || lower.contains('fruit')) return '🍎';
  if (lower.contains('coin') || lower.contains('metal')) return '🪙';
  if (lower.contains('water')) return '💧';
  if (lower.contains('air')) return '💨';
  if (lower.contains('plant') || lower.contains('leaf')) return '🌿';
  if (lower.contains('sun')) return '☀️';
  return '🔬';
}

({Color? coat, Color? goggles}) _scienceMascotSkin(BuildContext context) {
  final cosmetic =
      BrightQuestScope.of(context).equippedCosmeticForGame('science_lab');
  return switch (cosmetic?.id) {
    'lion_lab_coat' => (
        coat: const Color(0xFFDCEEFF),
        goggles: const Color(0xFF2368B3),
      ),
    'science_nebula_coat' => (
        coat: const Color(0xFF574590),
        goggles: const Color(0xFF64DCEB),
      ),
    'science_rainbow_goggles' => (
        coat: const Color(0xFFFFEFF9),
        goggles: const Color(0xFFE33C9A),
      ),
    _ => (coat: null, goggles: null),
  };
}

class _ExperimentPanel extends StatelessWidget {
  const _ExperimentPanel(
      {required this.ingredients,
      required this.reactionEmoji,
      required this.recorded,
      required this.onAdd,
      required this.onClear});
  final Set<String> ingredients;
  final String reactionEmoji;
  final bool recorded;
  final ValueChanged<String> onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final mascotSkin = _scienceMascotSkin(context);
    const choices = <({String label, String emoji})>[
      (label: 'Water', emoji: '💧'),
      (label: 'Salt', emoji: '🧂'),
      (label: 'Baking Soda', emoji: '⚪'),
      (label: 'Vinegar', emoji: '🧴'),
    ];
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF7F1FF), Color(0xFFEAF7FF)]),
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: const Color(0xFF7B4EEB).withValues(alpha: 0.13)),
      ),
      child: Column(
        children: [
          const BrightSectionTitle(
              title: 'Virtual Experiment',
              subtitle:
                  'Find the two ingredients that create a fizzing reaction.',
              icon: Icons.science_rounded),
          const SizedBox(height: 14),
          Container(
            height: 172,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFF7B4EEB).withValues(alpha: .14))),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const BrightGameScene(gameId: 'science_lab'),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .32),
                        shape: BoxShape.circle),
                    child: Center(
                      child: BrightValuePop(
                        value: reactionEmoji,
                        child: Text(reactionEmoji,
                            style: const TextStyle(fontSize: 68)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                    right: 6,
                    bottom: -3,
                    child: SizedBox(
                        width: 95,
                        child: BrightLionMascot(
                          size: 90,
                          scientist: true,
                          scientistCoatColor: mascotSkin.coat,
                          scientistGoggleColor: mascotSkin.goggles,
                        ))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
              ingredients.isEmpty ? 'Beaker is ready' : ingredients.join(' + '),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppTheme.navy)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: choices.map((choice) {
              final selected = ingredients.contains(choice.label);
              return FilterChip(
                avatar: Text(choice.emoji),
                label: Text(choice.label,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: selected,
                onSelected: selected ? null : (_) => onAdd(choice.label),
              );
            }).toList(),
          ),
          const SizedBox(height: 9),
          TextButton.icon(
              onPressed: ingredients.isEmpty ? null : onClear,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear beaker')),
          if (recorded)
            const SuccessBanner(
                text:
                    'Experiment discovered! This step is recorded once for this run.'),
        ],
      ),
    );
  }
}

class _ExperimentResult extends StatelessWidget {
  const _ExperimentResult(
      {required this.title,
      required this.explanation,
      required this.emoji,
      required this.success,
      required this.recorded});
  final String title;
  final String explanation;
  final String emoji;
  final bool success;
  final bool recorded;

  @override
  Widget build(BuildContext context) {
    final mascotSkin = _scienceMascotSkin(context);
    return BrightSurface(
      color: success ? const Color(0xFFF2EBFF) : Colors.white,
      borderColor: success ? const Color(0xFFB8A4FF) : const Color(0x14000000),
      child: Column(
        children: [
          const BrightPill(
              icon: Icons.auto_awesome_rounded,
              label: 'EXPERIMENT RESULT',
              color: Color(0xFF2C8A4C),
              background: Color(0xFFE7F7EC)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8D8FF), Color(0xFFF8ECFF)]),
                borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                Expanded(
                  child: BrightValuePop(
                    value: emoji,
                    child: Text(emoji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 64)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                    width: 92,
                    child: BrightLionMascot(
                      size: 88,
                      scientist: true,
                      scientistCoatColor: mascotSkin.coat,
                      scientistGoggleColor: mascotSkin.goggles,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy)),
          const SizedBox(height: 7),
          Text(explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.inkMuted, height: 1.4)),
          const SizedBox(height: 12),
          BrightMascotBubble(
              message: recorded
                  ? 'Great discovery! Now finish the quiz.'
                  : 'Try different pairs and watch what changes!',
              emoji: '🧪',
              compact: true),
        ],
      ),
    );
  }
}
