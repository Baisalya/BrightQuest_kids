enum LearnerCapabilityKind {
  nursery,
  schoolClass,
}

enum LearnerCapabilityAvailability {
  available,
  notShipped,
}

class LearnerCapability {
  const LearnerCapability({
    required this.id,
    required this.label,
    required this.kind,
    required this.availability,
    this.classNumber,
  });

  final String id;
  final String label;
  final LearnerCapabilityKind kind;
  final LearnerCapabilityAvailability availability;
  final int? classNumber;

  bool get isAvailable =>
      availability == LearnerCapabilityAvailability.available;
}

/// Single source of truth for the learner span BrightQuest recognizes.
///
/// Recognition is deliberately different from availability. The product span is
/// Nursery through Class 6, but this build only ships a verified Nursery
/// experience and School Classes 3, 4 and 5. Classes 1, 2 and 6 are represented
/// here only so future work cannot accidentally treat "inside the age range" as
/// "content is available".
abstract final class LearnerCapabilityBoundary {
  static const LearnerCapability nursery = LearnerCapability(
    id: 'nursery',
    label: 'Nursery',
    kind: LearnerCapabilityKind.nursery,
    availability: LearnerCapabilityAvailability.available,
  );

  static const LearnerCapability class1 = LearnerCapability(
    id: 'class_1',
    label: 'Class 1',
    kind: LearnerCapabilityKind.schoolClass,
    classNumber: 1,
    availability: LearnerCapabilityAvailability.notShipped,
  );

  static const LearnerCapability class2 = LearnerCapability(
    id: 'class_2',
    label: 'Class 2',
    kind: LearnerCapabilityKind.schoolClass,
    classNumber: 2,
    availability: LearnerCapabilityAvailability.notShipped,
  );

  static const LearnerCapability class3 = LearnerCapability(
    id: 'class_3',
    label: 'Class 3',
    kind: LearnerCapabilityKind.schoolClass,
    classNumber: 3,
    availability: LearnerCapabilityAvailability.available,
  );

  static const LearnerCapability class4 = LearnerCapability(
    id: 'class_4',
    label: 'Class 4',
    kind: LearnerCapabilityKind.schoolClass,
    classNumber: 4,
    availability: LearnerCapabilityAvailability.available,
  );

  static const LearnerCapability class5 = LearnerCapability(
    id: 'class_5',
    label: 'Class 5',
    kind: LearnerCapabilityKind.schoolClass,
    classNumber: 5,
    availability: LearnerCapabilityAvailability.available,
  );

  static const LearnerCapability class6 = LearnerCapability(
    id: 'class_6',
    label: 'Class 6',
    kind: LearnerCapabilityKind.schoolClass,
    classNumber: 6,
    availability: LearnerCapabilityAvailability.notShipped,
  );

  static const List<LearnerCapability> recognizedLearnerSpan =
      <LearnerCapability>[
    nursery,
    class1,
    class2,
    class3,
    class4,
    class5,
    class6,
  ];

  static const List<LearnerCapability> availableLearnerOptions =
      <LearnerCapability>[
    nursery,
    class3,
    class4,
    class5,
  ];

  static const List<int> supportedSchoolClasses = <int>[3, 4, 5];
  static const List<int> unavailableSchoolClasses = <int>[1, 2, 6];

  static bool isSupportedSchoolClass(int classNumber) =>
      supportedSchoolClasses.contains(classNumber);

  static LearnerCapability? schoolClassCapability(int classNumber) {
    for (final capability in recognizedLearnerSpan) {
      if (capability.kind == LearnerCapabilityKind.schoolClass &&
          capability.classNumber == classNumber) {
        return capability;
      }
    }
    return null;
  }

  static void requireSupportedSchoolClass(int classNumber) {
    if (isSupportedSchoolClass(classNumber)) return;
    throw UnsupportedError(
      'Class $classNumber is not shipped in this BrightQuest build. '
      'Available School classes are 3, 4 and 5.',
    );
  }
}
