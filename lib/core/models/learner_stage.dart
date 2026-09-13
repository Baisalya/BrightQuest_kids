enum LearnerStage {
  nursery,
  school,
}

LearnerStage learnerStageFromStorage(Object? raw) {
  if (raw is String) {
    for (final value in LearnerStage.values) {
      if (value.name == raw) return value;
    }
  }
  // Backward-compatible default for every profile written before Phase 8.
  return LearnerStage.school;
}

extension LearnerStagePresentation on LearnerStage {
  String get label => switch (this) {
        LearnerStage.nursery => 'Nursery',
        LearnerStage.school => 'School',
      };
}
