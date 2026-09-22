import '../content/content_activity.dart';
import '../content/content_repository.dart';
import '../curriculum/content_contract.dart';
import '../curriculum/curriculum_catalog.dart';
import '../curriculum/curriculum_models.dart';
import 'activity_response_evaluator.dart';
import 'contextual_feedback_engine.dart';
import 'gameplay_activity_resolver.dart';
import 'mission_run_models.dart';
import 'mission_run_planner.dart';
import 'skill_studio_practice_planner.dart';

/// The teaching sequence deliberately separates explanation from assessment.
enum LessonStepKind {
  objective,
  explanation,
  workedExample,
  guidedTry,
  independentPractice,
  transfer,
  exitTicket,
  reteach,
  review,
}

class LessonStep {
  const LessonStep({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.activityId,
    this.hints = const <String>[],
    this.requiresIndependentResponse = false,
  });

  final String id;
  final LessonStepKind kind;
  final String title;
  final String body;
  final String? activityId;
  final List<String> hints;
  final bool requiresIndependentResponse;
}

class LessonFlow {
  const LessonFlow({
    required this.classNumber,
    required this.competencyId,
    required this.unitId,
    required this.objective,
    required this.steps,
    required this.reviewStatus,
  });

  final int classNumber;
  final String competencyId;
  final String unitId;
  final String objective;
  final List<LessonStep> steps;
  final String reviewStatus;

  bool get hasTeaching => steps.any(
        (step) =>
            step.kind == LessonStepKind.explanation ||
            step.kind == LessonStepKind.workedExample,
      );
  bool get hasAssessment => steps.any(
        (step) =>
            step.kind == LessonStepKind.independentPractice ||
            step.kind == LessonStepKind.transfer ||
            step.kind == LessonStepKind.exitTicket,
      );
}

class LessonEngine {
  const LessonEngine();

  LessonFlow buildForLevel({
    required ContentRepository repository,
    required LearningLevel level,
    MissionRunPlan? missionRunPlan,
  }) {
    final gameCandidates = repository.activitiesForGame(
      level.classNumber,
      level.gameId,
      difficulty: level.difficulty,
    );
    final levelCandidates = gameCandidates
        .where(
          (activity) =>
              activity.difficulty == level.difficulty &&
              !_isFallbackExperiment(activity),
        )
        .toList(growable: false);
    if (levelCandidates.isEmpty) {
      throw StateError(
        'No ${level.gameId} activity is authored for ${level.id} at '
        'difficulty ${level.difficulty}.',
      );
    }
    final base = buildForCompetency(
      repository: repository,
      classNumber: level.classNumber,
      competencyId: levelCandidates.first.competencyId,
      targetDifficulty: level.difficulty,
    );
    if (missionRunPlan == null) return base;
    return _applyMissionTrainingAllocation(
      repository: repository,
      level: level,
      base: base,
      plan: missionRunPlan,
    );
  }

