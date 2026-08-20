enum CodingCommand { move, turnLeft, turnRight, repeatLast }

enum FacingDirection { north, east, south, west }

extension FacingDirectionLogic on FacingDirection {
  FacingDirection get turnLeft => switch (this) {
        FacingDirection.north => FacingDirection.west,
        FacingDirection.west => FacingDirection.south,
        FacingDirection.south => FacingDirection.east,
        FacingDirection.east => FacingDirection.north,
      };

  FacingDirection get turnRight => switch (this) {
        FacingDirection.north => FacingDirection.east,
        FacingDirection.east => FacingDirection.south,
        FacingDirection.south => FacingDirection.west,
        FacingDirection.west => FacingDirection.north,
      };

  (int, int) get delta => switch (this) {
        FacingDirection.north => (0, -1),
        FacingDirection.east => (1, 0),
        FacingDirection.south => (0, 1),
        FacingDirection.west => (-1, 0),
      };
}

class MathQuestion {
  const MathQuestion(
    this.text,
    this.answer,
    this.choices,
    this.hint, {
    this.id = '',
    this.topicId = 'operations',
    this.difficulty = 1,
  });
  final String text;
  final String id;
  final int answer;
  final List<int> choices;
  final String hint;
  final String topicId;
  final int difficulty;
}

class FractionMission {
  const FractionMission({
    required this.id,
    required this.totalSlices,
    required this.numerator,
    required this.denominator,
    this.topicId = 'fractions',
    this.difficulty = 1,
  });
  final String id;
  final int totalSlices;
  final int numerator;
  final int denominator;
  final String topicId;
  final int difficulty;
}

class ScienceQuizQuestion {
  const ScienceQuizQuestion(
    this.question,
    this.answer,
    this.choices,
    this.explanation, {
    this.id = '',
    this.topicId = 'science_core',
    this.difficulty = 1,
  });
  final String question;
  final String id;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String topicId;
  final int difficulty;
}

class ScienceReaction {
  const ScienceReaction({
    required this.id,
    required this.title,
    required this.explanation,
    required this.emoji,
  });
  final String id;
  final String title;
  final String explanation;
  final String emoji;
}

class StoryMission {
  const StoryMission({
    required this.id,
    required this.prompt,
    required this.words,
    this.topicId = 'sentence_building',
    this.difficulty = 1,
  });
  final String id;
  final String prompt;
  final List<String> words;
  final String topicId;
  final int difficulty;
}

class GrammarMission {
  const GrammarMission({
    required this.id,
    required this.sentence,
    required this.noun,
    required this.verb,
    required this.adjective,
    this.topicId = 'parts_of_speech',
    this.difficulty = 1,
  });
  final String id;
  final String sentence;
  final String noun;
  final String verb;
  final String adjective;
  final String topicId;
  final int difficulty;
}

class MapQuestion {
  const MapQuestion(
    this.id,
    this.question,
    this.answer,
    this.choices,
    this.hint, {
    this.topicId = 'map_skills',
    this.difficulty = 1,
  });
  final String id;
  final String question;
  final String answer;
  final List<String> choices;
  final String hint;
  final String topicId;
  final int difficulty;
}

class CodingMission {
  const CodingMission({
    required this.id,
    required this.width,
    required this.height,
    required this.startX,
    required this.startY,
    required this.goalX,
    required this.goalY,
    required this.startDirection,
    this.obstacles = const <String>{},
    required this.maxCommands,
    this.topicId = 'algorithms',
    this.difficulty = 1,
  });
  final String id;
  final int width;
  final int height;
  final int startX;
  final int startY;
  final int goalX;
  final int goalY;
  final FacingDirection startDirection;
  final Set<String> obstacles;
  final int maxCommands;
  final String topicId;
  final int difficulty;
}

class RecyclingItem {
  const RecyclingItem(
    this.id,
    this.name,
    this.emoji,
    this.bin, {
    this.topicId = 'waste_sorting',
    this.difficulty = 1,
  });
  final String id;
  final String name;
  final String emoji;
  final String bin;
  final String topicId;
  final int difficulty;
}
