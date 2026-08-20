import 'learning_models.dart';

class ReviewScheduler {
  const ReviewScheduler();

  static const List<int> intervalsDays = <int>[1, 3, 7, 14, 30];

  ReviewTask scheduleFirst({
    required String competencyId,
    required int classNumber,
    required DateTime now,
    String? sourceItemId,
    double evidenceQuality = 1,
  }) {
    final intervalIndex = evidenceQuality >= 0.85 ? 1 : 0;
    return _task(
      competencyId: competencyId,
      classNumber: classNumber,
      now: now,
      intervalIndex: intervalIndex,
      sourceItemId: sourceItemId,
    );
  }

  ReviewTask reschedule({
    required ReviewTask task,
    required DateTime now,
    required bool correct,
    required bool independent,
  }) {
    var nextIndex = task.intervalIndex;
    if (correct && independent) {
      nextIndex =
          (task.intervalIndex + 1).clamp(0, intervalsDays.length - 1).toInt();
    } else if (!correct) {
      nextIndex =
          (task.intervalIndex - 1).clamp(0, intervalsDays.length - 1).toInt();
    }
    return _task(
      competencyId: task.competencyId,
      classNumber: task.classNumber,
      now: now,
      intervalIndex: nextIndex,
      sourceItemId: task.sourceItemId,
    );
  }

  ReviewTask _task({
    required String competencyId,
    required int classNumber,
    required DateTime now,
    required int intervalIndex,
    String? sourceItemId,
  }) {
    final safeIndex = intervalIndex.clamp(0, intervalsDays.length - 1).toInt();
    final due = DateTime(now.year, now.month, now.day)
        .add(Duration(days: intervalsDays[safeIndex]));
    return ReviewTask(
      id: 'review:$classNumber:$competencyId',
      competencyId: competencyId,
      classNumber: classNumber,
      dueIso: due.toIso8601String(),
      intervalIndex: safeIndex,
      sourceItemId: sourceItemId,
    );
  }

  List<ReviewTask> dueTasks(
    Iterable<ReviewTask> tasks, {
    required int classNumber,
    required DateTime now,
    int limit = 10,
  }) {
    final day = DateTime(now.year, now.month, now.day);
    final due = tasks.where((task) {
      if (task.classNumber != classNumber || task.completed) return false;
      final dueAt = task.dueAt;
      if (dueAt == null) return false;
      final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
      return !dueDay.isAfter(day);
    }).toList();
    due.sort((a, b) {
      final timeOrder = a.dueIso.compareTo(b.dueIso);
      return timeOrder != 0
          ? timeOrder
          : a.competencyId.compareTo(b.competencyId);
    });
    return List<ReviewTask>.unmodifiable(
      due.take(limit.clamp(0, 10).toInt()).toList(),
    );
  }
}
