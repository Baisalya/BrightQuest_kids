import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/adaptive_difficulty_models.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_widgets.dart';

class StoryBuilderScreen extends StatefulWidget {
  const StoryBuilderScreen({this.learningLevel, super.key});
  final LearningLevel? learningLevel;

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  int missionIndex = 0;
  int score = 0;
  final List<String> selected = <String>[];
  bool checked = false;
  bool? correct;
  bool hadMistake = false;
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
      gameId: 'story_builder',
      classNumber: _classNumber,
      fallbackDifficulty: widget.learningLevel?.difficulty ??
          controller.recommendedDifficulty('story_builder'),
      learningLevelId: widget.learningLevel?.id,
    );
    final missions = BrightQuestScope.contentOf(context)
        .storyMissionsForClass(_classNumber, difficulty: _difficulty);
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'story_builder',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    missionIndex = checkpoint.cursor.clamp(0, missions.length - 1).toInt();
    score = checkpoint.score.clamp(0, missions.length).toInt();
    selected
      ..clear()
      ..addAll((checkpoint.data['selected'] as List?)?.whereType<String>() ??
          const <String>[]);
    checked = checkpoint.data['checked'] as bool? ?? false;
    correct = checkpoint.data['correct'] as bool?;
    hadMistake = checkpoint.data['hadMistake'] as bool? ?? false;
    _hintUsed = checkpoint.data['hintUsed'] as bool? ?? false;
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    if (checkpoint.stage == GameSessionStage.result &&
        checkpoint.reward != null) {
      finished = true;
      missionReward = checkpoint.reward!.toReward();
    }
    _sessionConfigured = true;
  }

  List<String> _remainingWords(StoryMission mission) {
    final remaining = List<String>.from(mission.words);
    for (final word in selected) {
      remaining.remove(word);
    }
    return remaining;
  }

  void _addWord(String word) {
    if (finished || correct == true) return;
    setState(() {
      selected.add(word);
      checked = false;
      correct = null;
    });
    _checkpoint();
  }

  void _removeWord(int index) {
    if (finished || correct == true) return;
    setState(() {
      selected.removeAt(index);
      checked = false;
      correct = null;
    });
    _checkpoint();
  }

  Future<void> _check(StoryMission mission) async {
    if (checked || selected.isEmpty || _answerInFlight) return;
    _answerInFlight = true;
    try {
      final isCorrect = selected.join(' ') == mission.words.join(' ');
      final controller = BrightQuestScope.of(context);
      final activity = const GameEvidenceAdapter().resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'story_builder',
        legacyContentId: mission.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'story_builder',
        learningLevel: widget.learningLevel,
        correct: isCorrect,
        attemptMarker: 'answer:$_attemptSerial:${selected.join('|')}',
        topicId: mission.topicId,
        difficulty: mission.difficulty,
        masteryGain: 0.07,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: const GameEvidenceAdapter().kindFor(widget.learningLevel),
        hintLevel: _hintUsed ? 1 : 0,
        retries: hadMistake ? 1 : 0,
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId: isCorrect ? null : 'sentence_order',
        confidence: _hintUsed ? 0.55 : 0.82,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      final chosenSentence = selected.join(' ');
      if (isCorrect) {
        FeedbackService.correct(
          controller,
          answer: chosenSentence,
          detail: 'You built the sentence in the right order.',
        );
      } else {
        FeedbackService.wrong(
          controller,
          answer: chosenSentence,
          guidance: 'Rearrange the words and try again.',
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

  Future<void> _next(List<StoryMission> missions, int classNumber) async {
    if (correct != true) return;
    if (missionIndex == missions.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'story_builder',
        fallbackMissionId: 'story_builder:c$classNumber:d$_difficulty:core_run',
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
      selected.clear();
      checked = false;
      correct = null;
      hadMistake = false;
      _hintUsed = false;
      _itemStarted = DateTime.now();
    });
    _checkpoint();
  }

  Future<void> _showHint(StoryMission mission) async {
    if (!learningLevelAllowsMainGameHints(widget.learningLevel)) return;
    final controller = BrightQuestScope.of(context);
    final hintUnlocked = await controller.useHintSafely(
      gameId: 'story_builder',
      learningLevel: widget.learningLevel,
      cost: 3,
      marker: 'story:$missionIndex',
    );
    if (!mounted) return;
    if (!hintUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need 3 coins for a hint.')),
      );
      return;
    }
    setState(() {
      hadMistake = true;
      _hintUsed = true;
    });
    _checkpoint();
    final nextIndex =
        selected.length.clamp(0, mission.words.length - 1).toInt();
    final nextWord = mission.words[nextIndex];
    final hintText = 'Next word: $nextWord';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(hintText)));
    FeedbackService.hint(controller, hintText);
  }

  void _restart() {
    final missions = BrightQuestScope.contentOf(context)
        .storyMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).restartActiveGameSession(
      gameId: 'story_builder',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    setState(() {
      missionIndex = 0;
      score = 0;
      _attemptSerial = 0;
      selected.clear();
      checked = false;
      correct = null;
      hadMistake = false;
      _hintUsed = false;
      finished = false;
      missionReward = null;
      _itemStarted = DateTime.now();
    });
  }

  void _checkpoint() {
    final missions = BrightQuestScope.contentOf(context)
        .storyMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'story_builder',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: missionIndex,
      score: score,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        'selected': List<String>.from(selected),
        'checked': checked,
        if (correct != null) 'correct': correct,
        'hadMistake': hadMistake,
        'hintUsed': _hintUsed,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final missions = BrightQuestScope.contentOf(context)
        .storyMissionsForClass(classNumber, difficulty: _difficulty);
    final mission = missions[missionIndex];
    final remaining = _remainingWords(mission);

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Story Builder',
      subtitle: widget.learningLevel == null
          ? 'Class $classNumber • Read, choose, arrange, learn'
          : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF22B8A7),
      voicePrompt: mission.prompt,
      voiceChoices: mission.words,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          GameProgressStrip(
              current: missionIndex + 1, total: missions.length, score: score),
          const SizedBox(height: 14),
          _StoryScene(index: missionIndex, prompt: mission.prompt),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final builderPanel = _SentenceBuilder(
                selected: selected,
                remaining: remaining,
                correct: correct,
                checked: checked,
                onAdd: _addWord,
                onRemove: _removeWord,
              );
              const helper = _WordHelper();
              if (!wide)
                return Column(children: [
                  builderPanel,
                  const SizedBox(height: 12),
                  helper
                ]);
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: builderPanel),
                    const SizedBox(width: 14),
                    const Expanded(flex: 2, child: helper)
                  ]);
            },
          ),
          if (checked) ...[
            const SizedBox(height: 12),
            correct == true
                ? const SuccessBanner(
                    text: 'Excellent! The sentence is in the correct order.')
                : const ErrorBanner(
                    text:
                        'The order is not correct yet. Rearrange the words and try again.'),
          ],
          const SizedBox(height: 16),
          if (finished)
            MissionSummaryCard(
                learningLevel: widget.learningLevel,
                score: score,
                maxScore: missions.length,
                reward: missionReward,
                onReplay: _restart)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Read the scene',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            Text(mission.prompt,
                                style:
                                    const TextStyle(fontSize: 18, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Read'),
                ),
                if (learningLevelAllowsMainGameHints(widget.learningLevel))
                  OutlinedButton.icon(
                    onPressed:
                        correct == true ? null : () => _showHint(mission),
                    icon: const Icon(Icons.lightbulb_rounded),
                    label: const Text('Hint · 3 coins'),
                  ),
                FilledButton.icon(
                    onPressed: checked || selected.isEmpty
                        ? null
                        : () => _check(mission),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Check')),
                if (correct == true)
                  FilledButton.icon(
                    onPressed: () => _next(missions, classNumber),
                    icon: Icon(missionIndex == missions.length - 1
                        ? Icons.flag_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(missionIndex == missions.length - 1
                        ? 'Finish Story'
                        : 'Next Scene'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StoryScene extends StatelessWidget {
  const _StoryScene({required this.index, required this.prompt});
  final int index;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: const Color(0xFF22B8A7).withValues(alpha: .15), width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x160C3356), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final art = Stack(
            children: [
              const Positioned.fill(
                  child: BrightGameScene(gameId: 'story_builder')),
              Positioned(
                  left: 12,
                  top: 12,
                  child: BrightPill(
                      icon: Icons.auto_stories_rounded,
                      label: 'SCENE ${index + 1}',
                      color: const Color(0xFF167E70),
                      background: Colors.white.withValues(alpha: .90))),
              const Positioned(
                  right: 10,
                  bottom: 4,
                  child:
                      SizedBox(width: 92, child: BrightLionMascot(size: 86))),
            ],
          );
          final copy = Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFFFFCF5), Color(0xFFF3FFF9)])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prompt,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy)),
                const SizedBox(height: 10),
                const BrightMascotBubble(
                    message: 'Read the scene, then build the sentence.',
                    emoji: '📚',
                    compact: true),
              ],
            ),
          );
          if (compact)
            return Column(children: [SizedBox(height: 150, child: art), copy]);
          return SizedBox(
              height: 190,
              child: Row(children: [
                Expanded(flex: 5, child: art),
                Expanded(flex: 4, child: copy)
              ]));
        },
      ),
    );
  }
}

