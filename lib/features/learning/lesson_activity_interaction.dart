import 'package:flutter/material.dart';

import '../../core/content/content_activity.dart';
import '../../core/content/game_content.dart';
import '../../core/learning/activity_response_evaluator.dart';
import '../../core/learning/lesson_engine.dart';

typedef LessonAttemptCallback = void Function(
  ActivityEvaluation evaluation,
  int previousRetries,
  int responseTimeMs,
);

/// Renders every response rule used by the bundled BrightQuest activities.
/// LessonFlowScreen owns progress/evidence; this widget only collects and
/// evaluates a child's concrete response.
class LessonActivityInteraction extends StatefulWidget {
  const LessonActivityInteraction({
    required this.activity,
    required this.onAttempt,
    this.experimentChoices = const <String>[],
    super.key,
  });

  final ContentActivity activity;
  final LessonAttemptCallback onAttempt;
  final List<String> experimentChoices;

  @override
  State<LessonActivityInteraction> createState() =>
      _LessonActivityInteractionState();
}

class _LessonActivityInteractionState extends State<LessonActivityInteraction> {
  static const _evaluator = ActivityResponseEvaluator();

  Object? _singleChoice;
  int? _selectedSlices;
  final Map<String, String> _grammar = <String, String>{};
  final List<_WordToken> _selectedWords = <_WordToken>[];
  late List<_WordToken> _availableWords;
  final List<CodingCommand> _commands = <CodingCommand>[];
  final Set<String> _selectedIngredients = <String>{};
  ActivityEvaluation? _evaluation;
  int _attempts = 0;
  DateTime _attemptStarted = DateTime.now();

  @override
  void initState() {
    super.initState();
    _prepareActivity();
  }

