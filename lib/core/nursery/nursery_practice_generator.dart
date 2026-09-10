import 'nursery_content.dart';

class NurseryGeneratedPractice {
  const NurseryGeneratedPractice({
    required this.id,
    required this.skillId,
    required this.seed,
    required this.prompt,
    required this.narration,
    required this.options,
    required this.correctResponseRule,
    required this.explanation,
    this.visualTokens = const <String>[],
  });

  final String id;
  final String skillId;
  final int seed;
  final String prompt;
  final String narration;
  final List<NurseryOption> options;
  final Map<String, dynamic> correctResponseRule;
  final String explanation;
  final List<String> visualTokens;
}

class NurseryPracticeGenerator {
  const NurseryPracticeGenerator();

  NurseryGeneratedPractice generate({
    required NurseryContentPack pack,
    required NurserySkill skill,
    required int seed,
  }) {
    final family = skill.generatorFamily;
    if (family == null) {
      throw ArgumentError.value(
        skill.id,
        'skill',
        'Skill has no generator family.',
      );
    }
    final random = _NurseryStableRandom(seed ^ _stableHash(skill.id));
    return switch (family) {
      'letterChoice' => _letterChoice(pack, skill, seed, random),
      'caseMatch' => _caseMatch(pack, skill, seed, random),
      'wordPicture' => _wordPicture(pack, skill, seed, random),
      'letterSound' => _letterSound(pack, skill, seed, random),
      'listenLetter' => _listenLetter(pack, skill, seed, random),
      'beginningSound' => _beginningSound(pack, skill, seed, random),
      'numberRecognition' => _numberRecognition(skill, seed, random),
      'counting' => _counting(skill, seed, random),
      'numberQuantity' => _numberQuantity(skill, seed, random),
      'missingNumber' => _missingNumber(skill, seed, random),
      'comparison' => _comparison(skill, seed, random),
      'addition' => _addition(skill, seed, random),
      'colourChoice' => _colourChoice(skill, seed, random),
      'shapeChoice' => _shapeChoice(skill, seed, random),
      'knowledgeChoice' => _knowledgeChoice(skill, seed, random),
      'routineChoice' => _routineChoice(skill, seed, random),
      'pattern' => _pattern(skill, seed, random),
      'matching' => _matching(skill, seed, random),
      'sorting' => _sorting(skill, seed, random),
      'observation' => _observation(skill, seed, random),
      _ => throw ArgumentError.value(
          family,
          'family',
          'Unknown Nursery generator family.',
        ),
    };
  }

