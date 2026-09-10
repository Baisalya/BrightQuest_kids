import 'dart:math' as math;

import '../content/content_activity.dart';
import '../content/content_repository.dart';
import '../content/game_content.dart';
import '../curriculum/curriculum_catalog.dart';
import '../curriculum/curriculum_models.dart';
import '../learning/activity_response_evaluator.dart';
import '../learning/gameplay_activity_resolver.dart';
import '../learning/mission_balance_policy.dart';
import '../learning/mission_run_allocation_policy.dart';
import '../learning/mission_run_models.dart';
import '../learning/mission_run_planner.dart';

/// Severity for Step 8 mission balance/content-quality findings.
enum MissionQualitySeverity { blocker, high, medium, low }

class MissionQualityFinding {
  const MissionQualityFinding({
    required this.severity,
    required this.code,
    required this.location,
    required this.message,
  });

  final MissionQualitySeverity severity;
  final String code;
  final String location;
  final String message;

  bool get releaseBlocking =>
      severity == MissionQualitySeverity.blocker ||
      severity == MissionQualitySeverity.high;

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}] $code · $location · $message';
}

class MissionLevelQualitySnapshot {
  const MissionLevelQualitySnapshot({
    required this.levelId,
    required this.classNumber,
    required this.gameId,
    required this.difficulty,
    required this.candidateCount,
    required this.authoredCount,
    required this.generatedCount,
    required this.topicCount,
    required this.competencyCount,
    required this.uniquePlanSignatures,
  });

  final String levelId;
  final int classNumber;
  final String gameId;
  final int difficulty;
  final int candidateCount;
  final int authoredCount;
  final int generatedCount;
  final int topicCount;
  final int competencyCount;
  final int uniquePlanSignatures;
}

class MissionContentQualityReport {
  const MissionContentQualityReport({
    required this.checksRun,
    required this.levelsAudited,
    required this.generatedActivitiesAudited,
    required this.simulationRuns,
    required this.snapshots,
    required this.findings,
  });

  final int checksRun;
  final int levelsAudited;
  final int generatedActivitiesAudited;
  final int simulationRuns;
  final List<MissionLevelQualitySnapshot> snapshots;
  final List<MissionQualityFinding> findings;

  bool get hasReleaseBlockingFindings =>
      findings.any((finding) => finding.releaseBlocking);

  List<MissionQualityFinding> get releaseBlockingFindings => List.unmodifiable(
        findings.where((finding) => finding.releaseBlocking),
      );

  int count(MissionQualitySeverity severity) =>
      findings.where((finding) => finding.severity == severity).length;
}

/// Step 8 deterministic audit for Classes 3–5 mission pools.
///
/// The audit intentionally checks only properties the product can prove from
/// its own content contracts and game logic. It does not infer pedagogical
/// correctness from prompt length or claim qualified-teacher review.
class MissionContentQualityAudit {
  const MissionContentQualityAudit({
    this.simulationSeedsPerLevel = 64,
    this.nearSimilarityThreshold = 0.90,
    this.planner = const MissionRunPlanner(),
    this.balancePolicy = const MissionBalancePolicy(),
  })  : assert(simulationSeedsPerLevel > 0),
        assert(nearSimilarityThreshold > 0 && nearSimilarityThreshold <= 1);

  final int simulationSeedsPerLevel;
  final double nearSimilarityThreshold;
  final MissionRunPlanner planner;
  final MissionBalancePolicy balancePolicy;

