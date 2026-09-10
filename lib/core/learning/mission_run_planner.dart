import '../content/content_activity.dart';
import '../content/content_repository.dart';
import '../curriculum/curriculum_models.dart';
import 'gameplay_activity_models.dart';
import 'gameplay_activity_resolver.dart';
import 'mission_balance_policy.dart';
import 'mission_content_signature.dart';
import 'mission_run_models.dart';
import 'mission_variety_models.dart';

/// Central content-selection boundary for a Learning World run.
///
/// The planner is deliberately renderer-neutral and does not score answers,
/// mutate progress, infer facts from prompt text, or change authored response
/// rules. It only selects among activities already exposed by the repository
/// and the existing deterministic generators.
class MissionRunPlanner {
  const MissionRunPlanner({
    this.activityResolver = const GameplayActivityResolver(),
    this.balancePolicy = const MissionBalancePolicy(),
  });

  final GameplayActivityResolver activityResolver;
  final MissionBalancePolicy balancePolicy;

  MissionRunPlan planForLevel({
    required ContentRepository repository,
    required LearningLevel level,
    required MissionRunRequest request,
  }) {
    final candidates = candidatesForLevel(
      repository: repository,
      level: level,
      includeGeneratedPractice: request.includeGeneratedPractice,
    );
    if (candidates.isEmpty) {
      throw StateError(
        'No supported ${level.gameId} mission candidates for ${level.id} at '
        'difficulty ${level.difficulty}.',
      );
    }

    final trainingEligible = candidates
        .where(
          (candidate) =>
              request.trainingMechanics.isEmpty ||
              request.trainingMechanics.contains(candidate.mechanic),
        )
        .toList(growable: false);
    final gameEligible = candidates
        .where(
          (candidate) =>
              request.gameMechanics.isEmpty ||
              request.gameMechanics.contains(candidate.mechanic),
        )
        .toList(growable: false);
    final gameEligibleKeys =
        gameEligible.map((candidate) => candidate.stableKey).toSet();
    // Protect at least one representative of each viable game topic before
    // Training allocation. Without this reservation, authored-first Training
    // can consume the only minority-topic items and leave the Real Game with a
    // one-topic run even though the exact-tier pool contained alternatives.
    final reservedGameTopicKeys = _reservedGameTopicKeys(
      pool: gameEligible,
      count: request.gameItemCount,
      runSeed: request.runSeed,
    );

    // Reserve candidates that the real-game renderer can consume. When a
    // family has a Training-only mechanic (Science Lab experiment simulation),
    // use that first instead of consuming a scarce quiz question. Reviewed
    // authored content remains a soft Training preference, not a hard group,
    // so evidence cooldown/freshness can choose a different valid concept.
    final training = <MissionCandidate>[];
    void fillTrainingFrom(
      Iterable<MissionCandidate> values,
      String seedSalt,
    ) {
      if (training.length >= request.trainingItemCount) return;
      final selectedKeys = training.map((item) => item.stableKey).toSet();
      final uniquePool = values
          .where((item) => !selectedKeys.contains(item.stableKey))
          .toList(growable: false);
      training.addAll(
        _select(
          pool: uniquePool,
          count: request.trainingItemCount - training.length,
          runSeed: request.runSeed,
          seedSalt: seedSalt,
          history: request.history,
          role: MissionRunRole.training,
          selectionProfile: request.selectionProfile,
        ),
      );
    }

    final trainingOnly = trainingEligible
        .where((candidate) => !gameEligibleKeys.contains(candidate.stableKey))
        .toList(growable: false);
    fillTrainingFrom(trainingOnly, 'training-only');
    fillTrainingFrom(
      trainingEligible.where(
        (candidate) => !reservedGameTopicKeys.contains(candidate.stableKey),
      ),
      'training-balanced',
    );
    // Capacity wins over balance. If a small pool cannot fill Training without
    // touching a reserved representative, fall back to the complete eligible
    // pool rather than creating a content shortfall.
    fillTrainingFrom(trainingEligible, 'training-fallback');

    final trainingKeys =
        training.map((candidate) => candidate.stableKey).toSet();
    final strictGamePool = candidates
        .where(
          (candidate) =>
              !trainingKeys.contains(candidate.stableKey) &&
              (request.gameMechanics.isEmpty ||
                  request.gameMechanics.contains(candidate.mechanic)),
        )
        .toList(growable: false);
    final game = _select(
      pool: strictGamePool,
      count: request.gameItemCount,
      runSeed: request.runSeed,
      seedSalt: 'game',
      history: request.history,
      role: MissionRunRole.game,
      selectionProfile: request.selectionProfile,
    ).toList(growable: true);

    if (request.allowTrainingReuseWhenExhausted &&
        game.length < request.gameItemCount) {
      final selectedKeys = game.map((candidate) => candidate.stableKey).toSet();
      final fallbackPool = training
          .where(
            (candidate) =>
                !selectedKeys.contains(candidate.stableKey) &&
                (request.gameMechanics.isEmpty ||
                    request.gameMechanics.contains(candidate.mechanic)),
          )
          .toList(growable: false);
      final fallback = _select(
        pool: fallbackPool,
        count: request.gameItemCount - game.length,
        runSeed: request.runSeed,
        seedSalt: 'game-fallback',
        history: request.history,
        role: MissionRunRole.game,
        selectionProfile: request.selectionProfile,
      );
      game.addAll(fallback);
    }

    return MissionRunPlan(
      levelId: level.id,
      classNumber: level.classNumber,
      gameId: level.gameId,
      difficulty: level.difficulty,
      runSeed: request.runSeed,
      requestedTrainingItemCount: request.trainingItemCount,
      requestedGameItemCount: request.gameItemCount,
      trainingItems: List<PlannedMissionItem>.unmodifiable(
        <PlannedMissionItem>[
          for (var index = 0; index < training.length; index += 1)
            PlannedMissionItem(
              candidate: training[index],
              role: MissionRunRole.training,
              position: index,
            ),
        ],
      ),
      gameItems: List<PlannedMissionItem>.unmodifiable(
        <PlannedMissionItem>[
          for (var index = 0; index < game.length; index += 1)
            PlannedMissionItem(
              candidate: game[index],
              role: MissionRunRole.game,
              position: index,
            ),
        ],
      ),
      availableCandidateCount: candidates.length,
      selectionDemand: request.selectionProfile.demand.name,
      selectionReason: request.selectionProfile.reason,
    );
  }