class _SentenceBuilder extends StatelessWidget {
  const _SentenceBuilder(
      {required this.selected,
      required this.remaining,
      required this.correct,
      required this.checked,
      required this.onAdd,
      required this.onRemove});
  final List<String> selected;
  final List<String> remaining;
  final bool? correct;
  final bool checked;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => BrightSurface(
        borderColor: const Color(0xFF22B8A7).withValues(alpha: 0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrightSectionTitle(
                title: 'Build the sentence',
                subtitle: 'Tap the words in the correct order.',
                icon: Icons.view_week_rounded),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 90),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF6FBFF),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0x14000000))),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selected.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Tap words below to build the sentence.',
                            style: TextStyle(color: AppTheme.inkMuted))),
                  for (var i = 0; i < selected.length; i++)
                    InputChip(
                      backgroundColor: const Color(0xFFEAF6FF),
                      label: Text(selected[i],
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      onDeleted: correct == true ? null : () => onRemove(i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: remaining
                  .map((word) => ActionChip(
                        backgroundColor: const Color(0xFFFFF7D9),
                        label: Text(word,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        onPressed: () => onAdd(word),
                      ))
                  .toList(),
            ),
            if (checked) ...[
              const SizedBox(height: 9),
              BrightPill(
                icon: correct == true
                    ? Icons.check_circle_rounded
                    : Icons.refresh_rounded,
                label: correct == true ? 'Sentence ready!' : 'Try a new order',
                color: correct == true
                    ? const Color(0xFF25763C)
                    : const Color(0xFF9B4A3F),
                background: correct == true
                    ? const Color(0xFFE3F7E7)
                    : const Color(0xFFFFE9E5),
              ),
            ],
          ],
        ),
      );
}

