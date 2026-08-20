import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../widgets/bright_widgets.dart';

class RecyclingChallengeScreen extends StatefulWidget {
  const RecyclingChallengeScreen({this.learningLevel, super.key});

  final LearningLevel? learningLevel;

  @override
  State<RecyclingChallengeScreen> createState() =>
      _RecyclingChallengeScreenState();
}

class _RecyclingChallengeScreenState extends State<RecyclingChallengeScreen> {
  int index = 0;
  int score = 0;
  String? selectedBin;
  bool? correct;
  DateTime _itemStarted = DateTime.now();
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
        controller.recommendedDifficulty('recycling_challenge');
    _sessionConfigured = true;
  }

  void _choose(String bin, RecyclingItem item) {
    if (selectedBin != null || finished) return;
    final isCorrect = bin == item.bin;
    final controller = BrightQuestScope.of(context);
    final adapter = const GameEvidenceAdapter();
    final activity = adapter.resolve(
      repository: BrightQuestScope.contentOf(context),
      classNumber: _classNumber,
      gameId: 'recycling_challenge',
      legacyContentId: item.id,
    );
    controller.recordAnswer(
      gameId: 'recycling_challenge',
      correct: isCorrect,
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
    final chosen = '${item.name} in the $bin bin';
    if (isCorrect) {
      FeedbackService.correct(controller, answer: chosen);
    } else {
      FeedbackService.wrong(
        controller,
        answer: chosen,
        correctAnswer: '${item.bin} bin',
        guidance: 'Remember what the item is made from.',
      );
    }
    setState(() {
      selectedBin = bin;
      correct = isCorrect;
      if (isCorrect) score += 1;
    });
  }

  void _next(List<RecyclingItem> items, int classNumber) {
    if (selectedBin == null) return;
    if (index == items.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = controller.completeRun(
        gameId: 'recycling_challenge',
        fallbackMissionId:
            'recycling_challenge:c$classNumber:d$_difficulty:core_run',
        learningLevel: widget.learningLevel,
        score: score,
        maxScore: items.length,
      );
      FeedbackService.complete(controller, reward: reward);
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
      _itemStarted = DateTime.now();
    });
  }

  void _restart() {
    setState(() {
      index = 0;
      score = 0;
      selectedBin = null;
      correct = null;
      _itemStarted = DateTime.now();
      finished = false;
      missionReward = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final items = BrightQuestScope.contentOf(context)
        .recyclingItemsForClass(classNumber, difficulty: _difficulty);
    final item = items[index];

    return GameScaffold(
      title: 'Recycling Challenge',
      subtitle: widget.learningLevel == null
          ? 'Class $classNumber • Adaptive level $_difficulty • Sort It Right'
          : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF4BAF52),
      voicePrompt: 'Which bin should ${item.name} go into?',
      voiceChoices: const <String>['Paper', 'Plastic', 'Organic'],
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GameProgressStrip(
            current: index + 1,
            total: items.length,
            score: score,
          ),
          const SizedBox(height: 12),
          const GameSceneBanner(
              gameId: 'recycling_challenge',
              caption:
                  'Sort each item into the correct bin and protect Green Planet.',
              accent: Color(0xFF4BAF52)),
          const SizedBox(height: 18),
          Center(child: Text(item.emoji, style: const TextStyle(fontSize: 92))),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Where does ${item.name} go?',
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
                onTap: () => _choose('Paper', item),
              ),
              _Bin(
                label: 'Plastic',
                emoji: '🟡',
                selected: selectedBin == 'Plastic',
                onTap: () => _choose('Plastic', item),
              ),
              _Bin(
                label: 'Organic',
                emoji: '🟢',
                selected: selectedBin == 'Organic',
                onTap: () => _choose('Organic', item),
              ),
            ],
          ),
          if (selectedBin != null) ...[
            const SizedBox(height: 12),
            correct == true
                ? SuccessBanner(
                    text: 'Correct! ${item.name} belongs in ${item.bin}.')
                : ErrorBanner(
                    text: '${item.name} belongs in the ${item.bin} bin.'),
          ],
          const SizedBox(height: 18),
          if (finished)
            MissionSummaryCard(
              score: score,
              maxScore: items.length,
              reward: missionReward,
              onReplay: _restart,
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: selectedBin == null
                    ? null
                    : () => _next(items, classNumber),
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
  final VoidCallback onTap;

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
