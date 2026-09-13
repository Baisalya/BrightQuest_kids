import 'package:brightquest_kids/app/learner_shell_policy.dart';
import 'package:brightquest_kids/core/capabilities/learner_capability_boundary.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/entitlements/entitlement_service.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  test('recognized Nursery-to-Class-6 span exposes only shipped learners', () {
    expect(
      LearnerCapabilityBoundary.recognizedLearnerSpan
          .map((capability) => capability.label)
          .toList(),
      const <String>[
        'Nursery',
        'Class 1',
        'Class 2',
        'Class 3',
        'Class 4',
        'Class 5',
        'Class 6',
      ],
    );

    expect(
      LearnerCapabilityBoundary.availableLearnerOptions
          .map((capability) => capability.label)
          .toList(),
      const <String>['Nursery', 'Class 3', 'Class 4', 'Class 5'],
    );

    for (final classNumber in const <int>[1, 2, 6]) {
      expect(
        LearnerCapabilityBoundary.isSupportedSchoolClass(classNumber),
        isFalse,
      );
      expect(
        LearnerCapabilityBoundary.schoolClassCapability(classNumber)
            ?.isAvailable,
        isFalse,
      );
    }
  });

  test('capability registry matches the curriculum and bundled class packs',
      () {
    final curriculumClasses =
        curriculumTopics.map((topic) => topic.classNumber).toSet();
    final repositoryClasses =
        buildContentRepository().packs.map((pack) => pack.classNumber).toSet();

    expect(
      curriculumClasses,
      LearnerCapabilityBoundary.supportedSchoolClasses.toSet(),
    );
    expect(
      repositoryClasses,
      LearnerCapabilityBoundary.supportedSchoolClasses.toSet(),
    );
  });

  test('legacy integer snapshots normalize back inside the shipped boundary',
      () {
    for (final rawClass in const <int>[0, 1, 2, 6, 99]) {
      final profile = ChildProfileSnapshot.fromJson(
        <String, Object?>{
          'id': 'legacy-$rawClass',
          'name': 'Legacy',
          'selectedClass': rawClass,
        },
      );

      expect(
        LearnerCapabilityBoundary.isSupportedSchoolClass(
          profile.selectedClass,
        ),
        isTrue,
      );
    }
  });

  test('unsupported School classes fail closed at controller and shell edges',
      () async {
    final controller = GameController();
    await controller.load();

    final originalClass = controller.selectedClass;
    final profileCount = controller.profiles.length;

    for (final classNumber in const <int>[1, 2, 6]) {
      controller.setClass(classNumber);
      expect(controller.selectedClass, originalClass);

      final created = controller.createProfile(
        name: 'Unsupported',
        classNumber: classNumber,
      );
      expect(created, isEmpty);
      expect(controller.profiles.length, profileCount);

      expect(
        () => LearnerShellPolicy.forClass(classNumber),
        throwsA(isA<UnsupportedError>()),
      );
    }
  });

  test('commercial purchase boundary rejects unshipped School classes',
      () async {
    final service = EntitlementService();

    for (final classNumber in const <int>[1, 2, 6]) {
      await expectLater(
        service.purchaseClass(classNumber),
        throwsA(isA<UnsupportedError>()),
      );
    }
  });
}
