import '../content/content_repository.dart';
import '../curriculum/curriculum_models.dart';
import 'learning_models.dart';
import 'mission_mastery_models.dart';
import 'mission_run_planner.dart';

/// Derives long-term mastery confidence from evidence BrightQuest already
/// stores. No parallel score is persisted and no reward/unlock rule depends on
/// this engine.
///
/// Repeating the same item may improve ordinary practice evidence, but it
/// cannot by itself satisfy the distinct-item breadth required by this signal.
class MissionMasteryIntelligence {
  const MissionMasteryIntelligence({
    this.planner = const MissionRunPlanner(),
  });

  final MissionRunPlanner planner;

  ClassMasteryExpectation expectationForClass(int classNumber) =>
      switch (classNumber) {
        3 => const ClassMasteryExpectation(
            classNumber: 3,
            minimumDistinctIndependentItems: 2,
            minimumDistinctTransferItems: 1,
            minimumDelayedReviewSuccesses: 1,
            confidenceThreshold: 0.68,
          ),
        4 => const ClassMasteryExpectation(
            classNumber: 4,
            minimumDistinctIndependentItems: 2,
            minimumDistinctTransferItems: 1,
            minimumDelayedReviewSuccesses: 1,
            confidenceThreshold: 0.72,
          ),
        5 => const ClassMasteryExpectation(
            classNumber: 5,
            minimumDistinctIndependentItems: 3,
            minimumDistinctTransferItems: 1,
            minimumDelayedReviewSuccesses: 1,
            confidenceThreshold: 0.76,
          ),
        _ => const ClassMasteryExpectation(
            classNumber: 4,
            minimumDistinctIndependentItems: 2,
            minimumDistinctTransferItems: 1,
            minimumDelayedReviewSuccesses: 1,
            confidenceThreshold: 0.72,
          ),
      };

