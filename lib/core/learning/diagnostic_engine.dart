import '../content/content_activity.dart';
import '../content/content_repository.dart';
import 'evidence_engine.dart';
import 'learning_models.dart';

class DiagnosticEngine {
  const DiagnosticEngine({this.targetItemCount = 12});

  final int targetItemCount;

  DiagnosticProgress start({
    required ContentRepository repository,
    required int classNumber,
    required DateTime now,
  }) {
    final activities = _selectActivities(repository, classNumber);
    return DiagnosticProgress(
      classNumber: classNumber,
      itemIds: activities.map((item) => item.id).toList(growable: false),
      currentIndex: 0,
      startedAtIso: now.toIso8601String(),
    );
  }

  List<ContentActivity> _selectActivities(
    ContentRepository repository,
    int classNumber,
  ) {
    final all = repository
        .activitiesForClass(classNumber)
        .where(_supportsDiagnosticInteraction)
        .toList();
    all.sort((a, b) {
      final subjectOrder = a.subject.compareTo(b.subject);
      if (subjectOrder != 0) return subjectOrder;
      final competencyOrder = a.competencyId.compareTo(b.competencyId);
      if (competencyOrder != 0) return competencyOrder;
      final difficultyOrder = a.difficulty.compareTo(b.difficulty);
      if (difficultyOrder != 0) return difficultyOrder;
      return a.id.compareTo(b.id);
    });

    final chosen = <ContentActivity>[];
    final seenCompetencies = <String>{};
    for (final activity in all) {
      if (seenCompetencies.add(activity.competencyId)) {
        chosen.add(activity);
        if (chosen.length >= targetItemCount) break;
      }
    }
    if (chosen.length < targetItemCount) {
      for (final activity in all) {
        if (chosen.any((candidate) => candidate.id == activity.id)) continue;
        chosen.add(activity);
        if (chosen.length >= targetItemCount) break;
      }
    }
    return List<ContentActivity>.unmodifiable(chosen);
  }

  bool _supportsDiagnosticInteraction(ContentActivity activity) {
    if (activity.payload['masteryEligible'] == false) return false;
    final choices = activity.payload['choices'];
    final answer =
        activity.correctResponseRule['value'] ?? activity.payload['answer'];
    return choices is List && choices.length >= 2 && answer != null;
  }

  ContentActivity? currentActivity(
    ContentRepository repository,
    DiagnosticProgress progress,
  ) {
    if (!progress.started || progress.completed) return null;
    if (progress.currentIndex < 0 ||
        progress.currentIndex >= progress.itemIds.length) {
      return null;
    }
    return repository.activityById(progress.itemIds[progress.currentIndex]);
  }

  DiagnosticProgress advance(
    DiagnosticProgress progress, {
    required DateTime now,
  }) {
    final next = progress.currentIndex + 1;
    if (next >= progress.itemIds.length) {
      return progress.copyWith(
        currentIndex: progress.itemIds.length,
        completedAtIso: now.toIso8601String(),
      );
    }
    return progress.copyWith(currentIndex: next);
  }

  Map<String, DiagnosticBand> classify(
    Iterable<AttemptEvidence> allEvidence,
  ) {
    final byCompetency = <String, List<AttemptEvidence>>{};
    for (final evidence in allEvidence) {
      if (evidence.kind != LearningAttemptKind.diagnostic) continue;
      byCompetency
          .putIfAbsent(evidence.competencyId, () => <AttemptEvidence>[])
          .add(evidence);
    }
    const engine = EvidenceEngine();
    return <String, DiagnosticBand>{
      for (final entry in byCompetency.entries)
        entry.key: engine.diagnosticBandFor(entry.value),
    };
  }
}