  MissionContentQualityReport audit(ContentRepository repository) {
    var checks = 0;
    var generatedAudited = 0;
    var simulationRuns = 0;
    final findings = <MissionQualityFinding>[];
    final snapshots = <MissionLevelQualitySnapshot>[];

    for (final level in learningLevels) {
      final candidates = planner.candidatesForLevel(
        repository: repository,
        level: level,
      );
      final allocation = const MissionRunAllocationPolicy().forLevel(
        repository: repository,
        level: level,
        planner: planner,
      );
      final rawGenerated =
          repository.generatedPracticeActivitiesForGameAtExactDifficulty(
        level.classNumber,
        level.gameId,
        difficulty: level.difficulty,
      );
      final authoredCount =
          candidates.where((item) => !item.isGenerated).length;
      final generatedCount =
          candidates.where((item) => item.isGenerated).length;
      final topicCount = candidates
          .map((item) => item.topicId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .length;
      final competencyCount = <String>{
        for (final candidate in candidates) ...candidate.allCompetencyIds,
      }.length;
      final location = level.id;

      checks += 1;
      if (allocation.trainingItemCount != 5 || allocation.gameItemCount != 5) {
        findings.add(
          MissionQualityFinding(
            severity: MissionQualitySeverity.blocker,
            code: 'mission.capacity.full_run_shortfall',
            location: location,
            message:
                'Expected the hardened 5 Training + 5 Game shape, got ${allocation.trainingItemCount} + ${allocation.gameItemCount}.',
          ),
        );
      }

      checks += 1;
      if (candidates.length < 10) {
        findings.add(
          MissionQualityFinding(
            severity: MissionQualitySeverity.blocker,
            code: 'mission.capacity.insufficient_unique_candidates',
            location: location,
            message:
                'Only ${candidates.length} exact-tier unique candidates are available.',
          ),
        );
      }

      checks += 1;
      if (candidates.map((item) => item.contentFingerprint).toSet().length !=
          candidates.length) {
        findings.add(
          MissionQualityFinding(
            severity: MissionQualitySeverity.blocker,
            code: 'mission.pool.visible_duplicate',
            location: location,
            message:
                'The planner candidate pool still contains visible duplicates.',
          ),
        );
      }

      checks += 2;
      if (rawGenerated.length !=
          ContentRepository.generatedPracticeVariantsPerFamily) {
        findings.add(
          MissionQualityFinding(
            severity: MissionQualitySeverity.blocker,
            code: 'mission.generated.bank_capacity',
            location: location,
            message:
                'Expected ${ContentRepository.generatedPracticeVariantsPerFamily} generated exact-tier variants, found ${rawGenerated.length}.',
          ),
        );
      }
      final rawGeneratedFingerprints =
          rawGenerated.map((item) => _fingerprint(item.prompt)).toSet();
      if (rawGeneratedFingerprints.length != rawGenerated.length) {
        findings.add(
          MissionQualityFinding(
            severity: MissionQualitySeverity.blocker,
            code: 'mission.generated.visible_duplicate',
            location: location,
            message: 'Generated exact-tier bank contains visible duplicates.',
          ),
        );
      }
      generatedAudited += rawGenerated.length;

      final candidateActivityIds =
          candidates.map((item) => item.activityId).toSet();
      for (final activity in rawGenerated) {
        checks += 3;
        if (activity.generation.mode != 'generated' ||
            activity.generation.deterministicSeed == null ||
            activity.generation.deterministicSeed!.trim().isEmpty) {
          findings.add(
            MissionQualityFinding(
              severity: MissionQualitySeverity.blocker,
              code: 'mission.generated.invalid_generation_identity',
              location: activity.id,
              message:
                  'Generated mission must retain deterministic generator identity.',
            ),
          );
        }
        if (activity.status != 'needsReview') {
          findings.add(
            MissionQualityFinding(
              severity: MissionQualitySeverity.blocker,
              code: 'mission.generated.review_status_bypass',
              location: activity.id,
              message:
                  'Deterministic generated content must remain needsReview until explicitly reviewed.',
            ),
          );
        }
        final byId = repository.activityById(activity.id);
        final byLegacy = repository.activityForLegacyContent(
          classNumber: activity.classNumber,
          gameId: activity.gameId,
          legacyContentId: activity.legacyContentId,
        );
        if (byId?.prompt != activity.prompt ||
            byLegacy?.prompt != activity.prompt) {
          findings.add(
            MissionQualityFinding(
              severity: MissionQualitySeverity.blocker,
              code: 'mission.generated.rehydration_mismatch',
              location: activity.id,
              message:
                  'Generated mission does not rehydrate identically by canonical and legacy IDs.',
            ),
          );
        }

        if (candidateActivityIds.contains(activity.id)) continue;
        final activityAudit = _auditActivity(activity);
        checks += activityAudit.checks;
        findings.addAll(activityAudit.findings);
        findings.add(
          MissionQualityFinding(
            severity: MissionQualitySeverity.medium,
            code: 'mission.generated.deduped_against_authored',
            location: activity.id,
            message:
                'Generated content is valid but adds no new visible planner candidate because its prompt duplicates existing exact-tier content.',
          ),
        );
      }

      for (final candidate in candidates) {
        checks += 1;
        if (candidate.classNumber != level.classNumber ||
            candidate.gameId != level.gameId ||
            candidate.difficulty != level.difficulty) {
          findings.add(
            MissionQualityFinding(
              severity: MissionQualitySeverity.blocker,
              code: 'mission.pool.tier_or_class_leak',
              location: '${level.id}/${candidate.stableKey}',
              message:
                  'Candidate escaped its exact class/game/difficulty boundary.',
            ),
          );
        }

        final activity = planner.resolveCandidateActivity(
          repository: repository,
          candidate: candidate,
        );
        final activityAudit = _auditActivity(activity);
        checks += activityAudit.checks;
        findings.addAll(activityAudit.findings);
      }

      _auditNearSimilarity(level, candidates, findings, () => checks += 1);

      final planSignatures = <String>{};
      for (var seed = 0; seed < simulationSeedsPerLevel; seed += 1) {
        final plan = planner.planForLevel(
          repository: repository,
          level: level,
          request: MissionRunRequest(
            runSeed: _simulationSeed(level, seed),
            trainingItemCount: allocation.trainingItemCount,
            gameItemCount: allocation.gameItemCount,
            gameMechanics: allocation.gameMechanics,
          ),
        );
        simulationRuns += 1;
        checks += 4;
        if (plan.hasContentShortfall) {
          findings.add(
            MissionQualityFinding(
              severity: MissionQualitySeverity.blocker,
              code: 'mission.simulation.content_shortfall',
              location: '$location/seed:$seed',
              message: 'A deterministic simulated run could not fill 5 + 5.',
            ),
          );
        }
        if (plan.hasTrainingGameOverlap ||
            plan.hasVisibleContentOverlap ||
            plan.hasInternalContentRepeat) {
          findings.add(
            MissionQualityFinding(
              severity: MissionQualitySeverity.blocker,
              code: 'mission.simulation.repeat_or_overlap',
              location: '$location/seed:$seed',
              message:
                  'A simulated run repeated content internally or across Training/Game.',
            ),
          );
        }
        if (!_roleIsBalanced(plan.trainingItems, candidates) ||
            !_roleIsBalanced(plan.gameItems, candidates)) {
          findings.add(
            MissionQualityFinding(
              severity: MissionQualitySeverity.high,
              code: 'mission.simulation.topic_monopoly',
              location: '$location/seed:$seed',
              message:
                  'A neutral run over-concentrated one topic despite viable exact-tier alternatives.',
            ),
          );
        }
        planSignatures.add(_planSignature(plan));
      }

      checks += 1;
      final expectedSignatures = math.min(8, simulationSeedsPerLevel);
      if (planSignatures.length < expectedSignatures) {
        findings.add(
          MissionQualityFinding(
            severity: MissionQualitySeverity.high,
            code: 'mission.simulation.low_run_variety',
            location: location,
            message:
                'Only ${planSignatures.length} distinct 5+5 run signatures appeared across $simulationSeedsPerLevel deterministic seeds.',
          ),
        );
      }

      snapshots.add(
        MissionLevelQualitySnapshot(
          levelId: level.id,
          classNumber: level.classNumber,
          gameId: level.gameId,
          difficulty: level.difficulty,
          candidateCount: candidates.length,
          authoredCount: authoredCount,
          generatedCount: generatedCount,
          topicCount: topicCount,
          competencyCount: competencyCount,
          uniquePlanSignatures: planSignatures.length,
        ),
      );
    }

    final crossFamily = _auditGeneratedSeparation(repository);
    checks += crossFamily.checks;
    findings.addAll(crossFamily.findings);

    return MissionContentQualityReport(
      checksRun: checks,
      levelsAudited: learningLevels.length,
      generatedActivitiesAudited: generatedAudited,
      simulationRuns: simulationRuns,
      snapshots: List<MissionLevelQualitySnapshot>.unmodifiable(snapshots),
      findings: List<MissionQualityFinding>.unmodifiable(findings),
    );
  }

  _ActivityAudit _auditActivity(ContentActivity activity) {
    var checks = 0;
    final findings = <MissionQualityFinding>[];
    final location = activity.id;

    void blocker(String code, String message) {
      findings.add(
        MissionQualityFinding(
          severity: MissionQualitySeverity.blocker,
          code: code,
          location: location,
          message: message,
        ),
      );
    }

    try {
      checks += 1;
      if (activity.prompt.trim().isEmpty ||
          activity.explanation.trim().isEmpty) {
        blocker(
          'mission.activity.missing_instruction_or_explanation',
          'Prompt and explanation must both be non-empty.',
        );
      }

      checks += 1;
      final spec = const GameplayActivityResolver().resolve(activity);
      if (!spec.isSupported) {
        blocker(
          'mission.activity.unsupported_renderer',
          spec.unsupportedReason ??
              'Activity has no supported gameplay renderer.',
        );
      }

      final route = activity.correctResponseRule['type'] == 'reachGridGoal'
          ? _findCodingRoute(activity)
          : null;
      final correctResponse = _correctResponse(activity, route);
      checks += 1;
      if (correctResponse == null ||
          !const ActivityResponseEvaluator()
              .evaluate(activity, correctResponse)
              .correct) {
        blocker(
          'mission.activity.correct_response_rejected',
          'The activity response rule rejects its own declared/derived correct response.',
        );
      }

      final choices = const ActivityResponseEvaluator().choicesFor(activity);
      if (choices.isNotEmpty) {
        checks += 2;
        final normalized = choices.map(_normalizeValue).toList(growable: false);
        if (normalized.length != normalized.toSet().length) {
          blocker(
            'mission.activity.duplicate_choices',
            'Visible answer choices contain duplicates.',
          );
        }
        final answerKey = _normalizeValue(correctResponse);
        if (normalized.where((value) => value == answerKey).length != 1) {
          blocker(
            'mission.activity.answer_choice_mismatch',
            'The correct response must appear exactly once in visible choices.',
          );
        }
      }

      if (activity.distractors.isNotEmpty) {
        checks += 1;
        final answerKey = _normalizeValue(correctResponse);
        final distractorKeys = activity.distractors
            .map((item) => _normalizeValue(item.value))
            .toList();
        if (distractorKeys.contains(answerKey) ||
            distractorKeys.length != distractorKeys.toSet().length) {
          blocker(
            'mission.activity.invalid_distractors',
            'Distractors duplicate the correct answer or each other.',
          );
        }
      }

      final type = activity.correctResponseRule['type'];
      if (type == 'selectedSlices') {
        checks += 1;
        final total = (activity.payload['totalSlices'] as num?)?.toInt();
        final numerator = (activity.payload['numerator'] as num?)?.toInt();
        final denominator = (activity.payload['denominator'] as num?)?.toInt();
        final selected =
            (activity.correctResponseRule['value'] as num?)?.toInt();
        if (total == null ||
            numerator == null ||
            denominator == null ||
            selected == null ||
            total <= 0 ||
            numerator <= 0 ||
            denominator <= 1 ||
            numerator >= denominator ||
            total % denominator != 0 ||
            selected * denominator != total * numerator) {
          blocker(
            'mission.activity.invalid_fraction_payload',
            'Fraction payload and selected-slice answer are inconsistent.',
          );
        }
      }

      if (type == 'orderedWords') {
        checks += 1;
        final words = activity.payload['words'];
        final answer = activity.correctResponseRule['value'];
        if (words is! List ||
            answer is! List ||
            words.length < 3 ||
            words.length != answer.length ||
            List.generate(words.length, (index) => '${words[index]}')
                .asMap()
                .entries
                .any((entry) =>
                    entry.value.trim().isEmpty ||
                    entry.value != '${answer[entry.key]}')) {
          blocker(
            'mission.activity.invalid_story_order',
            'Story words and orderedWords answer are inconsistent.',
          );
        }
      }

      if (type == 'grammarParts') {
        checks += 1;
        final sentence = '${activity.payload['sentence'] ?? ''}'.toLowerCase();
        final parts = const <String>['noun', 'verb', 'adjective'];
        if (sentence.isEmpty ||
            parts.any((part) {
              final value = '${activity.correctResponseRule[part] ?? ''}'
                  .trim()
                  .toLowerCase();
              return value.isEmpty || !sentence.contains(value);
            })) {
          blocker(
            'mission.activity.invalid_grammar_parts',
            'Scored noun/verb/adjective must all occur in the visible sentence.',
          );
        }
      }

      if (type == 'reachGridGoal') {
        checks += 1;
        if (route == null) {
          blocker(
            'mission.activity.coding_goal_unreachable',
            'No valid route reaches the coding goal within the command budget.',
          );
        }
      }
    } catch (error) {
      blocker(
        'mission.activity.audit_exception',
        'Quality audit could not safely validate the activity: $error',
      );
    }

    return _ActivityAudit(checks: checks, findings: findings);
  }

  void _auditNearSimilarity(
    LearningLevel level,
    List<MissionCandidate> candidates,
    List<MissionQualityFinding> findings,
    void Function() countCheck,
  ) {
    final generated = candidates.where((item) => item.isGenerated).toList();
    if (generated.length < 4) return;
    var compared = 0;
    var near = 0;
    for (var left = 0; left < generated.length; left += 1) {
      for (var right = left + 1; right < generated.length; right += 1) {
        compared += 1;
        if (_promptSimilarity(
              generated[left].contentFingerprint,
              generated[right].contentFingerprint,
            ) >=
            nearSimilarityThreshold) {
          near += 1;
        }
      }
    }
    countCheck();
    if (compared > 0 && near / compared >= 0.60) {
      findings.add(
        MissionQualityFinding(
          severity: MissionQualitySeverity.medium,
          code: 'mission.pool.template_similarity',
          location: level.id,
          message:
              '$near of $compared generated prompt pairs are highly similar. This is a variety warning, not a correctness failure.',
        ),
      );
    }
  }

  bool _roleIsBalanced(
    List<PlannedMissionItem> items,
    List<MissionCandidate> pool,
  ) {
    if (items.length < 2) return true;
    final poolByTopic = <String, int>{};
    for (final candidate in pool) {
      if (candidate.topicId.isEmpty) continue;
      poolByTopic[candidate.topicId] =
          (poolByTopic[candidate.topicId] ?? 0) + 1;
    }
    final viableTopics = poolByTopic.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toSet();
    if (viableTopics.length <= 1) return true;

    final selectedCounts = <String, int>{};
    for (final item in items) {
      selectedCounts[item.candidate.topicId] =
          (selectedCounts[item.candidate.topicId] ?? 0) + 1;
    }
    final maxAllowed = balancePolicy.neutralMaxOccurrences(
      itemCount: items.length,
      distinctFamilies: viableTopics.length,
    );
    final maxSelected = selectedCounts.values.fold<int>(
      0,
      (current, value) => math.max(current, value),
    );
    return selectedCounts.keys.where(viableTopics.contains).length >= 2 &&
        maxSelected <= maxAllowed;
  }

  _ActivityAudit _auditGeneratedSeparation(ContentRepository repository) {
    var checks = 0;
    final findings = <MissionQualityFinding>[];
    const games = <String>[
      'math_market',
      'fraction_pizza',
      'story_builder',
      'grammar_puzzle',
      'science_lab',
      'map_quest',
      'coding_maze',
      'recycling_challenge',
    ];

    for (final gameId in games) {
      final family = _familyForGame(gameId);
      for (final difficulty in const <int>[1, 2, 3]) {
        for (var seed = 0;
            seed < ContentRepository.generatedPracticeVariantsPerFamily;
            seed += 1) {
          final classFingerprints = <String>{};
          for (final classNumber in const <int>[3, 4, 5]) {
            final activity = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: gameId,
              legacyContentId:
                  'gen_${family}_c${classNumber}_d${difficulty}_s$seed',
            );
            checks += 1;
            if (activity == null) {
              findings.add(
                MissionQualityFinding(
                  severity: MissionQualitySeverity.blocker,
                  code: 'mission.generated.missing_variant',
                  location: '$gameId/c$classNumber/d$difficulty/seed:$seed',
                  message:
                      'Expected deterministic generated variant is missing.',
                ),
              );
              continue;
            }
            classFingerprints.add(_fingerprint(activity.prompt));
          }
          checks += 1;
          if (classFingerprints.length != 3) {
            findings.add(
              MissionQualityFinding(
                severity: MissionQualitySeverity.blocker,
                code: 'mission.generated.cross_class_copy',
                location: '$gameId/d$difficulty/seed:$seed',
                message:
                    'The same generated seed collapses to identical visible content across classes.',
              ),
            );
          }
        }
      }

      for (final classNumber in const <int>[3, 4, 5]) {
        for (var seed = 0;
            seed < ContentRepository.generatedPracticeVariantsPerFamily;
            seed += 1) {
          final tierFingerprints = <String>{};
          for (final difficulty in const <int>[1, 2, 3]) {
            final activity = repository.activityForLegacyContent(
              classNumber: classNumber,
              gameId: gameId,
              legacyContentId:
                  'gen_${family}_c${classNumber}_d${difficulty}_s$seed',
            );
            if (activity != null)
              tierFingerprints.add(_fingerprint(activity.prompt));
          }
          checks += 1;
          if (tierFingerprints.length != 3) {
            findings.add(
              MissionQualityFinding(
                severity: MissionQualitySeverity.high,
                code: 'mission.generated.cross_tier_collapse',
                location: '$gameId/c$classNumber/seed:$seed',
                message:
                    'Practice/Challenge/Mastery generated variants collapse to identical visible content.',
              ),
            );
          }
        }
      }
    }

    return _ActivityAudit(checks: checks, findings: findings);
  }

