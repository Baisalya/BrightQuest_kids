import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/learning/learning_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';

class ScienceLabScreen extends StatefulWidget {
  const ScienceLabScreen({this.learningLevel, super.key});
  final LearningLevel? learningLevel;

  @override
  State<ScienceLabScreen> createState() => _ScienceLabScreenState();
}

class _ScienceLabScreenState extends State<ScienceLabScreen> {
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
  bool _sessionConfigured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionConfigured) return;
    final controller = BrightQuestScope.of(context);
    _classNumber =
        widget.learningLevel?.classNumber ?? controller.selectedClass;
    _difficulty = widget.learningLevel?.difficulty ??
        controller.recommendedDifficulty('science_lab');
    _sessionConfigured = true;
  }

  void _addIngredient(String ingredient) {
    if (finished) return;
    setState(() => ingredients.add(ingredient));
    final reaction = BrightQuestScope.contentOf(context)
        .scienceReactionForIngredients(_classNumber, ingredients);
    if (reaction.id == 'fizz' && !experimentRecorded) {
      final controller = BrightQuestScope.of(context);
      final activity =
          BrightQuestScope.contentOf(context).activityForScienceReaction(
        classNumber: _classNumber,
        reactionId: reaction.id,
      );
      controller.recordAnswer(
        gameId: 'science_lab',
        correct: true,
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
      FeedbackService.correct(
        BrightQuestScope.of(context),
        answer: reaction.title,
        detail: reaction.explanation,
      );
      setState(() => experimentRecorded = true);
    }
  }

  void _clearExperiment() {
    if (finished) return;
    setState(ingredients.clear);
  }

  void _answerQuiz(ScienceQuizQuestion question, String value) {
    if (selectedQuiz != null || finished) return;
    final correct = value == question.answer;
    final controller = BrightQuestScope.of(context);
    final adapter = const GameEvidenceAdapter();
    final activity = adapter.resolve(
      repository: BrightQuestScope.contentOf(context),
      classNumber: _classNumber,
      gameId: 'science_lab',
      legacyContentId: question.id,
    );
    controller.recordAnswer(
      gameId: 'science_lab',
      correct: correct,
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
    if (correct) {
      FeedbackService.correct(
        controller,
        answer: value,
        detail: question.explanation,
      );
    } else {
      FeedbackService.wrong(
        controller,
        answer: value,
        correctAnswer: question.answer,
        guidance: question.explanation,
      );
    }
    setState(() {
      selectedQuiz = value;
      quizCorrect = correct;
      if (correct) quizScore += 1;
    });
  }

  void _nextQuiz(List<ScienceQuizQuestion> questions, int classNumber) {
    if (selectedQuiz == null) return;
    if (quizIndex == questions.length - 1) {
      if (!experimentRecorded) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Complete the fizzing experiment before finishing the lab.')));
        return;
      }
      final totalScore = quizScore + 1;
      final controller = BrightQuestScope.of(context);
      final reward = controller.completeRun(
        gameId: 'science_lab',
        fallbackMissionId: 'science_lab:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        score: totalScore,
        maxScore: questions.length + 1,
      );
      FeedbackService.complete(controller, reward: reward);
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
      _quizStarted = DateTime.now();
    });
  }

  void _restart() {
    setState(() {
      ingredients.clear();
      quizIndex = 0;
      quizScore = 0;
      selectedQuiz = null;
      quizCorrect = null;
      _quizStarted = DateTime.now();
      experimentRecorded = false;
      finished = false;
      missionReward = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final questions = BrightQuestScope.contentOf(context)
        .scienceQuestionsForClass(classNumber, difficulty: _difficulty);
    final reaction = BrightQuestScope.contentOf(context)
        .scienceReactionForIngredients(classNumber, ingredients);
    final question = questions[quizIndex];

    return GameScaffold(
      title: 'Science Lab',
      subtitle: widget.learningLevel == null
          ? 'Class $classNumber • Adaptive level $_difficulty • Mix & Discover'
          : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF7B4EEB),
      voicePrompt: question.question,
      voiceChoices: question.choices,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
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
              if (!wide)
                return Column(
                    children: [experiment, const SizedBox(height: 12), result]);
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: experiment),
                    const SizedBox(width: 14),
                    Expanded(child: result)
                  ]);
            },
          ),
          const SizedBox(height: 16),
          GameProgressStrip(
              current: quizIndex + 1,
              total: questions.length,
              score: quizScore),
          const SizedBox(height: 14),
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
                            onTap: selectedQuiz == null && !finished
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
                : ErrorBanner(text: 'Not quite. ${question.explanation}'),
          ],
          const SizedBox(height: 16),
          if (finished)
            MissionSummaryCard(
                score: quizScore + 1,
                maxScore: questions.length + 1,
                reward: missionReward,
                onReplay: _restart)
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: selectedQuiz == null
                    ? null
                    : () => _nextQuiz(questions, classNumber),
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
                const Positioned(
                    right: 6,
                    bottom: -3,
                    child: SizedBox(
                        width: 95,
                        child: BrightLionMascot(size: 90, scientist: true))),
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
  Widget build(BuildContext context) => BrightSurface(
        color: success ? const Color(0xFFF2EBFF) : Colors.white,
        borderColor:
            success ? const Color(0xFFB8A4FF) : const Color(0x14000000),
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
                  const SizedBox(
                      width: 92,
                      child: BrightLionMascot(size: 88, scientist: true)),
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
