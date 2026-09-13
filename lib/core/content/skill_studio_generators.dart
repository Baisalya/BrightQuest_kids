import 'content_activity.dart';

/// Deterministic practice variants for Skill Studio competencies that can be
/// parameterised without inventing new curriculum facts.
///
/// This generator is intentionally conservative. It supports only numeric /
/// structured Maths competencies whose authored Class 3–5 Skill Studio items
/// already establish the underlying rule. Language, EVS and other
/// knowledge-heavy competencies remain authored-only and use spaced review.
class SkillStudioPracticeGenerators {
  const SkillStudioPracticeGenerators();

  static const int maxSeed = 999999999;

  static const Set<String> supportedCompetencyIds = <String>{
    'c3_math_place_value_999',
    'c3_math_money_bills',
    'c3_math_measurement',
    'c3_math_time_calendar',
    'c3_math_shapes_patterns_data',
    'c4_math_place_value_10000',
    'c4_math_measure_perimeter',
    'c4_math_time_money',
    'c4_math_geometry_symmetry',
    'c4_math_data_patterns',
    'c5_math_large_numbers_100000',
    'c5_math_estimation',
    'c5_math_factors_multiples',
    'c5_math_geometry_angles_symmetry',
    'c5_math_measure_conversion_volume',
    'c5_math_data',
  };

  bool supports(String competencyId) =>
      supportedCompetencyIds.contains(competencyId);

  ContentActivity? generate({
    required ContentActivity template,
    required int seed,
  }) {
    if (!supports(template.competencyId) ||
        seed < 0 ||
        seed > maxSeed ||
        template.gameId != 'skill_studio') {
      return null;
    }
    final question = switch (template.competencyId) {
      'c3_math_place_value_999' => _placeValue(seed, digits: 3),
      'c3_math_money_bills' => _money(seed, classNumber: 3),
      'c3_math_measurement' => _measurementC3(seed),
      'c3_math_time_calendar' => _timeCalendarC3(seed),
      'c3_math_shapes_patterns_data' => _patternsAndData(
          seed,
          classNumber: 3,
        ),
      'c4_math_place_value_10000' => _placeValue(seed, digits: 4),
      'c4_math_measure_perimeter' => _perimeterC4(seed),
      'c4_math_time_money' => _timeMoneyC4(seed),
      'c4_math_geometry_symmetry' => _angleClassification(seed, classNumber: 4),
      'c4_math_data_patterns' => _patternsAndData(
          seed,
          classNumber: 4,
        ),
      'c5_math_large_numbers_100000' => _placeValue(seed, digits: 5),
      'c5_math_estimation' => _estimationC5(seed),
      'c5_math_factors_multiples' => _factorsMultiplesC5(seed),
      'c5_math_geometry_angles_symmetry' =>
        _angleClassification(seed, classNumber: 5),
      'c5_math_measure_conversion_volume' => _measurementVolumeC5(seed),
      'c5_math_data' => _dataC5(seed),
      _ => null,
    };
    if (question == null) return null;

    final id = 'skillgen_${template.competencyId}_s$seed';
    final choices = _uniqueChoices(question.answer, question.choices);
    if (choices.length < 2 || !choices.contains(question.answer)) return null;
    final ruleType = question.answer is num ? 'exactNumber' : 'exactText';
    return ContentActivity(
      id: id,
      legacyContentId: id,
      classNumber: template.classNumber,
      gameId: 'skill_studio',
      topicId: template.topicId,
      subject: template.subject,
      unitId: template.unitId,
      competencyId: template.competencyId,
      relatedCompetencyIds: template.relatedCompetencyIds,
      learningOutcomeId: template.learningOutcomeId,
      relatedLearningOutcomeIds: template.relatedLearningOutcomeIds,
      activityType: 'independentPractice',
      difficulty: template.difficulty,
      prompt: question.prompt,
      correctResponseRule: <String, dynamic>{
        'type': ruleType,
        'value': question.answer,
      },
      explanation: question.explanation,
      distractors: <ContentDistractor>[
        for (final choice in choices)
          if (choice != question.answer)
            ContentDistractor(
              value: choice,
              misconceptionId: 'generated_skill_practice_distractor',
            ),
      ],
      hints: <ContentHint>[
        ContentHint(step: 1, text: question.hint),
      ],
      narrationText: question.prompt,
      locale: template.locale,
      author: 'brightquest-skill-practice-generator',
      reviewerOwnerId: template.reviewerOwnerId,
      status: 'needsReview',
      revision: 1,
      generation: ContentGeneration(
        mode: 'generated',
        deterministicSeed: id,
      ),
      payload: <String, dynamic>{
        'answer': question.answer,
        'choices': choices,
        'hint': question.hint,
        'masteryEligible': true,
        'evidenceScope': 'generatedSkillPractice',
      },
    );
  }

