import 'learning_models.dart';

class RecommendationEngine {
  const RecommendationEngine();

  List<LearningRecommendation> recommend(
    Map<String, SkillMastery> mastery, {
    int limit = 5,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final values = <LearningRecommendation>[];
    for (final skill in mastery.values) {
      final due = skill.nextReviewIso == null
          ? false
          : !(DateTime.tryParse(skill.nextReviewIso!) ?? currentTime)
              .isAfter(currentTime);
      final priority = switch (skill.state) {
        LearningEvidenceState.needsSupport => 0,
        LearningEvidenceState.reviewDue => 1,
        LearningEvidenceState.practising => 2,
        LearningEvidenceState.introduced => 3,
        LearningEvidenceState.masteredNow when due => 1,
        LearningEvidenceState.masteredNow => 4,
        LearningEvidenceState.notStarted => 5,
        LearningEvidenceState.secure => 6,
      };
      final reason = switch (skill.state) {
        LearningEvidenceState.needsSupport =>
          'A few pieces of evidence show this skill needs a calmer reteach.',
        LearningEvidenceState.reviewDue => 'A short review is due now.',
        LearningEvidenceState.practising =>
          'Keep practising until the child can solve independently.',
        LearningEvidenceState.introduced => 'Build one more example together.',
        LearningEvidenceState.masteredNow when due =>
          'Mastered recently; check retention with a delayed review.',
        LearningEvidenceState.masteredNow =>
          'Mastered now; a later review will make it secure.',
        LearningEvidenceState.notStarted =>
          'This skill has not been explored yet.',
        LearningEvidenceState.secure =>
          'Secure; revisit later in mixed practice.',
      };
      values.add(
        LearningRecommendation(
          competencyId: skill.competencyId,
          reason: reason,
          priority: priority,
          state: skill.state,
        ),
      );
    }
    values.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      return priority != 0
          ? priority
          : a.competencyId.compareTo(b.competencyId);
    });
    return List<LearningRecommendation>.unmodifiable(
      values.take(limit.clamp(0, 20).toInt()).toList(),
    );
  }
}
