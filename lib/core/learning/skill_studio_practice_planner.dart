import '../content/content_activity.dart';
import '../content/content_repository.dart';
import 'gameplay_activity_resolver.dart';
import 'learning_models.dart';
import 'mission_content_signature.dart';
import 'mission_exposure_memory.dart';
import 'mission_run_models.dart';

/// One adaptive direct-practice allocation for Class Skill Studio.
///
/// This is deliberately a selection plan, not a second progress model. Mastery,
/// scoring and review scheduling remain owned by the existing evidence engine.
class SkillStudioPracticePlan {
  const SkillStudioPracticePlan({
    required this.classNumber,
    required this.competencyId,
    required this.runSeed,
    required this.runId,
    required this.activityIds,
    required this.candidateCount,
    required this.freshCandidateCount,
    required this.selectionReason,
  });

  final int classNumber;
  final String competencyId;
  final int runSeed;
  final String runId;

  /// Ordered fresh-first response activities. LessonEngine maps these into
  /// guided, independent, transfer and exit roles without changing answers.
  final List<String> activityIds;
  final int candidateCount;
  final int freshCandidateCount;
  final String selectionReason;

  String? activityIdAt(int index) =>
      index >= 0 && index < activityIds.length ? activityIds[index] : null;
}

/// Shared-history Skill Studio selector.
///
/// Guarantees when alternatives exist:
/// * the recently seen visible prompt is deprioritized before an unseen one;
/// * exact item reuse is deprioritized across previous Skill Studio attempts;
/// * the selected set maximizes prompt/mechanic/topic diversity;
/// * stronger mastery can prefer the harder authored check without inventing
///   curriculum content or changing the authored scoring rule.
class SkillStudioPracticePlanner {
  const SkillStudioPracticePlanner({
    this.activityResolver = const GameplayActivityResolver(),
  });

  final GameplayActivityResolver activityResolver;

