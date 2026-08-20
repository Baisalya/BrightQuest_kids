import '../content/game_content.dart';

int greatestCommonDivisor(int a, int b) {
  var x = a.abs();
  var y = b.abs();
  while (y != 0) {
    final remainder = x % y;
    x = y;
    y = remainder;
  }
  return x == 0 ? 1 : x;
}

bool fractionMatches({
  required int selectedSlices,
  required int totalSlices,
  required int targetNumerator,
  required int targetDenominator,
}) {
  if (selectedSlices < 0 || totalSlices <= 0 || targetDenominator <= 0) {
    return false;
  }
  final left = selectedSlices * targetDenominator;
  final right = targetNumerator * totalSlices;
  return left == right;
}

String simplifiedFraction(int numerator, int denominator) {
  if (denominator <= 0) return '$numerator/$denominator';
  final gcd = greatestCommonDivisor(numerator, denominator);
  return '${numerator ~/ gcd}/${denominator ~/ gcd}';
}

ScienceReaction evaluateReaction(Set<String> ingredients) {
  if (ingredients.contains('Baking Soda') && ingredients.contains('Vinegar')) {
    return const ScienceReaction(
      id: 'fizz',
      title: 'Fizzing reaction',
      explanation: 'Baking soda and vinegar release carbon dioxide gas bubbles.',
      emoji: '🧪🫧✨',
    );
  }
  if (ingredients.contains('Water') && ingredients.contains('Salt')) {
    return const ScienceReaction(
      id: 'dissolve',
      title: 'Dissolving',
      explanation: 'Salt spreads through the water to form a solution.',
      emoji: '💧✨',
    );
  }
  return const ScienceReaction(
    id: 'none',
    title: 'No target reaction yet',
    explanation: 'Try a different safe virtual combination.',
    emoji: '🔬',
  );
}

CodingRunResult runCodingMission(
  CodingMission mission,
  List<CodingCommand> commands,
) {
  var x = mission.startX;
  var y = mission.startY;
  var direction = mission.startDirection;
  CodingCommand? previousExecutable;
  var valid = true;
  var executed = 0;

  void execute(CodingCommand command) {
    if (command == CodingCommand.repeatLast) {
      final previous = previousExecutable;
      if (previous == null) {
        valid = false;
        return;
      }
      execute(previous);
      return;
    }

    if (command == CodingCommand.turnLeft) {
      direction = direction.turnLeft;
    } else if (command == CodingCommand.turnRight) {
      direction = direction.turnRight;
    } else if (command == CodingCommand.move) {
      final (dx, dy) = direction.delta;
      final nextX = x + dx;
      final nextY = y + dy;
      if (nextX < 0 || nextY < 0 || nextX >= mission.width || nextY >= mission.height) {
        valid = false;
        return;
      }
      if (mission.obstacles.contains('$nextX,$nextY')) {
        valid = false;
        return;
      }
      x = nextX;
      y = nextY;
    }

    previousExecutable = command;
    executed += 1;
  }

  for (final command in commands) {
    if (!valid) break;
    execute(command);
  }

  return CodingRunResult(
    success: valid && x == mission.goalX && y == mission.goalY,
    valid: valid,
    finalX: x,
    finalY: y,
    executedCommands: executed,
  );
}

class CodingRunResult {
  const CodingRunResult({
    required this.success,
    required this.valid,
    required this.finalX,
    required this.finalY,
    required this.executedCommands,
  });

  final bool success;
  final bool valid;
  final int finalX;
  final int finalY;
  final int executedCommands;
}
