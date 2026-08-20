import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/learning/lesson_engine.dart';

class LessonFlowScreen extends StatefulWidget {
  const LessonFlowScreen({
    required this.level,
    super.key,
  });

  final LearningLevel level;

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  int index = 0;
  final Set<int> _shownHints = <int>{};

  @override
  Widget build(BuildContext context) {
    final repository = BrightQuestScope.contentOf(context);
    final flow = const LessonEngine().buildForLevel(
      repository: repository,
      level: widget.level,
    );
    final step = flow.steps[index.clamp(0, flow.steps.length - 1).toInt()];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Practice'),
          ),
        ],
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
                            onPressed: () {
                              setState(() {
                                final nextHint = _shownHints.length
                                    .clamp(0, step.hints.length - 1)
                                    .toInt();
                                _shownHints.add(nextHint);
                              });
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
                      onPressed: index == flow.steps.length - 1
                          ? () => Navigator.of(context).pop(true)
                          : () => setState(() {
                                index += 1;
                                _shownHints.clear();
                              }),
                      child: Text(
                        index == flow.steps.length - 1
                            ? 'Start practice'
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
