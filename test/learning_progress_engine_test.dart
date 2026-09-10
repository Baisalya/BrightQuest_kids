import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/learning_progress_engine.dart';
import 'package:flutter_test/flutter_test.dart';

AttemptEvidence _evidence({
  required String id,
  required LearningAttemptKind kind,
  required DateTime recordedAt,
}) =>
    AttemptEvidence(
      id: id,
      profileId: 'child-1',
      classNumber: 3,
      competencyId: 'c3_math_equal_sharing_division',
      itemId: 'item-$id',
      kind: kind,
      correct: true,
      hintLevel: 0,
      retries: 0,
      responseTimeMs: 2500,
      confidence: 1,
      recordedAtIso: recordedAt.toIso8601String(),
      sourceGameId: 'math_market',
    );

void main() {
  test('mastery review lifecycle continues into bounded maintenance review',
      () {
    const engine = LearningProgressEngine();
    final learnedAt = DateTime(2026, 8, 20, 10);
    var state = const LearningProfileState();

    state = engine.recordEvidence(
      state,
      _evidence(
        id: 'independent-1',
        kind: LearningAttemptKind.independent,
        recordedAt: learnedAt,
      ),
    );
    state = engine.recordEvidence(
      state,
      _evidence(
        id: 'independent-2',
        kind: LearningAttemptKind.independent,
        recordedAt: learnedAt.add(const Duration(minutes: 1)),
      ),
    );
    state = engine.recordEvidence(
      state,
      _evidence(
        id: 'transfer',
        kind: LearningAttemptKind.transfer,
        recordedAt: learnedAt.add(const Duration(minutes: 2)),
      ),
    );

    final competency = state.skillMastery.keys.single;
    expect(
      state.skillMastery[competency]!.state,
      LearningEvidenceState.masteredNow,
    );
    expect(state.reviewTasks, hasLength(1));
    expect(state.reviewTasks.single.completed, isFalse);

    final dueAt = state.reviewTasks.single.dueAt!;
    state = engine.refreshReviewStates(state, dueAt);
    expect(
      state.skillMastery[competency]!.state,
      LearningEvidenceState.reviewDue,
    );
    expect(
      engine.dueReviewTasks(
        state,
        classNumber: 3,
        now: dueAt,
      ),
      hasLength(1),
    );

    state = engine.recordEvidence(
      state,
      _evidence(
        id: 'review',
        kind: LearningAttemptKind.review,
        recordedAt: dueAt,
      ),
    );
    expect(
      state.skillMastery[competency]!.state,
      LearningEvidenceState.secure,
    );
    expect(state.skillMastery[competency]!.nextReviewIso, isNotNull);
    expect(state.reviewTasks.single.completed, isFalse);

    final maintenanceDue = state.reviewTasks.single.dueAt!;
    state = engine.refreshReviewStates(state, maintenanceDue);
    expect(
      state.skillMastery[competency]!.state,
      LearningEvidenceState.reviewDue,
    );
    expect(
      engine.dueReviewTasks(
        state,
        classNumber: 3,
        now: maintenanceDue,
      ),
      hasLength(1),
    );
  });
}