  CompetencyMasteryInsight forCompetency({
    required LearningProfileState learningState,
    required int classNumber,
    required String competencyId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final expectation = expectationForClass(classNumber);
    final mastery = learningState.skillMastery[competencyId] ??
        SkillMastery(competencyId: competencyId);
    final evidence = learningState.attemptEvidence
        .where(
          (item) =>
              item.classNumber == classNumber &&
              item.competencyId == competencyId,
        )
        .toList(growable: false)
      ..sort((a, b) => _timeOf(a).compareTo(_timeOf(b)));

    final distinctIndependentItems = evidence
        .where((item) => item.correct && item.independent)
        .map((item) => item.itemId)
        .toSet()
        .length;
    final distinctTransferItems = evidence
        .where((item) => item.correct && item.independent && item.transfer)
        .map((item) => item.itemId)
        .toSet()
        .length;
    final delayedReviewSuccesses = evidence
        .where((item) => item.correct && item.independent && item.delayed)
        .map((item) => item.itemId)
        .toSet()
        .length;
    final activeReview = _activeReviewTask(
      learningState.reviewTasks,
      classNumber: classNumber,
      competencyId: competencyId,
    );
    final taskDueAt = activeReview?.dueAt;
    final masteryDueAt = mastery.nextReviewIso == null
        ? null
        : DateTime.tryParse(mastery.nextReviewIso!);
    final dueAt = taskDueAt ?? masteryDueAt;
    final reviewDue = dueAt != null && !dueAt.isAfter(timestamp);
    final latest = evidence.isEmpty ? null : evidence.last;
    final latestRetentionFailure = latest != null &&
        latest.kind == LearningAttemptKind.review &&
        !latest.correct;

    final hasDemonstrationBreadth = distinctIndependentItems >=
            expectation.minimumDistinctIndependentItems &&
        distinctTransferItems >= expectation.minimumDistinctTransferItems &&
        mastery.confidence >= expectation.confidenceThreshold;
    final hasRetentionEvidence =
        delayedReviewSuccesses >= expectation.minimumDelayedReviewSuccesses;
    final hasAnyEvidence = evidence.isNotEmpty || mastery.evidenceCount > 0;

    final status = !hasAnyEvidence
        ? LongTermMasteryStatus.notStarted
        : latestRetentionFailure ||
                mastery.state == LearningEvidenceState.needsSupport ||
                (mastery.state == LearningEvidenceState.reviewDue && !reviewDue)
            ? LongTermMasteryStatus.needsPractice
            : reviewDue && (hasDemonstrationBreadth || hasRetentionEvidence)
                ? LongTermMasteryStatus.retentionDue
                : hasDemonstrationBreadth && hasRetentionEvidence
                    ? LongTermMasteryStatus.secure
                    : hasDemonstrationBreadth
                        ? LongTermMasteryStatus.demonstrated
                        : LongTermMasteryStatus.improving;

    return CompetencyMasteryInsight(
      competencyId: competencyId,
      status: status,
      confidence: mastery.confidence,
      distinctIndependentItems: distinctIndependentItems,
      distinctTransferItems: distinctTransferItems,
      delayedReviewSuccesses: delayedReviewSuccesses,
      evidenceCount: evidence.length > mastery.evidenceCount
          ? evidence.length
          : mastery.evidenceCount,
      reviewDue: reviewDue,
      reason: _reason(
        status: status,
        expectation: expectation,
        independentItems: distinctIndependentItems,
        transferItems: distinctTransferItems,
        delayedReviews: delayedReviewSuccesses,
      ),
    );
  }

  LevelMasteryInsight forLevel({
    required ContentRepository repository,
    required LearningLevel level,
    required LearningProfileState learningState,
    DateTime? now,
  }) {
    final competencyIds = <String>{};
    for (final candidate in planner.candidatesForLevel(
      repository: repository,
      level: level,
    )) {
      competencyIds.addAll(candidate.allCompetencyIds);
    }
    final insights = <CompetencyMasteryInsight>[
      for (final competencyId in competencyIds.toList()..sort())
        forCompetency(
          learningState: learningState,
          classNumber: level.classNumber,
          competencyId: competencyId,
          now: now,
        ),
    ];
    final status = _aggregate(insights);
    return LevelMasteryInsight(
      levelId: level.id,
      status: status,
      competencyInsights: List<CompetencyMasteryInsight>.unmodifiable(insights),
      reason: insights.isEmpty
          ? 'No scorable competency is mapped to this level.'
          : _levelReason(status, insights),
    );
  }

  LearningLevel? nextLongTermLevel({
    required ContentRepository repository,
    required Iterable<LearningLevel> levels,
    required LearningProfileState learningState,
    required bool Function(LearningLevel level) isUnlocked,
    required bool Function(LearningLevel level) isCompleted,
    DateTime? now,
  }) {
    final unlocked = levels.where(isUnlocked).toList(growable: false);
    for (final level in unlocked) {
      if (!isCompleted(level)) continue;
      final insight = forLevel(
        repository: repository,
        level: level,
        learningState: learningState,
        now: now,
      );
      if (insight.status == LongTermMasteryStatus.retentionDue) return level;
    }
    for (final level in unlocked) {
      if (!isCompleted(level)) continue;
      final insight = forLevel(
        repository: repository,
        level: level,
        learningState: learningState,
        now: now,
      );
      if (insight.status == LongTermMasteryStatus.needsPractice) return level;
    }
    return null;
  }

  ReviewTask? _activeReviewTask(
    Iterable<ReviewTask> tasks, {
    required int classNumber,
    required String competencyId,
  }) {
    ReviewTask? best;
    for (final task in tasks) {
      if (task.classNumber != classNumber ||
          task.competencyId != competencyId ||
          task.completed) {
        continue;
      }
      if (best == null || task.dueIso.compareTo(best.dueIso) < 0) {
        best = task;
      }
    }
    return best;
  }

  LongTermMasteryStatus _aggregate(List<CompetencyMasteryInsight> insights) {
    if (insights.isEmpty) return LongTermMasteryStatus.notStarted;
    if (insights
        .any((item) => item.status == LongTermMasteryStatus.retentionDue)) {
      return LongTermMasteryStatus.retentionDue;
    }
    if (insights
        .any((item) => item.status == LongTermMasteryStatus.needsPractice)) {
      return LongTermMasteryStatus.needsPractice;
    }
    if (insights.every((item) => item.status == LongTermMasteryStatus.secure)) {
      return LongTermMasteryStatus.secure;
    }
    if (insights.every((item) =>
        item.status == LongTermMasteryStatus.secure ||
        item.status == LongTermMasteryStatus.demonstrated)) {
      return LongTermMasteryStatus.demonstrated;
    }
    if (insights
        .every((item) => item.status == LongTermMasteryStatus.notStarted)) {
      return LongTermMasteryStatus.notStarted;
    }
    return LongTermMasteryStatus.improving;
  }

  String _reason({
    required LongTermMasteryStatus status,
    required ClassMasteryExpectation expectation,
    required int independentItems,
    required int transferItems,
    required int delayedReviews,
  }) =>
      switch (status) {
        LongTermMasteryStatus.notStarted =>
          'No scorable evidence has been recorded yet.',
        LongTermMasteryStatus.needsPractice =>
          'Recent evidence shows this skill needs another supported pass before long-term mastery is trusted.',
        LongTermMasteryStatus.improving =>
          'Evidence is growing across $independentItems distinct independent item${independentItems == 1 ? '' : 's'} and $transferItems transfer item${transferItems == 1 ? '' : 's'}; Class ${expectation.classNumber} expects ${expectation.minimumDistinctIndependentItems} independent plus ${expectation.minimumDistinctTransferItems} transfer.',
        LongTermMasteryStatus.demonstrated =>
          'The skill is demonstrated across distinct items and transfer, but a delayed retention check is still required.',
        LongTermMasteryStatus.retentionDue =>
          'Prior learning is ready for a delayed retention check before it remains secure.',
        LongTermMasteryStatus.secure =>
          '$delayedReviews delayed review success${delayedReviews == 1 ? '' : 'es'} plus distinct independent and transfer evidence support long-term security.',
      };

  String _levelReason(
    LongTermMasteryStatus status,
    List<CompetencyMasteryInsight> insights,
  ) {
    final affected = insights
        .where((item) => item.status == status)
        .map((item) => item.competencyId)
        .take(3)
        .join(', ');
    return switch (status) {
      LongTermMasteryStatus.retentionDue =>
        'A retention check is due for ${affected.isEmpty ? 'a linked skill' : affected}.',
      LongTermMasteryStatus.needsPractice =>
        'One or more linked skills need another supported encounter.',
      LongTermMasteryStatus.secure =>
        'All mapped skills have distinct-item, transfer and delayed-retention evidence.',
      LongTermMasteryStatus.demonstrated =>
        'Mapped skills are demonstrated; delayed retention is the next confidence gate.',
      LongTermMasteryStatus.improving =>
        'Mapped skills are still building breadth across independent and transfer evidence.',
      LongTermMasteryStatus.notStarted =>
        'No long-term evidence is available for this mission yet.',
    };
  }

  DateTime _timeOf(AttemptEvidence evidence) =>
      DateTime.tryParse(evidence.recordedAtIso)?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
