import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/content_activity.dart';
import '../../core/learning/learning_models.dart';

class PowerReviewScreen extends StatefulWidget {
  const PowerReviewScreen({super.key});

  @override
  State<PowerReviewScreen> createState() => _PowerReviewScreenState();
}

class _PowerReviewScreenState extends State<PowerReviewScreen> {
  int index = 0;
  DateTime _started = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final tasks = controller.dueReviewTasks(limit: 10);
    if (tasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Power Review')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nothing is due right now. BrightQuest will bring skills back after a helpful delay—no streak pressure.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final safeIndex = index.clamp(0, tasks.length - 1).toInt();
    final task = tasks[safeIndex];
    final activity = _reviewActivity(repository, task);
    if (activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Power Review')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('A full-game review is needed for this skill.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to learning worlds'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final choices = List<Object?>.from(activity.payload['choices'] as List);
    final answer =
        activity.correctResponseRule['value'] ?? activity.payload['answer'];
    return Scaffold(
      appBar: AppBar(title: const Text('Power Review')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(
            value: (safeIndex + 1) / tasks.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 18),
          const Text(
            'Try this without a hint. It is okay if the idea needs another lesson.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                activity.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                onPressed: () {
                  final correct = choice == answer;
                  final elapsed =
                      DateTime.now().difference(_started).inMilliseconds;
                  String? misconception;
                  for (final distractor in activity.distractors) {
                    if (distractor.value == choice) {
                      misconception = distractor.misconceptionId;
                      break;
                    }
                  }
                  controller.recordLearningEvidence(
                    AttemptEvidence(
                      id: 'e:${controller.activeProfileId}:${DateTime.now().microsecondsSinceEpoch}',
                      profileId: controller.activeProfileId,
                      classNumber: controller.selectedClass,
                      competencyId: task.competencyId,
                      itemId: activity.id,
                      kind: LearningAttemptKind.review,
                      correct: correct,
                      hintLevel: 0,
                      retries: 0,
                      responseTimeMs: elapsed,
                      confidence: 0.85,
                      recordedAtIso: DateTime.now().toIso8601String(),
                      misconceptionId: correct ? null : misconception,
                      sourceGameId: activity.gameId,
                    ),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        correct
                            ? 'Nice retention check. ${activity.explanation}'
                            : 'This skill will come back sooner. ${activity.explanation}',
                      ),
                    ),
                  );
                  setState(() {
                    if (index >= tasks.length - 1) {
                      index = 0;
                    } else {
                      index += 1;
                    }
                    _started = DateTime.now();
                  });
                },
                child: Text('$choice'),
              ),
            ),
        ],
      ),
    );
  }

  ContentActivity? _reviewActivity(repository, ReviewTask task) {
    final source = task.sourceItemId == null
        ? null
        : repository.activityById(task.sourceItemId!);
    if (_supportsChoice(source)) return source;
    final candidates = repository.activitiesForCompetency(
      task.classNumber,
      task.competencyId,
    );
    for (final activity in candidates.reversed) {
      if (_supportsChoice(activity)) return activity;
    }
    return null;
  }

  bool _supportsChoice(ContentActivity? activity) =>
      activity != null &&
      activity.payload['masteryEligible'] != false &&
      activity.payload['choices'] is List;
}
