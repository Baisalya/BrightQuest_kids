import '../models/game_models.dart';
import 'curriculum_models.dart';

const curriculumTopics = <CurriculumTopic>[
  // Class 3
  CurriculumTopic(
      id: 'c3_math_operations',
      classNumber: 3,
      subject: SubjectWorld.maths,
      title: 'Numbers & Operations',
      summary: 'Addition, subtraction, multiplication and simple division.',
      gameIds: ['math_market'],
      order: 1),
  CurriculumTopic(
      id: 'c3_math_fractions',
      classNumber: 3,
      subject: SubjectWorld.maths,
      title: 'Fractions Around Us',
      summary: 'Halves, thirds and quarters using visual models.',
      gameIds: ['fraction_pizza'],
      order: 2),
  CurriculumTopic(
      id: 'c3_english_sentence',
      classNumber: 3,
      subject: SubjectWorld.english,
      title: 'Sentence Building',
      summary: 'Arrange words into clear and meaningful sentences.',
      gameIds: ['story_builder'],
      order: 1),
  CurriculumTopic(
      id: 'c3_english_grammar',
      classNumber: 3,
      subject: SubjectWorld.english,
      title: 'Nouns, Verbs & Adjectives',
      summary: 'Recognise basic parts of speech in short sentences.',
      gameIds: ['grammar_puzzle'],
      order: 2),
  CurriculumTopic(
      id: 'c3_science_matter',
      classNumber: 3,
      subject: SubjectWorld.science,
      title: 'Materials & Matter',
      summary:
          'Observe solids, liquids, floating and simple material properties.',
      gameIds: ['science_lab'],
      order: 1),
  CurriculumTopic(
      id: 'c3_evs_waste',
      classNumber: 3,
      subject: SubjectWorld.evs,
      title: 'Waste & Clean Surroundings',
      summary: 'Sort common household waste and learn reuse habits.',
      gameIds: ['recycling_challenge'],
      order: 1),
  CurriculumTopic(
      id: 'c3_social_places',
      classNumber: 3,
      subject: SubjectWorld.social,
      title: 'Places & Directions',
      summary: 'Read simple maps, directions and important places.',
      gameIds: ['map_quest'],
      order: 1),
  CurriculumTopic(
      id: 'c3_coding_sequence',
      classNumber: 3,
      subject: SubjectWorld.coding,
      title: 'Sequences',
      summary: 'Give a robot instructions in the correct order.',
      gameIds: ['coding_maze'],
      order: 1),

  // Class 4
  CurriculumTopic(
      id: 'c4_math_operations',
      classNumber: 4,
      subject: SubjectWorld.maths,
      title: 'Multi-step Operations',
      summary: 'Use multiplication, division and mixed arithmetic fluently.',
      gameIds: ['math_market'],
      order: 1),
  CurriculumTopic(
      id: 'c4_math_fractions',
      classNumber: 4,
      subject: SubjectWorld.maths,
      title: 'Equivalent Fractions',
      summary: 'Model and identify equivalent parts of a whole.',
      gameIds: ['fraction_pizza'],
      order: 2),
  CurriculumTopic(
      id: 'c4_english_story',
      classNumber: 4,
      subject: SubjectWorld.english,
      title: 'Story Sequence',
      summary: 'Build coherent story events and strengthen vocabulary.',
      gameIds: ['story_builder'],
      order: 1),
  CurriculumTopic(
      id: 'c4_english_grammar',
      classNumber: 4,
      subject: SubjectWorld.english,
      title: 'Grammar in Context',
      summary: 'Identify nouns, verbs and adjectives inside richer sentences.',
      gameIds: ['grammar_puzzle'],
      order: 2),
  CurriculumTopic(
      id: 'c4_science_changes',
      classNumber: 4,
      subject: SubjectWorld.science,
      title: 'Matter & Changes',
      summary: 'Explore reactions, states of matter and observable changes.',
      gameIds: ['science_lab'],
      order: 1),
  CurriculumTopic(
      id: 'c4_evs_resources',
      classNumber: 4,
      subject: SubjectWorld.evs,
      title: 'Resources & Recycling',
      summary: 'Separate waste and connect choices to environmental impact.',
      gameIds: ['recycling_challenge'],
      order: 1),
  CurriculumTopic(
      id: 'c4_social_india',
      classNumber: 4,
      subject: SubjectWorld.social,
      title: 'India Map Skills',
      summary: 'Locate regions, capitals, directions and landmarks.',
      gameIds: ['map_quest'],
      order: 1),
  CurriculumTopic(
      id: 'c4_coding_turns',
      classNumber: 4,
      subject: SubjectWorld.coding,
      title: 'Algorithms & Turns',
      summary: 'Plan routes with movement, turns and repeated steps.',
      gameIds: ['coding_maze'],
      order: 1),

  // Class 5
  CurriculumTopic(
      id: 'c5_math_operations',
      classNumber: 5,
      subject: SubjectWorld.maths,
      title: 'Advanced Operations',
      summary:
          'Solve larger-number multiplication, division and mixed problems.',
      gameIds: ['math_market'],
      order: 1),
  CurriculumTopic(
      id: 'c5_math_fractions',
      classNumber: 5,
      subject: SubjectWorld.maths,
      title: 'Fraction Equivalence',
      summary: 'Work with more complex equivalent fractions and visual models.',
      gameIds: ['fraction_pizza'],
      order: 2),
  CurriculumTopic(
      id: 'c5_english_composition',
      classNumber: 5,
      subject: SubjectWorld.english,
      title: 'Composition & Vocabulary',
      summary: 'Build descriptive sentences and ordered story events.',
      gameIds: ['story_builder'],
      order: 1),
  CurriculumTopic(
      id: 'c5_english_grammar',
      classNumber: 5,
      subject: SubjectWorld.english,
      title: 'Parts of Speech Mastery',
      summary: 'Apply grammar recognition to longer sentences.',
      gameIds: ['grammar_puzzle'],
      order: 2),
  CurriculumTopic(
      id: 'c5_science_life',
      classNumber: 5,
      subject: SubjectWorld.science,
      title: 'Life & Physical Science',
      summary:
          'Review plants, matter, materials and simple scientific reasoning.',
      gameIds: ['science_lab'],
      order: 1),
  CurriculumTopic(
      id: 'c5_evs_sustainability',
      classNumber: 5,
      subject: SubjectWorld.evs,
      title: 'Sustainable Choices',
      summary: 'Classify waste and connect actions to resource conservation.',
      gameIds: ['recycling_challenge'],
      order: 1),
  CurriculumTopic(
      id: 'c5_social_india',
      classNumber: 5,
      subject: SubjectWorld.social,
      title: 'India & Geography',
      summary: 'Use map knowledge, directions and geographic reasoning.',
      gameIds: ['map_quest'],
      order: 1),
  CurriculumTopic(
      id: 'c5_coding_repeat',
      classNumber: 5,
      subject: SubjectWorld.coding,
      title: 'Efficient Algorithms',
      summary: 'Use repeats and route planning to solve mazes efficiently.',
      gameIds: ['coding_maze'],
      order: 1),
];

