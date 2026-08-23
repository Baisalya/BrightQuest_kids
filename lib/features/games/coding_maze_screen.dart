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

class CodingMazeScreen extends StatefulWidget {
  const CodingMazeScreen({this.learningLevel, super.key});

  final LearningLevel? learningLevel;

  @override
  State<CodingMazeScreen> createState() => _CodingMazeScreenState();
}

class _CodingMazeScreenState extends State<CodingMazeScreen> {
  int missionIndex = 0;
  int score = 0;
  final List<CodingCommand> commands = <CodingCommand>[];
  CodingRunResult? result;
  bool missionHadFailure = false;
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
      gameId: 'coding_maze',
      classNumber: _classNumber,
      fallbackDifficulty: widget.learningLevel?.difficulty ??
          controller.recommendedDifficulty('coding_maze'),
      learningLevelId: widget.learningLevel?.id,
    );
    final missions = BrightQuestScope.contentOf(context)
        .codingMissionsForClass(_classNumber, difficulty: _difficulty);
    final checkpoint = controller.beginOrResumeGameSession(
      gameId: 'coding_maze',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    missionIndex = checkpoint.cursor.clamp(0, missions.length - 1).toInt();
    score = checkpoint.score.clamp(0, missions.length).toInt();
    commands
      ..clear()
      ..addAll((checkpoint.data['commands'] as List?)
              ?.whereType<String>()
              .map(_commandFromName)
              .whereType<CodingCommand>() ??
          const <CodingCommand>[]);
    missionHadFailure = checkpoint.data['missionHadFailure'] as bool? ?? false;
    _attemptSerial = (checkpoint.data['attemptSerial'] as num?)?.toInt() ?? 0;
    if (checkpoint.data['ran'] == true && commands.isNotEmpty) {
      result = runCodingMission(missions[missionIndex], commands);
    }
    if (checkpoint.stage == GameSessionStage.result &&
        checkpoint.reward != null) {
      finished = true;
      missionReward = checkpoint.reward!.toReward();
    }
    _sessionConfigured = true;
  }

  void _add(CodingCommand command, CodingMission mission) {
    if (finished ||
        result?.success == true ||
        commands.length >= mission.maxCommands) return;
    setState(() {
      commands.add(command);
      result = null;
    });
    _checkpoint();
  }

  void _remove(int index) {
    if (finished || result?.success == true) return;
    setState(() {
      commands.removeAt(index);
      result = null;
    });
    _checkpoint();
  }

  Future<void> _run(CodingMission mission) async {
    if (commands.isEmpty || result != null || _answerInFlight) return;
    _answerInFlight = true;
    try {
      final runResult = runCodingMission(mission, commands);
      final controller = BrightQuestScope.of(context);
      final activity = const GameEvidenceAdapter().resolve(
        repository: BrightQuestScope.contentOf(context),
        classNumber: _classNumber,
        gameId: 'coding_maze',
        legacyContentId: mission.id,
      );
      await controller.recordAnswerSafely(
        gameId: 'coding_maze',
        learningLevel: widget.learningLevel,
        correct: runResult.success,
        attemptMarker:
            'answer:$_attemptSerial:${commands.map((item) => item.name).join('|')}',
        topicId: mission.topicId,
        difficulty: mission.difficulty,
        masteryGain: 0.08,
        coinReward: 12,
        xpReward: 14,
        itemId: activity?.id,
        competencyId: activity?.competencyId,
        evidenceKind: const GameEvidenceAdapter().kindFor(widget.learningLevel),
        retries: missionHadFailure ? 1 : 0,
        responseTimeMs: DateTime.now().difference(_itemStarted).inMilliseconds,
        misconceptionId: runResult.success ? null : 'algorithm_trace_or_turn',
        confidence: missionHadFailure ? 0.58 : 0.86,
      );
      if (!mounted) return;
      _attemptSerial += 1;
      final spokenProgram = commands.map(_label).join(', ');
      if (runResult.success) {
        FeedbackService.correct(
          controller,
          answer: spokenProgram,
          detail: 'The robot reached the goal.',
        );
      } else {
        FeedbackService.wrong(
          controller,
          answer: spokenProgram,
          guidance: 'Change the commands and run the robot again.',
        );
      }
      setState(() {
        result = runResult;
        if (runResult.success && !missionHadFailure) score += 1;
        if (!runResult.success) missionHadFailure = true;
      });
      _checkpoint(ran: true);
    } finally {
      _answerInFlight = false;
    }
  }

  Future<void> _next(List<CodingMission> missions, int classNumber) async {
    if (result?.success != true) return;
    if (missionIndex == missions.length - 1) {
      final controller = BrightQuestScope.of(context);
      final reward = await controller.completeRunSafely(
        gameId: 'coding_maze',
        fallbackMissionId: 'coding_maze:c$classNumber:d$_difficulty:core_run',
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
      commands.clear();
      result = null;
      missionHadFailure = false;
      _itemStarted = DateTime.now();
    });
    _checkpoint();
  }

  void _clear() {
    if (result?.success == true || finished) return;
    setState(() {
      commands.clear();
      result = null;
    });
    _checkpoint();
  }

  void _restart() {
    final missions = BrightQuestScope.contentOf(context)
        .codingMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).restartActiveGameSession(
      gameId: 'coding_maze',
      classNumber: _classNumber,
      difficulty: _difficulty,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
    );
    setState(() {
      missionIndex = 0;
      score = 0;
      _attemptSerial = 0;
      commands.clear();
      result = null;
      missionHadFailure = false;
      _itemStarted = DateTime.now();
      finished = false;
      missionReward = null;
    });
  }

  void _checkpoint({bool ran = false}) {
    final missions = BrightQuestScope.contentOf(context)
        .codingMissionsForClass(_classNumber, difficulty: _difficulty);
    BrightQuestScope.of(context).checkpointGameSession(
      gameId: 'coding_maze',
      classNumber: _classNumber,
      difficulty: _difficulty,
      cursor: missionIndex,
      score: score,
      maxScore: missions.length,
      learningLevel: widget.learningLevel,
      data: <String, Object?>{
        'attemptSerial': _attemptSerial,
        'commands': commands.map((command) => command.name).toList(),
        'missionHadFailure': missionHadFailure,
        'ran': ran || result != null,
      },
    );
  }

  CodingCommand? _commandFromName(String name) {
    for (final command in CodingCommand.values) {
      if (command.name == name) return command;
    }
    return null;
  }

  String _label(CodingCommand command) => switch (command) {
        CodingCommand.move => 'move',
        CodingCommand.turnLeft => 'turn left',
        CodingCommand.turnRight => 'turn right',
        CodingCommand.repeatLast => 'repeat',
      };

  IconData _icon(CodingCommand command) => switch (command) {
        CodingCommand.move => Icons.arrow_upward_rounded,
        CodingCommand.turnLeft => Icons.turn_left_rounded,
        CodingCommand.turnRight => Icons.turn_right_rounded,
        CodingCommand.repeatLast => Icons.repeat_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;
    final missions = BrightQuestScope.contentOf(context)
        .codingMissionsForClass(classNumber, difficulty: _difficulty);
    final mission = missions[missionIndex];

    return GameScaffold(
      learningLevel: widget.learningLevel,
      title: 'Coding Maze',
      subtitle: widget.learningLevel == null
          ? 'Class $classNumber • Adaptive level $_difficulty • Sequence and logic'
          : 'Class $classNumber • ${widget.learningLevel!.typeLabel} • ${widget.learningLevel!.title}',
      color: const Color(0xFF6652D9),
      voicePrompt:
          'Guide the robot to the goal using no more than ${mission.maxCommands} commands.',
      voiceChoices: CodingCommand.values.map(_label),
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
              gameId: 'coding_maze',
              caption:
                  'Build a command sequence and guide your robot to the goal.',
              accent: Color(0xFF6652D9)),
          const SizedBox(height: 16),
          _MazeGrid(mission: mission, result: result),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Program',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              const Spacer(),
              Text('${commands.length}/${mission.maxCommands} commands'),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (commands.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('Add commands, then run the program.'),
                  ),
                for (var i = 0; i < commands.length; i++)
                  InputChip(
                    avatar: Icon(_icon(commands[i]), size: 18),
                    label: Text('${i + 1}. ${_label(commands[i])}'),
                    onDeleted:
                        result?.success == true ? null : () => _remove(i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CodingCommand.values
                .map(
                  (command) => ActionChip(
                    avatar: Icon(_icon(command), size: 18),
                    label: Text(_label(command)),
                    onPressed: commands.length >= mission.maxCommands ||
                            result?.success == true
                        ? null
                        : () => _add(command, mission),
                  ),
                )
                .toList(),
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            result!.success
                ? const SuccessBanner(
                    text: 'Excellent! The robot reached the star.')
                : ErrorBanner(
                    text: result!.valid
                        ? 'The robot stopped at (${result!.finalX + 1}, ${result!.finalY + 1}). Edit the program and try again.'
                        : 'The program hit a wall or obstacle. Edit the sequence and try again.',
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
                OutlinedButton.icon(
                  onPressed: commands.isEmpty ? null : _clear,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: commands.isEmpty || result != null
                      ? null
                      : () => _run(mission),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Run'),
                ),
                if (result?.success == true) ...[
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

class _MazeGrid extends StatelessWidget {
  const _MazeGrid({required this.mission, required this.result});
  final CodingMission mission;
  final CodingRunResult? result;

  @override
  Widget build(BuildContext context) {
    final robotX = result?.finalX ?? mission.startX;
    final robotY = result?.finalY ?? mission.startY;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2250),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text(
            'Reach ⭐ without hitting a wall',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: mission.width / mission.height,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: mission.width,
              ),
              itemCount: mission.width * mission.height,
              itemBuilder: (context, index) {
                final x = index % mission.width;
                final y = index ~/ mission.width;
                final key = '$x,$y';
                var label = '';
                if (mission.obstacles.contains(key)) label = '🪨';
                if (x == mission.goalX && y == mission.goalY) label = '⭐';
                if (x == robotX && y == robotY) label = '🤖';
                return Container(
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 28)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