  /// Builds one post-progression practice round without creating a fake
  /// curriculum level. Only deterministic generated content is used here so
  /// the child can keep practising after the three canonical levels are done.
  MissionRunPlan planEndlessPractice({
    required ContentRepository repository,
    required int classNumber,
    required String gameId,
    required int maxDifficulty,
    required MissionRunRequest request,
  }) {
    final candidates = candidatesForEndlessPractice(
      repository: repository,
      classNumber: classNumber,
      gameId: gameId,
      maxDifficulty: maxDifficulty,
      runSeed: request.runSeed,
    );
    if (candidates.isEmpty) {
      throw StateError(
        'No generated Endless Practice candidates for $gameId / Class $classNumber.',
      );
    }

    final recentFingerprints = <String>{...request.history.contentFingerprints};
    final immediateFingerprints = <String>{};
    var matchingHistoryItems = 0;
    for (final key in request.history.activityKeys) {
      final parts = key.split('|');
      if (parts.length < 3) continue;
      final historyClass = int.tryParse(parts.first);
      if (historyClass == null ||
          historyClass != classNumber ||
          parts[1] != gameId) {
        continue;
      }
      final legacyId = parts.sublist(2).join('|');
      final activity = repository.activityForLegacyContent(
        classNumber: classNumber,
        gameId: gameId,
        legacyContentId: legacyId,
      );
      if (activity != null) {
        final fingerprint = missionActivityFingerprint(activity);
        recentFingerprints.add(fingerprint);
        // History is most-recent-first. The first completed Endless round is a
        // hard no-repeat boundary; older history stays a soft freshness signal.
        if (matchingHistoryItems < request.gameItemCount) {
          immediateFingerprints.add(fingerprint);
        }
        matchingHistoryItems += 1;
      }
    }

    final fresh = candidates
        .where((candidate) =>
            !recentFingerprints.contains(candidate.contentFingerprint))
        .toList(growable: false);
    final immediateSafe = candidates
        .where((candidate) =>
            !immediateFingerprints.contains(candidate.contentFingerprint))
        .toList(growable: false);
    final pool = fresh.length >= request.gameItemCount
        ? fresh
        : immediateSafe.length >= request.gameItemCount
            ? immediateSafe
            : candidates;
    final selected = _select(
      pool: pool,
      count: request.gameItemCount,
      runSeed: request.runSeed,
      seedSalt: 'endless-game',
      history: request.history,
      role: MissionRunRole.game,
      selectionProfile: request.selectionProfile,
    );

    return MissionRunPlan(
      levelId: 'endless:c$classNumber:$gameId',
      classNumber: classNumber,
      gameId: gameId,
      difficulty: maxDifficulty.clamp(1, 3).toInt(),
      runSeed: request.runSeed,
      requestedTrainingItemCount: 0,
      requestedGameItemCount: request.gameItemCount,
      trainingItems: const <PlannedMissionItem>[],
      gameItems: List<PlannedMissionItem>.unmodifiable(<PlannedMissionItem>[
        for (var index = 0; index < selected.length; index += 1)
          PlannedMissionItem(
            candidate: selected[index],
            role: MissionRunRole.game,
            position: index,
          ),
      ]),
      availableCandidateCount: candidates.length,
      selectionDemand: request.selectionProfile.demand.name,
      selectionReason: request.selectionProfile.reason,
    );
  }