  SkillStudioPracticePlan plan({
    required ContentRepository repository,
    required int classNumber,
    required String competencyId,
    required MissionExposureHistory history,
    required LearningProfileState learningState,
    int? runSeed,
  }) {
    if (classNumber < 3 || classNumber > 5) {
      throw ArgumentError.value(classNumber, 'classNumber');
    }

    final evidence = learningState.attemptEvidence
        .where(
          (item) =>
              item.classNumber == classNumber &&
              item.competencyId == competencyId &&
              item.itemId.trim().isNotEmpty,
        )
        .toList(growable: false)
      ..sort((a, b) => _timeOf(b).compareTo(_timeOf(a)));
    final recentEvidenceIds = evidence.map((item) => item.itemId).toList();
    final seed = runSeed ??
        _stableScore(
          '$classNumber|$competencyId|${history.activityKeys.join('~')}|'
          '${history.contentFingerprints.join('~')}|${evidence.length}',
        );
    final candidates = <ContentActivity>[
      ...repository.activitiesForCompetency(classNumber, competencyId),
      ...repository.generatedSkillStudioPracticeForCompetency(
        classNumber,
        competencyId,
        seedBase: seed,
      ),
    ]
        .where(
          (activity) =>
              activity.classNumber == classNumber &&
              activity.allCompetencyIds.contains(competencyId) &&
              !_isFallbackExperiment(activity) &&
              activityResolver.resolve(activity).isSupported,
        )
        .fold<List<ContentActivity>>(<ContentActivity>[], (result, activity) {
      if (!result.any((candidate) => candidate.id == activity.id)) {
        result.add(activity);
      }
      return result;
    });
    if (candidates.isEmpty) {
      throw StateError(
        'No supported Skill Studio activities for Class $classNumber / '
        '$competencyId.',
      );
    }

    final mastery = learningState.skillMastery[competencyId];
    final preferChallenge = mastery != null &&
        (mastery.state == LearningEvidenceState.masteredNow ||
            mastery.state == LearningEvidenceState.reviewDue ||
            mastery.state == LearningEvidenceState.secure ||
            mastery.confidence >= 0.75);

    final freshCandidateCount = candidates
        .map(missionActivityFingerprint)
        .where(
          (fingerprint) => !history.contentFingerprints.contains(fingerprint),
        )
        .toSet()
        .length;
    final visiblePoolExhausted = freshCandidateCount == 0;
    final hasPriorExposure = history.activityKeys.isNotEmpty ||
        history.contentFingerprints.isNotEmpty ||
        recentEvidenceIds.isNotEmpty;
    final remaining = List<ContentActivity>.from(candidates);
    final selected = <ContentActivity>[];
    final selectedFingerprints = <String>{};
    final selectedTopics = <String>{};
    final selectedMechanics = <String>{};

    while (remaining.isNotEmpty && selected.length < 4) {
      remaining.sort((a, b) {
        final aFingerprint = missionActivityFingerprint(a);
        final bFingerprint = missionActivityFingerprint(b);

        // When every reviewed example has already been seen, the set may need
        // to return as honest spaced review. Do not, however, restart that
        // review with the exact same first item when another item exists.
        // Skill Studio exposure records are stored most-recent-first, so the
        // previous round's first response is the last matching activity key.
        if (visiblePoolExhausted &&
            selected.isEmpty &&
            history.activityKeys.isNotEmpty) {
          final previousFirstKey = history.activityKeys.last;
          final previousFirst =
              (previousFirstKey.endsWith('|${a.id}') ? 1 : 0).compareTo(
            previousFirstKey.endsWith('|${b.id}') ? 1 : 0,
          );
          if (previousFirst != 0) return previousFirst;
        }

        final visible = _skillRecentPenalty(
          history.contentFingerprints,
          aFingerprint,
          poolExhausted: visiblePoolExhausted,
        ).compareTo(
          _skillRecentPenalty(
            history.contentFingerprints,
            bFingerprint,
            poolExhausted: visiblePoolExhausted,
          ),
        );
        if (visible != 0) return visible;

        final exactEvidence = _skillRecentPenalty(
          recentEvidenceIds,
          a.id,
          poolExhausted: visiblePoolExhausted,
        ).compareTo(
          _skillRecentPenalty(
            recentEvidenceIds,
            b.id,
            poolExhausted: visiblePoolExhausted,
          ),
        );
        if (exactEvidence != 0) return exactEvidence;

        // Prefer the dedicated Skill Studio authoring lane, but never at the
        // cost of immediate visible repetition when another valid competency
        // activity exists.
        final studio = _studioPriority(b).compareTo(_studioPriority(a));
        if (studio != 0) return studio;

        final challenge = _difficultyPriority(
          b,
          preferChallenge: preferChallenge,
        ).compareTo(
          _difficultyPriority(a, preferChallenge: preferChallenge),
        );
        if (challenge != 0) return challenge;

        final aSpec = activityResolver.resolve(a);
        final bSpec = activityResolver.resolve(b);
        final fingerprintDiversity =
            (selectedFingerprints.contains(aFingerprint) ? 1 : 0).compareTo(
          selectedFingerprints.contains(bFingerprint) ? 1 : 0,
        );
        if (fingerprintDiversity != 0) return fingerprintDiversity;
        final topicDiversity =
            (selectedTopics.contains(a.topicId) ? 1 : 0).compareTo(
          selectedTopics.contains(b.topicId) ? 1 : 0,
        );
        if (topicDiversity != 0) return topicDiversity;
        final mechanicDiversity =
            (selectedMechanics.contains(aSpec.mechanic.name) ? 1 : 0)
                .compareTo(
          selectedMechanics.contains(bSpec.mechanic.name) ? 1 : 0,
        );
        if (mechanicDiversity != 0) return mechanicDiversity;

        if (!hasPriorExposure) return a.id.compareTo(b.id);

        final stable = _stableScore('$seed|${a.id}').compareTo(
          _stableScore('$seed|${b.id}'),
        );
        return stable != 0 ? stable : a.id.compareTo(b.id);
      });

      final chosen = remaining.removeAt(0);
      selected.add(chosen);
      selectedFingerprints.add(missionActivityFingerprint(chosen));
      selectedTopics.add(chosen.topicId);
      selectedMechanics.add(activityResolver.resolve(chosen).mechanic.name);
    }

    final generatedCandidateCount =
        candidates.where((activity) => activity.generation.mode == 'generated').length;
    final reason = freshCandidateCount > 0
        ? generatedCandidateCount > 0
            ? 'Fresh competency examples first; safe generated drills extend this skill while recent wording stays spaced.'
            : 'Fresh competency examples first; recent wording is spaced for later review.'
        : 'Recent pool exhausted; least-recent competency examples are returning as review.';
    final runId = 'skill:$classNumber:$competencyId:$seed:'
        '${selected.map((item) => item.id).join(',')}';
    return SkillStudioPracticePlan(
      classNumber: classNumber,
      competencyId: competencyId,
      runSeed: seed,
      runId: runId,
      activityIds: List<String>.unmodifiable(
        selected.map((item) => item.id),
      ),
      candidateCount: candidates.length,
      freshCandidateCount: freshCandidateCount,
      selectionReason: reason,
    );
  }