  _GeneratedQuestion _placeValue(int seed, {required int digits}) {
    final values = List<int>.generate(digits, (index) {
      final modulus = index == 0 ? 9 : 10;
      final base = (seed * (17 + index * 8) + 3 + index * 11) % modulus;
      return index == 0 ? base + 1 : base;
    });
    final targetIndex = seed % digits;
    if (values[targetIndex] == 0) {
      values[targetIndex] = 1 + ((seed + targetIndex * 3) % 9);
    }
    final targetDigit = values[targetIndex];
    for (var index = 0; index < values.length; index += 1) {
      if (index == targetIndex || values[index] != targetDigit) continue;
      var replacement = (values[index] + index + 1) % 10;
      if (index == 0 && replacement == 0) replacement = 1;
      while (replacement == targetDigit) {
        replacement = (replacement + 1) % 10;
        if (index == 0 && replacement == 0) replacement = 1;
      }
      values[index] = replacement;
    }
    var number = 0;
    for (final digit in values) {
      number = number * 10 + digit;
    }
    final placePower = digits - targetIndex - 1;
    final place = _pow10(placePower);
    final digit = values[targetIndex];
    final answer = digit * place;
    final largerPlace = placePower + 1 < digits ? digit * place * 10 : digit;
    final smallerPlace = place > 1 ? digit * (place ~/ 10) : digit * 10;
    return _GeneratedQuestion(
      prompt: 'In $number, what value does the digit $digit represent?',
      answer: answer,
      choices: <Object?>[answer, digit, largerPlace, smallerPlace, number],
      hint: 'Name the place of the digit first, then write its value.',
      explanation:
          'The digit $digit is in the ${_placeName(place)} place, so its value is $answer.',
    );
  }

  _GeneratedQuestion _money(int seed, {required int classNumber}) {
    final mode = seed % 4;
    final a = 12 + ((seed * 17 + 5) % 67);
    final b = 6 + ((seed * 23 + 9) % 43);
    if (mode == 0) {
      final answer = a + b;
      return _numericQuestion(
        'A notebook costs ₹$a and a pencil costs ₹$b. What is the total cost?',
        answer,
        'Add the two costs.',
        '₹$a + ₹$b = ₹$answer.',
      );
    }
    if (mode == 1) {
      final paid = classNumber == 3 ? 100 : 200;
      final price = 20 + ((seed * 19 + 7) % (paid - 30));
      final answer = paid - price;
      return _numericQuestion(
        'You have ₹$paid and spend ₹$price. How many rupees remain?',
        answer,
        'Subtract the amount spent from the amount you had.',
        '₹$paid − ₹$price = ₹$answer.',
      );
    }
    if (mode == 2) {
      final first = 30 + ((seed * 29 + 3) % 65);
      var second = 30 + ((seed * 31 + 11) % 65);
      if (second == first) second = first == 99 ? 92 : first + 1;
      final answer = first > second ? first : second;
      return _GeneratedQuestion(
        prompt: 'Which amount is greater: ₹$first or ₹$second?',
        answer: answer,
        choices: <Object?>[first, second],
        hint: 'Compare the tens first, then the ones.',
        explanation: '₹$answer is the greater amount.',
      );
    }
    final unit = 8 + ((seed * 13 + 5) % 31);
    final quantity = 2 + (seed % 4);
    final answer = unit * quantity;
    return _numericQuestion(
      '$quantity juice boxes cost ₹$unit each. What is the total cost?',
      answer,
      'Use repeated addition or multiplication.',
      '$quantity × ₹$unit = ₹$answer.',
    );
  }

