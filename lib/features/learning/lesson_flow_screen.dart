import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/content_activity.dart';
import '../../core/content/content_repository.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/activity_response_evaluator.dart';
import '../../core/learning/lesson_engine.dart';
import '../../core/learning/learning_models.dart';
import '../../core/services/feedback_service.dart';
import 'lesson_activity_interaction.dart';

class LessonFlowScreen extends StatefulWidget {
  const LessonFlowScreen({
    required this.level,
    super.key,
  })  : classNumber = null,
        competencyId = null,
        title = null;

  const LessonFlowScreen.forCompetency({
    required this.classNumber,
    required this.competencyId,
    required this.title,
    super.key,
  }) : level = null;

  final LearningLevel? level;
  final int? classNumber;
  final String? competencyId;
  final String? title;

  bool get isDirectCompetency => level == null;

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  int index = 0;
  final Set<int> _shownHints = <int>{};
  final Set<String> _completedInteractiveSteps = <String>{};

  @override
  Widget build(BuildContext context) {
    final repository = BrightQuestScope.contentOf(context);
    final level = widget.level;
    final flow = level != null
        ? const LessonEngine().buildForLevel(
            repository: repository,
            level: level,
          )
        : const LessonEngine().buildForCompetency(
            repository: repository,
            classNumber: widget.classNumber!,
            competencyId: widget.competencyId!,
          );
    final step = flow.steps[index.clamp(0, flow.steps.length - 1).toInt()];
    final activity = step.activityId == null
        ? null
        : repository.activityById(step.activityId!);
    final needsResponse = _needsResponse(step, activity);
    final canContinue =
        !needsResponse || _completedInteractiveSteps.contains(step.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? level!.title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                LinearProgressIndicator(
                  value: (index + 1) / flow.steps.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(step.body, style: const TextStyle(height: 1.5)),
                        if (step.hints.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: _shownHints.length >= step.hints.length
                                ? null
                                : () {
                                    final nextHint = _shownHints.length;
                                    setState(() {
                                      _shownHints.add(nextHint);
                                    });
                                    FeedbackService.hint(
                                      BrightQuestScope.of(context),
                                      step.hints[nextHint],
                                    );
                                  },
                            icon: const Icon(Icons.lightbulb_outline_rounded),
                            label: Text(
                              _shownHints.isEmpty
                                  ? 'Concept clue'
                                  : 'Worked step',
                            ),
                          ),
                          for (final hintIndex in _shownHints.toList()..sort())
                            if (hintIndex < step.hints.length)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(step.hints[hintIndex]),
                                  ),
                                ),
                              ),
                        ],
                        if (step.kind == LessonStepKind.explanation ||
                            step.kind == LessonStepKind.workedExample) ...[
                          const SizedBox(height: 14),
                          TextButton.icon(
                            onPressed: () => _showWhy(context, step.body),
                            icon: const Icon(Icons.psychology_alt_rounded),
                            label: const Text('Show me why'),
                          ),
                        ],
                        if (needsResponse && activity != null) ...[
                          if (activity.payload['masteryEligible'] == false) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              label:
                                  'Practice only. Secure mastery needs an adult-reviewed constructed response.',
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.edit_note_rounded),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Practice only — this activity builds the skill, but it does not award secure mastery. A constructed response still needs adult review.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          LessonActivityInteraction(
                            key: ValueKey(step.id),
                            activity: activity,
                            experimentChoices:
                                _experimentChoices(repository, activity),
                            onAttempt: (evaluation, retries, responseTimeMs) =>
                                _recordAttempt(
                              context: context,
                              step: step,
                              activity: activity,
                              evaluation: evaluation,
                              retries: retries,
                              responseTimeMs: responseTimeMs,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: index == 0
                          ? null
                          : () => setState(() {
                                index -= 1;
                                _shownHints.clear();
                              }),
                      child: const Text('Back'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: !canContinue
                          ? null
                          : index == flow.steps.length - 1
                              ? () => Navigator.of(context).pop(true)
                              : () => setState(() {
                                    index += 1;
                                    _shownHints.clear();
                                  }),
                      child: Text(
                        !canContinue
                            ? 'Answer to continue'
                            : index == flow.steps.length - 1
                                ? widget.isDirectCompetency
                                    ? 'Finish lesson'
                                    : 'Start practice'
                                : 'Continue',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  flow.reviewStatus == 'approved'
                      ? 'Content reviewed.'
                      : 'Draft learning support — teacher review is still pending.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _needsResponse(LessonStep step, ContentActivity? activity) =>
      activity != null &&
      (step.kind == LessonStepKind.guidedTry ||
          step.kind == LessonStepKind.independentPractice ||
          step.kind == LessonStepKind.transfer ||
          step.kind == LessonStepKind.exitTicket);

  List<String> _experimentChoices(
    ContentRepository repository,
    ContentActivity activity,
  ) {
    if (activity.correctResponseRule['type'] != 'experimentOutcome') {
      return const <String>[];
    }
    final choices = <String>{};
    for (final candidate
        in repository.packForClass(activity.classNumber).activities) {
      if (candidate.gameId != 'science_lab') continue;
      final required = candidate.payload['requiredIngredients'];
      if (required is List) choices.addAll(required.whereType<String>());
    }
    return choices.toList()..sort();
  }

  void _recordAttempt({
    required BuildContext context,
    required LessonStep step,
    required ContentActivity activity,
    required ActivityEvaluation evaluation,
    required int retries,
    required int responseTimeMs,
  }) {
    final controller = BrightQuestScope.of(context);
    final now = DateTime.now();
    final kind = switch (step.kind) {
      LessonStepKind.guidedTry => LearningAttemptKind.guided,
      LessonStepKind.transfer => LearningAttemptKind.transfer,
      _ => LearningAttemptKind.independent,
    };
    final masteryEligible = activity.payload['masteryEligible'] != false;
    if (masteryEligible) {
      controller.recordLearningEvidence(
        AttemptEvidence(
          id: 'lesson:${controller.activeProfileId}:${now.microsecondsSinceEpoch}',
          profileId: controller.activeProfileId,
          classNumber: activity.classNumber,
          competencyId: activity.competencyId,
          itemId: activity.id,
          kind: kind,
          correct: evaluation.correct,
          hintLevel: _shownHints.length.clamp(0, 2).toInt(),
          retries: retries.clamp(0, 99).toInt(),
          responseTimeMs: responseTimeMs.clamp(0, 3600000).toInt(),
          confidence: evaluation.correct ? (retries == 0 ? 0.88 : 0.68) : 0.45,
          recordedAtIso: now.toIso8601String(),
          misconceptionId: evaluation.misconceptionId,
          sourceGameId: activity.gameId,
        ),
      );
    }
    const evaluator = ActivityResponseEvaluator();
    if (evaluation.correct) {
      FeedbackService.correct(
        controller,
        answer: evaluator.responseLabel(evaluation.response),
        detail: activity.explanation,
      );
      setState(() => _completedInteractiveSteps.add(step.id));
    } else {
      FeedbackService.wrong(
        controller,
        answer: evaluator.responseLabel(evaluation.response),
        guidance: const LessonEngine().feedbackFor(
          activity: activity,
          correct: false,
          selectedAnswer: evaluation.response,
        ),
      );
    }
  }

  void _showWhy(BuildContext context, String text) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Why this works\n\n$text\n\nSay the rule in your own words, then change one part of the example and check whether the same reasoning still works.',
            style: const TextStyle(height: 1.5),
          ),
        ),
      ),
    );
  }
}