const learningWorlds = <LearningWorld>[
  LearningWorld(
      subject: SubjectWorld.maths,
      title: 'Maths Kingdom',
      subtitle: 'Numbers, fractions and problem solving',
      emoji: '🧮'),
  LearningWorld(
      subject: SubjectWorld.english,
      title: 'Story Forest',
      subtitle: 'Grammar, vocabulary and composition',
      emoji: '📚'),
  LearningWorld(
      subject: SubjectWorld.science,
      title: 'Discovery Lab',
      subtitle: 'Experiments, matter, plants and forces',
      emoji: '🔬'),
  LearningWorld(
      subject: SubjectWorld.evs,
      title: 'Green Planet',
      subtitle: 'Environment, resources and responsible choices',
      emoji: '🌱'),
  LearningWorld(
      subject: SubjectWorld.social,
      title: 'India Explorer',
      subtitle: 'Maps, directions, places and geography',
      emoji: '🗺️'),
  LearningWorld(
      subject: SubjectWorld.coding,
      title: 'Robot City',
      subtitle: 'Sequences, turns, repeats and algorithms',
      emoji: '🤖'),
];

final List<LearningLevel> learningLevels = _buildLearningLevels();

List<LearningLevel> _buildLearningLevels() {
  final result = <LearningLevel>[];
  for (final topic in curriculumTopics) {
    for (final gameId in topic.gameIds) {
      final baseOrder = topic.order * 10;
      result.addAll(<LearningLevel>[
        LearningLevel(
          id: '${topic.id}:$gameId:l1',
          classNumber: topic.classNumber,
          subject: topic.subject,
          gameId: gameId,
          curriculumTopicId: topic.id,
          title: '${topic.title} Warm-up',
          summary: 'Learn the core idea with friendly guided questions.',
          order: baseOrder + 1,
          difficulty: 1,
          type: LearningLevelType.practice,
        ),
        LearningLevel(
          id: '${topic.id}:$gameId:l2',
          classNumber: topic.classNumber,
          subject: topic.subject,
          gameId: gameId,
          curriculumTopicId: topic.id,
          title: '${topic.title} Challenge',
          summary: 'Apply the idea with less guidance and trickier choices.',
          order: baseOrder + 2,
          difficulty: 2,
          type: LearningLevelType.challenge,
        ),
        LearningLevel(
          id: '${topic.id}:$gameId:l3',
          classNumber: topic.classNumber,
          subject: topic.subject,
          gameId: gameId,
          curriculumTopicId: topic.id,
          title: '${topic.title} Mastery',
          summary: 'A mastery checkpoint. Score at least 60% to clear it.',
          order: baseOrder + 3,
          difficulty: 3,
          type: LearningLevelType.mastery,
        ),
      ]);
    }
  }
  return List<LearningLevel>.unmodifiable(result);
}