  List<MissionCandidate> candidatesForEndlessPractice({
    required ContentRepository repository,
    required int classNumber,
    required String gameId,
    required int maxDifficulty,
    required int runSeed,
  }) {
    final activities = repository.generatedEndlessPracticeActivitiesForGame(
      classNumber,
      gameId,
      maxDifficulty: maxDifficulty,
      seedBase: runSeed,
    );
    final seenKeys = <String>{};
    final seenContent = <String>{};
    final result = <MissionCandidate>[];
    for (final activity in activities) {
      if (activity.classNumber != classNumber ||
          activity.gameId != gameId ||
          activity.difficulty < 1 ||
          activity.difficulty > maxDifficulty ||
          _isFallbackExperiment(activity)) {
        continue;
      }
      final spec = activityResolver.resolve(activity);
      if (!spec.isSupported) continue;
      final candidate = _candidateFrom(activity, spec);
      if (seenKeys.add(candidate.stableKey) &&
          seenContent.add(candidate.contentFingerprint)) {
        result.add(candidate);
      }
    }
    result.sort((a, b) => a.stableKey.compareTo(b.stableKey));
    return List<MissionCandidate>.unmodifiable(result);
  }

  /// Returns only candidates for this exact LearningLevel difficulty.
  ///
  /// This is the architectural boundary that prevents Challenge from
  /// automatically inheriting Practice content and Mastery from inheriting
  /// both earlier tiers.
  List<MissionCandidate> candidatesForLevel({
    required ContentRepository repository,
    required LearningLevel level,
    bool includeGeneratedPractice = true,
  }) {
    final activities = <ContentActivity>[
      ...repository.activitiesForGameAtExactDifficulty(
        level.classNumber,
        level.gameId,
        difficulty: level.difficulty,
      ),
      if (includeGeneratedPractice)
        ...repository.generatedPracticeActivitiesForGameAtExactDifficulty(
          level.classNumber,
          level.gameId,
          difficulty: level.difficulty,
        ),
    ];

    final seenKeys = <String>{};
    final seenContent = <String>{};
    final result = <MissionCandidate>[];
    for (final activity in activities) {
      if (activity.classNumber != level.classNumber ||
          activity.gameId != level.gameId ||
          activity.difficulty != level.difficulty ||
          _isFallbackExperiment(activity)) {
        continue;
      }
      final spec = activityResolver.resolve(activity);
      if (!spec.isSupported) continue;
      final candidate = _candidateFrom(activity, spec);
      if (seenKeys.add(candidate.stableKey) &&
          seenContent.add(candidate.contentFingerprint)) {
        result.add(candidate);
      }
    }
    result.sort((a, b) => a.stableKey.compareTo(b.stableKey));
    return List<MissionCandidate>.unmodifiable(result);
  }

