import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/parent_report_engine.dart';
import 'package:brightquest_kids/core/learning/review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  group('Phase 5 spaced review', () {
    test('review intervals are deterministic, bounded and date-based', () {
      const scheduler = ReviewScheduler();
      expect(ReviewScheduler.intervalsDays, <int>[1, 3, 7, 14, 30]);
      final now = DateTime(2026, 12, 31, 23, 59);
      final first = scheduler.scheduleFirst(
        competencyId: 'skill-a',
        classNumber: 3,
        now: now,
        evidenceQuality: 0.5,
      );
      final again = scheduler.scheduleFirst(
        competencyId: 'skill-a',
        classNumber: 3,
        now: now,
        evidenceQuality: 0.5,
      );
      expect(first.dueIso, again.dueIso);
      expect(first.dueAt, DateTime(2027, 1, 1));

      final tasks = List<ReviewTask>.generate(
        15,
        (index) => ReviewTask(
          id: 'review-$index',
          competencyId: 'skill-${index.toString().padLeft(2, '0')}',
          classNumber: 3,
          dueIso: DateTime(2026, 8, 19).toIso8601String(),
          intervalIndex: 0,
        ),
      );
      final due = scheduler.dueTasks(
        tasks,
        classNumber: 3,
        now: DateTime(2026, 8, 20),
        limit: 50,
      );
      expect(due.length, 10);
      expect(
          due.map((item) => item.competencyId).toList(),
          List<String>.generate(
              10, (index) => 'skill-${index.toString().padLeft(2, '0')}'));
    });
  });

  group('Phase 7 parent evidence', () {
    test('report distinguishes missing evidence and support without ranking',
        () {
      final repository = buildContentRepository();
      final classPack = repository.curriculum.classPack(3)!;
      final supportId = classPack.competencies.first.id;
      final learning = LearningProfileState(
        skillMastery: <String, SkillMastery>{
          supportId: SkillMastery(
            competencyId: supportId,
            state: LearningEvidenceState.needsSupport,
            evidenceCount: 3,
            correctCount: 1,
            misconceptionCounts: const <String, int>{'arithmetic_error': 2},
          ),
        },
      );
      final report = const ParentReportEngine().build(
        curriculum: repository.curriculum,
        learning: learning,
        classNumber: 3,
        now: DateTime(2026, 8, 20),
      );
      expect(report.rows.length, 37);
      expect(report.weekly.needsSupport, 1);
      expect(
        report.rows
            .firstWhere((row) => row.competencyId == supportId)
            .parentNote,
        contains('Several pieces of evidence'),
      );
      expect(
        report.rows.firstWhere((row) => row.evidenceCount == 0).parentNote,
        contains('will not infer ability'),
      );
    });

    test('child project reflection is explicitly unverified after persistence',
        () {
      final evidence = ProjectEvidence(
        id: 'p1',
        missionId: 'mission-1',
        classNumber: 3,
        competencyIds: const <String>['a', 'b'],
        correctness: 0.75,
        strategy: 0.5,
        independence: 0.5,
        explanation: 0.75,
        completedAtIso: DateTime(2026, 8, 20).toIso8601String(),
      );
      final restored = ProjectEvidence.fromJson(evidence.toJson());
      expect(restored.adultVerified, isFalse);
    });
  });
}