  LessonFlow buildForCompetency({
    required ContentRepository repository,
    required int classNumber,
    required String competencyId,
    int? targetDifficulty,
    SkillStudioPracticePlan? practicePlan,
  }) {
    final contract = repository.curriculum.classPack(classNumber);
    if (contract == null) {
      throw StateError('No curriculum contract for Class $classNumber.');
    }
    CompetencyContract? competency;
    for (final candidate in contract.competencies) {
      if (candidate.id == competencyId) {
        competency = candidate;
        break;
      }
    }
    if (competency == null) {
      throw StateError(
        'Unknown Class $classNumber competency $competencyId.',
      );
    }

    final blueprint = repository.learningBlueprintForCompetency(competencyId);

    final allActivities = repository
        .activitiesForClass(classNumber)
        .where(
          (activity) =>
              activity.allCompetencyIds.contains(competencyId) &&
              !(activity.correctResponseRule['type'] == 'experimentOutcome' &&
                  activity.payload['fallback'] == true),
        )
        .toList()
      ..sort((a, b) {
        final difficulty = a.difficulty.compareTo(b.difficulty);
        return difficulty != 0 ? difficulty : a.id.compareTo(b.id);
      });

    // Learning World levels are capped at their authored difficulty. The old
    // competency flow intentionally remains broad for direct Skill Studio use.
    final cappedActivities = targetDifficulty == null
        ? allActivities
        : allActivities
            .where((activity) => activity.difficulty <= targetDifficulty)
            .toList(growable: false);
    if (targetDifficulty != null && cappedActivities.isEmpty) {
      throw StateError(
        'No $competencyId activity is authored at or below difficulty '
        '$targetDifficulty.',
      );
    }
    final activities = cappedActivities;
    ContentActivity? plannedActivityAt(int index) {
      if (practicePlan == null || targetDifficulty != null) return null;
      final id = practicePlan.activityIdAt(index);
      if (id == null) return null;
      final activity = repository.activityById(id);
      if (activity == null ||
          activity.classNumber != classNumber ||
          !activity.allCompetencyIds.contains(competencyId)) {
        return null;
      }
      return activity;
    }

    final targetActivities = targetDifficulty == null
        ? const <ContentActivity>[]
        : activities
            .where((activity) => activity.difficulty == targetDifficulty)
            .toList(growable: false);
    if (targetDifficulty != null && targetActivities.isEmpty) {
      throw StateError(
        'No $competencyId activity is authored at target difficulty '
        '$targetDifficulty.',
      );
    }

    final example = targetDifficulty == null
        ? (plannedActivityAt(0) ??
            (activities.isEmpty ? null : activities.first))
        : _teachingExample(activities, targetDifficulty);
    final guidedActivity =
        targetDifficulty == null ? (plannedActivityAt(0) ?? example) : example;
    final blueprintActivities = blueprint?.independentSourceActivityIds
            .map(repository.activityById)
            .whereType<ContentActivity>()
            .where(activities.contains)
            .toList(growable: false) ??
        const <ContentActivity>[];
    final targetBlueprintActivities = targetDifficulty == null
        ? blueprintActivities
        : blueprintActivities
            .where((activity) => activity.difficulty == targetDifficulty)
            .toList(growable: false);
    final independent = targetDifficulty == null
        ? (plannedActivityAt(1) ??
            (blueprintActivities.isNotEmpty
                ? blueprintActivities.first
                : activities.isEmpty
                    ? null
                    : activities[activities.length ~/ 2]))
        : (targetBlueprintActivities.firstOrNull ??
            targetActivities.firstOrNull);
    final transfer = targetDifficulty == null
        ? (plannedActivityAt(2) ??
            (activities.length < 2 ? independent : activities.last))
        : (targetActivities
                .where((activity) => activity.id != independent?.id)
                .firstOrNull ??
            independent);
    ContentActivity? exitTicket =
        targetDifficulty == null ? plannedActivityAt(3) : null;
    if (targetDifficulty == null && exitTicket == null) {
      for (final candidate in activities.reversed) {
        if (candidate.id != independent?.id && candidate.id != transfer?.id) {
          exitTicket = candidate;
          break;
        }
      }
    } else {
      exitTicket = targetActivities
              .where(
                (activity) =>
                    activity.id != independent?.id &&
                    activity.id != transfer?.id,
              )
              .firstOrNull ??
          independent ??
          transfer;
    }
    exitTicket ??= independent ?? transfer ?? example;
    final objective = blueprint?.objective ?? competency.objective;
    final conceptualHint = blueprint?.guidedHints.firstOrNull ??
        _conceptualHint(objective, example);
    final workedHint = blueprint?.guidedHints.elementAtOrNull(1) ??
        _workedHint(example, objective);

    final steps = <LessonStep>[
      LessonStep(
        id: '$competencyId:objective',
        kind: LessonStepKind.objective,
        title: 'Mission goal',
        body: objective,
      ),
      LessonStep(
        id: '$competencyId:explain',
        kind: LessonStepKind.explanation,
        title: 'Discover the idea',
        body: blueprint?.teach ?? _explanation(competency, example),
      ),
      LessonStep(
        id: '$competencyId:worked',
        kind: LessonStepKind.workedExample,
        title: 'Worked example',
        body: blueprint?.workedExample ?? _workedExample(example, objective),
        // Direct Skill Studio reserves the four authored response items for
        // guided/independent/transfer/exit so a single fresh set never asks
        // the same question twice. The worked example remains teaching-only.
        activityId: practicePlan == null ? example?.id : null,
      ),
      LessonStep(
        id: '$competencyId:guided',
        kind: LessonStepKind.guidedTry,
        title: 'Try it with a clue',
        body: blueprint?.guidedPrompt ??
            guidedActivity?.prompt ??
            'Explain one small example of this idea in your own words.',
        activityId: guidedActivity?.id,
        hints: <String>[conceptualHint, workedHint],
      ),
      LessonStep(
        id: '$competencyId:independent',
        kind: LessonStepKind.independentPractice,
        title: 'Your turn',
        body: independent?.prompt ??
            blueprint?.independentFallbackPrompt ??
            'Use the idea independently on a fresh example.',
        activityId: independent?.id,
        requiresIndependentResponse: true,
      ),
      LessonStep(
        id: '$competencyId:transfer',
        kind: LessonStepKind.transfer,
        title: 'Use it a new way',
        body: blueprint?.transferPrompt ??
            (transfer == null
                ? 'Tell where this idea could be useful outside this lesson.'
                : 'Solve this without a hint, then explain why your method works: ${transfer.prompt}'),
        activityId: transfer?.id,
        requiresIndependentResponse: true,
      ),
      LessonStep(
        id: '$competencyId:exit',
        kind: LessonStepKind.exitTicket,
        title: 'Show what you know',
        body: 'Finish one independent check without a clue.',
        activityId: exitTicket?.id,
        requiresIndependentResponse: true,
      ),
      LessonStep(
        id: '$competencyId:reteach',
        kind: LessonStepKind.reteach,
        title: 'Need another way?',
        body: _reteach(objective, example),
        hints: <String>[conceptualHint, workedHint],
      ),
      LessonStep(
        id: '$competencyId:review',
        kind: LessonStepKind.review,
        title: 'Later power review',
        body: blueprint?.reviewPrompt ??
            'BrightQuest will revisit this skill after a delay using a differently worded task.',
      ),
    ];

    return LessonFlow(
      classNumber: classNumber,
      competencyId: competency.id,
      unitId: competency.unitId,
      objective: objective,
      steps: List<LessonStep>.unmodifiable(steps),
      reviewStatus:
          blueprint?.review.status.name ?? competency.review.status.name,
    );
  }

