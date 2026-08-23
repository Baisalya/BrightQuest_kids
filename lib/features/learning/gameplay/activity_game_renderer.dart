import 'package:flutter/material.dart';

import '../../../core/content/content_activity.dart';
import '../../../core/learning/activity_response_evaluator.dart';
import '../../../core/learning/contextual_feedback_engine.dart';
import '../../../core/learning/contextual_feedback_models.dart';
import '../../../core/learning/gameplay_activity_models.dart';
import '../../../core/learning/mission_session_models.dart';
import '../../../core/presentation/game_feel_director.dart';
import '../../../core/presentation/game_feel_models.dart';
import '../../../widgets/bright_design_system.dart';
import '../../../widgets/bright_motion.dart';
import 'activity_game_contract.dart';
import 'activity_game_registry.dart';
import 'learning_game_guidance.dart';
import 'learning_game_stage.dart';

typedef LearningGameAttemptCallback = void Function(
  ActivityEvaluation evaluation,
  int previousRetries,
  int responseTimeMs,
);

/// Orchestrates one authored learning activity without owning mechanic-specific
/// temporary state.
///
/// Individual mini-games live behind [ActivityGameRegistry] and report a
/// response snapshot. This widget is the common lifecycle boundary that owns
/// evaluation, retry accounting, feedback and the lesson-facing attempt event.
class ActivityGameRenderer extends StatefulWidget {
  const ActivityGameRenderer({
    required this.activity,
    required this.spec,
    required this.onAttempt,
    this.experimentChoices = const <String>[],
    this.guidance,
    super.key,
  });

  final ContentActivity activity;
  final LearningGameActivitySpec spec;
  final LearningGameAttemptCallback onAttempt;
  final List<String> experimentChoices;
  final LearningGameGuidance? guidance;

  @override
  State<ActivityGameRenderer> createState() => _ActivityGameRendererState();
}

class _ActivityGameRendererState extends State<ActivityGameRenderer> {
  static const _evaluator = ActivityResponseEvaluator();
  static const _feedbackEngine = ContextualFeedbackEngine();

  GameActivityResponseSnapshot _snapshot =
      const GameActivityResponseSnapshot.empty();
  ActivityEvaluation? _evaluation;
  int _attempts = 0;
  int _interactionRevision = 0;
  DateTime _attemptStarted = DateTime.now();
  final GlobalKey _primaryActionKey = GlobalKey();
  final Set<int> _revealedHintIndices = <int>{};
  bool _rescueRevealed = false;

