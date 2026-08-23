import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/gameplay/game_logic.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../widgets/bright_widgets.dart';

class FractionPizzaScreen extends StatefulWidget {
  const FractionPizzaScreen({this.learningLevel, super.key});

  final LearningLevel? learningLevel;

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
      fallbackDifficulty: widget.learningLevel?.difficulty ??
          controller.recommendedDifficulty('fraction_pizza'),
      learningLevelId: widget.learningLevel?.id,
    );
    final missions = BrightQuestScope.contentOf(context)
        .fractionMissionsForClass(_classNumber, difficulty: _difficulty);
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'fraction_pizza',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    missionIndex = checkpoint.cursor.clamp(0, missions.length - 1).toInt();
    score = checkpoint.score.clamp(0, missions.length).toInt();
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
        fallbackMissionId:
            'fraction_pizza:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
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
    final missions = BrightQuestScope.contentOf(context)
        .fractionMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).restartActiveGameSession(
      gameId: 'fraction_pizza',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    setState(() {
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
    final missions = BrightQuestScope.contentOf(context)
        .fractionMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'fraction_pizza',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: missionIndex,
      score: score,
      maxScore: missions.length,
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
    final missions = BrightQuestScope.contentOf(context)
        .fractionMissionsForClass(classNumber, difficulty: _difficulty);
    final mission = missions[missionIndex];
    final target = '${mission.numerator}/${mission.denominator}';

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Fraction Pizza',
      subtitle: widget.learningLevel == null
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