  LessonFlow _applyMissionTrainingAllocation({
    required ContentRepository repository,
    required LearningLevel level,
    required LessonFlow base,
    required MissionRunPlan plan,
  }) {
    if (plan.levelId != level.id ||
        plan.classNumber != level.classNumber ||
        plan.gameId != level.gameId ||
        plan.difficulty != level.difficulty) {
      throw StateError('Mission run plan does not match ${level.id}.');
    }
    if (plan.hasTrainingGameOverlap ||
        plan.hasVisibleContentOverlap ||
        plan.hasInternalContentRepeat) {
      throw StateError(
        'Mission run plan for ${level.id} contains repeated mission content.',
      );
    }

    final allocatedKinds = _trainingKindsForCount(plan.trainingItems.length);

    const planner = MissionRunPlanner();
    final allocated = <LessonStepKind, ContentActivity>{};
    for (var index = 0; index < allocatedKinds.length; index += 1) {
      final item = plan.trainingItems[index];
      final activity = planner.resolveCandidateActivity(
        repository: repository,
        candidate: item.candidate,
      );
      if (activity.classNumber != level.classNumber ||
          activity.gameId != level.gameId ||
          activity.difficulty != level.difficulty) {
        throw StateError(
          'Training allocation ${activity.id} escaped ${level.id}.',
        );
      }
      allocated[allocatedKinds[index]] = activity;
    }

    final allocatedIds =
        allocated.values.map((activity) => activity.id).toSet();
    if (allocatedIds.length != allocated.length) {
      throw StateError('Mission training allocation contains a repeated item.');
    }

    final topic = _curriculumTopicForLevel(level);
    final missionObjective = topic?.summary ?? level.summary;
    final firstAllocated = allocated.values.firstOrNull;

    // A Learning World mission has two different content layers:
    // 1. the world/topic framing shown as the mission goal; and
    // 2. the authored competency teaching sequence underneath it.
    //
    // Do not flatten those layers into one sentence. In particular, the
    // explanation must keep the blueprint's teaching copy while activity-backed
    // stages use the exact items allocated to this run. This is what keeps
    // See it progressing from goal -> concept -> example instead of reading the
    // topic summary again on every page.
    final steps = <LessonStep>[
      for (final step in base.steps)
        _composeMissionStep(
          step: step,
          allocatedActivity: allocated[step.kind],
          missionObjective: missionObjective,
          firstAllocatedActivity: firstAllocated,
        ),
    ];
    return LessonFlow(
      classNumber: base.classNumber,
      competencyId: base.competencyId,
      unitId: base.unitId,
      objective: missionObjective,
      steps: List<LessonStep>.unmodifiable(steps),
      reviewStatus: base.reviewStatus,
    );
  }

