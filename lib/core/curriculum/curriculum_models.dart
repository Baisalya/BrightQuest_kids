import '../models/game_models.dart';

class CurriculumTopic {
  const CurriculumTopic({
    required this.id,
    required this.classNumber,
    required this.subject,
    required this.title,
    required this.summary,
    required this.gameIds,
    required this.order,
  });

  final String id;
  final int classNumber;
  final SubjectWorld subject;
  final String title;
  final String summary;
  final List<String> gameIds;
  final int order;
}

class CurriculumCoverage {
  const CurriculumCoverage({
    required this.totalTopics,
    required this.startedTopics,
    required this.strongTopics,
  });

  final int totalTopics;
  final int startedTopics;
  final int strongTopics;
}

enum LearningLevelType { practice, challenge, mastery }

class LearningLevel {
  const LearningLevel({
    required this.id,
    required this.classNumber,
    required this.subject,
    required this.gameId,
    required this.curriculumTopicId,
    required this.title,
    required this.summary,
    required this.order,
    required this.difficulty,
    required this.type,
    this.passRatio = 0.6,
  });

  final String id;
  final int classNumber;
  final SubjectWorld subject;
  final String gameId;
  final String curriculumTopicId;
  final String title;
  final String summary;
  final int order;
  final int difficulty;
  final LearningLevelType type;
  final double passRatio;

  bool get isMastery => type == LearningLevelType.mastery;

  String get typeLabel => switch (type) {
        LearningLevelType.practice => 'Practice',
        LearningLevelType.challenge => 'Challenge',
        LearningLevelType.mastery => 'Mastery',
      };
}

class LearningWorld {
  const LearningWorld({
    required this.subject,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  final SubjectWorld subject;
  final String title;
  final String subtitle;
  final String emoji;
}