  @override
  void didUpdateWidget(covariant LessonActivityInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity.id != widget.activity.id) _prepareActivity();
  }

  void _prepareActivity() {
    _singleChoice = null;
    _selectedSlices = null;
    _grammar.clear();
    _selectedWords.clear();
    _commands.clear();
    _selectedIngredients.clear();
    _evaluation = null;
    _attempts = 0;
    _attemptStarted = DateTime.now();
    final rawWords = widget.activity.payload['words'];
    final tokens = rawWords is List
        ? <_WordToken>[
            for (var index = 0; index < rawWords.length; index += 1)
              _WordToken(index, '${rawWords[index]}'),
          ]
        : <_WordToken>[];
    _availableWords = _stableShuffle(tokens, widget.activity.id);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.activity.correctResponseRule['type'];
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.activity.prompt,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            switch (type) {
              'exactNumber' || 'exactText' => _choiceInteraction(context),
              'selectedSlices' => _fractionInteraction(context),
              'orderedWords' => _wordOrderInteraction(context),
              'grammarParts' => _grammarInteraction(context),
              'reachGridGoal' => _codingInteraction(context),
              'experimentOutcome' => _experimentInteraction(context),
              _ => const Text('This activity rule is not supported.'),
            },
            const SizedBox(height: 14),
            if (_evaluation case final evaluation?)
              _FeedbackCard(
                correct: evaluation.correct,
                text: const LessonEngine().feedbackFor(
                  activity: widget.activity,
                  correct: evaluation.correct,
                  selectedAnswer: evaluation.response,
                ),
              ),
            const SizedBox(height: 12),
            if (_evaluation?.correct == false)
              OutlinedButton.icon(
                onPressed: _tryAgain,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              )
            else
              FilledButton.icon(
                onPressed: _canSubmit && _evaluation == null ? _submit : null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  type == 'reachGridGoal' ? 'Run my code' : 'Check my answer',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _choiceInteraction(BuildContext context) {
    final choices = _evaluator.choicesFor(widget.activity);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final choice in choices)
          ChoiceChip(
            label: Text('$choice'),
            selected: _singleChoice == choice,
            onSelected: _evaluation == null
                ? (_) => setState(() => _singleChoice = choice)
                : null,
          ),
      ],
    );
  }

  Widget _fractionInteraction(BuildContext context) {
    final total = widget.activity.payload['totalSlices'] as int;
    return Column(
      children: [
        Text(
          _selectedSlices == null
              ? 'Choose how many of $total equal slices.'
              : 'Selected $_selectedSlices of $total slices',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var value = 1; value <= total; value += 1)
              ChoiceChip(
                label: Text('$value'),
                selected: _selectedSlices == value,
                onSelected: _evaluation == null
                    ? (_) => setState(() => _selectedSlices = value)
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _wordOrderInteraction(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedWords.isEmpty)
                const Text('Tap words below to build the sentence.'),
              for (final token in _selectedWords)
                InputChip(
                  label: Text(token.word),
                  onDeleted: _evaluation == null
                      ? () => setState(() {
                            _selectedWords.remove(token);
                            _availableWords.add(token);
                          })
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final token in _availableWords)
              ActionChip(
                label: Text(token.word),
                onPressed: _evaluation == null
                    ? () => setState(() {
                          _availableWords.remove(token);
                          _selectedWords.add(token);
                        })
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _grammarInteraction(BuildContext context) {
    final sentence = '${widget.activity.payload['sentence']}';
    final words = RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => match.group(0)!)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(sentence, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        for (final part in const <String>['noun', 'verb', 'adjective']) ...[
          Text(
            'Choose the $part',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final word in words)
                ChoiceChip(
                  label: Text(word),
                  selected: _sameText(_grammar[part], word),
                  onSelected: _evaluation == null
                      ? (_) => setState(() => _grammar[part] = word)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _codingInteraction(BuildContext context) {
    final payload = widget.activity.payload;
    final maxCommands = payload['maxCommands'] as int;
    final rocks = List<String>.from(payload['obstacles'] as List);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Robot (${payload['startX']}, ${payload['startY']}) → Goal (${payload['goalX']}, ${payload['goalY']})\n'
          'Facing ${payload['startDirection']}${rocks.isEmpty ? '' : ' • Rocks: ${rocks.join(', ')}'}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (_commands.isEmpty) Text('Build up to $maxCommands commands.'),
              for (var index = 0; index < _commands.length; index += 1)
                InputChip(
                  label: Text(
                    ActivityResponseEvaluator.commandLabel(_commands[index]),
                  ),
                  onDeleted: _evaluation == null
                      ? () => setState(() => _commands.removeAt(index))
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final command in CodingCommand.values)
              ActionChip(
                avatar: Icon(_commandIcon(command), size: 18),
                label: Text(ActivityResponseEvaluator.commandLabel(command)),
                onPressed: _evaluation == null && _commands.length < maxCommands
                    ? () => setState(() => _commands.add(command))
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _experimentInteraction(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose ingredients, then test your mixture.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final ingredient in widget.experimentChoices)
              FilterChip(
                label: Text(ingredient),
                selected: _selectedIngredients.contains(ingredient),
                onSelected: _evaluation == null
                    ? (selected) => setState(() {
                          if (selected) {
                            _selectedIngredients.add(ingredient);
                          } else {
                            _selectedIngredients.remove(ingredient);
                          }
                        })
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  bool get _canSubmit {
    return switch (widget.activity.correctResponseRule['type']) {
      'exactNumber' || 'exactText' => _singleChoice != null,
      'selectedSlices' => _selectedSlices != null,
      'orderedWords' => _availableWords.isEmpty && _selectedWords.isNotEmpty,
      'grammarParts' => _grammar.length == 3,
      'reachGridGoal' => _commands.isNotEmpty,
      'experimentOutcome' => _selectedIngredients.isNotEmpty,
      _ => false,
    };
  }

  Object? get _response {
    return switch (widget.activity.correctResponseRule['type']) {
      'exactNumber' || 'exactText' => _singleChoice,
      'selectedSlices' => _selectedSlices,
      'orderedWords' => _selectedWords.map((token) => token.word).toList(),
      'grammarParts' => Map<String, String>.from(_grammar),
      'reachGridGoal' => List<CodingCommand>.from(_commands),
      'experimentOutcome' => _selectedIngredients.toList()..sort(),
      _ => null,
    };
  }

  void _submit() {
    final elapsed = DateTime.now().difference(_attemptStarted).inMilliseconds;
    final evaluation = _evaluator.evaluate(widget.activity, _response);
    widget.onAttempt(evaluation, _attempts, elapsed);
    setState(() {
      _attempts += 1;
      _evaluation = evaluation;
    });
  }

  void _tryAgain() {
    setState(() {
      _singleChoice = null;
      _selectedSlices = null;
      _grammar.clear();
      _commands.clear();
      _selectedIngredients.clear();
      _evaluation = null;
      _attemptStarted = DateTime.now();
      final words = <_WordToken>[..._selectedWords, ..._availableWords];
      _selectedWords.clear();
      _availableWords = _stableShuffle(words, widget.activity.id);
    });
  }

  static bool _sameText(String? left, String right) =>
      left?.toLowerCase() == right.toLowerCase();

  static List<_WordToken> _stableShuffle(
    List<_WordToken> values,
    String seed,
  ) {
    final result = List<_WordToken>.from(values)
      ..sort((a, b) {
        final aScore =
            (seed.codeUnitAt(a.id % seed.length) * 31 + a.id * 17) % 101;
        final bScore =
            (seed.codeUnitAt(b.id % seed.length) * 31 + b.id * 17) % 101;
        final score = aScore.compareTo(bScore);
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    if (result.length > 1 &&
        result.asMap().entries.every((entry) => entry.value.id == entry.key)) {
      result.add(result.removeAt(0));
    }
    return result;
  }

  static IconData _commandIcon(CodingCommand command) => switch (command) {
        CodingCommand.move => Icons.arrow_upward_rounded,
        CodingCommand.turnLeft => Icons.turn_left_rounded,
        CodingCommand.turnRight => Icons.turn_right_rounded,
        CodingCommand.repeatLast => Icons.replay_rounded,
      };
}

class _WordToken {
  const _WordToken(this.id, this.word);

  final int id;
  final String word;
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.correct, required this.text});

  final bool correct;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = correct ? const Color(0xFF137A49) : const Color(0xFF9A5A00);
    return Semantics(
      liveRegion: true,
      label: '${correct ? 'Correct' : 'Try again'}. $text',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct ? Icons.celebration_rounded : Icons.tips_and_updates,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
