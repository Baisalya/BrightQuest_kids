import 'package:flutter/material.dart';

import '../../../core/content/content_activity.dart';
import '../../../core/learning/gameplay_activity_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/bright_illustrations.dart';
import '../../../widgets/bright_motion.dart';

class LearningGameStage extends StatelessWidget {
  const LearningGameStage({
    required this.activity,
    required this.spec,
    required this.interaction,
    required this.primaryAction,
    this.feedback,
    this.secondaryAction,
    super.key,
  });

  final ContentActivity activity;
  final LearningGameActivitySpec spec;
  final Widget interaction;
  final Widget primaryAction;
  final Widget? feedback;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(spec.theme);
    return Semantics(
      container: true,
      label: '${_missionLabel(spec)}. ${activity.prompt}',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.soft,
              Colors.white,
              palette.soft.withValues(alpha: .55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: palette.accent.withValues(alpha: .20)),
          boxShadow: [
            BoxShadow(
              color: palette.deep.withValues(alpha: .10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 620;
            final shortViewport = MediaQuery.sizeOf(context).height < 820;
            final actionInMissionRail = wide && shortViewport;
            final scene = _MissionScene(
              spec: spec,
              palette: palette,
              compact: !wide,
              commandAction: actionInMissionRail ? primaryAction : null,
            );
            final playArea = _PlayArea(
              palette: palette,
              interaction: interaction,
              feedback: feedback,
              primaryAction: actionInMissionRail ? null : primaryAction,
              secondaryAction: secondaryAction,
            );

            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 238, child: scene),
                    const SizedBox(width: 16),
                    Expanded(child: playArea),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  scene,
                  const SizedBox(height: 12),
                  playArea,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MissionScene extends StatelessWidget {
  const _MissionScene({
    required this.spec,
    required this.palette,
    required this.compact,
    this.commandAction,
  });

  final LearningGameActivitySpec spec;
  final _StagePalette palette;
  final bool compact;
  final Widget? commandAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.accent, palette.deep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: compact
          ? Row(
              children: [
                SizedBox(
                  width: 132,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _LivingGameScene(
                      gameId: spec.sceneGameId,
                      compact: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _MissionCopy(spec: spec, compact: true)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _MissionBadge(spec: spec),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _themeEmoji(spec.theme),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                if (commandAction != null) ...[
                  const SizedBox(height: 10),
                  _MissionCommandAction(
                    palette: palette,
                    child: commandAction!,
                  ),
                ],
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _LivingGameScene(gameId: spec.sceneGameId),
                ),
                const SizedBox(height: 14),
                _MissionCopy(spec: spec, compact: false),
              ],
            ),
    );
  }
}

class _LivingGameScene extends StatelessWidget {
  const _LivingGameScene({required this.gameId, this.compact = false});

  final String gameId;
  final bool compact;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          BrightGameScene(gameId: gameId, compact: compact),
          const Positioned.fill(
            child: IgnorePointer(child: BrightGlint()),
          ),
        ],
      );
}

class _MissionCopy extends StatelessWidget {
  const _MissionCopy({required this.spec, required this.compact});

  final LearningGameActivitySpec spec;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compact) ...[
            _MissionBadge(spec: spec),
            const SizedBox(height: 7),
          ],
          Text(
            _missionTitle(spec),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _missionInstruction(spec),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .86),
              fontWeight: FontWeight.w700,
              height: 1.3,
              fontSize: 11.5,
            ),
          ),
        ],
      );
}

class _MissionBadge extends StatelessWidget {
  const _MissionBadge({required this.spec});

  final LearningGameActivitySpec spec;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .17),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: .20)),
        ),
        child: Text(
          _missionLabel(spec).toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
            fontSize: 9.5,
          ),
        ),
      );
}

class _PlayArea extends StatelessWidget {
  const _PlayArea({
    required this.palette,
    required this.interaction,
    this.primaryAction,
    this.feedback,
    this.secondaryAction,
  });