List<CurriculumTopic> topicsForClass(int classNumber, {SubjectWorld? subject}) {
  final result = curriculumTopics
      .where((topic) =>
          topic.classNumber == classNumber &&
          (subject == null || topic.subject == subject))
      .toList();
  result.sort((a, b) {
    final subjectOrder = a.subject.index.compareTo(b.subject.index);
    return subjectOrder != 0 ? subjectOrder : a.order.compareTo(b.order);
  });
  return result;
}

List<CurriculumTopic> topicsForGame(int classNumber, String gameId) =>
    topicsForClass(classNumber)
        .where((topic) => topic.gameIds.contains(gameId))
        .toList();

List<LearningLevel> levelsForClass(int classNumber, {SubjectWorld? subject}) {
  final result = learningLevels
      .where((level) =>
          level.classNumber == classNumber &&
          (subject == null || level.subject == subject))
      .toList();
  result.sort((a, b) {
    final subjectOrder = a.subject.index.compareTo(b.subject.index);
    return subjectOrder != 0 ? subjectOrder : a.order.compareTo(b.order);
  });
  return result;
}

List<LearningLevel> levelsForGame(int classNumber, String gameId) {
  final result = learningLevels
      .where(
          (level) => level.classNumber == classNumber && level.gameId == gameId)
      .toList();
  result.sort((a, b) => a.order.compareTo(b.order));
  return result;
}

List<LearningLevel> levelsForSubject(int classNumber, SubjectWorld subject) =>
    levelsForClass(classNumber, subject: subject);

LearningLevel? learningLevelById(String id) {
  for (final level in learningLevels) {
    if (level.id == id) return level;
  }
  return null;
}

LearningWorld? learningWorldForSubject(SubjectWorld subject) {
  for (final world in learningWorlds) {
    if (world.subject == subject) return world;
  }
  return null;
}