  _GeneratedQuestion _measurementC3(int seed) {
    final mode = seed % 4;
    final amount = 1 + (_mix(seed, 11) % 30);
    if (mode == 0) {
      return _numericQuestion(
        'How many centimetres are in $amount metres?',
        amount * 100,
        'Each metre has 100 centimetres.',
        '$amount × 100 = ${amount * 100} centimetres.',
      );
    }
    if (mode == 1) {
      return _numericQuestion(
        'A jug holds $amount litres. How many 500 mL cups fill it?',
        amount * 2,
        'One litre fills two 500 mL cups.',
        '$amount litres fill ${amount * 2} cups of 500 mL.',
      );
    }
    if (mode == 2) {
      final kg = 1 + (_mix(seed, 12) % 9);
      var grams = 250 + (_mix(seed, 13) % 8500);
      if (grams == kg * 1000) grams += 125;
      final kgLabel = '$kg kg object';
      final gramLabel = '$grams g object';
      final answer = kg * 1000 > grams ? kgLabel : gramLabel;
      return _GeneratedQuestion(
        prompt: 'Which is heavier: $kgLabel or $gramLabel?',
        answer: answer,
        choices: <Object?>[kgLabel, gramLabel, 'They have equal mass'],
        hint: 'Compare both masses in grams.',
        explanation: '$kg kg is ${kg * 1000} g, so $answer is heavier.',
      );
    }
    return _numericQuestion(
      'How many millilitres are in $amount litres?',
      amount * 1000,
      'Each litre has 1,000 millilitres.',
      '$amount × 1,000 = ${amount * 1000} millilitres.',
    );
  }

  _GeneratedQuestion _timeCalendarC3(int seed) {
    final mode = seed % 4;
    if (mode == 0) {
      final hour = 1 + (_mix(seed, 21) % 10);
      final minutesToAdd = <int>[15, 30, 45][_mix(seed, 22) % 3];
      final total = hour * 60 + minutesToAdd;
      final answer = _formatClock(total);
      return _GeneratedQuestion(
        prompt: 'What time is $minutesToAdd minutes after $hour:00?',
        answer: answer,
        choices: <Object?>[
          answer,
          _formatClock(hour * 60 + 60),
          _formatClock(hour * 60 + ((minutesToAdd + 15) % 60)),
          '$hour:00',
        ],
        hint: 'Move forward by the given number of minutes.',
        explanation: '$minutesToAdd minutes after $hour:00 is $answer.',
      );
    }
    if (mode == 1) {
      const days = <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final start = _mix(seed, 23) % 7;
      final offset = 1 + (_mix(seed, 24) % 6);
      final answer = days[(start + offset) % 7];
      return _GeneratedQuestion(
        prompt: 'If today is ${days[start]}, what day is $offset days later?',
        answer: answer,
        choices: <Object?>[
          answer,
          days[(start + offset + 1) % 7],
          days[(start + offset + 6) % 7],
          days[start],
        ],
        hint: 'Count forward one day at a time.',
        explanation: '$offset days after ${days[start]} is $answer.',
      );
    }
    if (mode == 2) {
      final start = 7 + (_mix(seed, 25) % 4);
      final duration = 1 + (_mix(seed, 26) % 4);
      final end = start + duration;
      return _GeneratedQuestion(
        prompt:
            'An activity starts at $start:00 and ends at $end:00. How much time passes?',
        answer: '$duration hours',
        choices: <Object?>[
          '$duration hours',
          '${duration + 1} hours',
          '${(duration - 1).clamp(1, 9)} hours',
          '${duration * 30} minutes',
        ],
        hint: 'Count the whole hours from the start time to the end time.',
        explanation: 'From $start:00 to $end:00 is $duration hours.',
      );
    }
    final weeks = 1 + (_mix(seed, 27) % 20);
    return _numericQuestion(
      'How many days are in $weeks weeks?',
      weeks * 7,
      'Each week has 7 days.',
      '$weeks × 7 = ${weeks * 7} days.',
    );
  }