class _WordHelper extends StatelessWidget {
  const _WordHelper();

  @override
  Widget build(BuildContext context) => BrightSurface(
        color: const Color(0xFFF9F5FF),
        borderColor: const Color(0xFF6D4BE8).withValues(alpha: 0.13),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrightSectionTitle(
                title: 'Word Helper',
                subtitle: 'Tiny clues for tricky words.',
                icon: Icons.auto_awesome_rounded),
            SizedBox(height: 12),
            _Definition(
                word: 'glowing', meaning: 'shining with light', emoji: '✨'),
            _Definition(
                word: 'adventure',
                meaning: 'an exciting journey',
                emoji: '🗺️'),
            _Definition(word: 'courage', meaning: 'bravery', emoji: '🛡️'),
          ],
        ),
      );
}

class _Definition extends StatelessWidget {
  const _Definition(
      {required this.word, required this.meaning, required this.emoji});
  final String word;
  final String meaning;
  final String emoji;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
              child: RichText(
                  text: TextSpan(
                      style:
                          const TextStyle(color: AppTheme.navy, height: 1.35),
                      children: [
                TextSpan(
                    text: '$word\n',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                TextSpan(
                    text: meaning,
                    style: const TextStyle(color: AppTheme.inkMuted))
              ])))
        ]),
      );
}
