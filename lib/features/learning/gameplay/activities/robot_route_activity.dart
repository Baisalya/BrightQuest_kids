import 'package:flutter/material.dart';

import '../../../../core/content/content_activity.dart';
import '../../../../core/content/game_content.dart';
import '../../../../core/gameplay/game_logic.dart';
import '../../../../core/learning/activity_response_evaluator.dart';
import '../../../../core/theme/app_theme.dart';
import '../activity_game_contract.dart';

class RobotRouteActivity extends StatefulWidget {
  const RobotRouteActivity({
    required this.activity,
    required this.locked,
    required this.onResponseChanged,
    super.key,
  });

  final ContentActivity activity;
  final bool locked;
  final GameActivityResponseChanged onResponseChanged;

  @override
  State<RobotRouteActivity> createState() => _RobotRouteActivityState();
}

class _RobotRouteActivityState extends State<RobotRouteActivity> {
  final List<CodingCommand> _commands = <CodingCommand>[];

  CodingMission get _mission {
    final payload = widget.activity.payload;
    final direction = FacingDirection.values.firstWhere(
      (value) => value.name == payload['startDirection'],
    );
    return CodingMission(
      id: widget.activity.id,
      width: payload['width'] as int,
      height: payload['height'] as int,
      startX: payload['startX'] as int,
      startY: payload['startY'] as int,
      goalX: payload['goalX'] as int,
      goalY: payload['goalY'] as int,
      startDirection: direction,
      obstacles: Set<String>.from(payload['obstacles'] as List),
      maxCommands: payload['maxCommands'] as int,
      topicId: widget.activity.topicId,
      difficulty: widget.activity.difficulty,
    );
  }

  void _add(CodingCommand command) {
    final mission = _mission;
    if (widget.locked || _commands.length >= mission.maxCommands) return;
    setState(() => _commands.add(command));
    _emit();
  }

  void _remove(int index) {
    if (widget.locked) return;
    setState(() => _commands.removeAt(index));
    _emit();
  }

  void _emit() {
    widget.onResponseChanged(
      GameActivityResponseSnapshot(
        value: List<CodingCommand>.from(_commands),
        ready: _commands.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mission = _mission;
    final run = _commands.isEmpty ? null : runCodingMission(mission, _commands);
    final robotX = run?.finalX ?? mission.startX;
    final robotY = run?.finalY ?? mission.startY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0EFFF), Color(0xFFF7FAFF)],
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Program the rescue route',
                      style: TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reach the flag in at most ${mission.maxCommands} commands.',
                      style: const TextStyle(
                        color: AppTheme.inkMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              _CommandBudget(
                used: _commands.length,
                max: mission.maxCommands,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RobotGrid(
          mission: mission,
          robotX: robotX,
          robotY: robotY,
          routeValid: run?.valid ?? true,
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F1FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD8D4FF)),
          ),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_commands.isEmpty)
                const Text(
                  '🧩 Command belt is empty — build a route below.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              for (var index = 0; index < _commands.length; index += 1)
                InputChip(
                  avatar: Icon(_commandIcon(_commands[index]), size: 17),
                  label: Text(
                    '${index + 1}. ${ActivityResponseEvaluator.commandLabel(_commands[index])}',
                  ),
                  onDeleted: widget.locked ? null : () => _remove(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (run != null)
          Text(
            run.valid
                ? run.success
                    ? '🏁 Preview reaches the goal! Run it to check the mission.'
                    : '👀 Preview ends at (${run.finalX}, ${run.finalY}). Keep programming.'
                : '⚠️ That preview hits a wall or rock. Edit the command belt.',
            style: TextStyle(
              color: run.valid ? AppTheme.inkMuted : const Color(0xFFB6532D),
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final command in CodingCommand.values)
              _CommandButton(
                command: command,
                enabled:
                    !widget.locked && _commands.length < mission.maxCommands,
                onPressed: () => _add(command),
              ),
          ],
        ),
      ],
    );
  }
}

class _CommandBudget extends StatelessWidget {
  const _CommandBudget({required this.used, required this.max});

  final int used;
  final int max;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFD8D4FF)),
        ),
        child: Text(
          '$used/$max',
          style: const TextStyle(
            color: Color(0xFF574FC4),
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _RobotGrid extends StatelessWidget {
  const _RobotGrid({
    required this.mission,
    required this.robotX,
    required this.robotY,
    required this.routeValid,
  });

  final CodingMission mission;
  final int robotX;
  final int robotY;
  final bool routeValid;

  @override
  Widget build(BuildContext context) {
    final cellCount = mission.width * mission.height;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: AspectRatio(
          aspectRatio: mission.width / mission.height,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: mission.width,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              final x = index % mission.width;
              final y = index ~/ mission.width;
              final rock = mission.obstacles.contains('$x,$y');
              final goal = x == mission.goalX && y == mission.goalY;
              final start = x == mission.startX && y == mission.startY;
              final robot = x == robotX && y == robotY;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: rock
                        ? const [Color(0xFFE8E3DA), Color(0xFFD7D0C5)]
                        : goal
                            ? const [Color(0xFFE2F8E6), Color(0xFFF5FFF6)]
                            : const [Color(0xFFF2F7FC), Color(0xFFFFFFFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: robot
                        ? const Color(0xFF6D63E8)
                        : const Color(0xFFD9E4EE),
                    width: robot ? 2 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (start && !robot)
                      const Positioned(
                        left: 4,
                        top: 3,
                        child: Text('S', style: TextStyle(fontSize: 8)),
                      ),
                    Text(
                      robot
                          ? routeValid
                              ? '🤖'
                              : '⚠️'
                          : rock
                              ? '🪨'
                              : goal
                                  ? '🏁'
                                  : '',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.command,
    required this.enabled,
    required this.onPressed,
  });

  final CodingCommand command;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(_commandIcon(command), size: 18),
        label: Text(ActivityResponseEvaluator.commandLabel(command)),
      );
}

IconData _commandIcon(CodingCommand command) => switch (command) {
      CodingCommand.move => Icons.arrow_upward_rounded,
      CodingCommand.turnLeft => Icons.turn_left_rounded,
      CodingCommand.turnRight => Icons.turn_right_rounded,
      CodingCommand.repeatLast => Icons.replay_rounded,
    };