  _GeneratedQuestion _patternsAndData(
    int seed, {
    required int classNumber,
  }) {
    final mode = seed % 4;
    final scale = classNumber == 3 ? 1 : 2;
    if (mode == 0) {
      final step = scale + 1 + (_mix(seed, 31) % (7 + scale));
      final start = 1 + (_mix(seed, 32) % 50);
      final values = <int>[for (var i = 0; i < 4; i += 1) start + i * step];
      final answer = start + 4 * step;
      return _numericQuestion(
        'Continue the pattern: ${values.join(', ')}, __.',
        answer,
        'Find how much is added each time.',
        'The rule adds $step, so the next number is $answer.',
      );
    }
    final first = 3 + (_mix(seed, 33) % 48);
    var second = 3 + (_mix(seed, 34) % 48);
    var third = 3 + (_mix(seed, 35) % 48);
    while (second == first) {
      second += 3;
    }
    while (third == first || third == second) {
      third += 5;
    }
    const labels = <String>['Red', 'Blue', 'Green'];
    final counts = <int>[first, second, third];
    if (mode == 1) {
      var best = 0;
      for (var i = 1; i < counts.length; i += 1) {
        if (counts[i] > counts[best]) best = i;
      }
      final answer = labels[best];
      return _GeneratedQuestion(
        prompt:
            'A table shows Red: $first, Blue: $second, Green: $third. Which colour has the greatest count?',
        answer: answer,
        choices: const <Object?>['Red', 'Blue', 'Green', 'All are equal'],
        hint: 'Compare the three counts.',
        explanation: '$answer has the greatest count.',
      );
    }
    if (mode == 2) {
      final high = first > second ? first : second;
      final low = first > second ? second : first;
      final answer = high - low;
      return _numericQuestion(
        'A chart shows Monday: $low books and Tuesday: $high books. How many more books were read Tuesday?',
        answer,
        'Subtract the smaller count from the larger count.',
        '$high − $low = $answer.',
      );
    }
    final add = 2 + (_mix(seed, 36) % 11);
    final current = 10 + (_mix(seed, 37) % 90);
    final answer = current + add;
    return _numericQuestion(
      'The rule is “add $add”. What comes after $current?',
      answer,
      'Apply the rule once.',
      '$current + $add = $answer.',
    );
  }

  _GeneratedQuestion _perimeterC4(int seed) {
    final mode = seed % 4;
    if (mode == 0) {
      final length = 3 + (_mix(seed, 41) % 28);
      final width = 2 + (_mix(seed, 42) % 19);
      final answer = 2 * (length + width);
      return _numericQuestion(
        'A rectangle is $length cm long and $width cm wide. What is its perimeter in centimetres?',
        answer,
        'Add all four sides, or use 2 × (length + width).',
        '2 × ($length + $width) = $answer cm.',
      );
    }
    if (mode == 1) {
      final side = 2 + (_mix(seed, 43) % 29);
      return _numericQuestion(
        'A square has sides of $side cm. What is its perimeter?',
        side * 4,
        'A square has four equal sides.',
        '4 × $side = ${side * 4} cm.',
      );
    }
    if (mode == 2) {
      final a = 3 + (_mix(seed, 44) % 18);
      final b = 4 + (_mix(seed, 45) % 18);
      final minC = (a - b).abs() + 1;
      final maxC = a + b - 1;
      final c = minC + (_mix(seed, 46) % (maxC - minC + 1));
      return _numericQuestion(
        'A triangular garden has sides $a m, $b m and $c m. What is its perimeter?',
        a + b + c,
        'Add the three side lengths.',
        '$a + $b + $c = ${a + b + c} m.',
      );
    }
    final metres = 1 + (_mix(seed, 47) % 50);
    return _numericQuestion(
      'How many centimetres are in $metres metres?',
      metres * 100,
      'Each metre has 100 centimetres.',
      '$metres × 100 = ${metres * 100} cm.',
    );
  }