  /// Rehydrates a planned reference through existing repository lookup paths.
  /// This gives later game-screen migrations one safe boundary for authored and
  /// deterministic generated items without storing answer payloads in the run
  /// plan itself.
  ContentActivity resolveCandidateActivity({
    required ContentRepository repository,
    required MissionCandidate candidate,
  }) {
    final activity = repository.activityById(candidate.activityId) ??
        repository.activityForLegacyContent(
          classNumber: candidate.classNumber,
          gameId: candidate.gameId,
          legacyContentId: candidate.legacyContentId,
        );
    if (activity == null ||
        activity.classNumber != candidate.classNumber ||
        activity.gameId != candidate.gameId ||
        activity.difficulty != candidate.difficulty) {
      throw StateError(
        'Mission candidate ${candidate.stableKey} can no longer be resolved.',
      );
    }
    return activity;
  }

  MissionCandidate _candidateFrom(
    ContentActivity activity,
    LearningGameActivitySpec spec,
  ) {
    final responseRuleType =
        activity.correctResponseRule['type']?.toString() ?? 'unknown';
    return MissionCandidate(
      activityId: activity.id,
      legacyContentId: activity.legacyContentId,
      classNumber: activity.classNumber,
      gameId: activity.gameId,
      topicId: activity.topicId,
      competencyId: activity.competencyId,
      relatedCompetencyIds: List<String>.unmodifiable(
        activity.relatedCompetencyIds
            .where((id) => id.isNotEmpty && id != activity.competencyId)
            .toSet()
            .toList()
          ..sort(),
      ),
      difficulty: activity.difficulty,
      activityType: activity.activityType,
      responseRuleType: responseRuleType,
      source: activity.generation.mode == 'generated'
          ? MissionContentSource.generated
          : MissionContentSource.authored,
      mechanic: spec.mechanic,
      // Topic is part of the structural family identity. The helper is shared
      // with Skill Studio/diagnostic exposure so every surface compares the
      // same child-visible structure.
      archetypeId: missionArchetypeId(activity, spec),
      contentFingerprint: missionActivityFingerprint(activity),
    );
  }

  Set<String> _reservedGameTopicKeys({
    required List<MissionCandidate> pool,
    required int count,
    required int runSeed,
  }) {
    if (count <= 1 || pool.isEmpty) return const <String>{};

    final byTopic = <String, List<MissionCandidate>>{};
    for (final candidate in pool) {
      if (candidate.topicId.isEmpty) continue;
      byTopic.putIfAbsent(candidate.topicId, () => <MissionCandidate>[])
        ..add(candidate);
    }
    if (byTopic.length <= 1) return const <String>{};

    final topics = byTopic.entries.toList(growable: false)
      ..sort((a, b) {
        // Scarce topic families are protected first so a large generated bank
        // cannot crowd out the few authored representatives of another valid
        // exact-tier concept.
        final capacity = a.value.length.compareTo(b.value.length);
        if (capacity != 0) return capacity;
        final stable = _stableScore('$runSeed|game-topic|${a.key}').compareTo(
          _stableScore('$runSeed|game-topic|${b.key}'),
        );
        if (stable != 0) return stable;
        return a.key.compareTo(b.key);
      });

    final reserved = <String>{};
    for (final entry in topics.take(count)) {
      final options = List<MissionCandidate>.from(entry.value)
        ..sort((a, b) {
          // Preserve authored material for Training when a generated candidate
          // can represent the same game topic. Authored-only minority topics
          // are still protected when no generated representative exists.
          if (a.isGenerated != b.isGenerated) {
            return a.isGenerated ? -1 : 1;
          }
          final stable = _stableScore(
            '$runSeed|game-topic|${entry.key}|${a.stableKey}',
          ).compareTo(
            _stableScore(
              '$runSeed|game-topic|${entry.key}|${b.stableKey}',
            ),
          );
          if (stable != 0) return stable;
          return a.stableKey.compareTo(b.stableKey);
        });
      if (options.isNotEmpty) reserved.add(options.first.stableKey);
    }
    return Set<String>.unmodifiable(reserved);
  }

