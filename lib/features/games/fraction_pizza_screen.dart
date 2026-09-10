import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/gameplay/game_logic.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/learning/endless_practice_coordinator.dart';
import '../../core/learning/mission_run_game_content.dart';
import '../../core/learning/mission_run_models.dart';
import '../../core/learning/mission_run_session_coordinator.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../widgets/bright_widgets.dart';

class FractionPizzaScreen extends StatefulWidget {
  const FractionPizzaScreen({
    this.learningLevel,
    this.endlessPractice = false,
    super.key,
  });

  final LearningLevel? learningLevel;
  final bool endlessPractice;

  @override
  State<FractionPizzaScreen> createState() => _FractionPizzaScreenState();
}

class _FractionPizzaScreenState extends State<FractionPizzaScreen> {
  int missionIndex = 0;
  int selectedSlices = 0;
  int score = 0;
  bool checked = false;
  bool? correct;
  bool hadMistake = false;
  bool finished = false;
  MissionReward? missionReward;
  int _difficulty = 1;
  int _classNumber = 4;
  int _attemptSerial = 0;
  bool _answerInFlight = false;
  bool _sessionConfigured = false;
  MissionRunPlan? _missionRunPlan;
  List<FractionMission> _missions = const <FractionMission>[];
  DateTime _itemStarted = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionConfigured) return;
    final controller = BrightQuestScope.of(context);
    _classNumber =
        widget.learningLevel?.classNumber ?? controller.selectedClass;
    _difficulty = controller.resumableDifficulty(
      gameId: 'fraction_pizza',
      classNumber: _classNumber,
      fallbackDifficulty: widget.endlessPractice
          ? 3
          : widget.learningLevel?.difficulty ??
              controller.recommendedDifficulty('fraction_pizza'),
      learningLevelId: widget.learningLevel?.id,
    );
    final repository = BrightQuestScope.contentOf(context);
    final existingCheckpoint = controller.gameSessionFor(
      gameId: 'fraction_pizza',
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
        gameId: 'fraction_pizza',
        checkpoint: existingCheckpoint,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'fraction_pizza',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('fraction_pizza'),
      );
    }
    _missions = _missionRunPlan == null
        ? repository.fractionMissionsForClass(
            _classNumber,
            difficulty: _difficulty,
          )
        : const MissionRunGameContent().fractionMissions(
            repository: repository,
            plan: _missionRunPlan!,
          );
    if (_missions.isEmpty) {
      throw StateError('Fraction Pizza cannot start without missions.');
    }
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'fraction_pizza',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: _missions.length,
      learningLevel: widget.learningLevel,
      sessionData: _missionRunPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(
              _missionRunPlan!,
            ),
    );
    missionIndex = checkpoint.cursor.clamp(0, _missions.length - 1).toInt();
    score = checkpoint.score.clamp(0, _missions.length).toInt();
    selectedSlices = (checkpoint.data['selectedSlices'] as num?)?.toInt() ?? 0;
    checked = checkpoint.data['checked'] as bool? ?? false;
    correct = checkpoint.data['correct'] as bool?;
    hadMistake = checkpoint.data['hadMistake'] as bool? ?? false;
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    if (checkpoint.stage == GameSessionStage.result &&
        checkpoint.reward != null) {
      finished = true;
      missionReward = checkpoint.reward!.toReward();
    }
    _sessionConfigured = true;
  }

  void _select(int count) {
    if (finished || correct == true) return;
    setState(() {
      selectedSlices = count;
      checked = false;
      correct = null;
    });
    _checkpoint();
  }

  Future<void> _check(FractionMission mission) async {
    if (checked || selectedSlices == 0 || _answerInFlight) return;
    _answerInFlight = true;
    try {
      final isCorrect = fractionMatches(
        selectedSlices: selectedSlices,
        totalSlices: mission.totalSlices,
        targetNumerator: mission.numerator,
        targetDenominator: mission.denominator,
      );
      final controller = BrightQuestScope.of(context);
      final repository = BrightQuestScope.contentOf(context);
      const adapter = GameEvidenceAdapter();
      final activity = adapter.resolve(
        repository: repository,
        classNumber: _classNumber,
        gameId: 'fraction_pizza',
        legacyContentId: mission.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'fraction_pizza',
        learningLevel: widget.learningLevel,
        correct: isCorrect,
        attemptMarker: 'answer:$_attemptSerial:$selectedSlices',
        topicId: mission.topicId,
        difficulty: mission.difficulty,
        masteryGain: 0.07,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: adapter.kindFor(widget.learningLevel),
        retries: hadMistake ? 1 : 0,
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId:
            isCorrect ? null : 'fraction_equal_parts_or_equivalence',
      );
      if (!mounted) return;
      _attemptSerial += 1;
      final chosen = '$selectedSlices of ${mission.totalSlices} slices';
      final expected =
          '${mission.numerator} out of ${mission.denominator} equal parts';
      if (isCorrect) {
        FeedbackService.correct(
          controller,
          answer: chosen,
          detail: 'That matches $expected.',
        );
      } else {
        FeedbackService.wrong(
          controller,
          answer: chosen,
          correctAnswer: expected,
          guidance: 'Adjust the slices and try again.',
        );
      }
      setState(() {
        checked = true;
        correct = isCorrect;
        if (isCorrect && !hadMistake) score += 1;
        if (!isCorrect) hadMistake = true;
      });
      _checkpoint();
    } finally {
      _answerInFlight = false;
    }
  }

  Future<void> _next(List<FractionMission> missions, int classNumber) async {
    if (correct != true) return;
    if (missionIndex == missions.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'fraction_pizza',
        fallbackMissionId: widget.endlessPractice
            ? 'endless_practice:c$classNumber:fraction_pizza'
            : 'fraction_pizza:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        practiceOnly: widget.endlessPractice,
        score: score,
        maxScore: missions.length,
      );
      if (!mounted) return;
      FeedbackService.complete(controller, reward: reward);
      setState(() {
        finished = true;
        missionReward = reward;
      });
      return;
    }
    setState(() {
      missionIndex += 1;
      selectedSlices = 0;
      checked = false;
      correct = null;
      hadMistake = false;
      _itemStarted = DateTime.now();
    });
    _checkpoint();
  }

  void _restart() {
    final repository = BrightQuestScope.contentOf(context);
    final controller = BrightQuestScope.of(context);
    var nextPlan = _missionRunPlan;
    var nextMissions = _missions;
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
      nextMissions = const MissionRunGameContent().fractionMissions(
        repository: repository,
        plan: nextPlan,
      );
    } else if (widget.endlessPractice && _missionRunPlan != null) {
      nextPlan = const EndlessPracticeCoordinator().createNextRound(
        repository: repository,
        previousPlan: _missionRunPlan!,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'fraction_pizza',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('fraction_pizza'),
      );
      nextMissions = const MissionRunGameContent().fractionMissions(
        repository: repository,
        plan: nextPlan,
      );
    } else {
      nextMissions = repository.fractionMissionsForClass(
        _classNumber,
        difficulty: _difficulty,
      );
    }
    controller.restartActiveGameSession(
      gameId: 'fraction_pizza',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: nextMissions.length,
      learningLevel: widget.learningLevel,
      sessionData: nextPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(nextPlan),
    );
    setState(() {
      _missionRunPlan = nextPlan;
      _missions = nextMissions;
      missionIndex = 0;
      selectedSlices = 0;
      score = 0;
      _attemptSerial = 0;
      checked = false;
      correct = null;
      hadMistake = false;
      finished = false;
      missionReward = null;
      _itemStarted = DateTime.now();
    });
  }

  void _checkpoint() {
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'fraction_pizza',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: missionIndex,
      score: score,
      maxScore: _missions.length,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        'selectedSlices': selectedSlices,
        'checked': checked,
        if (correct != null) 'correct': correct,
        'hadMistake': hadMistake,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final missions = _missions;
    final mission = missions[missionIndex];
    final target = '${mission.numerator}/${mission.denominator}';

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Fraction Pizza',
      subtitle: widget.endlessPractice
          ? 'Class $classNumber • ∞ Endless Practice • 10 rotating missions'
          : widget.learningLevel == null
              ? 'Class $classNumber • Adaptive level $_difficulty • Slice & Solve'
              : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFFFF9A35),
      voicePrompt:
          'Select ${mission.numerator} out of ${mission.denominator} equal parts from this ${mission.totalSlices}-slice pizza.',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GameProgressStrip(
            current: missionIndex + 1,
            total: missions.length,
            score: score,
          ),
          const SizedBox(height: 12),
          const GameSceneBanner(
              gameId: 'fraction_pizza',
              caption:
                  'Slice the pizza, compare fractions, and build fraction sense.',
              accent: Color(0xFFFF9A35)),
          const SizedBox(height: 18),
          Text(
            'Select $target of this ${mission.totalSlices}-slice pizza.',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(mission.totalSlices, (index) {
                final active = index < selectedSlices;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _select(index + 1),
                  child: Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFFC56E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFF9A35),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      active ? '🍕' : '${index + 1}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: Color(0xFFFF9A35)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedSlices == 0
                          ? 'Tap a slice number to choose how many pieces.'
                          : 'Selected $selectedSlices/${mission.totalSlices} = ${simplifiedFraction(selectedSlices, mission.totalSlices)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (checked) ...[
            const SizedBox(height: 12),
            correct == true
                ? SuccessBanner(
                    text:
                        'Correct! $selectedSlices/${mission.totalSlices} is equal to $target.',
                  )
                : ErrorBanner(
                    text:
                        'That fraction is not equal to $target. Change the number of slices and try again.',
                  ),
          ],
          const SizedBox(height: 18),
          if (finished)
            MissionSummaryCard(
              learningLevel: widget.learningLevel,
              score: score,
              maxScore: missions.length,
              reward: missionReward,
              onReplay: _restart,
              replayLabel: widget.endlessPractice ? 'Next 10 Missions' : null,
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: checked || selectedSlices == 0
                        ? null
                        : () => _check(mission),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Check Fraction'),
                  ),
                ),
                if (correct == true) ...[
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => _next(missions, classNumber),
                    icon: Icon(
                      missionIndex == missions.length - 1
                          ? Icons.flag_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      missionIndex == missions.length - 1 ? 'Finish' : 'Next',
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