  _GeneratedQuestion _timeMoneyC4(int seed) {
    final mode = seed % 4;
    if (mode == 0) {
      final startHour = 1 + ((seed * 7 + 1) % 10);
      final startMinute = <int>[0, 15, 30][(seed ~/ 4) % 3];
      final elapsed = <int>[15, 30, 45, 60][(seed ~/ 12) % 4];
      final endTotal = startHour * 60 + startMinute + elapsed;
      return _numericQuestion(
        'How many minutes pass from ${_formatClock(startHour * 60 + startMinute)} to ${_formatClock(endTotal)}?',
        elapsed,
        'Count forward from the start time to the end time.',
        '$elapsed minutes pass.',
      );
    }
    if (mode == 1) {
      final paid = seed.isEven ? 200 : 500;
      final price = 60 + ((seed * 19 + 7) % (paid - 80));
      final answer = paid - price;
      return _numericQuestion(
        'You pay ₹$paid for an item costing ₹$price. How much change should you get?',
        answer,
        'Subtract the cost from the amount paid.',
        '₹$paid − ₹$price = ₹$answer.',
      );
    }
    if (mode == 2) {
      final startHour = 1 + ((seed * 5 + 3) % 9);
      final startMinute = <int>[0, 15, 30, 45][(seed ~/ 4) % 4];
      final addMinutes = <int>[45, 60, 90, 120][(seed ~/ 16) % 4];
      final answer = _formatClock(startHour * 60 + startMinute + addMinutes);
      return _GeneratedQuestion(
        prompt:
            'What time is $addMinutes minutes after ${_formatClock(startHour * 60 + startMinute)}?',
        answer: answer,
        choices: <Object?>[
          answer,
          _formatClock(startHour * 60 + startMinute + addMinutes + 15),
          _formatClock(startHour * 60 + startMinute + addMinutes - 15),
          _formatClock(startHour * 60 + startMinute + 60),
        ],
        hint: 'Add the minutes, carrying 60 minutes into one hour when needed.',
        explanation: 'The new time is $answer.',
      );
    }
    final ticket = 20 + ((seed * 13 + 1) % 61);
    final count = 2 + ((seed * 3 + 1) % 5);
    return _numericQuestion(
      '$count tickets cost ₹$ticket each. What is the total cost?',
      ticket * count,
      'Multiply the price of one ticket by the number of tickets.',
      '$count × ₹$ticket = ₹${ticket * count}.',
    );
  }

  _GeneratedQuestion _angleClassification(
    int seed, {
    required int classNumber,
  }) {
    final acute = seed.isEven;
    final saltBase = classNumber == 4 ? 51 : 55;
    final degree = acute
        ? 10 + (_mix(seed, saltBase) % 80)
        : 100 + (_mix(seed, saltBase + 1) % 80);
    final answer = acute ? 'Acute angle' : 'Obtuse angle';
    final prompt = classNumber == 4
        ? 'How should a $degree° angle be classified?'
        : 'A turn measures $degree°. Which angle type describes it?';
    return _GeneratedQuestion(
      prompt: prompt,
      answer: answer,
      choices: const <Object?>[
        'Acute angle',
        'Right angle',
        'Obtuse angle',
        'Straight angle',
      ],
      hint: 'Compare the angle with 90°.',
      explanation:
          '$degree° is ${acute ? 'less than' : 'greater than'} 90°, so it is an ${acute ? 'acute' : 'obtuse'} angle.',
    );
  }

  _GeneratedQuestion _estimationC5(int seed) {
    final mode = seed % 3;
    if (mode == 0) {
      final a = 110 + ((seed * 37 + 9) % 780);
      final b = 110 + ((seed * 43 + 17) % 780);
      final answer = _roundHundred(a) + _roundHundred(b);
      return _numericQuestion(
        'Estimate $a + $b by rounding each number to the nearest hundred.',
        answer,
        'Round each number first, then add the rounded values.',
        '${_roundHundred(a)} + ${_roundHundred(b)} = $answer.',
      );
    }
    if (mode == 1) {
      final high = 1100 + ((seed * 47 + 23) % 3500);
      final low = 100 + ((seed * 29 + 11) % 900);
      final answer = _roundHundred(high) - _roundHundred(low);
      return _numericQuestion(
        'Estimate $high − $low by rounding each number to the nearest hundred.',
        answer,
        'Round both numbers to the nearest hundred before subtracting.',
        '${_roundHundred(high)} − ${_roundHundred(low)} = $answer.',
      );
    }
    final a = 21 + ((seed * 31 + 7) % 69);
    final b = 11 + ((seed * 17 + 3) % 39);
    final roundedA = _roundTen(a);
    final roundedB = _roundTen(b);
    final answer = roundedA * roundedB;
    return _numericQuestion(
      'Estimate $a × $b by rounding each factor to the nearest ten.',
      answer,
      'Round each factor to the nearest ten, then multiply.',
      '$roundedA × $roundedB = $answer.',
    );
  }