  List<MissionCandidate> _select({
    required List<MissionCandidate> pool,
    required int count,
    required int runSeed,
    required String seedSalt,
    required MissionExposureHistory history,
    required MissionRunRole role,
    required AdaptiveMissionSelectionProfile selectionProfile,
  }) {
    if (count <= 0 || pool.isEmpty) return const <MissionCandidate>[];

    final remaining = List<MissionCandidate>.from(pool);
    final selected = <MissionCandidate>[];
    final selectedCompetencies = <String, int>{};
    final selectedTopics = <String, int>{};
    final selectedArchetypes = <String, int>{};
    final selectedMechanics = <LearningGameMechanic, int>{};
    final eligibleCompetencies = <String>{
      for (final candidate in pool) ...candidate.allCompetencyIds,
    };
    final eligibleTopics = <String>{
      for (final candidate in pool)
        if (candidate.topicId.isNotEmpty) candidate.topicId,
    };
    final eligibleArchetypes = <String>{
      for (final candidate in pool)
        if (candidate.archetypeId.isNotEmpty) candidate.archetypeId,
    };
    final eligibleMechanics = <LearningGameMechanic>{
      for (final candidate in pool) candidate.mechanic,
    };

    while (remaining.isNotEmpty && selected.length < count) {
      remaining.sort((a, b) {
        // Child-visible freshness is the strongest rule. A prompt reachable
        // through another ID/surface is still a repeat to the child, so compare
        // shared fingerprints before stable activity identity.
        final visibleContent = _recentPenalty(
          history.contentFingerprints,
          a.contentFingerprint,
        ).compareTo(
          _recentPenalty(
            history.contentFingerprints,
            b.contentFingerprint,
          ),
        );
        if (visibleContent != 0) return visibleContent;

        // Stable activity identity is the second hard freshness signal. Adaptive
        // weighting can never force an immediate item repeat while a fresh
        // exact-tier candidate exists.
        final activity = _recentPenalty(
          history.activityKeys,
          a.stableKey,
        ).compareTo(
          _recentPenalty(history.activityKeys, b.stableKey),
        );
        if (activity != 0) return activity;

        final aAdaptive = _adaptivePriority(
              a,
              role: role,
              profile: selectionProfile,
            ) -
            balancePolicy.repeatPenaltyFor(
              candidate: a,
              selectedCompetencies: selectedCompetencies,
              selectedTopics: selectedTopics,
              selectedArchetypes: selectedArchetypes,
              selectedMechanics: selectedMechanics,
              eligibleCompetencies: eligibleCompetencies,
              eligibleTopics: eligibleTopics,
              eligibleArchetypes: eligibleArchetypes,
              eligibleMechanics: eligibleMechanics,
            );
        final bAdaptive = _adaptivePriority(
              b,
              role: role,
              profile: selectionProfile,
            ) -
            balancePolicy.repeatPenaltyFor(
              candidate: b,
              selectedCompetencies: selectedCompetencies,
              selectedTopics: selectedTopics,
              selectedArchetypes: selectedArchetypes,
              selectedMechanics: selectedMechanics,
              eligibleCompetencies: eligibleCompetencies,
              eligibleTopics: eligibleTopics,
              eligibleArchetypes: eligibleArchetypes,
              eligibleMechanics: eligibleMechanics,
            );
        final adaptive = bAdaptive.compareTo(aAdaptive);
        if (adaptive != 0) return adaptive;

        final topicHistory = _recentPenalty(
          history.topicIds,
          a.topicId,
        ).compareTo(
          _recentPenalty(history.topicIds, b.topicId),
        );
        if (topicHistory != 0) return topicHistory;

        final competencyHistory = _candidateHistoryPressure(
          candidate: a,
          mostRecentFirst: history.competencyIds,
        ).compareTo(
          _candidateHistoryPressure(
            candidate: b,
            mostRecentFirst: history.competencyIds,
          ),
        );
        if (competencyHistory != 0) return competencyHistory;

        final archetype = _recentPenalty(
          history.archetypeIds,
          a.archetypeId,
        ).compareTo(
          _recentPenalty(history.archetypeIds, b.archetypeId),
        );
        if (archetype != 0) return archetype;

        final mechanic = _recentPenalty(
          history.mechanics,
          a.mechanic,
        ).compareTo(
          _recentPenalty(history.mechanics, b.mechanic),
        );
        if (mechanic != 0) return mechanic;

        // Within one run, do not let a high-priority competency crowd out all
        // other eligible competencies. It can appear more often, but diversity
        // wins ties before archetype/mechanic repetition.
        final selectedCompetency =
            _selectedCompetencyPressure(a, selectedCompetencies).compareTo(
          _selectedCompetencyPressure(b, selectedCompetencies),
        );
        if (selectedCompetency != 0) return selectedCompetency;

        final selectedTopic = (selectedTopics[a.topicId] ?? 0).compareTo(
          selectedTopics[b.topicId] ?? 0,
        );
        if (selectedTopic != 0) return selectedTopic;

        final selectedArchetype =
            (selectedArchetypes[a.archetypeId] ?? 0).compareTo(
          selectedArchetypes[b.archetypeId] ?? 0,
        );
        if (selectedArchetype != 0) return selectedArchetype;

        final selectedMechanic = (selectedMechanics[a.mechanic] ?? 0).compareTo(
          selectedMechanics[b.mechanic] ?? 0,
        );
        if (selectedMechanic != 0) return selectedMechanic;

        final stable = _stableScore(
          '$runSeed|$seedSalt|${a.stableKey}',
        ).compareTo(
          _stableScore('$runSeed|$seedSalt|${b.stableKey}'),
        );
        if (stable != 0) return stable;
        return a.stableKey.compareTo(b.stableKey);
      });

      final chosen = remaining.removeAt(0);
      selected.add(chosen);
      for (final competencyId in chosen.allCompetencyIds) {
        selectedCompetencies[competencyId] =
            (selectedCompetencies[competencyId] ?? 0) + 1;
      }
      if (chosen.topicId.isNotEmpty) {
        selectedTopics[chosen.topicId] =
            (selectedTopics[chosen.topicId] ?? 0) + 1;
      }
      selectedArchetypes[chosen.archetypeId] =
          (selectedArchetypes[chosen.archetypeId] ?? 0) + 1;
      selectedMechanics[chosen.mechanic] =
          (selectedMechanics[chosen.mechanic] ?? 0) + 1;
    }

    return List<MissionCandidate>.unmodifiable(selected);
  }

