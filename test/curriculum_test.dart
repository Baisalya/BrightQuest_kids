import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each supported class has curriculum coverage', () {
    for (final classNumber in [3, 4, 5]) {
      final topics = topicsForClass(classNumber);
      expect(topics, isNotEmpty);
      expect(
          topics.any((topic) => topic.subject == SubjectWorld.maths), isTrue);
      expect(
          topics.any((topic) => topic.subject == SubjectWorld.english), isTrue);
      expect(
          topics.any((topic) => topic.subject == SubjectWorld.science), isTrue);
      expect(topics.any((topic) => topic.subject == SubjectWorld.evs), isTrue);
      expect(
          topics.any((topic) => topic.subject == SubjectWorld.social), isTrue);
      expect(
          topics.any((topic) => topic.subject == SubjectWorld.coding), isTrue);
    }
  });

  test('all curriculum game references point to real adventures', () {
    final gameIds = games.map((game) => game.id).toSet();
    for (final topic in curriculumTopics) {
      expect(topic.gameIds, isNotEmpty, reason: topic.id);
      for (final gameId in topic.gameIds) {
        expect(gameIds.contains(gameId), isTrue,
            reason: '${topic.id} -> $gameId');
      }
    }
  });

  test('topic ids are unique', () {
    final ids = curriculumTopics.map((topic) => topic.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('Phase 4 learning path contains 24 unique levels per class', () {
    final allIds = <String>{};
    for (final classNumber in [3, 4, 5]) {
      final levels = levelsForClass(classNumber);
      expect(levels.length, 24, reason: 'Class $classNumber');
      expect(levels.map((level) => level.id).toSet().length, 24);
      allIds.addAll(levels.map((level) => level.id));
    }
    expect(allIds.length, 72);
  });

  test('every curriculum track has practice challenge and mastery stages', () {
    for (final classNumber in [3, 4, 5]) {
      for (final game in games.where((game) => game.id != 'rewards_room')) {
        final levels = levelsForGame(classNumber, game.id);
        expect(levels.length, 3, reason: 'Class $classNumber ${game.id}');
        expect(levels[0].type.name, 'practice');
        expect(levels[0].difficulty, 1);
        expect(levels[1].type.name, 'challenge');
        expect(levels[1].difficulty, 2);
        expect(levels[2].type.name, 'mastery');
        expect(levels[2].difficulty, 3);
        expect(levels[2].isMastery, isTrue);
      }
    }
  });

  test('each learning world has at least one track in every class', () {
    for (final classNumber in [3, 4, 5]) {
      for (final world in learningWorlds) {
        expect(
          levelsForSubject(classNumber, world.subject),
          isNotEmpty,
          reason: 'Class $classNumber ${world.title}',
        );
      }
    }
  });
}