  _GeneratedQuestion _factorsMultiplesC5(int seed) {
    final mode = seed % 4;
    final a = 2 + (_mix(seed, 61) % 18);
    final b = 2 + (_mix(seed, 62) % 18);
    final product = a * b;
    if (mode == 0) {
      final distractors = _nonFactors(product, start: a + 1);
      return _GeneratedQuestion(
        prompt: 'Which number is a factor of $product?',
        answer: a,
        choices: <Object?>[a, ...distractors],
        hint: 'A factor divides the number exactly with no remainder.',
        explanation: '$product ÷ $a = ${product ~/ a}, so $a is a factor.',
      );
    }
    if (mode == 1) {
      final factor = 3 + (_mix(seed, 63) % 18);
      final multiplier = 2 + (_mix(seed, 64) % 18);
      final answer = factor * multiplier;
      final distractors = _nonMultiples(factor, start: answer - 2);
      return _GeneratedQuestion(
        prompt: 'Which number is a multiple of $factor?',
        answer: answer,
        choices: <Object?>[answer, ...distractors],
        hint: 'A multiple can be written as the number times a whole number.',
        explanation: '$factor × $multiplier = $answer.',
      );
    }
    if (mode == 2) {
      final first = 2 + (_mix(seed, 65) % 11);
      final second = 2 + (_mix(seed, 66) % 11);
      final answer = _lcm(first, second);
      return _numericQuestion(
        'What is the smallest common multiple of $first and $second?',
        answer,
        'List small multiples of both numbers and find the first match.',
        '$answer is the first positive number divisible by both $first and $second.',
      );
    }
    final n = product * (2 + (_mix(seed, 67) % 5));
    final pair = <int>[a, b];
    final wrong = _nonFactors(n, start: a + b);
    return _GeneratedQuestion(
      prompt: 'Which pair are both factors of $n?',
      answer: '${pair[0]} and ${pair[1]}',
      choices: <Object?>[
        '${pair[0]} and ${pair[1]}',
        '${wrong[0]} and ${pair[0]}',
        '${wrong[1]} and ${pair[1]}',
        '${wrong[0]} and ${wrong[1]}',
      ],
      hint: 'Check that both numbers divide $n exactly.',
      explanation: '$n is divisible by both ${pair[0]} and ${pair[1]}.',
    );
  }

  _GeneratedQuestion _measurementVolumeC5(int seed) {
    final mode = seed % 4;
    if (mode == 0) {
      final litres = 1 + (_mix(seed, 71) % 30);
      return _numericQuestion(
        'How many millilitres are in $litres litres?',
        litres * 1000,
        'Each litre has 1,000 millilitres.',
        '$litres × 1,000 = ${litres * 1000} mL.',
      );
    }
    if (mode == 1) {
      final length = 3 + (_mix(seed, 72) % 28);
      final width = 2 + (_mix(seed, 73) % 24);
      return _numericQuestion(
        'A rectangle is $length cm long and $width cm wide. What is its area in square centimetres?',
        length * width,
        'Area of a rectangle is length × width.',
        '$length × $width = ${length * width} cm².',
      );
    }
    if (mode == 2) {
      final length = 2 + (_mix(seed, 74) % 11);
      final width = 2 + (_mix(seed, 75) % 10);
      final height = 2 + (_mix(seed, 76) % 9);
      final answer = length * width * height;
      return _numericQuestion(
        'A box is $length cm × $width cm × $height cm. What is its volume in cubic centimetres?',
        answer,
        'Volume of a rectangular box is length × width × height.',
        '$length × $width × $height = $answer cm³.',
      );
    }
    final litres = 1 + (_mix(seed, 77) % 20);
    final cup = seed.isEven ? 250 : 500;
    final answer = litres * 1000 ~/ cup;
    return _numericQuestion(
      'A bottle holds $litres litres. How many $cup mL cups can it fill?',
      answer,
      'Convert litres to millilitres, then divide by the cup size.',
      '${litres * 1000} ÷ $cup = $answer cups.',
    );
  }

