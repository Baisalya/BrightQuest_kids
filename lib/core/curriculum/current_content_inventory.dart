import '../content/content_repository.dart';

class CurrentContentRecord {
  const CurrentContentRecord({
    required this.id,
    required this.classNumber,
    required this.gameId,
    required this.topicId,
    required this.difficulty,
    required this.displayText,
    required this.fingerprint,
  });

  final String id;
  final int classNumber;
  final String gameId;
  final String topicId;
  final int difficulty;
  final String displayText;
  final String fingerprint;

  String get selectorKey => '$classNumber::$gameId::$topicId';
}

String _normalise(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

String _legacyIndexedId(
        int classNumber, String gameId, String kind, int index) =>
    'legacy.c$classNumber.$gameId.$kind${(index + 1).toString().padLeft(2, '0')}';

List<CurrentContentRecord> currentContentInventory(
    ContentRepository repository) {
  final result = <CurrentContentRecord>[];
  for (final classNumber in const <int>[3, 4, 5]) {
    final maths = repository.mathQuestionsForClass(
      classNumber,
      includeGeneratedPractice: false,
    );
    for (var index = 0; index < maths.length; index += 1) {
      final item = maths[index];
      result.add(CurrentContentRecord(
        id: _legacyIndexedId(classNumber, 'math_market', 'q', index),
        classNumber: classNumber,
        gameId: 'math_market',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText: item.text,
        fingerprint:
            'math|${_normalise(item.text)}|${item.answer}|${item.choices.join(',')}',
      ));
    }

    final fractions = repository.fractionMissionsForClass(
      classNumber,
      includeGeneratedPractice: false,
    );
    for (final item in fractions) {
      result.add(CurrentContentRecord(
        id: 'legacy.c$classNumber.fraction_pizza.${item.id}',
        classNumber: classNumber,
        gameId: 'fraction_pizza',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText:
            '${item.numerator}/${item.denominator} using ${item.totalSlices} slices',
        fingerprint:
            'fraction|${item.totalSlices}|${item.numerator}|${item.denominator}',
      ));
    }

    final science = repository.scienceQuestionsForClass(classNumber);
    for (var index = 0; index < science.length; index += 1) {
      final item = science[index];
      result.add(CurrentContentRecord(
        id: _legacyIndexedId(classNumber, 'science_lab', 'q', index),
        classNumber: classNumber,
        gameId: 'science_lab',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText: item.question,
        fingerprint:
            'science|${_normalise(item.question)}|${_normalise(item.answer)}|${item.choices.map(_normalise).join('|')}',
      ));
    }

    final reactions = repository.scienceReactionsForClass(classNumber);
    for (final item in reactions) {
      result.add(CurrentContentRecord(
        id: 'legacy.c$classNumber.science_lab.reaction.${item.id}',
        classNumber: classNumber,
        gameId: 'science_lab',
        topicId: 'reactions',
        difficulty: 1,
        displayText: item.title,
        fingerprint:
            'reaction|${_normalise(item.title)}|${_normalise(item.explanation)}',
      ));
    }

    final stories = repository.storyMissionsForClass(classNumber);
    for (final item in stories) {
      result.add(CurrentContentRecord(
        id: 'legacy.c$classNumber.story_builder.${item.id}',
        classNumber: classNumber,
        gameId: 'story_builder',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText: item.prompt,
        fingerprint:
            'story|${_normalise(item.prompt)}|${item.words.map(_normalise).join('|')}',
      ));
    }

    final grammar = repository.grammarMissionsForClass(
      classNumber,
      includeGeneratedPractice: false,
    );
    for (final item in grammar) {
      result.add(CurrentContentRecord(
        id: 'legacy.c$classNumber.grammar_puzzle.${item.id}',
        classNumber: classNumber,
        gameId: 'grammar_puzzle',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText: item.sentence,
        fingerprint:
            'grammar|${_normalise(item.sentence)}|${_normalise(item.noun)}|${_normalise(item.verb)}|${_normalise(item.adjective)}',
      ));
    }

    final maps = repository.mapQuestionsForClass(
      classNumber,
      includeGeneratedPractice: false,
    );
    for (final item in maps) {
      result.add(CurrentContentRecord(
        id: 'legacy.c$classNumber.map_quest.${item.id}',
        classNumber: classNumber,
        gameId: 'map_quest',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText: item.question,
        fingerprint:
            'map|${_normalise(item.question)}|${_normalise(item.answer)}',
      ));
    }

    final coding = repository.codingMissionsForClass(classNumber);
    for (final item in coding) {
      final obstacles = item.obstacles.toList()..sort();
      result.add(CurrentContentRecord(
        id: 'legacy.c$classNumber.coding_maze.${item.id}',
        classNumber: classNumber,
        gameId: 'coding_maze',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText: 'Route ${item.id}',
        fingerprint:
            'coding|${item.width}x${item.height}|${item.startX},${item.startY}|${item.goalX},${item.goalY}|${item.startDirection.name}|${obstacles.join(';')}|${item.maxCommands}',
      ));
    }

    final recycling = repository.recyclingItemsForClass(classNumber);
    for (final item in recycling) {
      result.add(CurrentContentRecord(
        id: 'legacy.c$classNumber.recycling_challenge.${item.id}',
        classNumber: classNumber,
        gameId: 'recycling_challenge',
        topicId: item.topicId,
        difficulty: item.difficulty,
        displayText: item.name,
        fingerprint:
            'recycling|${_normalise(item.name)}|${_normalise(item.bin)}',
      ));
    }
  }
  return List<CurrentContentRecord>.unmodifiable(result);
}

Map<String, int> currentContentSelectorCounts(
  Iterable<CurrentContentRecord> records,
) {
  final result = <String, int>{};
  for (final record in records) {
    result.update(record.selectorKey, (value) => value + 1, ifAbsent: () => 1);
  }
  return result;
}

List<List<CurrentContentRecord>> duplicateCurrentContentGroups(
  Iterable<CurrentContentRecord> records,
) {
  final byFingerprint = <String, List<CurrentContentRecord>>{};
  for (final record in records) {
    byFingerprint
        .putIfAbsent(record.fingerprint, () => <CurrentContentRecord>[])
        .add(record);
  }
  final duplicates = byFingerprint.values
      .where(
          (group) => group.map((item) => item.classNumber).toSet().length > 1)
      .map((group) => List<CurrentContentRecord>.unmodifiable(group))
      .toList();
  duplicates.sort((a, b) => a.first.fingerprint.compareTo(b.first.fingerprint));
  return List<List<CurrentContentRecord>>.unmodifiable(duplicates);
}
