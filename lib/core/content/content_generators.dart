import 'game_content.dart';

class DeterministicContentGenerators {
  const DeterministicContentGenerators();

  MathQuestion arithmetic({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final random = _StableRandom(_mixSeed(classNumber, difficulty, seed, 11));
    final operation = random.nextInt(4);
    late String prompt;
    late int answer;
    late String hint;

    switch (operation) {
      case 0:
        final additionCeiling = switch (classNumber) {
          3 => difficulty == 1 ? 150 : 500,
          4 => difficulty == 1 ? 500 : 2000,
          _ => difficulty == 1 ? 1000 : 5000,
        };
        final addendA = 10 + random.nextInt(additionCeiling - 9);
        final addendB = 10 + random.nextInt(additionCeiling - 9);
        answer = addendA + addendB;
        prompt = '$addendA + $addendB = ?';
        hint = 'Add by place value, starting with the largest place.';
        break;
      case 1:
        final subtractionCeiling = switch (classNumber) {
          3 => difficulty == 1 ? 200 : 800,
          4 => difficulty == 1 ? 800 : 3000,
          _ => difficulty == 1 ? 1500 : 8000,
        };
        final low = 10 + random.nextInt(subtractionCeiling ~/ 2);
        final high = low + 1 + random.nextInt(subtractionCeiling - low);
        answer = high - low;
        prompt = '$high - $low = ?';
        hint = 'Subtract by place value and regroup only when needed.';
        break;
      case 2:
        final maxFactor = switch (classNumber) {
          3 => difficulty == 1 ? 8 : 12,
          4 => difficulty == 1 ? 12 : 20,
          _ => difficulty == 1 ? 15 : 30,
        };
        final factorA = 2 + random.nextInt(maxFactor - 1);
        final factorB = 2 + random.nextInt(maxFactor - 1);
        answer = factorA * factorB;
        prompt = '$factorA × $factorB = ?';
        hint = 'Break one factor into easier parts if you need to.';
        break;
      default:
        final maxDivisor = switch (classNumber) {
          3 => 10,
          4 => 12,
          _ => 20,
        };
        final divisor = 2 + random.nextInt(maxDivisor - 1);
        final maxQuotient = switch (difficulty) {
          1 => 10,
          2 => 20,
          _ => 40,
        };
        final quotient = 2 + random.nextInt(maxQuotient - 1);
        final dividend = divisor * quotient;
        answer = quotient;
        prompt = '$dividend ÷ $divisor = ?';
        hint = 'Think: $divisor × ? = $dividend.';
        break;
    }

    final choices = _numericChoices(answer, random);
    return MathQuestion(
      prompt,
      answer,
      choices,
      hint,
      id: 'gen_math_c${classNumber}_d${difficulty}_s$seed',
      topicId: _mathTopic(operation),
      difficulty: difficulty,
    );
  }

  FractionMission fraction({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final random = _StableRandom(_mixSeed(classNumber, difficulty, seed, 23));
    final denominators = switch (classNumber) {
      3 => const <int>[2, 3, 4, 5],
      4 => const <int>[2, 3, 4, 5, 6, 8],
      _ => const <int>[2, 3, 4, 5, 6, 8, 10, 12],
    };
    final denominator = denominators[random.nextInt(denominators.length)];
    final numerator = 1 + random.nextInt(denominator - 1);
    final multiplier = 1 + random.nextInt(difficulty + 2);
    final totalSlices = denominator * multiplier;
    return FractionMission(
      id: 'gen_fraction_c${classNumber}_d${difficulty}_s$seed',
      totalSlices: totalSlices,
      numerator: numerator,
      denominator: denominator,
      topicId: difficulty == 1 ? 'fraction_models' : 'equivalent_fractions',
      difficulty: difficulty,
    );
  }

  GrammarMission grammar({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final random = _StableRandom(_mixSeed(classNumber, difficulty, seed, 37));
    const nouns = <String>[
      'student',
      'river',
      'butterfly',
      'gardener',
      'explorer',
      'scientist',
      'puppy',
      'train',
    ];
    const verbs = <String>[
      'observes',
      'flows',
      'visits',
      'waters',
      'travels',
      'records',
      'runs',
      'moves',
    ];
    const adjectives = <String>[
      'curious',
      'powerful',
      'colourful',
      'patient',
      'brave',
      'careful',
      'playful',
      'noisy',
    ];
    final nounIndex = random.nextInt(nouns.length);
    final noun = nouns[nounIndex];
    final verb = verbs[nounIndex];
    final adjective = adjectives[nounIndex];
    final sentence = difficulty == 1
        ? 'The $adjective $noun $verb.'
        : difficulty == 2
            ? 'The $adjective $noun carefully $verb.'
            : 'Every morning, the $adjective $noun patiently $verb nearby.';
    return GrammarMission(
      id: 'gen_grammar_c${classNumber}_d${difficulty}_s$seed',
      sentence: sentence,
      noun: noun,
      verb: verb,
      adjective: adjective,
      topicId: 'parts_of_speech',
      difficulty: difficulty,
    );
  }

  MapQuestion mapDirection({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final random = _StableRandom(_mixSeed(classNumber, difficulty, seed, 53));
    const directions = <String>['North', 'East', 'South', 'West'];
    final facingIndex = random.nextInt(directions.length);
    final relation = random.nextInt(3);
    final answerIndex = switch (relation) {
      0 => (facingIndex + 1) % 4,
      1 => (facingIndex + 3) % 4,
      _ => (facingIndex + 2) % 4,
    };
    final relationText = switch (relation) {
      0 => 'on your right',
      1 => 'on your left',
      _ => 'behind you',
    };
    final facing = directions[facingIndex];
    final answer = directions[answerIndex];
    return MapQuestion(
      'gen_map_c${classNumber}_d${difficulty}_s$seed',
      'If you face $facing, which direction is $relationText?',
      answer,
      List<String>.from(directions),
      'Picture a compass with North at the top, then turn mentally from $facing.',
      topicId: 'directions',
      difficulty: difficulty,
    );
  }

  static String _mathTopic(int operation) => switch (operation) {
        0 => 'addition',
        1 => 'subtraction',
        2 => 'multiplication',
        _ => 'division',
      };

  static List<int> _numericChoices(int answer, _StableRandom random) {
    final values = <int>{answer};
    const offsets = <int>[1, 2, 5, 10, 20, 25, 50];
    final start = random.nextInt(offsets.length);
    final preferLowerFirst = random.nextInt(2) == 0;

    // Walk every offset once and try both directions. The previous unbounded
    // random loop could repeatedly choose only negative distractors for small
    // subtraction answers, making content validation and gameplay hang.
    for (var step = 0; step < offsets.length && values.length < 4; step += 1) {
      final offset = offsets[(start + step) % offsets.length];
      final lower = answer - offset;
      final higher = answer + offset;
      final candidates =
          preferLowerFirst ? <int>[lower, higher] : <int>[higher, lower];
      for (final candidate in candidates) {
        if (candidate >= 0) values.add(candidate);
        if (values.length == 4) break;
      }
    }

    // The offset set above always provides enough candidates, but keeping the
    // invariant explicit makes future edits safe without reintroducing a loop.
    if (values.length != 4) {
      throw StateError('Unable to generate four numeric choices for $answer.');
    }

    final result = values.toList();
    for (var i = result.length - 1; i > 0; i -= 1) {
      final j = random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return List<int>.unmodifiable(result);
  }

  static int _mixSeed(int classNumber, int difficulty, int seed, int salt) {
    var value = seed & 0x7fffffff;
    value ^= classNumber * 73856093;
    value ^= difficulty * 19349663;
    value ^= salt * 83492791;
    return value & 0x7fffffff;
  }

  static void _validateClassAndDifficulty(int classNumber, int difficulty) {
    if (classNumber < 3 || classNumber > 5) {
      throw ArgumentError.value(
          classNumber, 'classNumber', 'must be 3, 4 or 5');
    }
    if (difficulty < 1 || difficulty > 3) {
      throw ArgumentError.value(difficulty, 'difficulty', 'must be 1, 2 or 3');
    }
  }
}

class _StableRandom {
  _StableRandom(int seed) : _state = seed == 0 ? 0x6d2b79f5 : seed;

  int _state;

  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'must be positive');
    _state = (1664525 * _state + 1013904223) & 0xffffffff;
    return _state % max;
  }
}