  Object? _correctResponse(
    ContentActivity activity,
    List<CodingCommand>? codingRoute,
  ) {
    final rule = activity.correctResponseRule;
    return switch (rule['type']) {
      'exactNumber' ||
      'exactText' ||
      'exactTextCaseSensitive' ||
      'selectedSlices' =>
        rule['value'],
      'orderedWords' => rule['value'] is List
          ? List<Object?>.from(rule['value'] as List)
          : null,
      'grammarParts' => <String, Object?>{
          'noun': rule['noun'],
          'verb': rule['verb'],
          'adjective': rule['adjective'],
        },
      'experimentOutcome' => activity.payload['requiredIngredients'] is List
          ? List<Object?>.from(activity.payload['requiredIngredients'] as List)
          : null,
      'reachGridGoal' => codingRoute,
      _ => null,
    };
  }

  List<CodingCommand>? _findCodingRoute(ContentActivity activity) {
    final payload = activity.payload;
    final directions = FacingDirection.values
        .where((value) => value.name == payload['startDirection'])
        .toList(growable: false);
    if (directions.isEmpty) return null;
    final mission = CodingMission(
      id: activity.id,
      width: (payload['width'] as num).toInt(),
      height: (payload['height'] as num).toInt(),
      startX: (payload['startX'] as num).toInt(),
      startY: (payload['startY'] as num).toInt(),
      goalX: (payload['goalX'] as num).toInt(),
      goalY: (payload['goalY'] as num).toInt(),
      startDirection: directions.first,
      obstacles: Set<String>.from(payload['obstacles'] as List),
      maxCommands: (payload['maxCommands'] as num).toInt(),
      topicId: activity.topicId,
      difficulty: activity.difficulty,
    );
    if (mission.width <= 0 ||
        mission.height <= 0 ||
        mission.startX < 0 ||
        mission.startY < 0 ||
        mission.goalX < 0 ||
        mission.goalY < 0 ||
        mission.startX >= mission.width ||
        mission.goalX >= mission.width ||
        mission.startY >= mission.height ||
        mission.goalY >= mission.height ||
        mission.maxCommands <= 0 ||
        mission.obstacles.contains('${mission.startX},${mission.startY}') ||
        mission.obstacles.contains('${mission.goalX},${mission.goalY}')) {
      return null;
    }

    final queue = <_RouteNode>[
      _RouteNode(
        x: mission.startX,
        y: mission.startY,
        direction: mission.startDirection,
        commands: const <CodingCommand>[],
      ),
    ];
    final seen = <String>{};
    var cursor = 0;
    while (cursor < queue.length) {
      final node = queue[cursor++];
      final key = '${node.x},${node.y},${node.direction.name}';
      if (!seen.add(key)) continue;
      if (node.x == mission.goalX && node.y == mission.goalY) {
        return node.commands;
      }
      if (node.commands.length >= mission.maxCommands) continue;

      for (final command in const <CodingCommand>[
        CodingCommand.move,
        CodingCommand.turnLeft,
        CodingCommand.turnRight,
      ]) {
        var x = node.x;
        var y = node.y;
        var direction = node.direction;
        if (command == CodingCommand.turnLeft) {
          direction = direction.turnLeft;
        } else if (command == CodingCommand.turnRight) {
          direction = direction.turnRight;
        } else {
          final (dx, dy) = direction.delta;
          x += dx;
          y += dy;
          if (x < 0 ||
              y < 0 ||
              x >= mission.width ||
              y >= mission.height ||
              mission.obstacles.contains('$x,$y')) {
            continue;
          }
        }
        queue.add(
          _RouteNode(
            x: x,
            y: y,
            direction: direction,
            commands: <CodingCommand>[...node.commands, command],
          ),
        );
      }
    }
    return null;
  }

