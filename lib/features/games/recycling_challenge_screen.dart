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
import '../../core/models/progress_models.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../widgets/bright_widgets.dart';
import '../../widgets/game_turn_timer.dart';

class RecyclingChallengeScreen extends StatefulWidget {
  const RecyclingChallengeScreen({
    this.learningLevel,
    this.endlessPractice = false,
    super.key,
  });

  final LearningLevel? learningLevel;
  final bool endlessPractice;

  @override
  State<RecyclingChallengeScreen> createState() =>
      _RecyclingChallengeScreenState();
}

class _RecyclingChallengeScreenState extends State<RecyclingChallengeScreen> {
  static const BrightSfxProfile _soundProfile =
      BrightSfxProfile.recyclingChallenge;

  void _playInteraction(BrightInteractionSfx effect) {
    unawaited(
      BrightAudioService.instance.playProfileSfx(_soundProfile, effect),
    );
  }

  int index = 0;
  int score = 0;
  String? selectedBin;
  bool? correct;
  DateTime _itemStarted = DateTime.now();
  bool finished = false;
  MissionReward? missionReward;
  int _difficulty = 1;
  int _classNumber = 4;
  int _attemptSerial = 0;
  bool _answerInFlight = false;
  bool _timedOut = false;
  bool _sessionConfigured = false;
  MissionRunPlan? _missionRunPlan;
  List<RecyclingItem> _items = const <RecyclingItem>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionConfigured) return;
    final controller = BrightQuestScope.of(context);
    _classNumber =
        widget.learningLevel?.classNumber ?? controller.selectedClass;
    _difficulty = controller.resumableDifficulty(
      gameId: 'recycling_challenge',
      classNumber: _classNumber,
      fallbackDifficulty: widget.endlessPractice
          ? 3
          : widget.learningLevel?.difficulty ??
              controller.recommendedDifficulty('recycling_challenge'),
      learningLevelId: widget.learningLevel?.id,
    );
    final repository = BrightQuestScope.contentOf(context);
    final existingCheckpoint = controller.gameSessionFor(
      gameId: 'recycling_challenge',
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
        gameId: 'recycling_challenge',
        checkpoint: existingCheckpoint,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'recycling_challenge',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('recycling_challenge'),
      );
    }
    _items = _missionRunPlan == null
        ? repository.recyclingItemsForClass(
            _classNumber,
            difficulty: _difficulty,
          )
        : const MissionRunGameContent().recyclingItems(
            repository: repository,
            plan: _missionRunPlan!,
          );
    if (_items.isEmpty) {
      throw StateError('Recycling Challenge cannot start without items.');
    }
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'recycling_challenge',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: _items.length,
      learningLevel: widget.learningLevel,
      sessionData: _missionRunPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(
              _missionRunPlan!,
            ),
    );
    index = checkpoint.cursor.clamp(0, _items.length - 1).toInt();
    score = checkpoint.score.clamp(0, _items.length).toInt();
    selectedBin = checkpoint.data['selectedBin'] as String?;
    correct = checkpoint.data['correct'] as bool?;
    _timedOut = checkpoint.data['timedOut'] as bool? ?? false;
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    if (checkpoint.stage == GameSessionStage.result &&
        checkpoint.reward != null) {
      finished = true;
      missionReward = checkpoint.reward!.toReward();
    }
    _sessionConfigured = true;
  }

  Future<void> _choose(String bin, RecyclingItem item) async {
    if (selectedBin != null || _timedOut || finished || _answerInFlight) return;
    _playInteraction(BrightInteractionSfx.option);
    setState(() => _answerInFlight = true);
    final answeredIndex = index;
    try {
      final isCorrect = bin == item.bin;
      final controller = BrightQuestScope.of(context);
      final adapter = const GameEvidenceAdapter();
      final activity = adapter.resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'recycling_challenge',
        legacyContentId: item.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'recycling_challenge',
        learningLevel: widget.learningLevel,
        correct: isCorrect,
        attemptMarker: 'answer:$_attemptSerial:$bin',
        topicId: item.topicId,
        difficulty: item.difficulty,
        masteryGain: 0.05,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: adapter.kindFor(widget.learningLevel),
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId:
            isCorrect ? null : adapter.misconceptionFor(activity, bin),
        confidence: 0.84,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      final chosen = '${item.name} in the $bin bin';
      setState(() {
        selectedBin = bin;
        correct = isCorrect;
        if (isCorrect) score += 1;
      });
      _checkpoint();

      final pacing = const GameTurnPacingPolicy().forGame(
        gameId: 'recycling_challenge',
        learningLevel: widget.learningLevel,
        endlessPractice: widget.endlessPractice,
      );
      if (isCorrect && pacing.autoAdvanceCorrect && controller.soundEnabled) {
        await FeedbackService.correctAndWait(
          controller,
          answer: chosen,
          minimumDuration: const Duration(milliseconds: 1200),
          soundProfile: _soundProfile,
        );
        if (!mounted ||
            index != answeredIndex ||
            selectedBin != bin ||
            correct != true) {
          return;
        }
        await _next(_items, _classNumber);
      } else if (isCorrect) {
        FeedbackService.correct(
          controller,
          answer: chosen,
          soundProfile: _soundProfile,
        );
      } else if (pacing.isTimed) {
        await FeedbackService.wrongAndWait(
          controller,
          answer: chosen,
          correctAnswer: '${item.bin} bin',
          guidance:
              'For this practice, sort by the example material group. Real local recycling rules can differ.',
          minimumDuration: const Duration(milliseconds: 1200),
          soundProfile: _soundProfile,
        );
      } else {
        FeedbackService.wrong(
          controller,
          answer: chosen,
          correctAnswer: '${item.bin} bin',
          guidance:
              'For this practice, sort by the example material group. Real local recycling rules can differ.',
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

  Future<void> _expireItem(RecyclingItem item) async {
    if (selectedBin != null || _timedOut || finished || _answerInFlight) return;
    setState(() => _answerInFlight = true);
    try {
      final controller = BrightQuestScope.of(context);
      final adapter = const GameEvidenceAdapter();
      final activity = adapter.resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'recycling_challenge',
        legacyContentId: item.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'recycling_challenge',
        learningLevel: widget.learningLevel,
        correct: false,
        attemptMarker: 'timeout:$_attemptSerial',
        topicId: item.topicId,
        difficulty: item.difficulty,
        masteryGain: 0.05,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: adapter.kindFor(widget.learningLevel),
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId: 'time_limit_exceeded',
        confidence: 0.35,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      setState(() {
        _timedOut = true;
        correct = false;
      });
      _checkpoint();
      await FeedbackService.wrongAndWait(
        controller,
        correctAnswer: '${item.bin} bin',
        guidance: 'Time is up. Review the material group, then continue.',
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

  Future<void> _next(List<RecyclingItem> items, int classNumber) async {
    if (selectedBin == null && !_timedOut) return;
    if (index == items.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'recycling_challenge',
        fallbackMissionId: widget.endlessPractice
            ? 'endless_practice:c$classNumber:recycling_challenge'
            : 'recycling_challenge:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        practiceOnly: widget.endlessPractice,
        score: score,
        maxScore: items.length,
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
      index += 1;
      selectedBin = null;
      correct = null;
      _timedOut = false;
      _itemStarted = DateTime.now();
    });
    _checkpoint();
  }

  void _restart() {
    final repository = BrightQuestScope.contentOf(context);
    final controller = BrightQuestScope.of(context);
    var nextPlan = _missionRunPlan;
    var nextItems = _items;
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
      nextItems = const MissionRunGameContent().recyclingItems(
        repository: repository,
        plan: nextPlan,
      );
    } else if (widget.endlessPractice && _missionRunPlan != null) {
      nextPlan = const EndlessPracticeCoordinator().createNextRound(
        repository: repository,
        previousPlan: _missionRunPlan!,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'recycling_challenge',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('recycling_challenge'),
      );
      nextItems = const MissionRunGameContent().recyclingItems(
        repository: repository,
        plan: nextPlan,
      );
    } else {
      nextItems = repository.recyclingItemsForClass(
        _classNumber,
        difficulty: _difficulty,
      );
    }
    controller.restartActiveGameSession(
      gameId: 'recycling_challenge',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: nextItems.length,
      learningLevel: widget.learningLevel,
      sessionData: nextPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(nextPlan),
    );
    setState(() {
      _missionRunPlan = nextPlan;
      _items = nextItems;
      index = 0;
      score = 0;
      _attemptSerial = 0;
      selectedBin = null;
      correct = null;
      _timedOut = false;
      _itemStarted = DateTime.now();
      finished = false;
      missionReward = null;
    });
  }

  void _checkpoint() {
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'recycling_challenge',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: index,
      score: score,
      maxScore: _items.length,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        if (selectedBin != null) 'selectedBin': selectedBin,
        if (correct != null) 'correct': correct,
        'timedOut': _timedOut,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final items = _items;
    final item = items[index];
    final pacing = const GameTurnPacingPolicy().forGame(
      gameId: 'recycling_challenge',
      learningLevel: widget.learningLevel,
      endlessPractice: widget.endlessPractice,
    );

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Recycling Challenge',
      subtitle: widget.endlessPractice
          ? 'Class $classNumber • ∞ Endless Practice • 10 rotating missions'
          : widget.learningLevel == null
              ? 'Class $classNumber • Adaptive level $_difficulty • Sort It Right'
              : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF4BAF52),
      voicePrompt:
          'For this material-sorting practice, which group should ${item.name} go into?',
      voiceChoices: const <String>['Paper', 'Plastic', 'Organic'],
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GameProgressStrip(
            current: index + 1,
            total: items.length,
            score: score,
          ),
          if (pacing.turnLimit != null) ...[
            const SizedBox(height: 10),
            GameTurnTimer(
              duration: pacing.turnLimit!,
              resetKey: 'recycling:$index:${item.id}',
              paused: selectedBin != null || _timedOut || _answerInFlight || finished,
              onExpired: () => _expireItem(item),
            ),
          ],
          const SizedBox(height: 12),
          const GameSceneBanner(
              gameId: 'recycling_challenge',
              caption:
                  'Practice sorting clean example items by material. Real local recycling rules can differ.',
              accent: Color(0xFF4BAF52)),
          const SizedBox(height: 18),
          Center(child: Text(item.emoji, style: const TextStyle(fontSize: 92))),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Which practice group matches ${item.name}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _Bin(
                label: 'Paper',
                emoji: '🔵',
                selected: selectedBin == 'Paper',
                onTap: _answerInFlight || selectedBin != null || _timedOut
                    ? null
                    : () => _choose('Paper', item),
              ),
              _Bin(
                label: 'Plastic',
                emoji: '🟡',
                selected: selectedBin == 'Plastic',
                onTap: _answerInFlight || selectedBin != null || _timedOut
                    ? null
                    : () => _choose('Plastic', item),
              ),
              _Bin(
                label: 'Organic',
                emoji: '🟢',
                selected: selectedBin == 'Organic',
                onTap: _answerInFlight || selectedBin != null || _timedOut
                    ? null
                    : () => _choose('Organic', item),
              ),
            ],
          ),
          if (selectedBin != null || _timedOut) ...[
            const SizedBox(height: 12),
            correct == true
                ? SuccessBanner(
                    text:
                        'Correct for this practice! ${item.name} goes in the ${item.bin} group.')
                : ErrorBanner(
                    text: _timedOut
                        ? 'Time is up. For this practice, ${item.name} goes in the ${item.bin} group.'
                        : 'For this practice, ${item.name} goes in the ${item.bin} group. Local recycling rules can differ.'),
          ],
          const SizedBox(height: 18),
          if (finished)
            MissionSummaryCard(
              learningLevel: widget.learningLevel,
              score: score,
              maxScore: items.length,
              reward: missionReward,
              onReplay: _restart,
              replayLabel: widget.endlessPractice ? 'Next 10 Missions' : null,
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    (selectedBin == null && !_timedOut) || _answerInFlight
                        ? null
                        : () {
                            _playInteraction(BrightInteractionSfx.next);
                            unawaited(_next(items, classNumber));
                          },
                icon: Icon(
                  index == items.length - 1
                      ? Icons.flag_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  index == items.length - 1 ? 'Finish' : 'Next',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bin extends StatelessWidget {
  const _Bin({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        height: 130,
        child: FilledButton.tonal(
          onPressed: onTap,
          style: selected
              ? FilledButton.styleFrom(backgroundColor: const Color(0xFFD9F7DB))
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 42)),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}
