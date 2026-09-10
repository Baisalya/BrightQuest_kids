import 'game_content.dart';

class DeterministicContentGenerators {
  const DeterministicContentGenerators();

  MathQuestion arithmetic({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final variant = seed.abs();
    final cycle = variant ~/ 4;
    final classAnchor = (classNumber - 3) * 3;
    final tierAnchor = (difficulty - 1) * 2;
    final promptAnchor = classAnchor + tierAnchor + cycle;
    final random = _StableRandom(_mixSeed(classNumber, difficulty, seed, 11));
    // The first generated bank intentionally rotates operations by seed rather
    // than relying on random collision luck. Each operation receives a
    // monotonically changing anchor operand, which guarantees distinct visible
    // prompts for the first 12 exact-tier variants while retaining deterministic
    // randomisation for the companion operand and distractors.
    final operation = variant % 4;
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
        final addendA = 10 + (promptAnchor % (additionCeiling - 9));
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
        final lowRange = (subtractionCeiling ~/ 2) - 9;
        final low = 10 + (promptAnchor % lowRange);
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
        final factorA = 2 + (promptAnchor % (maxFactor - 1));
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
        final divisor = 2 + (promptAnchor % (maxDivisor - 1));
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
    // Denominator banks mirror denominators already authored for each
    // class/tier. Keeping the banks tier-distinct prevents Practice, Challenge
    // and Mastery from collapsing to the same visible construction for the
    // same generated seed while staying inside the existing curriculum data.
    final denominators = switch ((classNumber, difficulty)) {
      (3, 1) => const <int>[2, 4],
      (3, 2) => const <int>[3],
      (3, 3) => const <int>[5],
      (4, 1) => const <int>[3, 4],
      (4, 2) => const <int>[5],
      (4, 3) => const <int>[6, 10],
      (5, 1) => const <int>[6, 8],
      (5, 2) => const <int>[9, 10],
      (5, 3) => const <int>[5, 12],
      _ => const <int>[],
    };
    // Keep the release-audited first 12 variants exactly within the original
    // bounded whole-size range. Endless Practice may use larger seeds; those
    // expand only to visually manageable pizzas (at most 24 slices).
    final releaseMaxMultiplier =
        classNumber == 3 && difficulty == 2 ? 6 : difficulty + 2;
    final variants = <({int denominator, int numerator, int multiplier})>[];
    for (final denominator in denominators) {
      final localMax = seed.abs() < 12
          ? releaseMaxMultiplier
          : (24 ~/ denominator).clamp(1, 12).toInt();
      for (var numerator = 1; numerator < denominator; numerator += 1) {
        for (var multiplier = 1; multiplier <= localMax; multiplier += 1) {
          variants.add((
            denominator: denominator,
            numerator: numerator,
            multiplier: multiplier,
          ));
        }
      }
    }
    final offset = _mixSeed(classNumber, difficulty, 0, 23) % variants.length;
    final variant = variants[(seed.abs() + offset) % variants.length];
    final denominator = variant.denominator;
    final numerator = variant.numerator;
    final multiplier = variant.multiplier;
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
    final variant = seed.abs();
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
    final nounIndex = variant % nouns.length;
    final adjectiveIndex =
        (nounIndex + classNumber + difficulty + (variant ~/ nouns.length)) %
            adjectives.length;
    final noun = nouns[nounIndex];
    final verb = verbs[nounIndex];
    final adjective = adjectives[adjectiveIndex];
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
    final rawVariant = seed.abs();
    final variant = rawVariant % 12;
    final cycle = rawVariant ~/ 12;
    const directions = <String>['North', 'East', 'South', 'West'];
    // Four facings × three relative directions gives exactly twelve distinct
    // prompts before any combination repeats.
    final facingIndex =
        (variant + classNumber + difficulty) % directions.length;
    final relation =
        ((variant ~/ directions.length) + classNumber + difficulty) % 3;
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
    const places = <String>[
      'school gate',
      'library entrance',
      'playground',
      'bus stop',
      'park fountain',
      'museum door',
      'market square',
      'sports field',
      'community hall',
      'garden path',
      'science room',
      'station entrance',
    ];
    final promptLead =
        cycle == 0 ? 'If' : 'At the ${places[(cycle - 1) % places.length]}, if';
    return MapQuestion(
      'gen_map_c${classNumber}_d${difficulty}_s$seed',
      '$promptLead you face $facing, which direction is $relationText?',
      answer,
      List<String>.from(directions),
      'Picture a compass with North at the top, then turn mentally from $facing.',
      topicId: 'directions',
      difficulty: difficulty,
    );
  }

  /// Builds a deterministic ordered-word mission using the Story Builder
  /// schema already used by the authored class packs. The sentence patterns
  /// are class- and tier-specific so higher classes are not simple copies of
  /// the Class 3 bank.
  StoryMission story({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final rawVariant = seed.abs();
    final variant = rawVariant % 12;
    final cycle = rawVariant ~/ 12;
    final name = const <String>[
      'Aarav',
      'Mira',
      'Kabir',
      'Riya',
      'Ishaan',
      'Tara',
    ][variant % 6];
    final place = const <String>[
      'garden',
      'library',
      'playground',
      'classroom',
    ][variant % 4];
    final detail = const <String>[
      'carefully',
      'quietly',
      'cheerfully',
      'patiently',
    ][variant % 4];

    late String sentence;
    late String topicId;
    switch (classNumber) {
      case 3:
        if (difficulty == 1) {
          const objects = <String>['kite', 'book', 'seed', 'ball'];
          const adjectives = <String>['bright', 'small', 'green', 'blue'];
          final object = objects[variant % objects.length];
          final adjective = adjectives[(variant ~/ 3) % adjectives.length];
          sentence = '$name carried the $adjective $object to the $place';
          topicId = 'sentence_building';
        } else if (difficulty == 2) {
          const actions = <String>['packed', 'watered', 'opened', 'shared'];
          const objects = <String>[
            'school bag',
            'young plant',
            'story book',
            'fruit basket'
          ];
          sentence =
              'After lunch $name $detail ${actions[variant % 4]} the ${objects[(variant ~/ 3) % 4]}';
          topicId = variant.isEven ? 'story_sequence' : 'descriptive_language';
        } else {
          const endings = <String>[
            'returned home before sunset',
            'finished the task before dinner',
            'helped the team reach the gate',
            'placed every tool back safely',
          ];
          sentence = 'Before evening $name $detail ${endings[variant % 4]}';
          topicId = variant.isEven ? 'story_sequence' : 'descriptive_language';
        }
        break;
      case 4:
        if (difficulty == 1) {
          const objects = <String>[
            'old map',
            'silver key',
            'field journal',
            'clay model'
          ];
          const actions = <String>[
            'examined',
            'carried',
            'sketched',
            'labelled'
          ];
          sentence =
              '$name ${actions[variant % 4]} the ${objects[(variant ~/ 3) % 4]} inside the $place';
          topicId = 'sentence_building';
        } else if (difficulty == 2) {
          const causes = <String>[
            'the rain stopped',
            'the bell rang',
            'the path cleared',
            'the lights returned',
          ];
          const actions = <String>[
            'continued the garden survey',
            'organised the reading cards',
            'guided the group forward',
            'completed the science notes',
          ];
          sentence =
              'After ${causes[variant % 4]} $name $detail ${actions[(variant ~/ 3) % 4]}';
          topicId = variant.isEven ? 'story_sequence' : 'descriptive_language';
        } else {
          const causes = <String>[
            'the bridge was slippery',
            'the weather changed',
            'the first plan failed',
            'the supplies were limited',
          ];
          const results = <String>[
            'the team chose a safer route',
            'the group moved the activity indoors',
            'the friends tested another idea',
            'everyone shared the materials fairly',
          ];
          sentence =
              'Because ${causes[variant % 4]} ${results[(variant ~/ 3) % 4]}';
          topicId = variant.isEven ? 'cause_and_effect' : 'story_sequence';
        }
        break;
      default:
        if (difficulty == 1) {
          const settings = <String>[
            'busy community garden',
            'quiet museum gallery',
            'crowded book fair',
            'sunlit science room',
          ];
          const actions = <String>[
            'recorded three useful observations',
            'described the display in detail',
            'compared two interesting stories',
            'explained the model to the group',
          ];
          sentence =
              'In the ${settings[variant % 4]} $name $detail ${actions[(variant ~/ 3) % 4]}';
          topicId = variant.isEven ? 'descriptive_language' : 'story_sequence';
        } else if (difficulty == 2) {
          const firstClauses = <String>[
            'the first route was blocked',
            'the evidence was incomplete',
            'the group had little time',
            'the instructions seemed unclear',
          ];
          const secondClauses = <String>[
            'the team designed another plan',
            'the students checked another source',
            'everyone divided the work carefully',
            'the group reread each step together',
          ];
          sentence =
              'Although ${firstClauses[variant % 4]} ${secondClauses[(variant ~/ 3) % 4]}';
          topicId = variant.isEven ? 'cause_and_effect' : 'complex_sentences';
        } else {
          const observations = <String>[
            'dark clouds gathered above the field',
            'the final clue appeared beside the gate',
            'the model produced an unexpected result',
            'the audience asked a difficult question',
          ];
          const responses = <String>[
            'the team calmly revised its plan',
            'the explorers compared every earlier clue',
            'the students carefully checked their method',
            'the speaker supported the answer with evidence',
          ];
          sentence =
              'When ${observations[variant % 4]} ${responses[(variant ~/ 3) % 4]}';
          topicId =
              variant.isEven ? 'cause_and_effect' : 'descriptive_language';
        }
        break;
    }

    if (cycle > 0) {
      const settings = <String>[
        'during morning practice',
        'during club time',
        'during a class project',
        'during a weekend activity',
        'during team practice',
        'during a quiet study hour',
        'during a school event',
        'during an outdoor activity',
      ];
      sentence = '$sentence ${settings[(cycle - 1) % settings.length]}';
    }
    final words = sentence.split(' ');
    return StoryMission(
      id: 'gen_story_c${classNumber}_d${difficulty}_s$seed',
      prompt: sentence,
      words: List<String>.unmodifiable(words),
      topicId: topicId,
      difficulty: difficulty,
    );
  }

  /// Builds deterministic science choice missions from bounded class/tier
  /// concept banks. Context wording rotates across three scenarios, while the
  /// underlying fact and answer stay stable and explicit.
  ScienceQuizQuestion scienceQuiz({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final rawVariant = seed.abs();
    final variant = rawVariant % 12;
    final cycle = rawVariant ~/ 12;
    final fact = _scienceFact(classNumber, difficulty, variant % 4);
    const contexts = <String>[
      'During a classroom investigation',
      'While recording an observation',
      'In a science notebook challenge',
      'During a lab-table discussion',
      'While comparing two observations',
      'During a science-club activity',
      'While checking a prediction',
      'During a hands-on demonstration',
      'While explaining evidence to a partner',
      'During a revision challenge',
      'While sorting science evidence',
      'During a quick concept check',
    ];
    final contextIndex = cycle == 0
        ? (variant ~/ 4) % 3
        : (3 + ((cycle - 1) * 3 + (variant ~/ 4))) % contexts.length;
    final context = contexts[contextIndex];
    final prompt = '$context, ${fact.question}';
    return ScienceQuizQuestion(
      prompt,
      fact.answer,
      List<String>.unmodifiable(fact.choices),
      fact.explanation,
      id: 'gen_science_c${classNumber}_d${difficulty}_s$seed',
      topicId: fact.topicId,
      difficulty: difficulty,
    );
  }

  /// Creates a deterministic, always-reachable Coding Maze mission. The grid
  /// and target are class-specific; higher tiers tighten the command budget so
  /// the same renderer progresses from sequencing to route planning and then
  /// efficient/debugging-style missions without changing correctness rules.
  CodingMission codingRoute({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final rawVariant = seed.abs();
    final variant = rawVariant % 12;
    final cycle = rawVariant ~/ 12;
    final baseWidth = classNumber + 1 + (difficulty == 3 ? 1 : 0);
    final baseHeight = classNumber + (difficulty >= 2 ? 1 : 0);
    final width = baseWidth + (cycle == 0 ? 0 : cycle % 2);
    final height = baseHeight + (cycle == 0 ? 0 : (cycle ~/ 2) % 2);
    // The first twelve seeds use twelve distinct start cells. That gives the
    // child twelve genuinely different boards before anti-repeat history even
    // needs to recycle a generated route.
    final startX = variant % width;
    final startY = (variant ~/ width) % height;
    var goalX = (startX + 1 + difficulty + (variant ~/ 4)) % width;
    var goalY = (startY + 1 + (variant % 2)) % height;
    if (goalX == startX && goalY == startY) {
      goalX = (goalX + 1) % width;
    }
    final direction =
        FacingDirection.values[(variant + classNumber + difficulty) % 4];
    final distance = (goalX - startX).abs() + (goalY - startY).abs();
    // A Manhattan route can require up to two turns to face the first
    // axis plus one more turn for the second axis. Lower tiers receive a small
    // planning cushion; Mastery keeps the budget close to an efficient route.
    final maxCommands = distance +
        3 +
        (difficulty == 1
            ? 2
            : difficulty == 2
                ? 1
                : 0);

    final obstacles = <String>{};
    if (difficulty >= 2 && width * height > 8) {
      final obstacleX = (startX + 2 + seed.abs()) % width;
      final obstacleY = (startY + 2 + seed.abs() ~/ 2) % height;
      final key = '$obstacleX,$obstacleY';
      if (key != '$startX,$startY' && key != '$goalX,$goalY') {
        // Keep generated obstacles decorative rather than risking an
        // unsatisfiable mission. Exact goal reachability stays guaranteed by
        // leaving at least one open Manhattan corridor around the obstacle.
        final outsideGuaranteedCorridors = obstacleX != startX &&
            obstacleY != startY &&
            obstacleX != goalX &&
            obstacleY != goalY;
        if (outsideGuaranteedCorridors) obstacles.add(key);
      }
    }

    final topicId = switch ((classNumber, difficulty)) {
      (3, 1) => seed.isEven ? 'sequences' : 'turns',
      (3, 2) => 'route_planning',
      (3, 3) => 'repeat_patterns',
      (4, 1) => seed.isEven ? 'sequences' : 'turns',
      (4, 2) => 'route_planning',
      (4, 3) => 'efficient_algorithms',
      (5, 1) => 'algorithm_planning',
      (5, 2) => 'repeat_and_route',
      (5, 3) => seed.isEven ? 'debugging_routes' : 'efficient_algorithms',
      _ => 'sequences',
    };

    return CodingMission(
      id: 'gen_coding_c${classNumber}_d${difficulty}_s$seed',
      width: width,
      height: height,
      startX: startX,
      startY: startY,
      goalX: goalX,
      goalY: goalY,
      startDirection: direction,
      obstacles: Set<String>.unmodifiable(obstacles),
      maxCommands: maxCommands.clamp(2, 20).toInt(),
      topicId: topicId,
      difficulty: difficulty,
    );
  }

  /// Deterministic material-sorting missions using only the three bins already
  /// rendered by Recycling Challenge. Items are class/tier specific so Class 5
  /// sustainability practice is not a renamed copy of the Class 3 bank.
  RecyclingItem recycling({
    required int classNumber,
    required int difficulty,
    required int seed,
  }) {
    _validateClassAndDifficulty(classNumber, difficulty);
    final bank = _recyclingBank(classNumber, difficulty);
    final rawVariant = seed.abs();
    final item = bank[rawVariant % bank.length];
    final cycle = rawVariant ~/ bank.length;
    const contexts = <String>[
      'a home clean-up',
      'a school clean-up',
      'a picnic clean-up',
      'a park clean-up',
      'a class activity',
      'a community clean-up',
    ];
    final displayName = cycle == 0
        ? item.name
        : '${item.name} found during ${contexts[(cycle - 1) % contexts.length]}';
    return RecyclingItem(
      'gen_recycling_c${classNumber}_d${difficulty}_s$seed',
      displayName,
      item.emoji,
      item.bin,
      topicId: item.topicId,
      difficulty: difficulty,
    );
  }

  static _ScienceFact _scienceFact(
    int classNumber,
    int difficulty,
    int concept,
  ) {
    return switch ((classNumber, difficulty, concept)) {
      (3, 1, 0) => const _ScienceFact(
          topicId: 'plants',
          question: 'which plant part usually absorbs water from soil?',
          answer: 'Roots',
          choices: <String>['Roots', 'Flower', 'Fruit', 'Seed'],
          explanation: 'Roots take in water and minerals from the soil.',
        ),
      (3, 1, 1) => const _ScienceFact(
          topicId: 'matter',
          question: 'which state of matter keeps its own shape?',
          answer: 'Solid',
          choices: <String>['Solid', 'Liquid', 'Gas', 'Steam only'],
          explanation:
              'A solid keeps a definite shape unless a force changes it.',
        ),
      (3, 1, 2) => const _ScienceFact(
          topicId: 'materials',
          question: 'which material lets the most light pass through?',
          answer: 'Clear glass',
          choices: <String>['Clear glass', 'Cardboard', 'Wood', 'Stone'],
          explanation:
              'Clear glass is transparent, so light passes through it.',
        ),
      (3, 1, _) => const _ScienceFact(
          topicId: 'materials',
          question:
              'which object is most likely made from a flexible material?',
          answer: 'Rubber band',
          choices: <String>[
            'Rubber band',
            'Brick',
            'Glass marble',
            'Metal spoon'
          ],
          explanation:
              'Rubber can bend and stretch more easily than the other materials.',
        ),
      (3, 2, 0) => const _ScienceFact(
          topicId: 'plants',
          question: 'which flower part is involved in making seeds?',
          answer: 'Flower',
          choices: <String>['Flower', 'Root', 'Soil', 'Bark'],
          explanation: 'Flowers contain structures involved in seed formation.',
        ),
      (3, 2, 1) => const _ScienceFact(
          topicId: 'matter',
          question: 'what change happens when ice becomes liquid water?',
          answer: 'Melting',
          choices: <String>['Melting', 'Freezing', 'Condensing', 'Drying'],
          explanation: 'Melting changes a solid into a liquid.',
        ),
      (3, 2, 2) => const _ScienceFact(
          topicId: 'materials',
          question: 'which material is best described as waterproof?',
          answer: 'Plastic sheet',
          choices: <String>[
            'Plastic sheet',
            'Tissue paper',
            'Cotton wool',
            'Sponge'
          ],
          explanation:
              'A plastic sheet does not readily let water pass through it.',
        ),
      (3, 2, _) => const _ScienceFact(
          topicId: 'plants',
          question:
              'which plant part supports leaves and carries water upward?',
          answer: 'Stem',
          choices: <String>['Stem', 'Flower', 'Fruit', 'Seed'],
          explanation:
              'The stem supports the plant and carries water to leaves and other parts.',
        ),
      (3, 3, 0) => const _ScienceFact(
          topicId: 'plants',
          question: 'why do green plants need sunlight?',
          answer: 'To help make food',
          choices: <String>[
            'To help make food',
            'To make soil',
            'To stop using water',
            'To turn roots into flowers'
          ],
          explanation: 'Green plants use light energy to make food.',
        ),
      (3, 3, 1) => const _ScienceFact(
          topicId: 'matter',
          question:
              'what is the change from liquid water to water vapour called?',
          answer: 'Evaporation',
          choices: <String>[
            'Evaporation',
            'Freezing',
            'Melting',
            'Condensation'
          ],
          explanation: 'Evaporation changes liquid water into water vapour.',
        ),
      (3, 3, 2) => const _ScienceFact(
          topicId: 'materials',
          question: 'which property makes rubber useful for an elastic band?',
          answer: 'It can stretch',
          choices: <String>[
            'It can stretch',
            'It dissolves in water',
            'It is transparent',
            'It is brittle'
          ],
          explanation:
              'Elastic rubber can stretch and return toward its original shape.',
        ),
      (3, 3, _) => const _ScienceFact(
          topicId: 'matter',
          question: 'which change is caused by cooling liquid water enough?',
          answer: 'Freezing',
          choices: <String>['Freezing', 'Evaporation', 'Melting', 'Boiling'],
          explanation:
              'Cooling liquid water to its freezing point changes it into solid ice.',
        ),
      (4, 1, 0) => const _ScienceFact(
          topicId: 'materials',
          question: 'which object is most likely to float in water?',
          answer: 'Dry wood block',
          choices: <String>[
            'Dry wood block',
            'Steel ball',
            'Stone',
            'Iron nail'
          ],
          explanation:
              'A dry wood block is generally less dense than water and can float.',
        ),
      (4, 1, 1) => const _ScienceFact(
          topicId: 'matter',
          question: 'what process changes liquid water into water vapour?',
          answer: 'Evaporation',
          choices: <String>[
            'Evaporation',
            'Freezing',
            'Condensation',
            'Melting'
          ],
          explanation:
              'Evaporation is the change from liquid water to water vapour.',
        ),
      (4, 1, 2) => const _ScienceFact(
          topicId: 'plants',
          question: 'which part of a green plant captures most sunlight?',
          answer: 'Leaves',
          choices: <String>['Leaves', 'Roots', 'Seeds', 'Soil'],
          explanation:
              'Leaves contain chlorophyll and are the main light-capturing organs of most green plants.',
        ),
      (4, 1, _) => const _ScienceFact(
          topicId: 'materials',
          question: 'which material is strongly attracted by a magnet?',
          answer: 'Iron',
          choices: <String>['Iron', 'Wood', 'Glass', 'Rubber'],
          explanation:
              'Iron is a magnetic material and is strongly attracted by ordinary magnets.',
        ),
      (4, 2, 0) => const _ScienceFact(
          topicId: 'materials',
          question: 'which material would a magnet attract most strongly?',
          answer: 'Iron nail',
          choices: <String>[
            'Iron nail',
            'Plastic ruler',
            'Wooden stick',
            'Glass bead'
          ],
          explanation: 'The iron nail contains magnetic material.',
        ),
      (4, 2, 1) => const _ScienceFact(
          topicId: 'matter',
          question:
              'what forms when water vapour cools into tiny liquid drops?',
          answer: 'Condensation',
          choices: <String>[
            'Condensation',
            'Evaporation',
            'Melting',
            'Freezing'
          ],
          explanation:
              'Condensation changes water vapour into liquid water droplets.',
        ),
      (4, 2, 2) => const _ScienceFact(
          topicId: 'plants',
          question:
              'which plant structure carries water from roots toward leaves?',
          answer: 'Stem',
          choices: <String>['Stem', 'Flower', 'Fruit', 'Seed coat'],
          explanation:
              'Transport tissues in the stem carry water upward through the plant.',
        ),
      (4, 2, _) => const _ScienceFact(
          topicId: 'materials',
          question: 'which material is transparent rather than opaque?',
          answer: 'Clear glass',
          choices: <String>['Clear glass', 'Cardboard', 'Brick', 'Wood'],
          explanation:
              'Transparent clear glass allows light to pass through so objects can be seen through it.',
        ),
      (4, 3, 0) => const _ScienceFact(
          topicId: 'forces',
          question:
              'where is the magnetic pull of a bar magnet usually strongest?',
          answer: 'At its poles',
          choices: <String>[
            'At its poles',
            'Only at its centre',
            'At its label',
            'In its shadow'
          ],
          explanation:
              'A bar magnet has its strongest magnetic effect near its two poles.',
        ),
      (4, 3, 1) => const _ScienceFact(
          topicId: 'scientific_method',
          question: 'in a fair test what should you change on purpose?',
          answer: 'One factor',
          choices: <String>[
            'One factor',
            'Every factor',
            'The result after measuring',
            'Nothing at all'
          ],
          explanation:
              'A fair test changes one factor while keeping other important conditions controlled.',
        ),
      (4, 3, 2) => const _ScienceFact(
          topicId: 'matter',
          question:
              'which process moves water from a wet surface into the air as vapour?',
          answer: 'Evaporation',
          choices: <String>[
            'Evaporation',
            'Freezing',
            'Condensation',
            'Melting'
          ],
          explanation:
              'Evaporation transfers liquid water into the air as water vapour.',
        ),
      (4, 3, _) => const _ScienceFact(
          topicId: 'forces',
          question: 'what can a push or pull change about a moving object?',
          answer: 'Its speed or direction',
          choices: <String>[
            'Its speed or direction',
            'Its material',
            'Its colour only',
            'Its mass instantly'
          ],
          explanation:
              'Forces can change an object’s speed, direction, or both.',
        ),
      (5, 1, 0) => const _ScienceFact(
          topicId: 'human_body',
          question: 'which organs take oxygen from the air during breathing?',
          answer: 'Lungs',
          choices: <String>['Lungs', 'Kidneys', 'Bones', 'Skin only'],
          explanation:
              'The lungs exchange gases between inhaled air and the blood.',
        ),
      (5, 1, 1) => const _ScienceFact(
          topicId: 'materials',
          question: 'which material is attracted strongly by a magnet?',
          answer: 'Iron',
          choices: <String>['Iron', 'Plastic', 'Wood', 'Glass'],
          explanation: 'Iron is a magnetic material.',
        ),
      (5, 1, 2) => const _ScienceFact(
          topicId: 'matter',
          question: 'which change can usually be reversed by cooling?',
          answer: 'Melting ice',
          choices: <String>[
            'Melting ice',
            'Burning paper',
            'Rusting iron',
            'Cooking an egg'
          ],
          explanation:
              'Liquid water from melted ice can freeze back into solid ice.',
        ),
      (5, 1, _) => const _ScienceFact(
          topicId: 'human_body',
          question: 'which organ pumps blood around the body?',
          answer: 'Heart',
          choices: <String>['Heart', 'Lung', 'Stomach', 'Brain'],
          explanation:
              'The heart pumps blood through blood vessels around the body.',
        ),
      (5, 2, 0) => const _ScienceFact(
          topicId: 'plants',
          question:
              'which substance in green leaves helps capture light energy?',
          answer: 'Chlorophyll',
          choices: <String>['Chlorophyll', 'Salt', 'Sand', 'Starch only'],
          explanation:
              'Chlorophyll is the green pigment that absorbs light for photosynthesis.',
        ),
      (5, 2, 1) => const _ScienceFact(
          topicId: 'forces',
          question: 'which force usually slows a sliding book on a table?',
          answer: 'Friction',
          choices: <String>['Friction', 'Magnetism', 'Buoyancy', 'Light'],
          explanation:
              'Friction acts between surfaces and opposes sliding motion.',
        ),
      (5, 2, 2) => const _ScienceFact(
          topicId: 'changes',
          question: 'which condition usually makes water evaporate faster?',
          answer: 'Higher temperature',
          choices: <String>[
            'Higher temperature',
            'Lower temperature',
            'A sealed cold container',
            'Freezing'
          ],
          explanation:
              'Warmer water molecules have more energy, which generally increases evaporation.',
        ),
      (5, 2, _) => const _ScienceFact(
          topicId: 'forces',
          question:
              'what happens when balanced forces act on a resting object?',
          answer: 'It stays at rest',
          choices: <String>[
            'It stays at rest',
            'It must speed up',
            'It must turn',
            'Its mass doubles'
          ],
          explanation:
              'Balanced forces have zero net force, so a resting object remains at rest.',
        ),
      (5, 3, 0) => const _ScienceFact(
          topicId: 'light',
          question:
              'how does light usually travel through a uniform transparent material?',
          answer: 'In straight lines',
          choices: <String>[
            'In straight lines',
            'Only in circles',
            'Only downward',
            'Without direction'
          ],
          explanation:
              'In a uniform medium, light is modelled as travelling in straight lines.',
        ),
      (5, 3, 1) => const _ScienceFact(
          topicId: 'light',
          question: 'what causes a clear shadow to form?',
          answer: 'An opaque object blocks light',
          choices: <String>[
            'An opaque object blocks light',
            'A transparent object adds light',
            'Sound bends around an object',
            'Air becomes solid'
          ],
          explanation:
              'A shadow forms where an opaque object blocks light from reaching a surface.',
        ),
      (5, 3, 2) => const _ScienceFact(
          topicId: 'changes',
          question:
              'which change is difficult to reverse because a new substance forms?',
          answer: 'Rusting iron',
          choices: <String>[
            'Rusting iron',
            'Melting ice',
            'Freezing water',
            'Dissolving sugar in water'
          ],
          explanation:
              'Rusting is a chemical change that forms iron oxide, a new substance.',
        ),
      (5, 3, _) => const _ScienceFact(
          topicId: 'human_body',
          question:
              'which body system carries oxygen and nutrients around the body?',
          answer: 'Circulatory system',
          choices: <String>[
            'Circulatory system',
            'Skeletal system only',
            'Digestive tract only',
            'Skin'
          ],
          explanation:
              'The circulatory system moves blood carrying oxygen and nutrients around the body.',
        ),
      _ => throw StateError('Unsupported science generator combination.'),
    };
  }

  static List<_RecyclingTemplate> _recyclingBank(
    int classNumber,
    int difficulty,
  ) =>
      switch ((classNumber, difficulty)) {
        (3, 1) => const <_RecyclingTemplate>[
            _RecyclingTemplate(
                'Newspaper sheet', '📰', 'Paper', 'sorting_basics'),
            _RecyclingTemplate(
                'Notebook page', '📄', 'Paper', 'sorting_basics'),
            _RecyclingTemplate(
                'Cardboard tube', '🧻', 'Paper', 'sorting_basics'),
            _RecyclingTemplate(
                'Paper envelope', '✉️', 'Paper', 'sorting_basics'),
            _RecyclingTemplate(
                'Clean water bottle', '🧴', 'Plastic', 'sorting_basics'),
            _RecyclingTemplate(
                'Plastic bottle cap', '🔘', 'Plastic', 'sorting_basics'),
            _RecyclingTemplate(
                'Clean yoghurt cup', '🥣', 'Plastic', 'sorting_basics'),
            _RecyclingTemplate(
                'Plastic food box', '📦', 'Plastic', 'sorting_basics'),
            _RecyclingTemplate(
                'Banana peel', '🍌', 'Organic', 'sorting_basics'),
            _RecyclingTemplate('Apple core', '🍎', 'Organic', 'sorting_basics'),
            _RecyclingTemplate('Dry leaves', '🍂', 'Organic', 'sorting_basics'),
            _RecyclingTemplate(
                'Vegetable peelings', '🥕', 'Organic', 'sorting_basics'),
          ],
        (3, 2) => const <_RecyclingTemplate>[
            _RecyclingTemplate(
                'Cereal carton', '📦', 'Paper', 'clean_surroundings'),
            _RecyclingTemplate(
                'Old magazine', '📚', 'Paper', 'clean_surroundings'),
            _RecyclingTemplate(
                'Paper craft scraps', '✂️', 'Paper', 'clean_surroundings'),
            _RecyclingTemplate(
                'Flattened paper bag', '🛍️', 'Paper', 'clean_surroundings'),
            _RecyclingTemplate(
                'Rinsed shampoo bottle', '🧴', 'Plastic', 'clean_surroundings'),
            _RecyclingTemplate(
                'Clean plastic tray', '🍱', 'Plastic', 'clean_surroundings'),
            _RecyclingTemplate('Plastic stationery box', '🗃️', 'Plastic',
                'clean_surroundings'),
            _RecyclingTemplate(
                'Empty plastic jar', '🫙', 'Plastic', 'clean_surroundings'),
            _RecyclingTemplate(
                'Orange peel', '🍊', 'Organic', 'clean_surroundings'),
            _RecyclingTemplate(
                'Flower trimmings', '🌼', 'Organic', 'clean_surroundings'),
            _RecyclingTemplate(
                'Tea leaves', '🍵', 'Organic', 'clean_surroundings'),
            _RecyclingTemplate(
                'Pea pods', '🫛', 'Organic', 'clean_surroundings'),
          ],
        (3, 3) => const <_RecyclingTemplate>[
            _RecyclingTemplate(
                'Old worksheet', '📄', 'Paper', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Used gift box', '🎁', 'Paper', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Paper calendar page', '📅', 'Paper', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Cardboard model piece', '📦', 'Paper', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Clean refill bottle', '🧴', 'Plastic', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Reusable plastic tub', '🥡', 'Plastic', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Plastic plant pot', '🪴', 'Plastic', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Clean plastic lid', '🔵', 'Plastic', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Fruit peel mix', '🍎', 'Organic', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Garden leaves', '🍃', 'Organic', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Vegetable stalks', '🥬', 'Organic', 'reuse_and_recycle'),
            _RecyclingTemplate(
                'Wilted flower petals', '🌸', 'Organic', 'reuse_and_recycle'),
          ],
        (4, 1) => const <_RecyclingTemplate>[
            _RecyclingTemplate('Clean office paper', '📄', 'Paper', 'sorting'),
            _RecyclingTemplate('Shipping carton', '📦', 'Paper', 'sorting'),
            _RecyclingTemplate('Paper poster', '📰', 'Paper', 'sorting'),
            _RecyclingTemplate('Paper egg carton', '🥚', 'Paper', 'sorting'),
            _RecyclingTemplate(
                'Rinsed drink bottle', '🧴', 'Plastic', 'sorting'),
            _RecyclingTemplate(
                'Clean plastic container', '🥡', 'Plastic', 'sorting'),
            _RecyclingTemplate(
                'Plastic measuring cup', '🥤', 'Plastic', 'sorting'),
            _RecyclingTemplate('Empty plastic tub', '🪣', 'Plastic', 'sorting'),
            _RecyclingTemplate('Mango peel', '🥭', 'Organic', 'sorting'),
            _RecyclingTemplate('Grass clippings', '🌱', 'Organic', 'sorting'),
            _RecyclingTemplate('Vegetable scraps', '🥦', 'Organic', 'sorting'),
            _RecyclingTemplate('Used tea leaves', '🍵', 'Organic', 'sorting'),
          ],
        (4, 2) => const <_RecyclingTemplate>[
            _RecyclingTemplate(
                'Flattened delivery box', '📦', 'Paper', 'resources'),
            _RecyclingTemplate(
                'Old exercise booklet', '📒', 'Paper', 'resources'),
            _RecyclingTemplate(
                'Paper packaging sleeve', '📜', 'Paper', 'resources'),
            _RecyclingTemplate('Used paper folder', '📁', 'Paper', 'resources'),
            _RecyclingTemplate(
                'Clean detergent bottle', '🧴', 'Plastic', 'resources'),
            _RecyclingTemplate(
                'Plastic storage lid', '🔵', 'Plastic', 'resources'),
            _RecyclingTemplate(
                'Rinsed plastic jar', '🫙', 'Plastic', 'resources'),
            _RecyclingTemplate(
                'Plastic lunch container', '🍱', 'Plastic', 'resources'),
            _RecyclingTemplate('Corn husk', '🌽', 'Organic', 'resources'),
            _RecyclingTemplate('Fruit skins', '🍐', 'Organic', 'resources'),
            _RecyclingTemplate(
                'Small garden weeds', '🌿', 'Organic', 'resources'),
            _RecyclingTemplate('Vegetable ends', '🥕', 'Organic', 'resources'),
          ],
        (4, 3) => const <_RecyclingTemplate>[
            _RecyclingTemplate(
                'Draft printout', '📄', 'Paper', 'environmental_impact'),
            _RecyclingTemplate(
                'Cardboard refill box', '📦', 'Paper', 'environmental_impact'),
            _RecyclingTemplate(
                'Old paper timetable', '🗓️', 'Paper', 'environmental_impact'),
            _RecyclingTemplate('Paper instruction sheet', '📃', 'Paper',
                'environmental_impact'),
            _RecyclingTemplate('Empty cleaning bottle', '🧴', 'Plastic',
                'environmental_impact'),
            _RecyclingTemplate('Clean plastic refill pouch', '🧃', 'Plastic',
                'environmental_impact'),
            _RecyclingTemplate('Plastic seedling pot', '🪴', 'Plastic',
                'environmental_impact'),
            _RecyclingTemplate('Plastic storage box', '🗃️', 'Plastic',
                'environmental_impact'),
            _RecyclingTemplate('Kitchen vegetable peels', '🥬', 'Organic',
                'environmental_impact'),
            _RecyclingTemplate('Garden pruning leaves', '🍃', 'Organic',
                'environmental_impact'),
            _RecyclingTemplate(
                'Fruit cores', '🍏', 'Organic', 'environmental_impact'),
            _RecyclingTemplate(
                'Coffee grounds', '☕', 'Organic', 'environmental_impact'),
          ],
        (5, 1) => const <_RecyclingTemplate>[
            _RecyclingTemplate(
                'Newspaper bundle', '📰', 'Paper', 'resource_sorting'),
            _RecyclingTemplate(
                'Corrugated carton', '📦', 'Paper', 'resource_sorting'),
            _RecyclingTemplate(
                'Paper report pages', '📑', 'Paper', 'resource_sorting'),
            _RecyclingTemplate(
                'Paper packaging insert', '📃', 'Paper', 'resource_sorting'),
            _RecyclingTemplate(
                'Rinsed plastic bottle', '🧴', 'Plastic', 'resource_sorting'),
            _RecyclingTemplate(
                'Plastic food tub', '🥡', 'Plastic', 'resource_sorting'),
            _RecyclingTemplate(
                'Clean plastic cap set', '🔘', 'Plastic', 'resource_sorting'),
            _RecyclingTemplate('Plastic stationery tray', '🗂️', 'Plastic',
                'resource_sorting'),
            _RecyclingTemplate(
                'Banana skins', '🍌', 'Organic', 'resource_sorting'),
            _RecyclingTemplate(
                'Vegetable trimmings', '🥦', 'Organic', 'resource_sorting'),
            _RecyclingTemplate(
                'Dry garden leaves', '🍂', 'Organic', 'resource_sorting'),
            _RecyclingTemplate(
                'Fruit cores', '🍎', 'Organic', 'resource_sorting'),
          ],
        (5, 2) => const <_RecyclingTemplate>[
            _RecyclingTemplate('Double-sided draft paper', '📄', 'Paper',
                'resource_conservation'),
            _RecyclingTemplate('Flattened product carton', '📦', 'Paper',
                'resource_conservation'),
            _RecyclingTemplate('Old paper project board', '🗒️', 'Paper',
                'resource_conservation'),
            _RecyclingTemplate(
                'Paper mailer sleeve', '✉️', 'Paper', 'resource_conservation'),
            _RecyclingTemplate('Empty refill bottle', '🧴', 'Plastic',
                'resource_conservation'),
            _RecyclingTemplate(
                'Rinsed plastic tub', '🥡', 'Plastic', 'resource_conservation'),
            _RecyclingTemplate('Plastic organiser box', '🗃️', 'Plastic',
                'resource_conservation'),
            _RecyclingTemplate('Clean plastic plant pot', '🪴', 'Plastic',
                'resource_conservation'),
            _RecyclingTemplate('Compostable fruit peels', '🍊', 'Organic',
                'resource_conservation'),
            _RecyclingTemplate('Compostable leaf litter', '🍃', 'Organic',
                'resource_conservation'),
            _RecyclingTemplate(
                'Vegetable peel mix', '🥕', 'Organic', 'resource_conservation'),
            _RecyclingTemplate(
                'Used tea leaves', '🍵', 'Organic', 'resource_conservation'),
          ],
        (5, 3) => const <_RecyclingTemplate>[
            _RecyclingTemplate(
                'Discarded paper prototype', '📄', 'Paper', 'sustainability'),
            _RecyclingTemplate(
                'Flattened shipping carton', '📦', 'Paper', 'sustainability'),
            _RecyclingTemplate(
                'Archived paper notes', '📚', 'Paper', 'sustainability'),
            _RecyclingTemplate(
                'Paper packaging board', '📋', 'Paper', 'sustainability'),
            _RecyclingTemplate('Rinsed household plastic bottle', '🧴',
                'Plastic', 'sustainability'),
            _RecyclingTemplate(
                'Clean durable plastic tub', '🥡', 'Plastic', 'sustainability'),
            _RecyclingTemplate('Plastic storage crate piece', '🗃️', 'Plastic',
                'sustainability'),
            _RecyclingTemplate('Clean plastic container lid', '🔵', 'Plastic',
                'sustainability'),
            _RecyclingTemplate(
                'Kitchen fruit scraps', '🍎', 'Organic', 'sustainability'),
            _RecyclingTemplate(
                'Garden plant trimmings', '🌿', 'Organic', 'sustainability'),
            _RecyclingTemplate('Vegetable preparation scraps', '🥬', 'Organic',
                'sustainability'),
            _RecyclingTemplate(
                'Compostable coffee grounds', '☕', 'Organic', 'sustainability'),
          ],
        _ => throw StateError('Unsupported recycling generator combination.'),
      };

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

class _ScienceFact {
  const _ScienceFact({
    required this.topicId,
    required this.question,
    required this.answer,
    required this.choices,
    required this.explanation,
  });

  final String topicId;
  final String question;
  final String answer;
  final List<String> choices;
  final String explanation;
}

class _RecyclingTemplate {
  const _RecyclingTemplate(this.name, this.emoji, this.bin, this.topicId);

  final String name;
  final String emoji;
  final String bin;
  final String topicId;
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