  List<LessonStepKind> _trainingKindsForCount(int count) {
    if (count <= 0) return const <LessonStepKind>[];
    if (count == 1) {
      return const <LessonStepKind>[LessonStepKind.workedExample];
    }
    if (count == 2) {
      return const <LessonStepKind>[
        LessonStepKind.workedExample,
        LessonStepKind.independentPractice,
      ];
    }
    if (count == 3) {
      return const <LessonStepKind>[
        LessonStepKind.workedExample,
        LessonStepKind.guidedTry,
        LessonStepKind.independentPractice,
      ];
    }
    if (count == 4) {
      return const <LessonStepKind>[
        LessonStepKind.workedExample,
        LessonStepKind.guidedTry,
        LessonStepKind.independentPractice,
        LessonStepKind.exitTicket,
      ];
    }
    return const <LessonStepKind>[
      LessonStepKind.workedExample,
      LessonStepKind.guidedTry,
      LessonStepKind.independentPractice,
      LessonStepKind.transfer,
      LessonStepKind.exitTicket,
    ];
  }

  LessonStep _composeMissionStep({
    required LessonStep step,
    required ContentActivity? allocatedActivity,
    required String missionObjective,
    required ContentActivity? firstAllocatedActivity,
  }) {
    if (allocatedActivity != null) {
      return _stepForAllocatedActivity(step, allocatedActivity);
    }

    return switch (step.kind) {
      // The topic/level summary is framing copy, not teaching copy.
      LessonStepKind.objective =>
        _copyLessonStep(step, body: missionObjective),

      // Preserve authored blueprint teaching. Replacing this with the mission
      // objective is what previously made consecutive See it pages say the
      // same thing.
      LessonStepKind.explanation => step,

      // Capacity-aware runs may contain fewer allocated training activities.
      // Keep those residual stages non-interactive and role-specific without
      // leaking an unallocated activity prompt or repeating the topic summary.
      LessonStepKind.workedExample ||
      LessonStepKind.guidedTry ||
      LessonStepKind.independentPractice ||
      LessonStepKind.transfer ||
      LessonStepKind.exitTicket =>
        _stepWithoutAllocatedActivity(step),

      // Reteach keeps its authored strategy text. If this run has an allocated
      // activity, its hints can still support the learner without replacing the
      // reteach explanation with another copy of the worked item.
      LessonStepKind.reteach => _copyLessonStep(
          step,
          hints:
              firstAllocatedActivity?.hints.map((hint) => hint.text).toList(),
        ),
      LessonStepKind.review => step,
    };
  }

