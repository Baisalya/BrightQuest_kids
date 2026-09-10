import '../content/content_activity.dart';
import '../content/content_repository.dart';
import 'evidence_engine.dart';
import 'learning_models.dart';
import 'mission_content_signature.dart';

class DiagnosticEngine {
  const DiagnosticEngine({this.targetItemCount = 12});

  final int targetItemCount;

  DiagnosticProgress start({
    required ContentRepository repository,
    required int classNumber,
    required DateTime now,
    Iterable<String> recentItemIds = const <String>[],
    Iterable<String> recentContentFingerprints = const <String>[],
  }) {
    final activities = _selectActivities(
      repository,
      classNumber,
      recentItemIds: recentItemIds,
      recentContentFingerprints: recentContentFingerprints,
    );
    return DiagnosticProgress(
      classNumber: classNumber,
      itemIds: activities.map((item) => item.id).toList(growable: false),
      currentIndex: 0,
      startedAtIso: now.toIso8601String(),
    );
  }

  List<ContentActivity> _selectActivities(
    ContentRepository repository,
    int classNumber, {
    required Iterable<String> recentItemIds,
    required Iterable<String> recentContentFingerprints,
  }) {
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

    final recentIds = recentItemIds.toList(growable: false);
    final recentFingerprints =
        recentContentFingerprints.toList(growable: false);
    final chosen = <ContentActivity>[];
    final competencyOrder = <String>[];
    for (final activity in all) {
      if (!competencyOrder.contains(activity.competencyId)) {
        competencyOrder.add(activity.competencyId);
      }
    }
    for (final competencyId in competencyOrder) {
      final options = all
          .where((activity) => activity.competencyId == competencyId)
          .toList(growable: true)
        ..sort((a, b) => _freshnessCompare(
              a,
              b,
              recentIds: recentIds,
              recentFingerprints: recentFingerprints,
            ));
      if (options.isNotEmpty) chosen.add(options.first);
      if (chosen.length >= targetItemCount) break;
    }
    if (chosen.length < targetItemCount) {
      final remainder = all
          .where((activity) =>
              !chosen.any((candidate) => candidate.id == activity.id))
          .toList(growable: true)
        ..sort((a, b) => _freshnessCompare(
              a,
              b,
              recentIds: recentIds,
              recentFingerprints: recentFingerprints,
            ));
      for (final activity in remainder) {
        chosen.add(activity);
        if (chosen.length >= targetItemCount) break;
      }
    }
    return List<ContentActivity>.unmodifiable(chosen);
  }

  int _freshnessCompare(
    ContentActivity a,
    ContentActivity b, {
    required List<String> recentIds,
    required List<String> recentFingerprints,
  }) {
    final visible = _recentPenalty(
      recentFingerprints,
      missionActivityFingerprint(a),
    ).compareTo(
      _recentPenalty(recentFingerprints, missionActivityFingerprint(b)),
    );
    if (visible != 0) return visible;
    final exact = _recentPenalty(recentIds, a.id).compareTo(
      _recentPenalty(recentIds, b.id),
    );
    if (exact != 0) return exact;
    final subject = a.subject.compareTo(b.subject);
    if (subject != 0) return subject;
    final competency = a.competencyId.compareTo(b.competencyId);
    if (competency != 0) return competency;
    final difficulty = a.difficulty.compareTo(b.difficulty);
    if (difficulty != 0) return difficulty;
    return a.id.compareTo(b.id);
  }

  int _recentPenalty<T>(List<T> mostRecentFirst, T value) {
    final index = mostRecentFirst.indexOf(value);
    return index < 0 ? 0 : 100000 - index.clamp(0, 99999).toInt();
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
