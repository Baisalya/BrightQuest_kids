enum HomePrimaryActionKind {
  resume,
  diagnostic,
  review,
  curriculum,
  appliedMission,
  freePractice,
}

HomePrimaryActionKind chooseHomePrimaryAction({
  required bool hasResumableSession,
  required bool diagnosticInProgress,
  required bool needsStartingCheck,
  required int dueReviewCount,
  required bool hasCurriculumMission,
  required bool corePathComplete,
  required bool hasAppliedMissionEvidence,
}) {
  if (hasResumableSession) return HomePrimaryActionKind.resume;
  if (diagnosticInProgress || needsStartingCheck) {
    return HomePrimaryActionKind.diagnostic;
  }
  if (dueReviewCount > 0) return HomePrimaryActionKind.review;
  if (hasCurriculumMission) return HomePrimaryActionKind.curriculum;
  if (corePathComplete && !hasAppliedMissionEvidence) {
    return HomePrimaryActionKind.appliedMission;
  }
  return HomePrimaryActionKind.freePractice;
}
