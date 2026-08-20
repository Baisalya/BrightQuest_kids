import '../content/content_activity.dart';
import '../content/content_repository.dart';
import '../curriculum/content_contract.dart';
import '../curriculum/curriculum_models.dart';

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
  }) {
    final gameCandidates = repository.activitiesForGame(
      level.classNumber,
      level.gameId,
      difficulty: level.difficulty,
    );
    final levelCandidates = gameCandidates
        .where((activity) => activity.difficulty == level.difficulty)
        .toList(growable: false);
    final candidates =
        levelCandidates.isEmpty ? gameCandidates : levelCandidates;
    return buildForCompetency(
      repository: repository,
      classNumber: level.classNumber,
      competencyId: candidates.first.competencyId,
    );
  }

  LessonFlow buildForCompetency({
    required ContentRepository repository,
    required int classNumber,
    required String competencyId,
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

    final activities = repository
        .activitiesForClass(classNumber)
        .where(
          (activity) => activity.allCompetencyIds.contains(competencyId),
        )
        .toList()
      ..sort((a, b) {
        final difficulty = a.difficulty.compareTo(b.difficulty);
        return difficulty != 0 ? difficulty : a.id.compareTo(b.id);
      });

    final example = activities.isEmpty ? null : activities.first;
    final blueprintActivities = blueprint?.independentSourceActivityIds
            .map(repository.activityById)
            .whereType<ContentActivity>()
            .where(activities.contains)
            .toList(growable: false) ??
        const <ContentActivity>[];
    final independent = blueprintActivities.isNotEmpty
        ? blueprintActivities.first
        : activities.isEmpty
            ? null
            : activities[activities.length ~/ 2];
    final transfer = activities.length < 2 ? independent : activities.last;
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
        activityId: example?.id,
      ),
      LessonStep(
        id: '$competencyId:guided',
        kind: LessonStepKind.guidedTry,
        title: 'Try it with a clue',
        body: blueprint?.guidedPrompt ??
            example?.prompt ??
            'Explain one small example of this idea in your own words.',
        activityId: example?.id,
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
        body:
            'Finish one independent check and say the key idea you would teach to a friend.',
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

  String feedbackFor({
    required ContentActivity activity,
    required bool correct,
    Object? selectedAnswer,
  }) {
    if (correct) {
      return 'Yes. ${activity.explanation}';
    }
    String? misconceptionId;
    for (final distractor in activity.distractors) {
      if (distractor.value == selectedAnswer) {
        misconceptionId = distractor.misconceptionId;
        break;
      }
    }
    final misconception = _plainMisconception(misconceptionId);
    return '$misconception ${activity.explanation}'.trim();
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

  String _plainMisconception(String? id) {
    if (id == null || id.isEmpty) {
      return 'That answer does not fit the rule yet. Compare it with the important information in the question.';
    }
    if (id.contains('arithmetic')) {
      return 'A calculation step may have changed the value. Check the operation and each place-value step.';
    }
    if (id.contains('direction')) {
      return 'The direction may have been read from the wrong starting point. Face the starting direction first.';
    }
    if (id.contains('grammar')) {
      return 'The word may be doing a different job in this sentence. Check what the word names, does, or describes.';
    }
    if (id.contains('fraction')) {
      return 'The whole may not have been split into equal parts. Check the size and number of equal pieces.';
    }
    return 'This choice matches a common mix-up. Re-read the clue and explain why each part of your answer fits.';
  }
}