  NurseryGeneratedPractice _letterChoice(
    NurseryContentPack pack,
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final answerIndex = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:letter',
      length: pack.letterAssociations.length,
    );
    final answer = pack.letterAssociations[answerIndex];
    final lowercase =
        skill.id == 'alpha_lowercase' || skill.id == 'alpha_trace_lower';
    final target = lowercase ? answer.lowercase : answer.uppercase;
    final distractor1 = pack.letterAssociations[
        (answerIndex + 5 + random.nextInt(7)) % pack.letterAssociations.length];
    final distractor2 = pack.letterAssociations[
        (answerIndex + 13 + random.nextInt(5)) % pack.letterAssociations.length];
    final choices = <String>{
      target,
      lowercase ? distractor1.lowercase : distractor1.uppercase,
      lowercase ? distractor2.lowercase : distractor2.uppercase,
    }.toList();
    final example = answer.examples[_cycleIndex(
      seed: seed,
      salt: '${skill.id}:${answer.uppercase}:example',
      length: answer.examples.length,
    )];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Find ${lowercase ? 'lowercase' : 'uppercase'} $target.',
      answer: target,
      choices: choices,
      explanation: '$target is the letter we were looking for.',
      visualTokens: <String>[target, example.word],
    );
  }

  NurseryGeneratedPractice _caseMatch(
    NurseryContentPack pack,
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final index = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:case',
      length: pack.letterAssociations.length,
    );
    final answer = pack.letterAssociations[index];
    final d1 = pack.letterAssociations[(index + 8) % pack.letterAssociations.length];
    final d2 = pack.letterAssociations[(index + 17) % pack.letterAssociations.length];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which small letter matches big ${answer.uppercase}?',
      answer: answer.lowercase,
      choices: <String>[answer.lowercase, d1.lowercase, d2.lowercase],
      explanation:
          '${answer.uppercase} and ${answer.lowercase} are the same letter in uppercase and lowercase.',
      visualTokens: <String>[answer.uppercase, 'matches', answer.lowercase],
    );
  }

  NurseryGeneratedPractice _wordPicture(
    NurseryContentPack pack,
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final pool = <(NurseryLetterAssociation, NurseryLetterExample)>[
      for (final letter in pack.letterAssociations)
        for (final example in letter.examples)
          if (example.word.toUpperCase().startsWith(letter.uppercase))
            (letter, example),
    ];
    final selected = pool[
      _cycleIndex(seed: seed, salt: skill.id, length: pool.length)
    ];
    final answer = selected.$1;
    final example = selected.$2;
    final index = pack.letterAssociations.indexOf(answer);
    final d1 = pack.letterAssociations[
        (index + 6) % pack.letterAssociations.length];
    final d2 = pack.letterAssociations[
        (index + 14) % pack.letterAssociations.length];
    final d1Example = d1.examples[random.nextInt(d1.examples.length)];
    final d2Example = d2.examples[random.nextInt(d2.examples.length)];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt:
          'Look at the picture. Which word belongs with ${answer.uppercase}?',
      answer: example.word,
      choices: <String>[example.word, d1Example.word, d2Example.word],
      explanation:
          '${answer.uppercase} is for ${example.word}.',
      visualTokens: <String>[answer.uppercase, example.word],
    );
  }

  NurseryGeneratedPractice _letterSound(
    NurseryContentPack pack,
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final eligible = <(NurseryLetterAssociation, NurseryLetterExample)>[
      for (final letter in pack.letterAssociations)
        for (final example in letter.soundPracticeExamples) (letter, example),
    ];
    final selected = eligible[
      _cycleIndex(seed: seed, salt: skill.id, length: eligible.length)
    ];
    final answer = selected.$1;
    final example = selected.$2;
    final index = pack.letterAssociations.indexOf(answer);
    final d1 = pack.letterAssociations[
        (index + 9) % pack.letterAssociations.length];
    final d2 = pack.letterAssociations[
        (index + 18) % pack.letterAssociations.length];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Listen to ${example.word}. Which letter starts this word?',
      narration:
          'Listen to ${example.word}. ${example.soundCue} Which letter starts ${example.word}?',
      answer: answer.uppercase,
      choices: <String>[answer.uppercase, d1.uppercase, d2.uppercase],
      explanation:
          '${example.word} starts with ${answer.uppercase}. ${example.soundCue}',
      visualTokens: <String>[example.word, answer.uppercase],
    );
  }

  NurseryGeneratedPractice _listenLetter(
    NurseryContentPack pack,
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final index = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:listen',
      length: pack.letterAssociations.length,
    );
    final answer = pack.letterAssociations[index];
    final d1 = pack.letterAssociations[(index + 4) % pack.letterAssociations.length];
    final d2 = pack.letterAssociations[(index + 11) % pack.letterAssociations.length];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Listen or read: find letter ${answer.uppercase}.',
      narration: 'Listen carefully. Find letter ${answer.uppercase}.',
      answer: answer.uppercase,
      choices: <String>[answer.uppercase, d1.uppercase, d2.uppercase],
      explanation: 'You selected ${answer.uppercase}.',
    );
  }

  NurseryGeneratedPractice _beginningSound(
    NurseryContentPack pack,
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final eligible = <(NurseryLetterAssociation, NurseryLetterExample)>[
      for (final letter in pack.letterAssociations)
        for (final example in letter.beginningSoundExamples) (letter, example),
    ];
    final selected = eligible[
      _cycleIndex(seed: seed, salt: skill.id, length: eligible.length)
    ];
    final answer = selected.$1;
    final example = selected.$2;
    final index = pack.letterAssociations.indexOf(answer);
    final d1 = pack.letterAssociations[
        (index + 7) % pack.letterAssociations.length];
    final d2 = pack.letterAssociations[
        (index + 15) % pack.letterAssociations.length];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which letter begins ${example.word}?',
      narration:
          '${example.word}. ${example.soundCue} Which letter begins ${example.word}?',
      answer: answer.uppercase,
      choices: <String>[answer.uppercase, d1.uppercase, d2.uppercase],
      explanation:
          '${example.word} begins with ${answer.uppercase}. ${example.soundCue}',
      visualTokens: <String>[example.word],
    );
  }

  NurseryGeneratedPractice _numberRecognition(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final bounds = switch (skill.id) {
      'math_numbers_0_5' => (0, 5),
      'math_numbers_6_10' => (6, 10),
      _ => (11, 20),
    };
    final min = bounds.$1;
    final max = bounds.$2;
    final answer = min + _cycleIndex(
      seed: seed,
      salt: '${skill.id}:number',
      length: max - min + 1,
    );
    final choices = _nearbyNumberChoices(answer, min, max);
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Find the number $answer.',
      answer: '$answer',
      choices: choices.map((value) => '$value').toList(),
      explanation: 'This numeral is $answer.',
    );
  }

  NurseryGeneratedPractice _counting(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final min = skill.id == 'math_count_0_5' ? 0 : 6;
    final max = skill.id == 'math_count_0_5' ? 5 : 10;
    const visuals = <String>['dot', 'star', 'apple', 'fish'];
    final cases = <(int, String)>[
      if (min == 0) (0, 'dot'),
      for (var count = min == 0 ? 1 : min; count <= max; count += 1)
        for (final visual in visuals) (count, visual),
    ];
    final selected = cases[_cycleIndex(
      seed: seed,
      salt: '${skill.id}:count',
      length: cases.length,
    )];
    final count = selected.$1;
    final visual = selected.$2;
    final choices = _nearbyNumberChoices(count, 0, 10);
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: count == 0
          ? 'How many objects are in the empty counting space?'
          : 'Count the ${_pictureNoun(visual, count)} pictures. How many are there?',
      narration: count == 0
          ? 'How many objects are in the empty counting space?'
          : 'Count the ${_pictureNoun(visual, count)} carefully. How many are there?',
      answer: '$count',
      choices: choices.map((value) => '$value').toList(),
      explanation: count == 0
          ? 'The counting space is empty, so the amount is zero.'
          : 'There ${count == 1 ? 'is' : 'are'} $count ${count == 1 ? 'picture' : 'pictures'}.',
      visualTokens: count == 0
          ? const <String>['empty counting space']
          : List<String>.filled(count, visual),
    );
  }

  NurseryGeneratedPractice _numberQuantity(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final answer = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:quantity',
      length: 11,
    );
    final nearby = _nearbyNumberChoices(answer, 0, 10);
    final labels = nearby.map(_quantityLabel).toList(growable: false);
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which group shows $answer objects?',
      narration: 'Which group shows $answer objects?',
      answer: _quantityLabel(answer),
      choices: labels,
      explanation: answer == 0
          ? 'The empty group has zero objects.'
          : 'Count once: this group has $answer dots.',
      visualTokens: <String>['$answer', 'matches', _quantityLabel(answer)],
    );
  }

  NurseryGeneratedPractice _missingNumber(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final start = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:missing',
      length: 19,
    );
    final answer = start + 1;
    final choices = _nearbyNumberChoices(answer, 0, 20);
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'What number is missing? $start, __, ${start + 2}',
      narration: 'What number is missing? $start, blank, ${start + 2}.',
      answer: '$answer',
      choices: choices.map((value) => '$value').toList(),
      explanation: 'Count forward: $start, $answer, ${start + 2}.',
    );
  }

  NurseryGeneratedPractice _comparison(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    if (skill.id == 'math_same_different') {
      final cases = <(int, int)>[
        for (var value = 0; value <= 10; value += 1) (value, value),
        for (var value = 0; value < 10; value += 1) (value, value + 1),
      ];
      final selected = cases[_cycleIndex(
        seed: seed,
        salt: '${skill.id}:same-different',
        length: cases.length,
      )];
      final left = selected.$1;
      final right = selected.$2;
      final answer = left == right ? 'same' : 'different';
      return _choicePractice(
        skill: skill,
        seed: seed,
        prompt: 'Are $left and $right the same or different?',
        answer: answer,
        choices: const <String>['same', 'different'],
        explanation: left == right
            ? 'Both amounts are $left, so they are the same.'
            : '$left and $right are different amounts.',
      );
    }

    final cases = <(int, int, bool)>[
      for (var left = 1; left <= 9; left += 1)
        for (var right = left + 1; right <= 10; right += 1) ...[
          (left, right, true),
          (left, right, false),
        ],
    ];
    final selected = cases[_cycleIndex(
      seed: seed,
      salt: '${skill.id}:more-less',
      length: cases.length,
    )];
    final left = selected.$1;
    final right = selected.$2;
    final askMore = selected.$3;
    final answer = askMore ? right : left;
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which number is ${askMore ? 'more' : 'less'}: $left or $right?',
      answer: '$answer',
      choices: <String>['$left', '$right'],
      explanation: askMore
          ? '$right is more than $left.'
          : '$left is less than $right.',
    );
  }

  NurseryGeneratedPractice _addition(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final facts = <(int, int)>[
      for (var left = 1; left <= 5; left += 1)
        for (var right = 1; right <= 5; right += 1)
          if (left + right <= 10) (left, right),
    ];
    const visuals = <String>['dot', 'star', 'apple', 'fish'];
    final objectMode = skill.id == 'math_add_objects';
    final caseCount = objectMode ? facts.length * visuals.length : facts.length;
    final caseIndex = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:addition',
      length: caseCount,
    );
    final fact = facts[objectMode ? caseIndex ~/ visuals.length : caseIndex];
    final visual = objectMode ? visuals[caseIndex % visuals.length] : 'dot';
    final left = fact.$1;
    final right = fact.$2;
    final total = left + right;
    final choices = _nearbyNumberChoices(total, 0, 10);
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: objectMode
          ? 'Add $left ${_pictureNoun(visual, left)} and $right ${_pictureNoun(visual, right)}. How many altogether?'
          : '$left + $right = ?',
      narration: objectMode
          ? 'Join $left ${_pictureNoun(visual, left)} and $right ${_pictureNoun(visual, right)}. How many are there altogether?'
          : '$left plus $right equals what number?',
      answer: '$total',
      choices: choices.map((value) => '$value').toList(),
      explanation: '$left and $right combine to make $total.',
      visualTokens: objectMode
          ? <String>[
              ...List<String>.filled(left, visual),
              '+',
              ...List<String>.filled(right, visual),
              '=',
              '$total',
            ]
          : <String>['$left', '+', '$right', '=', '$total'],
    );
  }

  NurseryGeneratedPractice _colourChoice(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    const catalog = <String>['red', 'blue', 'green', 'yellow', 'orange', 'purple'];
    final index = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:colour',
      length: catalog.length,
    );
    final answer = catalog[index];
    final d1 = catalog[(index + 2) % catalog.length];
    final d2 = catalog[(index + 4) % catalog.length];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which colour word matches this colour?',
      narration: 'Look at the coloured circle. Which colour word matches it?',
      answer: answer,
      choices: <String>[answer, d1, d2],
      explanation: 'This colour is $answer.',
      visualTokens: <String>['colour:$answer'],
    );
  }

  NurseryGeneratedPractice _shapeChoice(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    const catalog = <String>['circle', 'square', 'triangle', 'rectangle'];
    final index = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:shape',
      length: catalog.length,
    );
    final answer = catalog[index];
    final d1 = catalog[(index + 1) % catalog.length];
    final d2 = catalog[(index + 2) % catalog.length];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which shape word matches this shape?',
      narration: 'Look at the shape. Which shape word matches it?',
      answer: answer,
      choices: <String>[answer, d1, d2],
      explanation: 'This shape is a $answer.',
      visualTokens: <String>[answer],
    );
  }

  NurseryGeneratedPractice _knowledgeChoice(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    final catalog = switch (skill.id) {
      'knowledge_animals' => const <String>[
          'cat', 'dog', 'fish', 'rabbit', 'goat', 'cow', 'tiger', 'bird',
        ],
      'knowledge_foods' => const <String>[
          'apple', 'mango', 'carrot', 'orange', 'banana', 'potato', 'pear',
          'broccoli',
        ],
      'knowledge_objects' => const <String>[
          'ball', 'book', 'shoe', 'cup', 'spoon', 'pencil', 'hat', 'key',
        ],
      'knowledge_body' => const <String>[
          'eyes', 'hands', 'feet', 'ears', 'nose', 'mouth',
        ],
      _ => const <String>['cat', 'ball', 'apple', 'book'],
    };
    final index = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:world',
      length: catalog.length,
    );
    final answer = catalog[index];
    final values = <String>[
      answer,
      catalog[(index + 1) % catalog.length],
      catalog[(index + 2) % catalog.length],
    ];
    final category = switch (skill.id) {
      'knowledge_animals' => 'animal',
      'knowledge_foods' => 'food',
      'knowledge_objects' => 'object',
      'knowledge_body' => 'body-part',
      _ => 'picture',
    };
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which word matches this $category picture?',
      narration: 'Look at the $category picture. Which word names it?',
      answer: answer,
      choices: values,
      explanation: 'This picture shows $answer.',
      visualTokens: <String>[answer],
    );
  }

  NurseryGeneratedPractice _routineChoice(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    const routines = <(String, String, List<String>)>[
      (
        'What helps clean our teeth?',
        'brush teeth',
        <String>['brush teeth', 'throw toys', 'wear a hat'],
      ),
      (
        'What is a helpful routine before eating?',
        'wash hands',
        <String>['wash hands', 'put on shoes', 'go to sleep'],
      ),
      (
        'When crossing a road with an adult, which choice is safest?',
        'stay with the adult and wait until it is safe to cross',
        <String>[
          'stay with the adult and wait until it is safe to cross',
          'run ahead',
          'look at a toy while crossing',
        ],
      ),
      (
        'After playing with toys, what is a helpful routine?',
        'put toys back in their place',
        <String>[
          'put toys back in their place',
          'leave toys on the stairs',
          'throw toys across the room',
        ],
      ),
      (
        'Before going to bed, what helps keep teeth clean?',
        'brush teeth',
        <String>['brush teeth', 'wear outdoor shoes', 'leave food on teeth'],
      ),
      (
        'After waking up for the day, which choice helps you get ready?',
        'get dressed for the day',
        <String>[
          'get dressed for the day',
          'get ready for bed',
          'eat dinner',
        ],
      ),
    ];
    final item = routines[_cycleIndex(
      seed: seed,
      salt: '${skill.id}:routine',
      length: routines.length,
    )];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: item.$1,
      answer: item.$2,
      choices: item.$3,
      explanation: '${item.$2} is the helpful routine in this activity.',
    );
  }

  NurseryGeneratedPractice _pattern(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    const pairs = <(String, String)>[
      ('red', 'blue'),
      ('triangle', 'circle'),
      ('apple', 'banana'),
      ('yellow', 'green'),
      ('square', 'triangle'),
      ('cat', 'fish'),
    ];
    final pair = pairs[_cycleIndex(
      seed: seed,
      salt: '${skill.id}:pattern',
      length: pairs.length,
    )];
    final distractor = switch (pair.$1) {
      'red' || 'yellow' => 'purple',
      'triangle' || 'square' => 'star',
      'apple' => 'orange',
      _ => 'dog',
    };
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'What comes next in this picture pattern?',
      answer: pair.$2,
      choices: <String>[pair.$2, pair.$1, distractor],
      explanation: 'The pattern repeats ${pair.$1}, ${pair.$2}.',
      visualTokens: <String>[pair.$1, pair.$2, pair.$1, '?'],
    );
  }

  NurseryGeneratedPractice _matching(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    const cards = <String>['triangle', 'blue', 'star', 'apple', 'fish'];
    final index = _cycleIndex(
      seed: seed,
      salt: '${skill.id}:matching',
      length: cards.length,
    );
    final answer = cards[index];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which card is exactly the same as the picture?',
      answer: answer,
      choices: <String>[
        answer,
        cards[(index + 1) % cards.length],
        cards[(index + 2) % cards.length],
      ],
      explanation: '$answer matches because both cards are the same.',
      visualTokens: <String>[answer, 'matches', '?'],
    );
  }

  NurseryGeneratedPractice _sorting(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    const groups = <(String, String, String, String)>[
      ('fruit', 'apple', 'dog', 'book'),
      ('animal', 'fish', 'carrot', 'ball'),
      ('object', 'book', 'orange', 'rabbit'),
      ('red things', 'red', 'blue', 'triangle'),
    ];
    final group = groups[_cycleIndex(
      seed: seed,
      salt: '${skill.id}:sorting',
      length: groups.length,
    )];
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Which item belongs in the ${group.$1} group?',
      answer: group.$2,
      choices: <String>[group.$2, group.$3, group.$4],
      explanation: '${group.$2} belongs in the ${group.$1} group.',
      visualTokens: <String>[group.$1, 'then', group.$2],
    );
  }

  NurseryGeneratedPractice _observation(
    NurserySkill skill,
    int seed,
    _NurseryStableRandom random,
  ) {
    const sets = <(List<String>, String, String)>[
      (<String>['apple', 'apple', 'banana'], 'banana', 'banana'),
      (<String>['star', 'star', 'ball'], 'ball', 'ball'),
      (<String>['triangle', 'triangle', 'blue'], 'blue', 'blue circle'),
      (<String>['cat', 'cat', 'fish'], 'fish', 'fish'),
      (<String>['yellow', 'yellow', 'green'], 'green', 'green circle'),
      (<String>['book', 'book', 'ball'], 'ball', 'ball'),
    ];
    final item = sets[_cycleIndex(
      seed: seed,
      salt: '${skill.id}:observation',
      length: sets.length,
    )];
    final repeated = item.$1.first;
    return _choicePractice(
      skill: skill,
      seed: seed,
      prompt: 'Look carefully at the ${item.$1.first} picture row. Which picture is different?',
      narration: 'Look carefully at the ${item.$1.first} picture row. Which picture is different?',
      answer: item.$2,
      choices: <String>[item.$2, repeated, 'dog'],
      explanation: '${item.$3} is the one that is different.',
      visualTokens: item.$1,
    );
  }

  NurseryGeneratedPractice _choicePractice({
    required NurserySkill skill,
    required int seed,
    required String prompt,
    String? narration,
    required String answer,
    required List<String> choices,
    required String explanation,
    List<String> visualTokens = const <String>[],
  }) {
    final unique = <String>[];
    for (final value in choices) {
      if (!unique.contains(value)) unique.add(value);
    }
    if (!unique.contains(answer)) unique.insert(0, answer);
    if (unique.length < 2) {
      throw StateError(
        'Generated Nursery choice needs at least two unique options.',
      );
    }
    final rotated = _rotate(unique, seed);
    return NurseryGeneratedPractice(
      id: 'nursery-generated:${skill.id}:$seed',
      skillId: skill.id,
      seed: seed,
      prompt: prompt,
      narration: narration ?? prompt,
      options: List<NurseryOption>.unmodifiable(
        rotated.map((value) => NurseryOption(id: value, label: value)),
      ),
      correctResponseRule: Map<String, dynamic>.unmodifiable(
        <String, dynamic>{'type': 'choice', 'value': answer},
      ),
      explanation: explanation,
      visualTokens: List<String>.unmodifiable(visualTokens),
    );
  }

  String _quantityLabel(int count) =>
      count == 0 ? 'empty group' : '$count ${count == 1 ? 'dot' : 'dots'}';

  String _pictureNoun(String visual, int count) {
    if (count == 1 || visual == 'fish') return visual;
    return '${visual}s';
  }

  List<int> _nearbyNumberChoices(int answer, int min, int max) {
    final candidates = <int>[answer];
    final offsets = <int>[-1, 1, -2, 2, -3, 3];
    for (final offset in offsets) {
      final value = answer + offset;
      if (value >= min && value <= max && !candidates.contains(value)) {
        candidates.add(value);
      }
      if (candidates.length == 3) break;
    }
    var fallback = min;
    while (candidates.length < 3 && fallback <= max) {
      if (!candidates.contains(fallback)) candidates.add(fallback);
      fallback += 1;
    }
    return candidates;
  }

  List<String> _rotate(List<String> values, int seed) {
    if (values.length < 2) return List<String>.from(values);
    final offset = seed.abs() % values.length;
    return <String>[...values.skip(offset), ...values.take(offset)];
  }


  int _cycleIndex({
    required int seed,
    required String salt,
    required int length,
  }) {
    if (length <= 1) return 0;
    final offset = _stableHash(salt) % length;
    var stride = 31 + (_stableHash('$salt:stride') % 31);
    while (_greatestCommonDivisor(stride, length) != 1) {
      stride += 1;
    }
    final normalizedSeed = ((seed % length) + length) % length;
    return (offset + (normalizedSeed * stride)) % length;
  }

  int _greatestCommonDivisor(int a, int b) {
    var left = a.abs();
    var right = b.abs();
    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }
    return left;
  }

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _NurseryStableRandom {
  _NurseryStableRandom(int seed) : _state = seed & 0x7fffffff;

  int _state;

  int nextInt(int max) {
    if (max <= 0) return 0;
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state % max;
  }
}
