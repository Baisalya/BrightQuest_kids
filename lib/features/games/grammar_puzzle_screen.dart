import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/game_content.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/game_evidence_adapter.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/feedback_service.dart';
import '../../core/session/game_session_models.dart';
import '../../widgets/bright_widgets.dart';

class GrammarPuzzleScreen extends StatefulWidget {
  const GrammarPuzzleScreen({this.learningLevel, super.key});

  final LearningLevel? learningLevel;

  @override
  State<GrammarPuzzleScreen> createState() => _GrammarPuzzleScreenState();
}

class _GrammarPuzzleScreenState extends State<GrammarPuzzleScreen> {
  int missionIndex = 0;
  int score = 0;
  String? noun;
  String? verb;
  String? adjective;
  bool checked = false;
  bool? correct;
  bool hadMistake = false;
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
      gameId: 'grammar_puzzle',
      classNumber: _classNumber,
      fallbackDifficulty: widget.learningLevel?.difficulty ??
          controller.recommendedDifficulty('grammar_puzzle'),
      learningLevelId: widget.learningLevel?.id,
    );
    final missions = BrightQuestScope.contentOf(context)
        .grammarMissionsForClass(_classNumber, difficulty: _difficulty);
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'grammar_puzzle',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    missionIndex = checkpoint.cursor.clamp(0, missions.length - 1).toInt();
    score = checkpoint.score.clamp(0, missions.length).toInt();
    noun = checkpoint.data['noun'] as String?;
    verb = checkpoint.data['verb'] as String?;
    adjective = checkpoint.data['adjective'] as String?;
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

  Future<void> _check(GrammarMission mission) async {
    if (checked ||
        noun == null ||
        verb == null ||
        adjective == null ||
        _answerInFlight) {
      return;
    }
    _answerInFlight = true;
    try {
      final isCorrect = noun == mission.noun &&
          verb == mission.verb &&
          adjective == mission.adjective;
      final controller = BrightQuestScope.of(context);
      final activity = const GameEvidenceAdapter().resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'grammar_puzzle',
        legacyContentId: mission.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'grammar_puzzle',
        learningLevel: widget.learningLevel,
        correct: isCorrect,
        attemptMarker: 'answer:$_attemptSerial:$noun|$verb|$adjective',
        topicId: mission.topicId,
        difficulty: mission.difficulty,
        masteryGain: 0.06,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: const GameEvidenceAdapter().kindFor(widget.learningLevel),
        retries: hadMistake ? 1 : 0,
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId: isCorrect ? null : 'parts_of_speech_classification',
        confidence: hadMistake ? 0.6 : 0.84,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      final chosen =
          '$noun as noun, $verb as verb, and $adjective as adjective';
      if (isCorrect) {
        FeedbackService.correct(
          controller,
          answer: chosen,
          detail: 'Every word is in the right grammar group.',
        );
      } else {
        FeedbackService.wrong(
          controller,
          answer: chosen,
          guidance: 'Change the word categories and try again.',
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

  Future<void> _next(List<GrammarMission> missions, int classNumber) async {
    if (correct != true) return;
    if (missionIndex == missions.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'grammar_puzzle',
        fallbackMissionId:
            'grammar_puzzle:c$classNumber:d$_difficulty:core_run',
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
      noun = null;
      verb = null;
      adjective = null;
      checked = false;
      correct = null;
      hadMistake = false;
      _itemStarted = DateTime.now();
    });
    _checkpoint();
  }

  void _resetSelection() {
    setState(() {
      noun = null;
      verb = null;
      adjective = null;
      checked = false;
      correct = null;
    });
    _checkpoint();
  }

  void _restart() {
    final missions = BrightQuestScope.contentOf(context)
        .grammarMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).restartActiveGameSession(
      gameId: 'grammar_puzzle',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    setState(() {
      missionIndex = 0;
      score = 0;
      _attemptSerial = 0;
      noun = null;
      verb = null;
      adjective = null;
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
        .grammarMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'grammar_puzzle',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: missionIndex,
      score: score,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        if (noun != null) 'noun': noun,
        if (verb != null) 'verb': verb,
        if (adjective != null) 'adjective': adjective,
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
        .grammarMissionsForClass(classNumber, difficulty: _difficulty);
    final mission = missions[missionIndex];

    final nounOptions = <String>{mission.noun, 'castle', 'quickly'}.toList();
    final verbOptions = <String>{mission.verb, 'brave', 'map'}.toList();
    final adjectiveOptions =
        <String>{mission.adjective, 'runs', 'dragon'}.toList();

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Grammar Puzzle',
      subtitle: widget.learningLevel == null
          ? 'Class $classNumber • Noun, verb and adjective challenge'
          : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFFF0549B),
      voicePrompt:
          'Sentence: ${mission.sentence}. Find the noun, verb, and adjective.',
      voiceChoices: <String>{
        ...nounOptions,
        ...verbOptions,
        ...adjectiveOptions,
      },
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
              gameId: 'grammar_puzzle',
              caption: 'Snap the word pieces into the right grammar groups.',
              accent: Color(0xFFF0549B)),
          const SizedBox(height: 16),
          Text(
            'Sentence: “${mission.sentence}”',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _ChoiceGroup(
            title: 'NOUN',
            color: Colors.blue,
            values: nounOptions,
            selected: noun,
            enabled: correct != true,
            onChanged: (value) {
              setState(() {
                noun = value;
                checked = false;
                correct = null;
              });
              _checkpoint();
            },
          ),
          const SizedBox(height: 12),
          _ChoiceGroup(
            title: 'VERB',
            color: Colors.green,
            values: verbOptions,
            selected: verb,
            enabled: correct != true,
            onChanged: (value) {
              setState(() {
                verb = value;
                checked = false;
                correct = null;
              });
              _checkpoint();
            },
          ),
          const SizedBox(height: 12),
          _ChoiceGroup(
            title: 'ADJECTIVE',
            color: Colors.orange,
            values: adjectiveOptions,
            selected: adjective,
            enabled: correct != true,
            onChanged: (value) {
              setState(() {
                adjective = value;
                checked = false;
                correct = null;
              });
              _checkpoint();
            },
          ),
          if (checked) ...[
            const SizedBox(height: 14),
            correct == true
                ? SuccessBanner(
                    text:
                        '${mission.noun} is the noun, ${mission.verb} is the verb, and ${mission.adjective} is the adjective.',
                  )
                : const ErrorBanner(
                    text:
                        'Some words are in the wrong category. Change your choices and try again.'),
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
                OutlinedButton.icon(
                  onPressed: correct == true ? null : _resetSelection,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: checked ||
                          noun == null ||
                          verb == null ||
                          adjective == null
                      ? null
                      : () => _check(mission),
                  icon: const Icon(Icons.extension_rounded),
                  label: const Text('Check Puzzle'),
                ),
                if (correct == true) ...[
                  const SizedBox(width: 8),
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

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.color,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });
  final String title;
  final Color color;
  final List<String> values;
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: selected == value,
                        onSelected: enabled ? (_) => onChanged(value) : null,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
}
