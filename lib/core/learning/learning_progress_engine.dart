import '../content/content_activity.dart';
import '../content/content_repository.dart';
import 'diagnostic_engine.dart';
import 'evidence_engine.dart';
import 'learning_models.dart';
import 'recommendation_engine.dart';
import 'review_scheduler.dart';

/// Owns the transitions between evidence, mastery, review, and recommendations.
/// Persistence and profile selection remain the responsibility of GameController.
class LearningProgressEngine {
  const LearningProgressEngine({
    this.diagnosticEngine = const DiagnosticEngine(),
    this.evidenceEngine = const EvidenceEngine(),
    this.reviewScheduler = const ReviewScheduler(),
    this.recommendationEngine = const RecommendationEngine(),
  });

  final DiagnosticEngine diagnosticEngine;
  final EvidenceEngine evidenceEngine;
  final ReviewScheduler reviewScheduler;
  final RecommendationEngine recommendationEngine;

  DiagnosticProgress startDiagnostic({
    required ContentRepository repository,
    required int classNumber,
    required DateTime now,
  }) =>
      diagnosticEngine.start(
        repository: repository,
        classNumber: classNumber,
        now: now,
      );

  ContentActivity? currentDiagnosticActivity({
    required ContentRepository repository,
    required DiagnosticProgress progress,
  }) =>
      diagnosticEngine.currentActivity(repository, progress);

  DiagnosticProgress advanceDiagnostic({
    required DiagnosticProgress progress,
    required DateTime now,
  }) =>
      diagnosticEngine.advance(progress, now: now);

  LearningProfileState recordEvidence(
    LearningProfileState state,
    AttemptEvidence evidence,
  ) {
    final before = state.skillMastery[evidence.competencyId];
    var updated = evidenceEngine.record(state, evidence);
    final after = updated.skillMastery[evidence.competencyId];
    final tasks = <ReviewTask>[...updated.reviewTasks];

    if (after != null &&
        after.state == LearningEvidenceState.masteredNow &&
        before?.state != LearningEvidenceState.masteredNow &&
        before?.state != LearningEvidenceState.secure) {
      final task = reviewScheduler.scheduleFirst(
        competencyId: evidence.competencyId,
        classNumber: evidence.classNumber,
        now: DateTime.tryParse(evidence.recordedAtIso) ?? DateTime.now(),
        sourceItemId: evidence.itemId,
        evidenceQuality: after.confidence,
      );
      final index = tasks.indexWhere((candidate) => candidate.id == task.id);
      if (index >= 0) {
        tasks[index] = task;
      } else {
        tasks.add(task);
      }
      final mastery = Map<String, SkillMastery>.from(updated.skillMastery);
      mastery[evidence.competencyId] =
          after.copyWith(nextReviewIso: task.dueIso);
      updated = updated.copyWith(
        reviewTasks: List<ReviewTask>.unmodifiable(tasks),
        skillMastery: Map<String, SkillMastery>.unmodifiable(mastery),
      );
    } else if (evidence.kind == LearningAttemptKind.review) {
      final index = tasks.indexWhere(
        (candidate) => candidate.competencyId == evidence.competencyId,
      );
      if (index >= 0) {
        var nextTask = reviewScheduler.reschedule(
          task: tasks[index],
          now: DateTime.tryParse(evidence.recordedAtIso) ?? DateTime.now(),
          correct: evidence.correct,
          independent: evidence.independent,
        );
        tasks[index] = nextTask;
        final mastery = Map<String, SkillMastery>.from(updated.skillMastery);
        final skill = mastery[evidence.competencyId];
        if (skill != null) {
          if (skill.state == LearningEvidenceState.secure) {
            nextTask = nextTask.copyWith(completed: true);
            tasks[index] = nextTask;
          }
          mastery[evidence.competencyId] = skill.copyWith(
            nextReviewIso: skill.state == LearningEvidenceState.secure
                ? null
                : nextTask.dueIso,
            clearNextReviewIso: skill.state == LearningEvidenceState.secure,
          );
        }
        updated = updated.copyWith(
          reviewTasks: List<ReviewTask>.unmodifiable(tasks),
          skillMastery: Map<String, SkillMastery>.unmodifiable(mastery),
        );
      }
    }

    return updated;
  }

  LearningProfileState refreshReviewStates(
    LearningProfileState state,
    DateTime now,
  ) {
    final mastery = Map<String, SkillMastery>.from(state.skillMastery);
    var changed = false;
    for (final entry in mastery.entries.toList()) {
      final skill = entry.value;
      final due = skill.nextReviewIso == null
          ? null
          : DateTime.tryParse(skill.nextReviewIso!);
      if (due != null &&
          !due.isAfter(now) &&
          skill.state == LearningEvidenceState.masteredNow) {
        mastery[entry.key] = skill.copyWith(
          state: LearningEvidenceState.reviewDue,
        );
        changed = true;
      }
    }
    if (!changed) return state;
    return state.copyWith(
      skillMastery: Map<String, SkillMastery>.unmodifiable(mastery),
    );
  }

  List<ReviewTask> dueReviewTasks(
    LearningProfileState state, {
    required int classNumber,
    required DateTime now,
    int limit = 10,
  }) =>
      reviewScheduler.dueTasks(
        state.reviewTasks,
        classNumber: classNumber,
        now: now,
        limit: limit,
      );

  List<LearningRecommendation> recommendations(
    LearningProfileState state, {
    int limit = 5,
  }) =>
      recommendationEngine.recommend(state.skillMastery, limit: limit);
}
