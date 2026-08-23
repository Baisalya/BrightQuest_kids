import 'package:flutter/material.dart';

import '../app/brightquest_scope.dart';
import '../core/content/content_activity.dart';
import '../core/curriculum/world_mission_models.dart';
import '../core/learning/activity_response_evaluator.dart';
import '../core/learning/lesson_engine.dart';
import '../core/learning/mission_session_models.dart';
import '../core/presentation/game_feel_director.dart';
import '../core/theme/app_theme.dart';
import 'bright_design_system.dart';
import 'bright_illustrations.dart';
import 'bright_motion.dart';

class MissionSessionProgress extends StatelessWidget {
  const MissionSessionProgress({
    required this.step,
    required this.session,
    this.plan,
    super.key,
  });

  final MissionSessionStep step;
  final MissionSession session;
  final WorldMissionPlan? plan;

  @override
  Widget build(BuildContext context) {
    final palette =
        plan == null ? null : paletteForSubject(plan!.identity.subject);
    final accent = palette?.primary ?? Theme.of(context).colorScheme.primary;
    final phases = session.activePhases;

    return Semantics(
      container: true,
      label:
          '${step.phase.label}, phase ${step.phaseIndex + 1} of ${session.phaseCount}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${step.phase.emoji} ${step.phase.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${step.phaseIndex + 1}/${session.phaseCount}',
                style: TextStyle(
                  color: palette?.deep ?? accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              return Row(
                children: [
                  for (var index = 0; index < phases.length; index++) ...[
                    Expanded(
                      child: _PhaseNode(
                        phase: phases[index],
                        index: index,
                        activeIndex: step.phaseIndex,
                        accent: accent,
                        compact: compact,
                      ),
                    ),
                    if (index != phases.length - 1)
                      Container(
                        width: compact ? 5 : 10,
                        height: 3,
                        decoration: BoxDecoration(
                          color: index < step.phaseIndex
                              ? accent
                              : accent.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
          if (step.phaseStepCount > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Part ${step.phaseStepIndex + 1} of ${step.phaseStepCount} in ${step.phase.label}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhaseNode extends StatelessWidget {
  const _PhaseNode({
    required this.phase,
    required this.index,
    required this.activeIndex,
    required this.accent,
    required this.compact,
  });

  final MissionSessionPhase phase;
  final int index;
  final int activeIndex;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = index == activeIndex;
    final complete = index < activeIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 8,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: .12)
            : complete
                ? accent.withValues(alpha: .07)
                : Colors.white.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? accent.withValues(alpha: .42)
              : accent.withValues(alpha: .10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            complete ? '✓' : phase.emoji,
            style: TextStyle(fontSize: compact ? 12 : 14),
          ),
          if (!compact) ...[
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                phase.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active || complete ? accent : AppTheme.inkMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: .35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Presents authored teaching as a short mission briefing/walkthrough instead
/// of a generic text worksheet card.
class MissionTeachingStage extends StatelessWidget {
  const MissionTeachingStage({
    required this.sessionStep,
    required this.lessonStep,
    this.activity,
    this.plan,
    this.onShowWhy,
    super.key,
  });

  final MissionSessionStep sessionStep;
  final LessonStep lessonStep;
  final ContentActivity? activity;
  final WorldMissionPlan? plan;
  final VoidCallback? onShowWhy;

  @override
  Widget build(BuildContext context) {
    final palette =
        plan == null ? null : paletteForSubject(plan!.identity.subject);
    final accent = palette?.primary ?? Theme.of(context).colorScheme.primary;
    final deep = palette?.deep ?? Theme.of(context).colorScheme.primary;
    final isWorked = lessonStep.kind == LessonStepKind.workedExample;
    final isObjective = lessonStep.kind == LessonStepKind.objective;
    final readingFocus = BrightQuestScope.of(context).readingFocusEnabled;
    final feel = GameFeelDirector.forSessionPhase(sessionStep.phase);

    return Semantics(
      container: true,
      label:
          '${sessionStep.phase.label}. ${lessonStep.title}. ${lessonStep.body}',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: readingFocus
                ? const <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xFFFFFDF5),
                    Color(0xFFFFFFFF),
                  ]
                : <Color>[
                    accent.withValues(alpha: .10),
                    Colors.white,
                    Colors.white.withValues(alpha: .94),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: accent.withValues(alpha: readingFocus ? .42 : .18),
            width: readingFocus ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: deep.withValues(alpha: .07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, deep]),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    _teachingEmoji(lessonStep.kind),
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isObjective
                            ? 'MISSION TARGET'
                            : isWorked
                                ? 'WATCH THE MOVE'
                                : 'SPOT THE IDEA',
                        style: TextStyle(
                          color: deep,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: .75,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lessonStep.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: BrightMomentReaction(
                    trigger:
                        '${sessionStep.phase.name}:${sessionStep.phaseStepIndex}:${lessonStep.id}',
                    kind: feel.kind,
                    child: BrightLionMascot(
                      size: 52,
                      mood: feel.mood,
                      animated: false,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  readingFocus ? const EdgeInsets.all(12) : EdgeInsets.zero,
              decoration: readingFocus
                  ? BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: .14)),
                    )
                  : null,
              child: Text(
                lessonStep.body,
                style: TextStyle(
                  color: AppTheme.navy,
                  fontWeight: readingFocus ? FontWeight.w800 : FontWeight.w700,
                  height: readingFocus ? 1.62 : 1.48,
                ),
              ),
            ),
            if (isWorked && activity != null) ...[
              const SizedBox(height: 16),
              _WorkedMoveStrip(
                activity: activity!,
                accent: accent,
                deep: deep,
              ),
            ],
            if (onShowWhy != null && !isObjective) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onShowWhy,
                  icon: const Icon(Icons.psychology_alt_rounded),
                  label: const Text('Why does this work?'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkedMoveStrip extends StatelessWidget {
  const _WorkedMoveStrip({
    required this.activity,
    required this.accent,
    required this.deep,
  });

  final ContentActivity activity;
  final Color accent;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    const evaluator = ActivityResponseEvaluator();
    final answer = evaluator.correctResponseLabel(activity);
    final parts = <(String, String, String)>[
      ('1', 'Challenge', activity.prompt),
      ('2', 'Winning move', answer),
      ('3', 'Why', activity.explanation),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 620;
        final cards = parts
            .map(
              (part) => _WorkedMoveCard(
                number: part.$1,
                label: part.$2,
                text: part.$3,
                accent: accent,
                deep: deep,
              ),
            )
            .toList(growable: false);
        if (stack) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index != cards.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _WorkedMoveCard extends StatelessWidget {
  const _WorkedMoveCard({
    required this.number,
    required this.label,
    required this.text,
    required this.accent,
    required this.deep,
  });

  final String number;
  final String label;
  final String text;
  final Color accent;
  final Color deep;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accent.withValues(alpha: .14)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: TextStyle(
                  color: deep,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: deep,
                      fontWeight: FontWeight.w900,
                      fontSize: 8.5,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class MissionFutureReviewNote extends StatelessWidget {
  const MissionFutureReviewNote({
    required this.reviewText,
    this.plan,
    super.key,
  });

  final String reviewText;
  final WorldMissionPlan? plan;

  @override
  Widget build(BuildContext context) {
    final palette =
        plan == null ? null : paletteForSubject(plan!.identity.subject);
    final accent = palette?.primary ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: .14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 21)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POWER REVIEW SAVED FOR LATER',
                  style: TextStyle(
                    color: palette?.deep ?? accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: .55,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reviewText,
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _teachingEmoji(LessonStepKind kind) => switch (kind) {
      LessonStepKind.objective => '🎯',
      LessonStepKind.explanation => '💡',
      LessonStepKind.workedExample => '✨',
      _ => '🎮',
    };