  final _StagePalette palette;
  final Widget interaction;
  final Widget? primaryAction;
  final Widget? feedback;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .93),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            interaction,
            if (feedback != null) ...[
              const SizedBox(height: 14),
              feedback!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: 14),
              secondaryAction!,
            ],
            if (primaryAction != null) ...[
              const SizedBox(height: 14),
              _PrimaryActionTheme(
                palette: palette,
                child: primaryAction!,
              ),
            ],
          ],
        ),
      );
}

class _MissionCommandAction extends StatelessWidget {
  const _MissionCommandAction({
    required this.palette,
    required this.child,
  });

  final _StagePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: palette.deep,
              disabledBackgroundColor: Colors.white.withValues(alpha: .38),
              disabledForegroundColor: Colors.white.withValues(alpha: .78),
              minimumSize: const Size.fromHeight(44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        child: child,
      );
}

class _PrimaryActionTheme extends StatelessWidget {
  const _PrimaryActionTheme({
    required this.palette,
    required this.child,
  });

  final _StagePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: palette.deep,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
        child: child,
      );
}

class _StagePalette {
  const _StagePalette({
    required this.accent,
    required this.deep,
    required this.soft,
  });

  final Color accent;
  final Color deep;
  final Color soft;
}

_StagePalette _paletteFor(LearningGameTheme theme) => switch (theme) {
      LearningGameTheme.maths => const _StagePalette(
          accent: Color(0xFF45A9F5),
          deep: Color(0xFF1761BD),
          soft: Color(0xFFE8F7FF),
        ),
      LearningGameTheme.story => const _StagePalette(
          accent: Color(0xFF4CC9A5),
          deep: Color(0xFF157A65),
          soft: Color(0xFFE9FBF5),
        ),
      LearningGameTheme.science => const _StagePalette(
          accent: Color(0xFF8A65F1),
          deep: Color(0xFF4D32B5),
          soft: Color(0xFFF2EDFF),
        ),
      LearningGameTheme.nature => const _StagePalette(
          accent: Color(0xFF5DCB6B),
          deep: Color(0xFF2E7E3A),
          soft: Color(0xFFECFAEF),
        ),
      LearningGameTheme.map => const _StagePalette(
          accent: Color(0xFFFFA34D),
          deep: Color(0xFFB55A13),
          soft: Color(0xFFFFF4E7),
        ),
      LearningGameTheme.coding => const _StagePalette(
          accent: Color(0xFF6D63E8),
          deep: Color(0xFF3D36A5),
          soft: Color(0xFFF0EFFF),
        ),
      LearningGameTheme.neutral => const _StagePalette(
          accent: AppTheme.purple,
          deep: AppTheme.purpleDeep,
          soft: AppTheme.surfaceLavender,
        ),
    };

String _themeEmoji(LearningGameTheme theme) => switch (theme) {
      LearningGameTheme.maths => '🏰',
      LearningGameTheme.story => '📚',
      LearningGameTheme.science => '🧪',
      LearningGameTheme.nature => '🌿',
      LearningGameTheme.map => '🗺️',
      LearningGameTheme.coding => '🤖',
      LearningGameTheme.neutral => '🦁',
    };

String _missionLabel(LearningGameActivitySpec spec) {
  if (spec.kind == LearningGameActivityKind.themedChoice) {
    return switch (spec.choicePresentation) {
      LearningGameChoicePresentation.marketStalls => 'Market mission',
      LearningGameChoicePresentation.storyTrail => 'Story trail',
      LearningGameChoicePresentation.labScanner => 'Lab scan',
      LearningGameChoicePresentation.ecoTrail => 'Green mission',
      LearningGameChoicePresentation.mapExpedition => 'Explorer checkpoint',
      LearningGameChoicePresentation.robotConsole => 'Robot console',
      LearningGameChoicePresentation.questCards => 'Mission challenge',
    };
  }
  return switch (spec.kind) {
    LearningGameActivityKind.themedChoice => 'Mission challenge',
    LearningGameActivityKind.fractionBuilder => 'Pizza builder',
    LearningGameActivityKind.sentenceBuilder => 'Story builder',
    LearningGameActivityKind.grammarSort => 'Grammar sorter',
    LearningGameActivityKind.robotRoute => 'Robot route',
    LearningGameActivityKind.experimentMixer => 'Lab mixer',
    LearningGameActivityKind.recyclingSort => 'Eco sorter',
    LearningGameActivityKind.unsupported => 'Learning mission',
  };
}