  @override
  void didUpdateWidget(covariant ActivityGameRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity.id != widget.activity.id ||
        oldWidget.spec.kind != widget.spec.kind) {
      _resetSession();
    }
  }

  void _resetSession() {
    _snapshot = const GameActivityResponseSnapshot.empty();
    _evaluation = null;
    _attempts = 0;
    _interactionRevision += 1;
    _attemptStarted = DateTime.now();
    _revealedHintIndices.clear();
    _rescueRevealed = false;
  }

  @override
  Widget build(BuildContext context) {
    final unrevealedHintCount = widget.guidance == null
        ? 0
        : widget.guidance!.hints.length - _revealedHintIndices.length;
    final feedbackModel = _evaluation == null
        ? null
        : _feedbackEngine.build(
            activity: widget.activity,
            spec: widget.spec,
            evaluation: _evaluation!,
            attemptNumber: _attempts,
            revealedHintCount: _revealedHintIndices.length,
            hasUnrevealedHint: unrevealedHintCount > 0 &&
                (widget.guidance?.canRevealHint(_attempts) ?? false),
            rescueAvailable:
                widget.guidance?.canRevealRescue(_attempts) ?? false,
          );
    final feedback =
        feedbackModel == null ? null : _FeedbackCard(feedback: feedbackModel);

    final retry = _evaluation?.correct == false
        ? OutlinedButton.icon(
            onPressed: _tryAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          )
        : null;

    final submitLabel = switch (widget.spec.kind) {
      LearningGameActivityKind.robotRoute => 'Run my code',
      LearningGameActivityKind.experimentMixer => 'Test my mixture',
      LearningGameActivityKind.fractionBuilder => 'Check my fraction',
      LearningGameActivityKind.sentenceBuilder => 'Check my story',
      LearningGameActivityKind.grammarSort => 'Check my sort',
      LearningGameActivityKind.recyclingSort => 'Check my answer',
      LearningGameActivityKind.themedChoice => 'Check my answer',
      LearningGameActivityKind.unsupported => 'Interaction unavailable',
    };

    final guidancePanel = widget.guidance == null
        ? null
        : _LearningCoachPanel(
            guidance: widget.guidance!,
            revealedHintIndices: _revealedHintIndices,
            hintAvailable: widget.guidance!.canRevealHint(_attempts),
            rescueAvailable: _evaluation?.correct == false &&
                widget.guidance!.canRevealRescue(_attempts),
            rescueRevealed: _rescueRevealed,
            feedback: feedbackModel,
            onRevealNextHint: _revealNextHint,
            onRevealRescue: _revealRescue,
          );

    final interaction = ActivityGameRegistry.build(
      key: ValueKey<String>(
        '${widget.activity.id}:${widget.spec.kind.name}:$_interactionRevision',
      ),
      activity: widget.activity,
      spec: widget.spec,
      locked: _evaluation != null,
      experimentChoices: widget.experimentChoices,
      onResponseChanged: _onResponseChanged,
    );

    return LearningGameStage(
      activity: widget.activity,
      spec: widget.spec,
      interaction: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (guidancePanel != null) ...[
            guidancePanel,
            const SizedBox(height: 14),
          ],
          Text(
            widget.activity.prompt,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          BrightMomentReaction(
            trigger:
                'response:$_interactionRevision:${_snapshot.value}:${_snapshot.ready}',
            kind: BrightMomentKind.selection,
            animateOnMount: false,
            child: interaction,
          ),
        ],
      ),
      feedback: feedback,
      secondaryAction: retry,
      primaryAction: FilledButton.icon(
        key: _primaryActionKey,
        onPressed: _snapshot.ready && _evaluation == null ? _submit : null,
        icon: Icon(
          widget.spec.kind == LearningGameActivityKind.robotRoute
              ? Icons.play_arrow_rounded
              : Icons.check_circle_outline_rounded,
        ),
        label: Text(submitLabel),
      ),
    );
  }

  void _onResponseChanged(GameActivityResponseSnapshot snapshot) {
    if (_evaluation != null) return;
    setState(() => _snapshot = snapshot);
    if (snapshot.ready) _revealPrimaryActionIfReady();
  }

  void _revealPrimaryActionIfReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_snapshot.ready || _evaluation != null) return;
      final actionContext = _primaryActionKey.currentContext;
      if (actionContext == null) return;
      Scrollable.ensureVisible(
        actionContext,
        alignment: 0.92,
        duration: Duration.zero,
      );
    });
  }

  void _revealNextHint() {
    final guidance = widget.guidance;
    if (guidance == null || !guidance.canRevealHint(_attempts)) return;
    final next = List<int>.generate(guidance.hints.length, (index) => index)
        .where((index) => !_revealedHintIndices.contains(index))
        .firstOrNull;
    if (next == null) return;
    setState(() => _revealedHintIndices.add(next));
    guidance.onHintRevealed?.call(next, guidance.hints[next]);
  }

  void _revealRescue() {
    final guidance = widget.guidance;
    if (guidance == null ||
        !guidance.canRevealRescue(_attempts) ||
        _rescueRevealed) {
      return;
    }
    setState(() => _rescueRevealed = true);
    guidance.onHintRevealed?.call(guidance.hints.length, guidance.rescueText!);
  }

  void _submit() {
    if (!_snapshot.ready || _evaluation != null) return;
    final elapsed = DateTime.now().difference(_attemptStarted).inMilliseconds;
    final evaluation = _evaluator.evaluate(widget.activity, _snapshot.value);
    widget.onAttempt(evaluation, _attempts, elapsed);
    setState(() {
      _attempts += 1;
      _evaluation = evaluation;
    });
  }

  void _tryAgain() {
    setState(() {
      _snapshot = const GameActivityResponseSnapshot.empty();
      _evaluation = null;
      _interactionRevision += 1;
      _attemptStarted = DateTime.now();
    });
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final ContextualAttemptFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final color = feedback.correct
        ? const Color(0xFF137A49)
        : feedback.stage == ContextualFeedbackStage.powerUp
            ? const Color(0xFF8A4B00)
            : const Color(0xFF9A5A00);
    final moment = GameFeelDirector.forFeedback(feedback);
    final trigger =
        '${feedback.stage.name}:${feedback.correct}:${feedback.headline}';

    return Semantics(
      liveRegion: true,
      label: feedback.semanticLabel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrightLeoMoment(
              message: '${feedback.worldEmoji} ${feedback.headline}',
              moment: moment,
              trigger: trigger,
              compact: true,
            ),
            const SizedBox(height: 9),
            Text(
              feedback.message,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (feedback.strategy.trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feedback.strategy,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LearningCoachPanel extends StatelessWidget {
  const _LearningCoachPanel({
    required this.guidance,
    required this.revealedHintIndices,
    required this.hintAvailable,
    required this.rescueAvailable,
    required this.rescueRevealed,
    required this.feedback,
    required this.onRevealNextHint,
    required this.onRevealRescue,
  });

  final LearningGameGuidance guidance;
  final Set<int> revealedHintIndices;
  final bool hintAvailable;
  final bool rescueAvailable;
  final bool rescueRevealed;
  final ContextualAttemptFeedback? feedback;
  final VoidCallback onRevealNextHint;
  final VoidCallback onRevealRescue;

  @override
  Widget build(BuildContext context) {
    final coached = guidance.mode == LearningGamePlayMode.coached;
    final accent = coached
        ? const Color(0xFF6D4BE8)
        : guidance.mode == LearningGamePlayMode.mastery
            ? const Color(0xFF9B5D00)
            : guidance.mode == LearningGamePlayMode.checkpoint
                ? const Color(0xFFB45D00)
                : const Color(0xFF176D7A);
    final unrevealedHints = guidance.hints.length - revealedHintIndices.length;
    final mediaSize = MediaQuery.sizeOf(context);
    final wideShortViewport = mediaSize.width >= 600 && mediaSize.height < 820;

    return Semantics(
      container: true,
      label: '${guidance.modeLabel}. ${guidance.modeMessage}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (coached && !wideShortViewport)
              BrightLeoMoment(
                message: '${guidance.modeLabel}: ${guidance.modeMessage}',
                moment: GameFeelDirector.forSessionPhase(
                  MissionSessionPhase.tryWithHelp,
                ),
                trigger: 'coach:${revealedHintIndices.length}:$rescueRevealed',
                compact: true,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coached
                        ? '🦁'
                        : guidance.mode == LearningGamePlayMode.mastery
                            ? '👑'
                            : guidance.mode == LearningGamePlayMode.challenge
                                ? '🚩'
                                : guidance.mode ==
                                        LearningGamePlayMode.checkpoint
                                    ? '🏁'
                                    : '🎮',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guidance.modeLabel,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: .7,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          guidance.modeMessage,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            for (final index in revealedHintIndices.toList()..sort())
              if (index < guidance.hints.length)
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: BrightMomentReaction(
                    trigger: 'hint:$index:${guidance.hints[index]}',
                    kind: BrightMomentKind.hint,
                    child: _CoachClue(
                      label: index == 0 ? 'Leo clue' : 'Worked clue',
                      text: guidance.hints[index],
                      accent: accent,
                    ),
                  ),
                ),
            if (hintAvailable && unrevealedHints > 0) ...[
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onRevealNextHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  label: Text(
                    feedback != null
                        ? (feedback?.stage == ContextualFeedbackStage.powerUp
                            ? 'Use the next clue'
                            : 'Show a clue for this miss')
                        : revealedHintIndices.isEmpty
                            ? 'Ask Leo for a clue'
                            : 'Show one more clue',
                  ),
                ),
              ),
            ],
            if (rescueRevealed ||
                (rescueAvailable &&
                    unrevealedHints <= 0 &&
                    (feedback?.suggestRescue ?? true))) ...[
              const SizedBox(height: 9),
              if (!rescueRevealed)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onRevealRescue,
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Need a power-up?'),
                  ),
                )
              else
                BrightMomentReaction(
                  trigger: 'power-up:${guidance.rescueText}',
                  kind: BrightMomentKind.powerUp,
                  child: _CoachClue(
                    label: 'Power-up strategy',
                    text: guidance.rescueText!,
                    accent: const Color(0xFFB45D00),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoachClue extends StatelessWidget {
  const _CoachClue({
    required this.label,
    required this.text,
    required this.accent,
  });

  final String label;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: accent.withValues(alpha: .16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: .55,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.35,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
}
