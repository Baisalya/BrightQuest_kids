import 'package:brightquest_kids/app/learner_shell_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Class 3 keeps learner navigation focused on three primary choices', () {
    final policy = LearnerShellPolicy.forClass(3);

    expect(
      policy.primaryDestinations,
      const <LearnerShellDestination>[
        LearnerShellDestination.home,
        LearnerShellDestination.worlds,
        LearnerShellDestination.journey,
      ],
    );
    expect(
      policy.utilityDestinations,
      const <LearnerShellDestination>[LearnerShellDestination.profile],
    );
  });

  test('Classes 4 and 5 expose profile as a primary learner destination', () {
    for (final classNumber in const <int>[4, 5]) {
      final policy = LearnerShellPolicy.forClass(classNumber);

      expect(
        policy.primaryDestinations,
        const <LearnerShellDestination>[
          LearnerShellDestination.home,
          LearnerShellDestination.worlds,
          LearnerShellDestination.journey,
          LearnerShellDestination.profile,
        ],
      );
      expect(policy.utilityDestinations, isEmpty);
    }
  });

  test('unsupported class values fail closed instead of receiving a shell', () {
    for (final classNumber in const <int>[1, 2, 6, 99]) {
      expect(
        () => LearnerShellPolicy.forClass(classNumber),
        throwsA(isA<UnsupportedError>()),
      );
    }
  });
}
