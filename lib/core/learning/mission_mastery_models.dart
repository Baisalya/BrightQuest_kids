/// Conservative long-term learning state derived from BrightQuest's existing
/// evidence, mastery and review records. It is intentionally not persisted as
/// a second mastery score.
enum LongTermMasteryStatus {
  notStarted,
  needsPractice,
  improving,
  demonstrated,
  retentionDue,
  secure,
}

class ClassMasteryExpectation {
  const ClassMasteryExpectation({
    required this.classNumber,
    required this.minimumDistinctIndependentItems,
    required this.minimumDistinctTransferItems,
    required this.minimumDelayedReviewSuccesses,
    required this.confidenceThreshold,
  });

  final int classNumber;
  final int minimumDistinctIndependentItems;
  final int minimumDistinctTransferItems;
  final int minimumDelayedReviewSuccesses;
  final double confidenceThreshold;
}

class CompetencyMasteryInsight {
  const CompetencyMasteryInsight({
    required this.competencyId,
    required this.status,
    required this.confidence,
    required this.distinctIndependentItems,
    required this.distinctTransferItems,
    required this.delayedReviewSuccesses,
    required this.evidenceCount,
    required this.reviewDue,
    required this.reason,
  });

  final String competencyId;
  final LongTermMasteryStatus status;
  final double confidence;
  final int distinctIndependentItems;
  final int distinctTransferItems;
  final int delayedReviewSuccesses;
  final int evidenceCount;
  final bool reviewDue;
  final String reason;

  String get label => switch (status) {
        LongTermMasteryStatus.notStarted => 'Not started',
        LongTermMasteryStatus.needsPractice => 'Needs practice',
        LongTermMasteryStatus.improving => 'Improving',
        LongTermMasteryStatus.demonstrated => 'Demonstrated',
        LongTermMasteryStatus.retentionDue => 'Retention due',
        LongTermMasteryStatus.secure => 'Secure',
      };
}

class LevelMasteryInsight {
  const LevelMasteryInsight({
    required this.levelId,
    required this.status,
    required this.competencyInsights,
    required this.reason,
  });

  final String levelId;
  final LongTermMasteryStatus status;
  final List<CompetencyMasteryInsight> competencyInsights;
  final String reason;

  String get label => switch (status) {
        LongTermMasteryStatus.notStarted => 'Not started',
        LongTermMasteryStatus.needsPractice => 'Needs practice',
        LongTermMasteryStatus.improving => 'Improving',
        LongTermMasteryStatus.demonstrated => 'Demonstrated',
        LongTermMasteryStatus.retentionDue => 'Retention due',
        LongTermMasteryStatus.secure => 'Secure',
      };

  double get confidence {
    if (competencyInsights.isEmpty) return 0;
    return competencyInsights
            .map((item) => item.confidence)
            .reduce((a, b) => a + b) /
        competencyInsights.length;
  }
}
