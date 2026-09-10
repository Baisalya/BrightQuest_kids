import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/content_activity.dart';
import '../../core/content/content_repository.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/adaptive_difficulty_models.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/learning/endless_practice_coordinator.dart';
import '../../core/learning/mission_run_models.dart';
import '../../core/learning/mission_run_planner.dart';
import '../../core/learning/mission_run_session_coordinator.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';

class MathMarketScreen extends StatefulWidget {
  const MathMarketScreen({
    this.learningLevel,
    this.endlessPractice = false,
    super.key,
  });
  final LearningLevel? learningLevel;
  final bool endlessPractice;

  @override
  State<MathMarketScreen> createState() => _MathMarketScreenState();
}

class _MathMarketScreenState extends State<MathMarketScreen> {
  int questionIndex = 0;
  int score = 0;
  int? selected;
  bool? wasCorrect;
  String? hint;
  bool finished = false;
  MissionReward? missionReward;
  int _difficulty = 1;
  int _classNumber = 4;
  int _attemptSerial = 0;
  bool _answerInFlight = false;
  bool _sessionConfigured = false;
  MissionRunPlan? _missionRunPlan;
  List<MathQuestion> _questions = const <MathQuestion>[];
  DateTime _itemStarted = DateTime.now();

  static const int _trainingItemCount = 5;
  static const int _gameItemCount = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionConfigured) return;
    final controller = BrightQuestScope.of(context);
    _classNumber =
        widget.learningLevel?.classNumber ?? controller.selectedClass;
    _difficulty = controller.resumableDifficulty(
      gameId: 'math_market',
      classNumber: _classNumber,
      fallbackDifficulty: widget.endlessPractice
          ? 3
          : widget.learningLevel?.difficulty ??
              controller.recommendedDifficulty('math_market'),
      learningLevelId: widget.learningLevel?.id,
    );
    final repository = BrightQuestScope.contentOf(context);
    final existingCheckpoint = controller.gameSessionFor(
      gameId: 'math_market',
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
        gameId: 'math_market',
        checkpoint: existingCheckpoint,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'math_market',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('math_market'),
      );
    }
    _questions = _missionRunPlan == null
        ? repository.mathQuestionsForClass(
            _classNumber,
            difficulty: _difficulty,
          )
        : _questionsForPlan(repository, _missionRunPlan!);
    if (_questions.isEmpty) {
      throw StateError('Math Market cannot start without questions.');
    }
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'math_market',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: _questions.length,
      learningLevel: widget.learningLevel,
      sessionData: _missionRunPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(
              _missionRunPlan!,
            ),
    );
    questionIndex = checkpoint.cursor.clamp(0, _questions.length - 1).toInt();
    score = checkpoint.score.clamp(0, _questions.length).toInt();
    selected = (checkpoint.data['selected'] as num?)?.toInt();
    wasCorrect = checkpoint.data['wasCorrect'] as bool?;
    hint = checkpoint.data['hint'] as String?;
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    if (checkpoint.stage == GameSessionStage.result &&
        checkpoint.reward != null) {
      finished = true;
      missionReward = checkpoint.reward!.toReward();
    }
    _sessionConfigured = true;
  }

  Future<void> _check(MathQuestion question, int value) async {
    if (selected != null || finished || _answerInFlight) return;
    _answerInFlight = true;
    try {
      final controller = BrightQuestScope.of(context);
      final repository = BrightQuestScope.contentOf(context);
      const adapter = GameEvidenceAdapter();
      final activity = adapter.resolve(
        repository: repository,
        classNumber: _classNumber,
        gameId: 'math_market',
        legacyContentId: question.id,
      );
      final correct = value == question.answer;
      await controller.recordAnswerSafely(
        gameId: 'math_market',
        learningLevel: widget.learningLevel,
        correct: correct,
        attemptMarker: 'answer:$_attemptSerial:$value',
        topicId: question.topicId,
        difficulty: question.difficulty,
        masteryGain: 0.045,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: adapter.kindFor(widget.learningLevel),
        hintLevel: hint == null ? 0 : 1,
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId:
            correct ? null : adapter.misconceptionFor(activity, value),
      );
      if (!mounted) return;
      _attemptSerial += 1;
      if (correct) {
        FeedbackService.correct(controller, answer: '$value');
      } else {
        FeedbackService.wrong(
          controller,
          answer: '$value',
          correctAnswer: '${question.answer}',
        );
      }
      setState(() {
        selected = value;
        wasCorrect = correct;
        if (correct) score += 1;
      });
      _checkpoint(questionsLength: _questions.length);
    } finally {
      _answerInFlight = false;
    }
  }

  Future<void> _next(List<MathQuestion> questions, int classNumber) async {
    if (selected == null) return;
    if (questionIndex == questions.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'math_market',
        fallbackMissionId: widget.endlessPractice
            ? 'endless_practice:c$classNumber:math_market'
            : 'math_market:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        practiceOnly: widget.endlessPractice,
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
      wasCorrect = null;
      hint = null;
      _itemStarted = DateTime.now();
    });
    _checkpoint(questionsLength: questions.length);
  }

  Future<void> _showHint(MathQuestion question) async {
    if (!learningLevelAllowsMainGameHints(widget.learningLevel)) return;
    final controller = BrightQuestScope.of(context);
    final hintUnlocked = await controller.useHintSafely(
      gameId: 'math_market',
      learningLevel: widget.learningLevel,
      cost: 5,
      marker: 'math:$questionIndex',
    );
    if (!mounted) return;
    if (!hintUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need 5 coins for a hint.')),
      );
      return;
    }
    setState(() => hint = question.hint);
    _checkpoint(questionsLength: _questions.length);
    FeedbackService.hint(controller, question.hint);
  }

  void _restart() {
    final repository = BrightQuestScope.contentOf(context);
    final controller = BrightQuestScope.of(context);
    var nextPlan = _missionRunPlan;
    var nextQuestions = _questions;
    final level = widget.learningLevel;
    if (level != null && _missionRunPlan != null) {
      nextPlan = const MissionRunSessionCoordinator().createReplay(
        repository: repository,
        level: level,
        previousPlan: _missionRunPlan!,
        history: controller.missionExposureHistoryFor(level),
        learningState: controller.learningState,
        levelProgress: controller.levelStatsFor(level.id),
        gameProgress: controller.statsFor(level.gameId),
        trainingItemCount: _trainingItemCount,
        gameItemCount: _gameItemCount,
      );
      if (nextPlan.hasContentShortfall || nextPlan.hasTrainingGameOverlap) {
        throw StateError('Fresh Math Market replay allocation is invalid.');
      }
      nextQuestions = _questionsForPlan(repository, nextPlan);
    } else if (widget.endlessPractice && _missionRunPlan != null) {
      nextPlan = const EndlessPracticeCoordinator().createNextRound(
        repository: repository,
        previousPlan: _missionRunPlan!,
        history: controller.missionExposureHistoryForGame(
          classNumber: _classNumber,
          gameId: 'math_market',
        ),
        learningState: controller.learningState,
        gameProgress: controller.statsFor('math_market'),
      );
      nextQuestions = _questionsForPlan(repository, nextPlan);
    } else {
      nextQuestions = repository.mathQuestionsForClass(
        _classNumber,
        difficulty: _difficulty,
      );
    }
    controller.restartActiveGameSession(
      gameId: 'math_market',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: nextQuestions.length,
      learningLevel: widget.learningLevel,
      sessionData: nextPlan == null
          ? const <String, Object?>{}
          : const MissionRunSessionCoordinator().sessionDataFor(nextPlan),
    );
    setState(() {
      _missionRunPlan = nextPlan;
      _questions = nextQuestions;
      questionIndex = 0;
      score = 0;
      _attemptSerial = 0;
      selected = null;
      wasCorrect = null;
      hint = null;
      finished = false;
      missionReward = null;
      _itemStarted = DateTime.now();
    });
  }

  void _checkpoint({required int questionsLength}) {
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'math_market',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: questionIndex,
      score: score,
      maxScore: questionsLength,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        if (selected != null) 'selected': selected,
        if (wasCorrect != null) 'wasCorrect': wasCorrect,
        if (hint != null) 'hint': hint,
      },
    );
  }

  List<MathQuestion> _questionsForPlan(
    ContentRepository repository,
    MissionRunPlan plan,
  ) {
    const planner = MissionRunPlanner();
    return List<MathQuestion>.unmodifiable(
      plan.gameItems.map((item) {
        final activity = planner.resolveCandidateActivity(
          repository: repository,
          candidate: item.candidate,
        );
        return _mathQuestionFromActivity(activity);
      }),
    );
  }

  MathQuestion _mathQuestionFromActivity(ContentActivity activity) {
    if (activity.gameId != 'math_market') {
      throw StateError('${activity.id} is not Math Market content.');
    }
    final answer = activity.payload['answer'];
    final choices = activity.payload['choices'];
    final hint = activity.payload['hint'];
    if (answer is! int || choices is! List || hint is! String) {
      throw StateError('Invalid Math Market payload for ${activity.id}.');
    }
    return MathQuestion(
      activity.prompt,
      answer,
      choices.whereType<num>().map((value) => value.toInt()).toList(),
      hint,
      id: activity.legacyContentId,
      topicId: activity.topicId,
      difficulty: activity.difficulty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final questions = _questions;
    final question = questions[questionIndex];

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Math Market',
      subtitle: widget.endlessPractice
          ? 'Class $classNumber • ∞ Endless Practice • 10 rotating missions'
          : widget.learningLevel == null
              ? 'Class $classNumber • Adaptive level $_difficulty • Solve and shop'
              : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF3E88F7),
      voicePrompt: question.text,
      voiceChoices: question.choices,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          GameProgressStrip(
              current: questionIndex + 1,
              total: questions.length,
              score: score),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final board = _QuestionBoard(
                question: question,
                selected: selected,
                wasCorrect: wasCorrect,
                onSelected: (value) => _check(question, value),
              );
              final market =
                  _MarketPanel(score: score, total: questions.length);
              if (!wide) {
                return Column(
                    children: [board, const SizedBox(height: 12), market]);
              }
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: board),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: market)
                  ]);
            },
          ),
          if (hint != null) ...[
            const SizedBox(height: 12),
            InfoBanner(icon: Icons.lightbulb_rounded, text: hint!)
          ],
          if (wasCorrect != null) ...[
            const SizedBox(height: 12),
            wasCorrect == true
                ? const SuccessBanner(
                    text:
                        'Correct! Great shopping maths. Keep filling the basket!')
                : ErrorBanner(
                    text: learningLevelAllowsMainGameHints(widget.learningLevel)
                        ? 'Not quite. You can use a hint, then try the next market challenge.'
                        : 'Not quite. This run stays independent — review the result, then try the next challenge.'),
          ],
          if (finished) ...[
            const SizedBox(height: 14),
            MissionSummaryCard(
              learningLevel: widget.learningLevel,
              score: score,
              maxScore: questions.length,
              reward: missionReward,
              onReplay: _restart,
              replayLabel: widget.endlessPractice ? 'Next 10 Missions' : null,
            ),
          ] else ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (learningLevelAllowsMainGameHints(widget.learningLevel))
                  OutlinedButton.icon(
                    key: const Key('math_market_hint_button'),
                    onPressed:
                        selected == null ? () => _showHint(question) : null,
                    icon: const Icon(Icons.lightbulb_rounded),
                    label: const Text('Hint · 5 coins'),
                  ),
                FilledButton.icon(
                  onPressed: selected == null
                      ? null
                      : () => _next(questions, classNumber),
                  icon: Icon(questionIndex == questions.length - 1
                      ? Icons.flag_rounded
                      : Icons.arrow_forward_rounded),
                  label: Text(questionIndex == questions.length - 1
                      ? 'Finish Mission'
                      : 'Next Question'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionBoard extends StatelessWidget {
  const _QuestionBoard(
      {required this.question,
      required this.selected,
      required this.wasCorrect,
      required this.onSelected});
  final MathQuestion question;
  final int? selected;
  final bool? wasCorrect;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => BrightAdventureLandscape(
        market: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF9C5B25), width: 4),
              borderRadius: BorderRadius.circular(30)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 560;
              final guide = Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 88, child: BrightLionMascot(size: 86)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .94),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(5)),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 9,
                                offset: Offset(0, 4))
                          ]),
                      child: const Column(
                        key: Key('math_market_guide'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Great job!',
                              style: TextStyle(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                          Text('Solve and shop smart!',
                              style: TextStyle(
                                  color: AppTheme.purpleDeep,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              final chalkboard = Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF123F36),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC48645), width: 7),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 7))
                  ],
                ),
                child: Column(
                  children: [
                    Text(question.text,
                        key: const Key('math_market_question_prompt'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: narrow ? 34 : 43,
                            shadows: const [
                              Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 2))
                            ])),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(question.choices.length, (index) {
                        final value = question.choices[index];
                        final base = const [
                          Color(0xFF2898F4),
                          Color(0xFF77BE26),
                          Color(0xFFFF9822),
                          Color(0xFF934DE7)
                        ][index % 4];
                        var background = base;
                        var foreground = Colors.white;
                        if (selected == value) {
                          background = wasCorrect == true
                              ? const Color(0xFF42B64F)
                              : const Color(0xFFE95F5F);
                        } else if (selected != null) {
                          background = Color.lerp(base, Colors.grey, .42)!;
                          foreground = Colors.white.withValues(alpha: .82);
                        }
                        return SizedBox(
                          width: narrow ? 84 : 105,
                          child: BrightValuePop(
                            value: '${selected == value}:$wasCorrect:$value',
                            child: BrightPressableScale(
                              hoverScale: selected == null ? 1.035 : 1.0,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: background,
                                  foregroundColor: foreground,
                                  elevation: selected == null ? 6 : 1,
                                  shadowColor: Colors.black26,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: .40),
                                          width: 2)),
                                ),
                                onPressed: selected == null
                                    ? () => onSelected(value)
                                    : null,
                                child: Text('$value',
                                    style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  guide,
                  const SizedBox(height: 12),
                  chalkboard,
                ],
              );
            },
          ),
        ),
      );
}

