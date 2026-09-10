import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_practice_generator.dart';
import 'package:brightquest_kids/core/nursery/nursery_response_evaluator.dart';
import 'package:brightquest_kids/core/qa/nursery_phonics_audit.dart';
import 'package:brightquest_kids/core/qa/nursery_phonics_reference.dart';
import 'package:flutter_test/flutter_test.dart';

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      ),
    );

NurseryLetterExample _example(
  NurseryContentPack pack,
  String letter,
  String word,
) =>
    pack.letterAssociations
        .firstWhere((item) => item.uppercase == letter)
        .examples
        .firstWhere((item) => item.word == word);

void main() {
  group('Phase B simple phonics policy', () {
    test('whole 208-card catalog matches independent phonics QA reference', () {
      final pack = _pack();
      const audit = NurseryPhonicsAudit(generatedSeedsPerSkill: 512);
      final report = audit.audit(pack);
      expect(
        report.findings,
        isEmpty,
        reason: report.findings.join('\n'),
      );
    });

    test('irregular vowels remain discovery-only, not simple phonics mastery', () {
      final pack = _pack();
      for (final pair in <(String, String)>[
        ('E', 'Eye'),
        ('E', 'Eagle'),
        ('E', 'Earth'),
        ('I', 'Island'),
        ('I', 'Ice Cream'),
        ('O', 'Owl'),
        ('O', 'Ocean'),
        ('O', 'Onion'),
        ('U', 'Unicorn'),
        ('U', 'Uniform'),
      ]) {
        final example = _example(pack, pair.$1, pair.$2);
        expect(example.soundPracticeEligible, isFalse, reason: pair.$2);
        expect(example.beginningSoundEligible, isFalse, reason: pair.$2);
        expect(example.soundCue, isNotEmpty, reason: pair.$2);
      }
    });

    test('clusters, SH, Q and X are excluded from simple onset mastery', () {
      final pack = _pack();
      for (final pair in <(String, String)>[
        ('D', 'Drum'),
        ('F', 'Frog'),
        ('G', 'Grapes'),
        ('S', 'Star'),
        ('S', 'Ship'),
        ('T', 'Train'),
        ('Q', 'Queen'),
        ('X', 'Xylophone'),
        ('X', 'Box'),
      ]) {
        final example = _example(pack, pair.$1, pair.$2);
        expect(example.soundPracticeEligible, isFalse, reason: pair.$2);
        expect(example.beginningSoundEligible, isFalse, reason: pair.$2);
        expect(nurseryAdvancedPhonicsReason[pair.$2], isNotNull);
      }
    });

    test('missing phonics flags fail closed instead of enabling mastery', () {
      final example = NurseryLetterExample.fromJson(<String, dynamic>{
        'word': 'Apple',
        'picture': 'apple',
        'assetPath': 'assets/nursery/letter_cards/a_1_apple.png',
        'soundCue': 'Listen to the first sound in apple.',
        'displayPhrase': 'A for Apple',
      });
      expect(example.soundPracticeEligible, isFalse);
      expect(example.beginningSoundEligible, isFalse);

      final raw = Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      );
      final letters = List<dynamic>.from(raw['letterAssociations'] as List);
      final firstLetter = Map<String, dynamic>.from(letters.first as Map);
      final examples = List<dynamic>.from(firstLetter['examples'] as List);
      final firstExample = Map<String, dynamic>.from(examples.first as Map)
        ..remove('soundPracticeEligible');
      examples[0] = firstExample;
      firstLetter['examples'] = examples;
      letters[0] = firstLetter;
      raw['letterAssociations'] = letters;
      final issues = NurseryContentValidator.validate(raw);
      expect(
        issues.join('\n'),
        contains('requires explicit soundPracticeEligible'),
      );
    });

    test('corrected vocabulary cards use dedicated assets with safe fallbacks', () {
      final pack = _pack();
      const corrected = <(String, String)>[
        ('I', 'Igloo'),
        ('J', 'Jug'),
        ('L', 'Lamp'),
        ('O', 'Ostrich'),
        ('Q', 'Quilt'),
        ('Q', 'Quail'),
        ('Q', 'Quiver'),
        ('U', 'Ukulele'),
        ('V', 'Vacuum'),
        ('V', 'Vulture'),
        ('W', 'Wagon'),
        ('Y', 'Yak'),
        ('Z', 'Zeppelin'),
      ];
      for (final pair in corrected) {
        final example = _example(pack, pair.$1, pair.$2);
        expect(File(example.assetPath).existsSync(), isTrue, reason: pair.$2);
        expect(example.picture, pair.$2.toLowerCase(), reason: '${pair.$2} fallback');
      }
    });

    test('same-first-sound authored tasks explain the sound relationship', () {
      final pack = _pack();
      const evaluator = NurseryResponseEvaluator();
      final dogDuck = pack.activityById('nursery.alpha_beginning_sound.i2')!;
      final catKite = pack.activityById('nursery.alpha_beginning_sound.t1')!;

      expect(evaluator.evaluate(dogDuck, 'Duck').correct, isTrue);
      expect(evaluator.evaluate(dogDuck, 'Dog').correct, isFalse);
      expect(
        evaluator.explanationFor(dogDuck).text,
        'dog and Duck start with the same first sound.',
      );

      expect(evaluator.evaluate(catKite, 'Kite').correct, isTrue);
      expect(evaluator.evaluate(catKite, 'Cat').correct, isFalse);
      expect(
        evaluator.explanationFor(catKite).text,
        'cat and Kite start with the same first sound.',
      );
    });

    test('simple phonics pool remains broad and reviewable', () {
      final count = nurserySimplePhonicsWords.values.fold<int>(
        0,
        (total, words) => total + words.length,
      );
      expect(count, 157);
      expect(nurserySimplePhonicsWords['Q'], isEmpty);
      expect(nurserySimplePhonicsWords['X'], isEmpty);
      expect(nurserySimplePhonicsWords['S'], contains('Sun'));
      expect(nurserySimplePhonicsWords['S'], isNot(contains('Ship')));
    });
  });

  group('Phase B deterministic sound practice', () {
    const generator = NurseryPracticeGenerator();

    test('letter-sound generator only selects simple approved examples', () {
      final pack = _pack();
      final skill = pack.skillById('alpha_letter_sounds')!;
      final seen = <String>{};
      for (var seed = 0; seed < 512; seed += 1) {
        final practice = generator.generate(pack: pack, skill: skill, seed: seed);
        final answer = practice.correctResponseRule['value'] as String;
        final word = practice.visualTokens.firstWhere(
          (token) => pack.letterAssociations.any(
            (letter) => letter.examples.any((example) => example.word == token),
          ),
        );
        expect(
          nurseryWordIsSimplePhonicsEligible(answer, word),
          isTrue,
          reason: '$seed: $answer/$word',
        );
        expect(answer == 'Q' || answer == 'X', isFalse);
        expect(practice.prompt.toLowerCase(), isNot(contains('sound cue')));
        seen.add('$answer|$word');
      }
      expect(seen.length, 157);
    });

    test('beginning-sound generator covers every approved pair before cycling', () {
      final pack = _pack();
      final skill = pack.skillById('alpha_beginning_sound')!;
      final expected = <String>{
        for (final entry in nurserySimplePhonicsWords.entries)
          for (final word in entry.value) '${entry.key}|$word',
      };
      final seen = <String>{};
      for (var seed = 0; seed < expected.length; seed += 1) {
        final practice = generator.generate(pack: pack, skill: skill, seed: seed);
        final answer = practice.correctResponseRule['value'] as String;
        final word = practice.visualTokens.firstWhere(
          (token) => pack.letterAssociations.any(
            (letter) => letter.examples.any((example) => example.word == token),
          ),
        );
        seen.add('$answer|$word');
      }
      expect(seen.length, expected.length);
      expect(seen, containsAll(expected));
    });
  });
}