String _missionTitle(LearningGameActivitySpec spec) {
  if (spec.kind == LearningGameActivityKind.themedChoice) {
    return switch (spec.choicePresentation) {
      LearningGameChoicePresentation.marketStalls => 'Solve the market order',
      LearningGameChoicePresentation.storyTrail => 'Choose the next story path',
      LearningGameChoicePresentation.labScanner => 'Scan for the right result',
      LearningGameChoicePresentation.ecoTrail => 'Choose the green path',
      LearningGameChoicePresentation.mapExpedition => 'Find the destination',
      LearningGameChoicePresentation.robotConsole => 'Pick the correct module',
      LearningGameChoicePresentation.questCards => 'Find the winning answer',
    };
  }
  return switch (spec.kind) {
    LearningGameActivityKind.themedChoice => 'Find the winning answer',
    LearningGameActivityKind.fractionBuilder => 'Build the fraction',
    LearningGameActivityKind.sentenceBuilder => 'Build the story trail',
    LearningGameActivityKind.grammarSort => 'Power up the word roles',
    LearningGameActivityKind.robotRoute => 'Guide the robot home',
    LearningGameActivityKind.experimentMixer => 'Mix the right ingredients',
    LearningGameActivityKind.recyclingSort => 'Clean up the planet',
    LearningGameActivityKind.unsupported => 'Complete the learning mission',
  };
}

String _missionInstruction(LearningGameActivitySpec spec) {
  if (spec.kind == LearningGameActivityKind.themedChoice) {
    return switch (spec.choicePresentation) {
      LearningGameChoicePresentation.marketStalls =>
        'Inspect the stalls, use the clue, and load the answer that completes the order.',
      LearningGameChoicePresentation.storyTrail =>
        'Follow the idea, then choose the trail step that keeps the story or language rule on track.',
      LearningGameChoicePresentation.labScanner =>
        'Use the evidence in the prompt and select the sample that matches the science idea.',
      LearningGameChoicePresentation.ecoTrail =>
        'Choose the action or idea that best completes this planet-friendly mission.',
      LearningGameChoicePresentation.mapExpedition =>
        'Read the clue like an explorer and choose the destination marker that fits it.',
      LearningGameChoicePresentation.robotConsole =>
        'Inspect the mission and select the module that gives the correct result.',
      LearningGameChoicePresentation.questCards =>
        'Use the mission clue, then choose one answer to continue the quest.',
    };
  }
  return switch (spec.kind) {
    LearningGameActivityKind.themedChoice =>
      'Use the clue in the mission, then choose one answer tile.',
    LearningGameActivityKind.fractionBuilder =>
      'Tap real pizza slices until the picture matches the target fraction.',
    LearningGameActivityKind.sentenceBuilder =>
      'Drag or tap word cards to restore the story trail in the right order.',
    LearningGameActivityKind.grammarSort =>
      'Send words into noun, verb and adjective portals to power the sentence.',
    LearningGameActivityKind.robotRoute =>
      'Build a command belt, preview the route, then run the robot.',
    LearningGameActivityKind.experimentMixer =>
      'Drag ingredients into the flask, adjust the mixture, then test it.',
    LearningGameActivityKind.recyclingSort =>
      'Drag the object into a bin or tap the bin that fits it.',
    LearningGameActivityKind.unsupported =>
      'This authored item needs a compatible interaction before it can be played.',
  };
}
