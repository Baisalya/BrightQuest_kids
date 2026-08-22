import '../learning/learning_models.dart';
import 'nursery_learning_models.dart';

class NurseryProgressEngine {
  const NurseryProgressEngine({
    this.maxEvidencePerProfile = 1600,
    this.masteryConfidenceThreshold = 0.72,
  });

  static const List<int> reviewIntervalsDays = <int>[1, 3, 7, 14, 30];

  final int maxEvidencePerProfile;
  final double masteryConfidenceThreshold;

  NurseryLearningState record(
    NurseryLearningState state,
    NurseryAttemptEvidence evidence,
  ) {
    final values = <NurseryAttemptEvidence>[...state.attemptEvidence, evidence];
    if (values.length > maxEvidencePerProfile) {
      values.removeRange(0, values.length - maxEvidencePerProfile);
    }

    if (!evidence.contributesToMastery) {
      return state.copyWith(
        attemptEvidence: List<NurseryAttemptEvidence>.unmodifiable(values),
      );
    }

    final mastery = Map<String, NurserySkillMastery>.from(state.skillMastery);
    final current = mastery[evidence.skillId] ??
        NurserySkillMastery(skillId: evidence.skillId);
    final tasks = <NurseryReviewTask>[...state.reviewTasks];
    final reviewIndex = tasks.indexWhere(
      (candidate) =>
          candidate.skillId == evidence.skillId && !candidate.completed,
    );
    final reviewIsDue = evidence.kind == LearningAttemptKind.review &&
        reviewIndex >= 0 &&
        _isDueAtEvidenceTime(tasks[reviewIndex], evidence);

    var next = _updateMastery(
      current,
      evidence,
      values,
      delayedReviewEligible: reviewIsDue,
    );

    if (next.state == LearningEvidenceState.masteredNow &&
        current.state != LearningEvidenceState.masteredNow &&
        current.state != LearningEvidenceState.reviewDue &&
        current.state != LearningEvidenceState.secure) {
      final task = _scheduleFirst(evidence);
      final index = tasks.indexWhere((candidate) => candidate.id == task.id);
      if (index >= 0) {
        tasks[index] = task;
      } else {
        tasks.add(task);
      }
      next = next.copyWith(nextReviewIso: task.dueIso);
    } else if (reviewIsDue && reviewIndex >= 0) {
      final task = _reschedule(tasks[reviewIndex], evidence);
      if (next.state == LearningEvidenceState.secure) {
        tasks[reviewIndex] = task.copyWith(completed: true);
        next = next.copyWith(clearNextReviewIso: true);
      } else {
        tasks[reviewIndex] = task;
        next = next.copyWith(nextReviewIso: task.dueIso);
      }
    }

    mastery[evidence.skillId] = next;
    return state.copyWith(
      attemptEvidence: List<NurseryAttemptEvidence>.unmodifiable(values),
      skillMastery: Map<String, NurserySkillMastery>.unmodifiable(mastery),
      reviewTasks: List<NurseryReviewTask>.unmodifiable(tasks),
    );
  }

  NurseryLearningState refreshReviewStates(
    NurseryLearningState state,
    DateTime now,
  ) {
    final mastery = Map<String, NurserySkillMastery>.from(state.skillMastery);
    var changed = false;
    for (final entry in mastery.entries.toList()) {
      final current = entry.value;
      final due = current.nextReviewIso == null
          ? null
          : DateTime.tryParse(current.nextReviewIso!);
      if (due != null &&
          !due.isAfter(now) &&
          current.state == LearningEvidenceState.masteredNow) {
        mastery[entry.key] =
            current.copyWith(state: LearningEvidenceState.reviewDue);
        changed = true;
      }
    }
    return changed
        ? state.copyWith(
            skillMastery:
                Map<String, NurserySkillMastery>.unmodifiable(mastery),
          )
        : state;
  }

  List<NurseryReviewTask> dueTasks(
    NurseryLearningState state, {
    required DateTime now,
    int limit = 10,
  }) {
    final day = DateTime(now.year, now.month, now.day);
    final tasks = state.reviewTasks.where((task) {
      if (task.completed) return false;
      final dueAt = task.dueAt;
      if (dueAt == null) return false;
      final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
      return !dueDay.isAfter(day);
    }).toList()
      ..sort((a, b) => a.dueIso.compareTo(b.dueIso));
    return List<NurseryReviewTask>.unmodifiable(
      tasks.take(limit.clamp(0, 10).toInt()),
    );
  }