class _MarketPanel extends StatelessWidget {
  const _MarketPanel({required this.score, required this.total});
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    const items = <({String emoji, String name, int price})>[
      (emoji: '🍎', name: 'Apple', price: 15),
      (emoji: '🍌', name: 'Banana', price: 10),
      (emoji: '🍇', name: 'Grapes', price: 20),
      (emoji: '✏️', name: 'Pencil Box', price: 25),
      (emoji: '📗', name: 'Notebook', price: 18),
    ];
    return BrightSurface(
      color: const Color(0xFFFFFAEF),
      borderColor: const Color(0xFFFFE3B8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrightWoodenSign(
              title: 'Fresh & School Picks',
              subtitle: 'Every correct answer fills your basket.',
              compact: true),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => _ShopItem(
                    emoji: item.emoji, name: item.name, price: item.price))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.shopping_basket_rounded, color: Color(0xFFB97800)),
            const SizedBox(width: 7),
            Expanded(
                child: Text('Basket $score / $total',
                    style: const TextStyle(fontWeight: FontWeight.w900))),
            Text('${(score / total * 100).round()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: AppTheme.purple))
          ]),
          const SizedBox(height: 6),
          BrightAnimatedProgress(
              value: score / total, minHeight: 8, color: AppTheme.purple),
        ],
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  const _ShopItem(
      {required this.emoji, required this.name, required this.price});
  final String emoji;
  final String name;
  final int price;

  @override
  Widget build(BuildContext context) => Container(
        width: 100,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4))
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            Text(name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            Text('🪙 $price',
                style: const TextStyle(color: AppTheme.inkMuted, fontSize: 10)),
          ],
        ),
      );
}