  LessonStep _stepWithoutAllocatedActivity(LessonStep step) {
    final body = switch (step.kind) {
      LessonStepKind.workedExample => step.body,
      LessonStepKind.guidedTry =>
        'Explain one small example of this idea in your own words.',
      LessonStepKind.independentPractice =>
        'Use the idea independently on a fresh example.',
      LessonStepKind.transfer =>
        'Tell where this idea could be useful outside this lesson.',
      LessonStepKind.exitTicket =>
        'Finish one independent check without a clue.',
      LessonStepKind.objective ||
      LessonStepKind.explanation ||
      LessonStepKind.reteach ||
      LessonStepKind.review =>
        step.body,
    };
    return LessonStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      body: body,
      activityId: null,
      hints: step.hints,
      requiresIndependentResponse: false,
    );
  }

  CurriculumTopic? _curriculumTopicForLevel(LearningLevel level) {
    for (final topic in curriculumTopics) {
      if (topic.id == level.curriculumTopicId &&
          topic.classNumber == level.classNumber &&
          topic.gameIds.contains(level.gameId)) {
        return topic;
      }
    }
    return null;
  }

  LessonStep _copyLessonStep(
    LessonStep step, {
    String? body,
    List<String>? hints,
  }) {
    return LessonStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      body: body ?? step.body,
      activityId: step.activityId,
      hints: hints == null || hints.isEmpty ? step.hints : hints,
      requiresIndependentResponse: step.requiresIndependentResponse,
    );
  }

  LessonStep _stepForAllocatedActivity(
    LessonStep step,
    ContentActivity activity,
  ) {
    final activityHints = activity.hints.map((hint) => hint.text).toList();
    final body = switch (step.kind) {
      LessonStepKind.workedExample =>
        '${activity.prompt} ${activity.explanation}'.trim(),
      LessonStepKind.guidedTry ||
      LessonStepKind.independentPractice ||
      LessonStepKind.exitTicket =>
        activity.prompt,
      LessonStepKind.transfer =>
        'Solve this fresh mission without a clue, then explain why your method works: ${activity.prompt}',
      LessonStepKind.objective ||
      LessonStepKind.explanation ||
      LessonStepKind.reteach ||
      LessonStepKind.review =>
        step.body,
    };
    return LessonStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      body: body,
      activityId: activity.id,
      hints: activityHints.isEmpty ? step.hints : activityHints,
      requiresIndependentResponse: step.requiresIndependentResponse,
    );
  }

  List<LessonFlow> buildClassDraftCoverage({
    required ContentRepository repository,
    required int classNumber,
  }) {
    final contract = repository.curriculum.classPack(classNumber);
    if (contract == null) return const <LessonFlow>[];
    return List<LessonFlow>.unmodifiable(
      contract.competencies.map(
        (competency) => buildForCompetency(
          repository: repository,
          classNumber: classNumber,
          competencyId: competency.id,
        ),
      ),
    );
  }

  /// Backward-compatible text boundary for callers that still ask the lesson
  /// engine for response copy. The contextual feedback engine is the single
  /// coaching implementation; this method no longer maintains a second
  /// misconception/answer-reveal policy.
  String feedbackFor({
    required ContentActivity activity,
    required bool correct,
    Object? selectedAnswer,
  }) {
    const evaluator = ActivityResponseEvaluator();
    const resolver = GameplayActivityResolver();
    const feedbackEngine = ContextualFeedbackEngine();
    final evaluation = correct
        ? ActivityEvaluation(correct: true, response: selectedAnswer)
        : evaluator.evaluate(activity, selectedAnswer);
    final feedback = feedbackEngine.build(
      activity: activity,
      spec: resolver.resolve(activity),
      evaluation: evaluation,
      attemptNumber: 1,
      revealedHintCount: 0,
      hasUnrevealedHint: activity.hints.isNotEmpty,
      rescueAvailable: true,
    );
    return <String>[feedback.message, feedback.strategy]
        .where((text) => text.trim().isNotEmpty)
        .join(' ');
  }

  bool _isFallbackExperiment(ContentActivity activity) =>
      activity.correctResponseRule['type'] == 'experimentOutcome' &&
      activity.payload['fallback'] == true;

  ContentActivity? _teachingExample(
    List<ContentActivity> activities,
    int targetDifficulty,
  ) {
    if (activities.isEmpty) return null;
    final lower = activities
        .where((activity) => activity.difficulty < targetDifficulty)
        .toList(growable: false);
    if (lower.isNotEmpty) return lower.last;
    return activities.first;
  }

  String _explanation(
    CompetencyContract competency,
    ContentActivity? example,
  ) {
    if (example == null) {
      return '${competency.objective} Start by identifying what changes, what stays the same, and which rule or evidence supports the answer.';
    }
    return '${competency.objective} A useful example is: ${example.explanation}';
  }

  String _workedExample(ContentActivity? activity, String objective) {
    if (activity == null) {
      return 'Take one simple case of “$objective”. Name the information you know, choose a strategy, carry it out, and check the result.';
    }
    return '${activity.prompt} ${activity.explanation} Notice the strategy before trying a new question.';
  }

  String _conceptualHint(String objective, ContentActivity? activity) {
    if (activity != null && activity.hints.isNotEmpty) {
      return activity.hints.first.text;
    }
    return 'Think about the main idea: $objective';
  }

  String _workedHint(ContentActivity? activity, String objective) {
    if (activity != null && activity.hints.length > 1) {
      return activity.hints[1].text;
    }
    if (activity != null) {
      return 'Work one step at a time. ${activity.explanation}';
    }
    return 'Break the task into smaller steps, then check each step against: $objective';
  }

  String _reteach(String objective, ContentActivity? activity) {
    final exampleText = activity == null
        ? 'Use a smaller or more concrete example.'
        : 'Return to this example: ${activity.prompt}';
    return '$exampleText Point to the important information, say the rule aloud, then try one changed example. Goal: $objective';
  }
}
