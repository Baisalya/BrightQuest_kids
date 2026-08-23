import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/adaptive_difficulty_models.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../widgets/bright_widgets.dart';

class MapQuestScreen extends StatefulWidget {
  const MapQuestScreen({this.learningLevel, super.key});

  final LearningLevel? learningLevel;

  @override
  State<MapQuestScreen> createState() => _MapQuestScreenState();
}

class _MapQuestScreenState extends State<MapQuestScreen> {
  int questionIndex = 0;
  int score = 0;
  String? selected;
  bool checked = false;
  bool? correct;
  bool _hintUsed = false;
  DateTime _itemStarted = DateTime.now();
  bool finished = false;
  MissionReward? missionReward;
  int _difficulty = 1;
  int _classNumber = 4;
  int _attemptSerial = 0;
  bool _answerInFlight = false;
  bool _sessionConfigured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionConfigured) return;
    final controller = BrightQuestScope.of(context);
    _classNumber =
        widget.learningLevel?.classNumber ?? controller.selectedClass;
    _difficulty = controller.resumableDifficulty(
      gameId: 'map_quest',
      classNumber: _classNumber,
      fallbackDifficulty: widget.learningLevel?.difficulty ??
          controller.recommendedDifficulty('map_quest'),
      learningLevelId: widget.learningLevel?.id,
    );
    final questions = BrightQuestScope.contentOf(context)
        .mapQuestionsForClass(_classNumber, difficulty: _difficulty);
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'map_quest',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: questions.length,
      learningLevel: widget.learningLevel,
    );
    questionIndex = checkpoint.cursor.clamp(0, questions.length - 1).toInt();
    score = checkpoint.score.clamp(0, questions.length).toInt();
    selected = checkpoint.data['selected'] as String?;
    checked = checkpoint.data['checked'] as bool? ?? false;
    correct = checkpoint.data['correct'] as bool?;
    _hintUsed = checkpoint.data['hintUsed'] as bool? ?? false;
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    if (checkpoint.stage == GameSessionStage.result &&
        checkpoint.reward != null) {
      finished = true;
      missionReward = checkpoint.reward!.toReward();
    }
    _sessionConfigured = true;
  }

  Future<void> _check(MapQuestion question) async {
    if (checked || selected == null || _answerInFlight) return;
    _answerInFlight = true;
    try {
      final isCorrect = selected == question.answer;
      final controller = BrightQuestScope.of(context);
      final adapter = const GameEvidenceAdapter();
      final activity = adapter.resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'map_quest',
        legacyContentId: question.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'map_quest',
        learningLevel: widget.learningLevel,
        correct: isCorrect,
        attemptMarker: 'answer:$_attemptSerial:$selected',
        topicId: question.topicId,
        difficulty: question.difficulty,
        masteryGain: 0.06,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: adapter.kindFor(widget.learningLevel),
        hintLevel: _hintUsed ? 1 : 0,
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId:
            isCorrect ? null : adapter.misconceptionFor(activity, selected),
        confidence: _hintUsed ? 0.58 : 0.84,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      if (isCorrect) {
        FeedbackService.correct(controller, answer: selected);
      } else {
        FeedbackService.wrong(
          controller,
          answer: selected,
          correctAnswer: question.answer,
          guidance: learningLevelAllowsMainGameHints(widget.learningLevel)
              ? question.hint
              : null,
        );
      }
      setState(() {
        checked = true;
        correct = isCorrect;
        if (isCorrect) score += 1;
      });
      _checkpoint();
    } finally {
      _answerInFlight = false;
    }
  }

  Future<void> _next(List<MapQuestion> questions, int classNumber) async {
    if (!checked) return;
    if (questionIndex == questions.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'map_quest',
        fallbackMissionId: 'map_quest:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        score: score,
        maxScore: questions.length,
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
      questionIndex += 1;
      selected = null;
      checked = false;
      correct = null;
      _hintUsed = false;
      _itemStarted = DateTime.now();
    });
    _checkpoint();
  }

  void _restart() {
    final questions = BrightQuestScope.contentOf(context)
        .mapQuestionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).restartActiveGameSession(
      gameId: 'map_quest',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: questions.length,
      learningLevel: widget.learningLevel,
    );
    setState(() {
      questionIndex = 0;
      score = 0;
      _attemptSerial = 0;
      selected = null;
      checked = false;
      correct = null;
      _hintUsed = false;
      _itemStarted = DateTime.now();
      finished = false;
      missionReward = null;
    });
  }

  void _checkpoint() {
    final questions = BrightQuestScope.contentOf(context)
        .mapQuestionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'map_quest',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: questionIndex,
      score: score,
      maxScore: questions.length,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        if (selected != null) 'selected': selected,
        'checked': checked,
        if (correct != null) 'correct': correct,
        'hintUsed': _hintUsed,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final questions = BrightQuestScope.contentOf(context)
        .mapQuestionsForClass(classNumber, difficulty: _difficulty);
    final question = questions[questionIndex];

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Map Quest',
      subtitle: widget.learningLevel == null
          ? 'Class $classNumber • Adaptive level $_difficulty • Explore India'
          : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF2B96E9),
      voicePrompt: question.question,
      voiceChoices: question.choices,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GameProgressStrip(
            current: questionIndex + 1,
            total: questions.length,
            score: score,
          ),
          const SizedBox(height: 12),
          const GameSceneBanner(
              gameId: 'map_quest',
              caption: 'Follow the compass, read the map, and explore India.',
              accent: Color(0xFF2B96E9)),
          const SizedBox(height: 16),
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F5FF), Color(0xFFEAFBEA)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🗺️', style: TextStyle(fontSize: 78)),
                    const SizedBox(height: 8),
                    Text(
                      question.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 21),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: question.choices
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    onSelected: checked || finished
                        ? null
                        : (_) {
                            setState(() => selected = value);
                            _checkpoint();
                          },
                  ),
                )
                .toList(),
          ),
          if (checked) ...[
            const SizedBox(height: 14),
            correct == true
                ? SuccessBanner(
                    text: 'Correct! ${question.answer} is the right answer.')
                : ErrorBanner(
                    text: learningLevelAllowsMainGameHints(widget.learningLevel)
                        ? 'Not this one. Hint: ${question.hint}'
                        : 'Not this one. Recheck the map from the reference point before the next checkpoint.',
                  ),
          ],
          const SizedBox(height: 18),
          if (finished)
            MissionSummaryCard(
              learningLevel: widget.learningLevel,
              score: score,
              maxScore: questions.length,
              reward: missionReward,
              onReplay: _restart,
            )
          else
            Row(
              children: [
                if (learningLevelAllowsMainGameHints(widget.learningLevel))
                  OutlinedButton.icon(
                    onPressed: checked
                        ? null
                        : () async {
                            final controller = BrightQuestScope.of(context);
                            final hintUnlocked = await controller.useHintSafely(
                              gameId: 'map_quest',
                              learningLevel: widget.learningLevel,
                              cost: 3,
                              marker: 'map:$questionIndex',
                            );
                            if (!mounted) return;
                            if (hintUnlocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(question.hint)),
                              );
                              setState(() => _hintUsed = true);
                              _checkpoint();
                              FeedbackService.hint(controller, question.hint);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('You need 3 coins for a hint.'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.lightbulb_rounded),
                    label: const Text('Hint · 3 coins'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: selected == null || checked
                      ? null
                      : () => _check(question),
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text('Place Pin'),
                ),
                if (checked) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _next(questions, classNumber),
                    icon: Icon(
                      questionIndex == questions.length - 1
                          ? Icons.flag_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      questionIndex == questions.length - 1 ? 'Finish' : 'Next',
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