  NurserySkillMastery _updateMastery(
    NurserySkillMastery current,
    NurseryAttemptEvidence evidence,
    List<NurseryAttemptEvidence> allEvidence, {
    required bool delayedReviewEligible,
  }) {
    final count = current.scorableEvidenceCount + 1;
    final correct = current.correctCount + (evidence.correct ? 1 : 0);
    final sameSkill = allEvidence.where(
      (candidate) =>
          candidate.skillId == evidence.skillId &&
          candidate.contributesToMastery,
    );
    final independent = sameSkill
        .where((candidate) => candidate.cleanIndependent)
        .map((candidate) => candidate.itemId)
        .toSet()
        .length;
    final transfer = sameSkill
        .where((candidate) => candidate.cleanTransfer)
        .map((candidate) => candidate.itemId)
        .toSet()
        .length;
    final review = current.cleanDelayedReviewSuccesses +
        (delayedReviewEligible && evidence.cleanReview ? 1 : 0);
    final misconceptions = Map<String, int>.from(current.misconceptionCounts);
    if (!evidence.correct &&
        evidence.misconceptionId != null &&
        evidence.misconceptionId!.isNotEmpty) {
      misconceptions[evidence.misconceptionId!] =
          (misconceptions[evidence.misconceptionId!] ?? 0) + 1;
    }

    final accuracy = count == 0 ? 0.0 : correct / count;
    final confidence = ((independent.clamp(0, 2) / 2) * 0.44 +
            transfer.clamp(0, 1) * 0.28 +
            review.clamp(0, 1) * 0.16 +
            accuracy * 0.12)
        .clamp(0.0, 1.0)
        .toDouble();

    final provisional = current.copyWith(
      scorableEvidenceCount: count,
      correctCount: correct,
      cleanIndependentCorrectCount: independent,
      cleanTransferCorrectCount: transfer,
      cleanDelayedReviewSuccesses: review,
      confidence: confidence,
      lastEvidenceIso: evidence.recordedAtIso,
      misconceptionCounts: Map<String, int>.unmodifiable(misconceptions),
    );
    return provisional.copyWith(state: _classify(provisional));
  }

  LearningEvidenceState _classify(NurserySkillMastery mastery) {
    if (mastery.scorableEvidenceCount == 0) {
      return LearningEvidenceState.notStarted;
    }
    if (mastery.scorableEvidenceCount >= 3 && mastery.accuracy < 0.45) {
      return LearningEvidenceState.needsSupport;
    }
    if (mastery.cleanIndependentCorrectCount >= 2 &&
        mastery.cleanTransferCorrectCount >= 1 &&
        mastery.cleanDelayedReviewSuccesses >= 1 &&
        mastery.confidence >= masteryConfidenceThreshold) {
      return LearningEvidenceState.secure;
    }
    if (mastery.cleanIndependentCorrectCount >= 2 &&
        mastery.cleanTransferCorrectCount >= 1 &&
        mastery.confidence >= masteryConfidenceThreshold) {
      return LearningEvidenceState.masteredNow;
    }
    if (mastery.correctCount > 0) return LearningEvidenceState.practising;
    return LearningEvidenceState.introduced;
  }

  bool _isDueAtEvidenceTime(
    NurseryReviewTask task,
    NurseryAttemptEvidence evidence,
  ) {
    final due = task.dueAt;
    final recorded = DateTime.tryParse(evidence.recordedAtIso);
    if (due == null || recorded == null) return false;
    return !recorded.isBefore(due);
  }

  NurseryReviewTask _scheduleFirst(NurseryAttemptEvidence evidence) {
    final now = DateTime.tryParse(evidence.recordedAtIso) ?? DateTime.now();
    return _task(evidence.skillId, evidence.itemId, now, 0);
  }

  NurseryReviewTask _reschedule(
    NurseryReviewTask current,
    NurseryAttemptEvidence evidence,
  ) {
    var index = current.intervalIndex;
    if (evidence.correct && evidence.clean) {
      index = (index + 1).clamp(0, reviewIntervalsDays.length - 1).toInt();
    } else if (!evidence.correct) {
      index = (index - 1).clamp(0, reviewIntervalsDays.length - 1).toInt();
    }
    final now = DateTime.tryParse(evidence.recordedAtIso) ?? DateTime.now();
    return _task(current.skillId, current.sourceItemId, now, index);
  }

  NurseryReviewTask _task(
    String skillId,
    String sourceItemId,
    DateTime now,
    int intervalIndex,
  ) {
    final safe = intervalIndex.clamp(0, reviewIntervalsDays.length - 1).toInt();
    final day = DateTime(now.year, now.month, now.day)
        .add(Duration(days: reviewIntervalsDays[safe]));
    return NurseryReviewTask(
      id: 'nursery-review:$skillId',
      packId: 'brightquest_nursery',
      skillId: skillId,
      dueIso: day.toIso8601String(),
      intervalIndex: safe,
      sourceItemId: sourceItemId,
    );
  }
}