  _GeneratedQuestion _dataC5(int seed) {
    final mode = seed % 4;
    final a = 8 + (_mix(seed, 81) % 50);
    var b = 8 + (_mix(seed, 82) % 50);
    var c = 8 + (_mix(seed, 83) % 50);
    while (b == a) {
      b += 2;
    }
    while (c == a || c == b) {
      c += 4;
    }
    if (mode == 0) {
      final values = <String, int>{'Team A': a, 'Team B': b, 'Team C': c};
      final answer = values.entries
          .reduce(
            (left, right) => left.value > right.value ? left : right,
          )
          .key;
      return _GeneratedQuestion(
        prompt:
            'A table shows Team A: $a points, Team B: $b, Team C: $c. Which team has the most points?',
        answer: answer,
        choices: const <Object?>[
          'Team A',
          'Team B',
          'Team C',
          'They are equal'
        ],
        hint: 'Compare the three values.',
        explanation: '$answer has the greatest value.',
      );
    }
    if (mode == 1) {
      final high = a > b ? a : b;
      final low = a > b ? b : a;
      return _numericQuestion(
        'A chart shows $low books in June and $high in July. How many more books were read in July?',
        high - low,
        'Subtract the smaller value from the larger one.',
        '$high − $low = ${high - low}.',
      );
    }
    if (mode == 2) {
      return _numericQuestion(
        'A table lists Red: $a, Blue: $b, Green: $c. What is the total?',
        a + b + c,
        'Add all three values.',
        '$a + $b + $c = ${a + b + c}.',
      );
    }
    final high = a > b ? a : b;
    final low = a > b ? b : a;
    final difference = high - low;
    return _GeneratedQuestion(
      prompt:
          'Plant A grew $low cm and Plant B grew $high cm. Which statement is supported?',
      answer: 'Plant B grew $difference cm more than Plant A',
      choices: <Object?>[
        'Plant B grew $difference cm more than Plant A',
        'Plant A grew $difference cm more than Plant B',
        'Both plants grew the same amount',
        'Plant B grew ${high + low} cm more than Plant A',
      ],
      hint: 'Compare the two measurements by subtraction.',
      explanation:
          '$high − $low = $difference, so Plant B grew $difference cm more.',
    );
  }

  _GeneratedQuestion _numericQuestion(
    String prompt,
    int answer,
    String hint,
    String explanation,
  ) {
    final delta = answer.abs() < 10
        ? 1
        : answer.abs() < 100
            ? 5
            : 10;
    return _GeneratedQuestion(
      prompt: prompt,
      answer: answer,
      choices: <Object?>[
        answer,
        answer + delta,
        (answer - delta).clamp(0, 999999999).toInt(),
        answer + delta * 2,
      ],
      hint: hint,
      explanation: explanation,
    );
  }

  List<Object?> _uniqueChoices(Object? answer, Iterable<Object?> values) {
    final result = <Object?>[];
    void add(Object? value) {
      if (!result.any((candidate) => candidate == value)) result.add(value);
    }

    add(answer);
    for (final value in values) {
      add(value);
      if (result.length >= 4) break;
    }
    if (answer is int) {
      var offset = 1;
      while (result.length < 4) {
        add(answer + offset);
        offset += 1;
      }
    }
    return List<Object?>.unmodifiable(result);
  }

  List<int> _nonFactors(int value, {required int start}) {
    final result = <int>[];
    var candidate = start.clamp(2, 99).toInt();
    while (result.length < 3) {
      if (value % candidate != 0 && !result.contains(candidate)) {
        result.add(candidate);
      }
      candidate += 1;
    }
    return result;
  }

  List<int> _nonMultiples(int factor, {required int start}) {
    final result = <int>[];
    var candidate = start.clamp(1, 999999).toInt();
    while (result.length < 3) {
      if (candidate % factor != 0 && !result.contains(candidate)) {
        result.add(candidate);
      }
      candidate += 1;
    }
    return result;
  }

  int _roundHundred(int value) => ((value + 50) ~/ 100) * 100;
  int _roundTen(int value) => ((value + 5) ~/ 10) * 10;

  int _lcm(int a, int b) => (a * b) ~/ _gcd(a, b);

  int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final next = x % y;
      x = y;
      y = next;
    }
    return x == 0 ? 1 : x;
  }

  int _mix(int seed, int salt) {
    var value = (seed ^ (salt * 0x9e3779b9)) & 0x7fffffff;
    value = (value * 1103515245 + 12345) & 0x7fffffff;
    value ^= value >> 11;
    return value & 0x7fffffff;
  }

  int _pow10(int power) {
    var value = 1;
    for (var index = 0; index < power; index += 1) {
      value *= 10;
    }
    return value;
  }

  String _placeName(int place) => switch (place) {
        1 => 'ones',
        10 => 'tens',
        100 => 'hundreds',
        1000 => 'thousands',
        10000 => 'ten-thousands',
        _ => 'place-value',
      };

  String _formatClock(int totalMinutes) {
    final normalized = totalMinutes % (12 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')}';
  }
}

class _GeneratedQuestion {
  const _GeneratedQuestion({
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.hint,
    required this.explanation,
  });

  final String prompt;
  final Object? answer;
  final List<Object?> choices;
  final String hint;
  final String explanation;
}
