import 'package:brightquest_kids/core/content/content_generators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all supported arithmetic seeds produce a finite valid choice set', () {
    const generators = DeterministicContentGenerators();

    for (final classNumber in const <int>[3, 4, 5]) {
      for (final difficulty in const <int>[1, 2, 3]) {
        for (var seed = 0; seed < 100; seed += 1) {
          final question = generators.arithmetic(
            classNumber: classNumber,
            difficulty: difficulty,
            seed: seed,
          );

          expect(
            question.choices,
            hasLength(4),
            reason:
                'Class $classNumber difficulty $difficulty seed $seed did not produce four choices.',
          );
          expect(question.choices.toSet(), hasLength(4));
          expect(question.choices.where((value) => value == question.answer),
              hasLength(1));
          expect(question.choices.every((value) => value >= 0), isTrue);
        }
      }
    }
  });
}
