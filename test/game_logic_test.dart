import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_repository.dart';
import 'package:brightquest_kids/core/content/game_content.dart';
import 'package:brightquest_kids/core/gameplay/game_logic.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readJson(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

ContentRepository _repository() => ContentRepository.fromJsonPacks(
      curriculumJson: _readJson('assets/content/curriculum_map.json'),
      schemaJson: _readJson('assets/content/content_schema_v1.json'),
      packJson: <Map<String, dynamic>>[
        _readJson('assets/content/class_3/pack.json'),
        _readJson('assets/content/class_4/pack.json'),
        _readJson('assets/content/class_5/pack.json'),
      ],
    );

void main() {
  group('fraction logic', () {
    test('accepts equivalent fractions', () {
      expect(
        fractionMatches(
          selectedSlices: 2,
          totalSlices: 8,
          targetNumerator: 1,
          targetDenominator: 4,
        ),
        isTrue,
      );
      expect(simplifiedFraction(8, 12), '2/3');
    });

    test('rejects a wrong slice count', () {
      expect(
        fractionMatches(
          selectedSlices: 3,
          totalSlices: 8,
          targetNumerator: 1,
          targetDenominator: 4,
        ),
        isFalse,
      );
    });
  });

  group('science logic', () {
    test('detects fizzing reaction from repository content', () {
      final reaction = _repository().scienceReactionForIngredients(
        4,
        {'Baking Soda', 'Vinegar'},
      );
      expect(reaction.id, 'fizz');
    });

    test('does not fake fizz for unrelated ingredients', () {
      final reaction = _repository().scienceReactionForIngredients(
        4,
        {'Water', 'Vinegar'},
      );
      expect(reaction.id, 'none');
    });
  });

  group('coding maze simulation', () {
    test('first Class 4 mission reaches the goal with a valid sequence', () {
      final mission = _repository().codingMissionsForClass(4).first;
      final result = runCodingMission(
        mission,
        const [
          CodingCommand.move,
          CodingCommand.move,
          CodingCommand.turnRight,
          CodingCommand.move,
        ],
      );
      expect(result.valid, isTrue);
      expect(result.success, isTrue);
      expect(result.finalX, 2);
      expect(result.finalY, 1);
    });

    test('leaving the board is invalid', () {
      final mission = _repository().codingMissionsForClass(4).first;
      final result = runCodingMission(
        mission,
        const [CodingCommand.turnLeft, CodingCommand.move],
      );
      expect(result.valid, isFalse);
      expect(result.success, isFalse);
    });

    test('repeat replays the previous executable command', () {
      final mission = CodingMission(
        id: 'repeat_test',
        width: 4,
        height: 1,
        startX: 0,
        startY: 0,
        goalX: 2,
        goalY: 0,
        startDirection: FacingDirection.east,
        maxCommands: 2,
      );
      final result = runCodingMission(
        mission,
        const [CodingCommand.move, CodingCommand.repeatLast],
      );
      expect(result.success, isTrue);
    });
  });

  test('class content changes difficulty and subject depth', () {
    final repository = _repository();
    final class3 = repository.mathQuestionsForClass(3, difficulty: 1);
    final class5 = repository.mathQuestionsForClass(5, difficulty: 1);
    expect(class3.first.text, isNot(class5.first.text));
    expect(class3, isNotEmpty);
    expect(class5, isNotEmpty);

    final class4Easy = repository.mathQuestionsForClass(4, difficulty: 1);
    final class4Advanced = repository.mathQuestionsForClass(4, difficulty: 3);
    expect(class4Advanced.length, greaterThan(class4Easy.length));
    expect(
      class4Advanced.any((question) => question.difficulty == 3),
      isTrue,
    );
  });

  test('repository keeps finite playable missions for every class', () {
    final repository = _repository();
    for (final classNumber in [3, 4, 5]) {
      expect(
        repository.fractionMissionsForClass(classNumber, difficulty: 1),
        isNotEmpty,
      );
      expect(
        repository.scienceQuestionsForClass(classNumber, difficulty: 1),
        isNotEmpty,
      );
      expect(
        repository.storyMissionsForClass(classNumber, difficulty: 1),
        isNotEmpty,
      );
      expect(
        repository.grammarMissionsForClass(classNumber, difficulty: 1),
        isNotEmpty,
      );
      expect(
        repository.mapQuestionsForClass(classNumber, difficulty: 1),
        isNotEmpty,
      );
      expect(
        repository.codingMissionsForClass(classNumber, difficulty: 1),
        isNotEmpty,
      );
      expect(
        repository.recyclingItemsForClass(classNumber, difficulty: 1),
        isNotEmpty,
      );
    }
  });

  test('coding banks are class-specific and difficulty-tiered', () {
    final repository = _repository();
    final class3 = repository.codingMissionsForClass(3, difficulty: 3);
    final class4 = repository.codingMissionsForClass(4, difficulty: 3);
    final class5 = repository.codingMissionsForClass(5, difficulty: 3);

    expect(class3.length, 6);
    expect(class4.length, 6);
    expect(class5.length, 6);
    expect(class3.first.id, isNot(class4.first.id));
    expect(class4.first.id, isNot(class5.first.id));
    expect(
      repository
          .codingMissionsForClass(5, difficulty: 1)
          .every((mission) => mission.difficulty == 1),
      isTrue,
    );
    expect(
      repository
          .codingMissionsForClass(5, difficulty: 2)
          .any((mission) => mission.difficulty == 2),
      isTrue,
    );
  });

  test(
      'all class-specific coding missions have a known valid route within budget',
      () {
    const routes = <String, String>{
      'c3_code_1': 'MM',
      'c3_code_2': 'MRMM',
      'c3_code_3': 'MLMMRMM',
      'c3_code_4': 'RMMMLMM',
      'c3_code_5': 'MLMMMRMMM',
      'c3_code_6': 'RMMMMLMMM',
      'c4_code_1': 'MMRM',
      'c4_code_2': 'MMLMM',
      'c4_code_3': 'RMMMLMM',
      'c4_code_4': 'RMMMMLMMMM',
      'c4_code_5': 'MLMMMMRMMMM',
      'c4_code_6': 'RMMMMLMMMM',
      'c5_code_1': 'MMMLM',
      'c5_code_2': 'MRMMMLMM',
      'c5_code_3': 'MLMMRMMMM',
      'c5_code_4': 'RMMMMLMMMM',
      'c5_code_5': 'MLMMMMRMMMMM',
      'c5_code_6': 'RMMMMMLMMMMM',
    };

    final repository = _repository();
    for (final classNumber in [3, 4, 5]) {
      for (final mission
          in repository.codingMissionsForClass(classNumber, difficulty: 3)) {
        final encoded = routes[mission.id];
        expect(encoded, isNotNull, reason: mission.id);
        final commands = encoded!
            .split('')
            .map((symbol) => switch (symbol) {
                  'M' => CodingCommand.move,
                  'L' => CodingCommand.turnLeft,
                  'R' => CodingCommand.turnRight,
                  _ => throw StateError('Unknown route symbol $symbol'),
                })
            .toList();
        expect(
          commands.length,
          lessThanOrEqualTo(mission.maxCommands),
          reason: mission.id,
        );
        final result = runCodingMission(mission, commands);
        expect(result.valid, isTrue, reason: mission.id);
        expect(result.success, isTrue, reason: mission.id);
      }
    }
  });
}
