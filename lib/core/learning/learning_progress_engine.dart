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
    Iterable<String> recentItemIds = const <String>[],
    Iterable<String> recentContentFingerprints = const <String>[],
  }) =>
      diagnosticEngine.start(
        repository: repository,
        classNumber: classNumber,
        now: now,
        recentItemIds: recentItemIds,
        recentContentFingerprints: recentContentFingerprints,
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
    final normalizedEvidence = promoteDueReviewEvidence(state, evidence);
    final before = state.skillMastery[normalizedEvidence.competencyId];
    var updated = evidenceEngine.record(state, normalizedEvidence);
    final after = updated.skillMastery[normalizedEvidence.competencyId];
    final tasks = <ReviewTask>[...updated.reviewTasks];

    if (after != null &&
        after.state == LearningEvidenceState.masteredNow &&
        before?.state != LearningEvidenceState.masteredNow &&
        before?.state != LearningEvidenceState.secure &&
        before?.state != LearningEvidenceState.reviewDue) {
      final task = reviewScheduler.scheduleFirst(
        competencyId: normalizedEvidence.competencyId,
        classNumber: normalizedEvidence.classNumber,
        now: DateTime.tryParse(normalizedEvidence.recordedAtIso) ??
            DateTime.now(),
        sourceItemId: normalizedEvidence.itemId,
        evidenceQuality: after.confidence,
      );
      final index = tasks.indexWhere((candidate) => candidate.id == task.id);
      if (index >= 0) {
        tasks[index] = task;
      } else {
        tasks.add(task);
      }
      final mastery = Map<String, SkillMastery>.from(updated.skillMastery);
      mastery[normalizedEvidence.competencyId] =
          after.copyWith(nextReviewIso: task.dueIso);
      updated = updated.copyWith(
        reviewTasks: List<ReviewTask>.unmodifiable(tasks),
        skillMastery: Map<String, SkillMastery>.unmodifiable(mastery),
      );
    } else if (normalizedEvidence.kind == LearningAttemptKind.review) {
      final index = tasks.indexWhere(
        (candidate) =>
            candidate.classNumber == normalizedEvidence.classNumber &&
            candidate.competencyId == normalizedEvidence.competencyId,
      );
      if (index >= 0) {
        final currentTask = tasks[index].copyWith(completed: false);
        final nextTask = reviewScheduler.reschedule(
          task: currentTask,
          now: DateTime.tryParse(normalizedEvidence.recordedAtIso) ??
              DateTime.now(),
          correct: normalizedEvidence.correct,
          independent: normalizedEvidence.independent,
        );
        tasks[index] = nextTask.copyWith(completed: false);
        final mastery = Map<String, SkillMastery>.from(updated.skillMastery);
        final skill = mastery[normalizedEvidence.competencyId];
        if (skill != null) {
          final retentionPassed =
              normalizedEvidence.correct && normalizedEvidence.independent;
          mastery[normalizedEvidence.competencyId] = skill.copyWith(
            state:
                retentionPassed ? skill.state : LearningEvidenceState.reviewDue,
            nextReviewIso: nextTask.dueIso,
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

  /// A due delayed-review opportunity counts as review evidence even when the
  /// child reaches it through an ordinary World replay. This closes the loop
  /// between mission rotation and spaced retention without requiring every
  /// game renderer to understand review scheduling.
  AttemptEvidence promoteDueReviewEvidence(
    LearningProfileState state,
    AttemptEvidence evidence,
  ) {
    if (evidence.kind == LearningAttemptKind.review ||
        evidence.kind == LearningAttemptKind.diagnostic ||
        evidence.kind == LearningAttemptKind.guided ||
        evidence.kind == LearningAttemptKind.project) {
      return evidence;
    }
    final recordedAt =
        DateTime.tryParse(evidence.recordedAtIso) ?? DateTime.now();
    final skill = state.skillMastery[evidence.competencyId];
    if (skill == null ||
        (skill.state != LearningEvidenceState.masteredNow &&
            skill.state != LearningEvidenceState.reviewDue &&
            skill.state != LearningEvidenceState.secure)) {
      return evidence;
    }
    for (final task in state.reviewTasks) {
      if (task.completed ||
          task.classNumber != evidence.classNumber ||
          task.competencyId != evidence.competencyId) {
        continue;
      }
      final due = task.dueAt;
      if (due != null && !due.isAfter(recordedAt)) {
        return evidence.copyWith(kind: LearningAttemptKind.review);
      }
    }
    return evidence;
  }

  LearningProfileState refreshReviewStates(
    LearningProfileState state,
    DateTime now,
  ) {
    final mastery = Map<String, SkillMastery>.from(state.skillMastery);
    final tasks = <ReviewTask>[...state.reviewTasks];
    var changed = false;

    for (final entry in mastery.entries.toList()) {
      var skill = entry.value;
      final latestEvidence = _latestEvidenceFor(
        state.attemptEvidence,
        skill.competencyId,
      );

      // Step 7 lazy compatibility: Step 6 treated the first successful delayed
      // review as terminal. Revive those secure skills into a bounded 30-day
      // maintenance loop without a save-schema migration.
      if (skill.state == LearningEvidenceState.secure &&
          skill.nextReviewIso == null &&
          latestEvidence != null) {
        final from = DateTime.tryParse(latestEvidence.recordedAtIso) ?? now;
        final maintenance = reviewScheduler.scheduleMaintenance(
          competencyId: skill.competencyId,
          classNumber: latestEvidence.classNumber,
          from: from,
          sourceItemId: latestEvidence.itemId,
        );
        final index = tasks.indexWhere(
          (candidate) => candidate.id == maintenance.id,
        );
        if (index >= 0) {
          tasks[index] = maintenance;
        } else {
          tasks.add(maintenance);
        }
        skill = skill.copyWith(nextReviewIso: maintenance.dueIso);
        mastery[entry.key] = skill;
        changed = true;
      } else if (skill.nextReviewIso != null && latestEvidence != null) {
        final id = 'review:${latestEvidence.classNumber}:${skill.competencyId}';
        final activeIndex = tasks.indexWhere(
          (candidate) => candidate.id == id && !candidate.completed,
        );
        if (activeIndex < 0) {
          final legacyIndex =
              tasks.indexWhere((candidate) => candidate.id == id);
          final intervalIndex = legacyIndex >= 0
              ? tasks[legacyIndex].intervalIndex
              : ReviewScheduler.intervalsDays.length - 1;
          final replacement = ReviewTask(
            id: id,
            competencyId: skill.competencyId,
            classNumber: latestEvidence.classNumber,
            dueIso: skill.nextReviewIso!,
            intervalIndex: intervalIndex,
            sourceItemId: latestEvidence.itemId,
          );
          if (legacyIndex >= 0) {
            tasks[legacyIndex] = replacement;
          } else {
            tasks.add(replacement);
          }
          changed = true;
        }
      }

      final due = skill.nextReviewIso == null
          ? null
          : DateTime.tryParse(skill.nextReviewIso!);
      if (due != null &&
          !due.isAfter(now) &&
          (skill.state == LearningEvidenceState.masteredNow ||
              skill.state == LearningEvidenceState.secure)) {
        mastery[entry.key] = skill.copyWith(
          state: LearningEvidenceState.reviewDue,
        );
        changed = true;
      }
    }
    if (!changed) return state;
    return state.copyWith(
      reviewTasks: List<ReviewTask>.unmodifiable(tasks),
      skillMastery: Map<String, SkillMastery>.unmodifiable(mastery),
    );
  }

  AttemptEvidence? _latestEvidenceFor(
    Iterable<AttemptEvidence> evidence,
    String competencyId,
  ) {
    AttemptEvidence? latest;
    DateTime? latestAt;
    for (final item in evidence) {
      if (item.competencyId != competencyId) continue;
      final at = DateTime.tryParse(item.recordedAtIso);
      if (latest == null ||
          (at != null && (latestAt == null || at.isAfter(latestAt)))) {
        latest = item;
        latestAt = at;
      }
    }
    return latest;
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