  int _adaptivePriority(
    MissionCandidate candidate, {
    required MissionRunRole role,
    required AdaptiveMissionSelectionProfile profile,
  }) {
    int? strongestPriority;
    for (final competencyId in candidate.allCompetencyIds) {
      final priority = role == MissionRunRole.training
          ? profile.trainingPriorityFor(competencyId)
          : profile.gamePriorityFor(competencyId);
      if (strongestPriority == null || priority > strongestPriority) {
        strongestPriority = priority;
      }
    }
    var value = strongestPriority ?? 0;
    if (role == MissionRunRole.training && !candidate.isGenerated) {
      value += profile.authoredTrainingBonus;
    }
    if (role == MissionRunRole.game && candidate.isGenerated) {
      value += profile.generatedGameBonus;
    }
    if (role == MissionRunRole.game &&
        candidate.relatedCompetencyIds.isNotEmpty) {
      value += profile.mixedSkillGameBonus;
    }
    return value;
  }

  int _selectedCompetencyPressure(
    MissionCandidate candidate,
    Map<String, int> selectedCompetencies,
  ) {
    var pressure = 0;
    for (final competencyId in candidate.allCompetencyIds) {
      final value = selectedCompetencies[competencyId] ?? 0;
      if (value > pressure) pressure = value;
    }
    return pressure;
  }

  int _candidateHistoryPressure({
    required MissionCandidate candidate,
    required List<String> mostRecentFirst,
  }) {
    var pressure = 0;
    for (final competencyId in candidate.allCompetencyIds) {
      final value = _recentPenalty(mostRecentFirst, competencyId);
      if (value > pressure) pressure = value;
    }
    return pressure;
  }

  int _recentPenalty<T>(List<T> mostRecentFirst, T value) {
    final index = mostRecentFirst.indexOf(value);
    if (index < 0) return 0;
    // Most recent receives the largest penalty. Older exposures progressively
    // become eligible before recent ones when fresh candidates are exhausted.
    return 100000 - index.clamp(0, 99999).toInt();
  }

  int _stableScore(String value) {
    // 32-bit FNV-1a: deterministic across runs/platforms and independent of
    // Dart's object hash implementation.
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
