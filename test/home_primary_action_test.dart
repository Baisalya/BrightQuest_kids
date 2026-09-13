import 'package:brightquest_kids/features/home/home_primary_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home primary action priority', () {
    test('resume always wins', () {
      expect(
        chooseHomePrimaryAction(
          hasResumableSession: true,
          diagnosticInProgress: true,
          needsStartingCheck: true,
          dueReviewCount: 4,
          hasCurriculumMission: true,
          corePathComplete: false,
          hasAppliedMissionEvidence: false,
        ),
        HomePrimaryActionKind.resume,
      );
    });

    test('starting check wins before review and curriculum', () {
      expect(
        chooseHomePrimaryAction(
          hasResumableSession: false,
          diagnosticInProgress: false,
          needsStartingCheck: true,
          dueReviewCount: 3,
          hasCurriculumMission: true,
          corePathComplete: false,
          hasAppliedMissionEvidence: false,
        ),
        HomePrimaryActionKind.diagnostic,
      );
    });

    test('due review wins before next curriculum quest', () {
      expect(
        chooseHomePrimaryAction(
          hasResumableSession: false,
          diagnosticInProgress: false,
          needsStartingCheck: false,
          dueReviewCount: 2,
          hasCurriculumMission: true,
          corePathComplete: false,
          hasAppliedMissionEvidence: false,
        ),
        HomePrimaryActionKind.review,
      );
    });

    test('curriculum quest wins while the core path is open', () {
      expect(
        chooseHomePrimaryAction(
          hasResumableSession: false,
          diagnosticInProgress: false,
          needsStartingCheck: false,
          dueReviewCount: 0,
          hasCurriculumMission: true,
          corePathComplete: false,
          hasAppliedMissionEvidence: false,
        ),
        HomePrimaryActionKind.curriculum,
      );
    });

    test('applied mission follows a completed core path once', () {
      expect(
        chooseHomePrimaryAction(
          hasResumableSession: false,
          diagnosticInProgress: false,
          needsStartingCheck: false,
          dueReviewCount: 0,
          hasCurriculumMission: false,
          corePathComplete: true,
          hasAppliedMissionEvidence: false,
        ),
        HomePrimaryActionKind.appliedMission,
      );
    });

    test('free practice is the final fallback', () {
      expect(
        chooseHomePrimaryAction(
          hasResumableSession: false,
          diagnosticInProgress: false,
          needsStartingCheck: false,
          dueReviewCount: 0,
          hasCurriculumMission: false,
          corePathComplete: true,
          hasAppliedMissionEvidence: true,
        ),
        HomePrimaryActionKind.freePractice,
      );
    });
  });
}
