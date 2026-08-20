import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
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
        controller.recommendedDifficulty('map_quest');
    _sessionConfigured = true;
  }

  void _check(MapQuestion question) {
    if (checked || selected == null) return;
    final isCorrect = selected == question.answer;
    BrightQuestScope.of(context).recordAnswer(
      gameId: 'map_quest',
      correct: isCorrect,
      topicId: question.topicId,
      difficulty: question.difficulty,
      masteryGain: 0.06,
    );
    final controller = BrightQuestScope.of(context);
    if (isCorrect) {
      FeedbackService.correct(controller, answer: selected);
    } else {
      FeedbackService.wrong(
        controller,
        answer: selected,
        correctAnswer: question.answer,
        guidance: question.hint,
      );
    }
    setState(() {
      checked = true;
      correct = isCorrect;
      if (isCorrect) score += 1;
    });
  }

  void _next(List<MapQuestion> questions, int classNumber) {
    if (!checked) return;
    if (questionIndex == questions.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = controller.completeRun(
        gameId: 'map_quest',
        fallbackMissionId: 'map_quest:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        score: score,
        maxScore: questions.length,
      );
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
    });
  }

  void _restart() {
    setState(() {
      questionIndex = 0;
      score = 0;
      selected = null;
      checked = false;
      correct = null;
      finished = false;
      missionReward = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final questions =
        mapQuestionsForClass(classNumber, difficulty: _difficulty);
    final question = questions[questionIndex];

    return GameScaffold(
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
                        : (_) => setState(() => selected = value),
                  ),
                )
                .toList(),
          ),
          if (checked) ...[
            const SizedBox(height: 14),
            correct == true
                ? SuccessBanner(
                    text: 'Correct! ${question.answer} is the right answer.')
                : ErrorBanner(text: 'Not this one. Hint: ${question.hint}'),
          ],
          const SizedBox(height: 18),
          if (finished)
            MissionSummaryCard(
              score: score,
              maxScore: questions.length,
              reward: missionReward,
              onReplay: _restart,
            )
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: checked
                      ? null
                      : () {
                          final controller = BrightQuestScope.of(context);
                          if (controller.useHint(
                              gameId: 'map_quest', cost: 3)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(question.hint)),
                            );
                            FeedbackService.hint(controller, question.hint);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('You need 3 coins for a hint.')),
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
