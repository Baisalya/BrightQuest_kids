import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/content_activity.dart';
import '../../core/learning/diagnostic_engine.dart';
import '../../core/learning/learning_models.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  DateTime _questionStarted = DateTime.now();
  double _confidence = 0.7;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final progress = controller.diagnosticProgress;

    if (!progress.started || progress.classNumber != controller.selectedClass) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discovery Check')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🧭', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(
                        'Find your best starting trail',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This is not an exam and there is no harsh score. A small set of questions helps BrightQuest choose what to teach first. You can leave and continue later.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          controller.startOrRestartDiagnostic(repository);
                          setState(() => _questionStarted = DateTime.now());
                        },
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Start discovery check'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (progress.completed) {
      final recommendations = controller.learningRecommendations(limit: 4);
      return Scaffold(
        appBar: AppBar(title: const Text('Discovery Check')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: Text('🌟', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 12),
            Text(
              'Starting trail ready',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'BrightQuest uses several pieces of evidence before suggesting support. It never ranks one child against another.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey<String>('discovery_check_again'),
              onPressed: () {
                controller.startOrRestartDiagnostic(repository);
                setState(() {
                  _questionStarted = DateTime.now();
                  _confidence = 0.7;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check my skills again'),
            ),
            const SizedBox(height: 10),
            const Text(
              'A re-check stays short and rotates recently used questions when another reviewed option exists.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (final recommendation in recommendations)
              Card(
                child: ListTile(
                  leading: Icon(_stateIcon(recommendation.state)),
                  title: Text(_stateLabel(recommendation.state)),
                  subtitle: Text(recommendation.reason),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue learning'),
            ),
          ],
        ),
      );
    }

    final activity =
        const DiagnosticEngine().currentActivity(repository, progress);
    if (activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discovery Check')),
        body: const Center(child: Text('This diagnostic item is unavailable.')),
      );
    }

    final choices = _choices(activity);
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery Check')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LinearProgressIndicator(
              value: progress.itemIds.isEmpty
                  ? 0
                  : progress.currentIndex / progress.itemIds.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${progress.currentIndex + 1} of ${progress.itemIds.length}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  activity.prompt,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (choices.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'This item needs its full game interaction, so it is skipped in the short discovery check.',
                  ),
                ),
              )
            else
              ...choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonal(
                    onPressed: _busy ? null : () => _answer(activity, choice),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('$choice'),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text('How sure do you feel?',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _confidence,
              min: 0.35,
              max: 1,
              divisions: 2,
              label: _confidence < 0.55
                  ? 'Not sure'
                  : _confidence < 0.9
                      ? 'Mostly sure'
                      : 'Very sure',
              onChanged: (value) => setState(() => _confidence = value),
            ),
            if (choices.isEmpty)
              OutlinedButton(
                onPressed: _busy ? null : () => _skipUnsupported(activity),
                child: const Text('Skip this one'),
              ),
          ],
        ),
      ),
    );
  }

  List<Object?> _choices(ContentActivity activity) {
    final raw = activity.payload['choices'];
    if (raw is List) return List<Object?>.from(raw);
    return const <Object?>[];
  }

  Object? _correctValue(ContentActivity activity) =>
      activity.correctResponseRule['value'] ?? activity.payload['answer'];

  String? _misconception(ContentActivity activity, Object? choice) {
    for (final distractor in activity.distractors) {
      if (distractor.value == choice) return distractor.misconceptionId;
    }
    return null;
  }

  Future<void> _answer(ContentActivity activity, Object? choice) async {
    setState(() => _busy = true);
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final elapsed = DateTime.now().difference(_questionStarted).inMilliseconds;
    final correct = choice == _correctValue(activity);
    controller.recordDiagnosticEvidence(
      repository: repository,
      correct: correct,
      responseTimeMs: elapsed,
      confidence: _confidence,
      misconceptionId: correct ? null : _misconception(activity, choice),
    );
    if (!mounted) return;
    setState(() {
      _questionStarted = DateTime.now();
      _confidence = 0.7;
      _busy = false;
    });
  }

  Future<void> _skipUnsupported(ContentActivity activity) async {
    setState(() => _busy = true);
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    controller.recordDiagnosticEvidence(
      repository: repository,
      correct: false,
      responseTimeMs: 0,
      confidence: 0.5,
      misconceptionId: 'diagnostic_interaction_unavailable',
    );
    if (!mounted) return;
    setState(() {
      _questionStarted = DateTime.now();
      _busy = false;
    });
  }

  static String _stateLabel(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.needsSupport => 'Needs support',
        LearningEvidenceState.secure => 'Strong evidence',
        LearningEvidenceState.masteredNow => 'Ready to stretch',
        _ => 'Ready to learn',
      };

  static IconData _stateIcon(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.needsSupport => Icons.volunteer_activism_rounded,
        LearningEvidenceState.secure => Icons.verified_rounded,
        LearningEvidenceState.masteredNow => Icons.rocket_launch_rounded,
        _ => Icons.school_rounded,
      };
}