  List<MissionExposureRecord> exposureRecords({
    required ContentRepository repository,
    required SkillStudioPracticePlan plan,
    required DateTime seenAt,
  }) {
    final records = <MissionExposureRecord>[];
    final seenIds = <String>{};
    for (var index = 0; index < plan.activityIds.length; index += 1) {
      final activity = repository.activityById(plan.activityIds[index]);
      if (activity == null ||
          activity.classNumber != plan.classNumber ||
          !activity.allCompetencyIds.contains(plan.competencyId) ||
          !seenIds.add(activity.id)) {
        continue;
      }
      final spec = activityResolver.resolve(activity);
      if (!spec.isSupported) continue;
      final timestamp = seenAt.subtract(
        Duration(microseconds: plan.activityIds.length - 1 - index),
      );
      records.add(
        MissionExposureRecord(
          classNumber: plan.classNumber,
          levelId: 'skill:${plan.competencyId}',
          gameId: 'skill_studio',
          activityKey: '${plan.classNumber}|skill_studio|${activity.id}',
          archetypeId: missionArchetypeId(activity, spec),
          mechanicName: spec.mechanic.name,
          roleName: MissionRunRole.training.name,
          runSeed: plan.runSeed,
          seenAtIso: timestamp.toUtc().toIso8601String(),
          contentFingerprint: missionActivityFingerprint(activity),
          topicId: activity.topicId,
          competencyId: plan.competencyId,
          difficulty: activity.difficulty,
        ),
      );
    }
    return List<MissionExposureRecord>.unmodifiable(records);
  }

  int _studioPriority(ContentActivity activity) =>
      activity.gameId == 'skill_studio' ? 100 : 0;

  int _difficultyPriority(
    ContentActivity activity, {
    required bool preferChallenge,
  }) {
    if (preferChallenge) return activity.difficulty;
    return 10 - activity.difficulty;
  }

  int _skillRecentPenalty<T>(
    List<T> mostRecentFirst,
    T value, {
    required bool poolExhausted,
  }) {
    final index = mostRecentFirst.indexOf(value);
    if (index < 0) return 0;
    if (!poolExhausted) return 100000 - index.clamp(0, 99999).toInt();
    // Once every visible example has been seen, keep the entire previous
    // four-response Skill Studio set as a hard boundary when alternatives
    // exist. Older examples can then return as intentional spaced review.
    return index < 4 ? 100000 - index : 100;
  }

  DateTime _timeOf(AttemptEvidence evidence) =>
      DateTime.tryParse(evidence.recordedAtIso) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  int _stableScore(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  bool _isFallbackExperiment(ContentActivity activity) =>
      activity.correctResponseRule['type'] == 'experimentOutcome' &&
      activity.payload['fallback'] == true;
}