  String _normalizeValue(Object? value) {
    if (value is num) return value.toDouble().toStringAsFixed(8);
    if (value is List) {
      return value.map(_normalizeValue).join('|').toLowerCase();
    }
    if (value is Map) {
      final keys = value.keys.map((key) => '$key').toList()..sort();
      return keys.map((key) => '$key:${_normalizeValue(value[key])}').join('|');
    }
    return '$value'.trim().toLowerCase();
  }

  double _promptSimilarity(String left, String right) {
    final a = _tokens(left);
    final b = _tokens(right);
    if (a.isEmpty || b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0 : intersection / union;
  }

  Set<String> _tokens(String value) => RegExp(r'[a-z0-9]+')
      .allMatches(value.toLowerCase())
      .map((match) => match.group(0)!)
      .toSet();

  String _fingerprint(String prompt) =>
      prompt.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _planSignature(MissionRunPlan plan) => <String>[
        ...plan.trainingItems.map((item) => item.candidate.stableKey),
        '--',
        ...plan.gameItems.map((item) => item.candidate.stableKey),
      ].join('|');

  int _simulationSeed(LearningLevel level, int seed) {
    var hash = 0x811c9dc5;
    final value = '${level.id}|step8|$seed';
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  String _familyForGame(String gameId) => switch (gameId) {
        'math_market' => 'math',
        'fraction_pizza' => 'fraction',
        'story_builder' => 'story',
        'grammar_puzzle' => 'grammar',
        'science_lab' => 'science',
        'map_quest' => 'map',
        'coding_maze' => 'coding',
        'recycling_challenge' => 'recycling',
        _ => throw ArgumentError.value(gameId, 'gameId'),
      };
}

class _ActivityAudit {
  const _ActivityAudit({required this.checks, required this.findings});

  final int checks;
  final List<MissionQualityFinding> findings;
}

class _RouteNode {
  const _RouteNode({
    required this.x,
    required this.y,
    required this.direction,
    required this.commands,
  });

  final int x;
  final int y;
  final FacingDirection direction;
  final List<CodingCommand> commands;
}
