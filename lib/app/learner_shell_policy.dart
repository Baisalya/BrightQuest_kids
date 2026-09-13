import '../core/capabilities/learner_capability_boundary.dart';

/// Child-facing destinations that can appear in the learner shell.
///
/// Parent controls intentionally do not appear in this enum. They are a
/// separate guarded utility route and must never become a normal learner tab.
enum LearnerShellDestination {
  home,
  worlds,
  journey,
  profile,
}

/// Defines how much navigation choice is surfaced for a supported school class.
///
/// BrightQuest currently ships verified School curriculum for Classes 3, 4 and
/// 5. Unsupported classes fail closed here instead of receiving a learner shell
/// that could be mistaken for real curriculum support.
class LearnerShellPolicy {
  const LearnerShellPolicy({
    required this.primaryDestinations,
    required this.utilityDestinations,
  });

  final List<LearnerShellDestination> primaryDestinations;
  final List<LearnerShellDestination> utilityDestinations;

  static const LearnerShellPolicy _class3 = LearnerShellPolicy(
    primaryDestinations: <LearnerShellDestination>[
      LearnerShellDestination.home,
      LearnerShellDestination.worlds,
      LearnerShellDestination.journey,
    ],
    utilityDestinations: <LearnerShellDestination>[
      LearnerShellDestination.profile,
    ],
  );

  static const LearnerShellPolicy _class4And5 = LearnerShellPolicy(
    primaryDestinations: <LearnerShellDestination>[
      LearnerShellDestination.home,
      LearnerShellDestination.worlds,
      LearnerShellDestination.journey,
      LearnerShellDestination.profile,
    ],
    utilityDestinations: <LearnerShellDestination>[],
  );

  factory LearnerShellPolicy.forClass(int classNumber) {
    LearnerCapabilityBoundary.requireSupportedSchoolClass(classNumber);
    return classNumber == 3 ? _class3 : _class4And5;
  }

  bool isPrimary(LearnerShellDestination destination) =>
      primaryDestinations.contains(destination);

  bool isUtility(LearnerShellDestination destination) =>
      utilityDestinations.contains(destination);

  bool contains(LearnerShellDestination destination) =>
      isPrimary(destination) || isUtility(destination);
}
