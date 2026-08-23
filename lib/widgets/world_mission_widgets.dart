import 'package:flutter/material.dart';

import '../core/curriculum/world_mission_models.dart';
import '../core/theme/app_theme.dart';
import 'bright_design_system.dart';
import 'bright_motion.dart';

class WorldMissionRibbon extends StatelessWidget {
  const WorldMissionRibbon({
    required this.plan,
    this.compact = false,
    this.showProgress = true,
    super.key,
  });

  final WorldMissionPlan plan;
  final bool compact;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForSubject(plan.identity.subject);
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 15,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .96),
            Color.lerp(Colors.white, palette.secondary, .22)!,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: palette.primary.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(
            color: palette.deep.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = compact || constraints.maxWidth < 520;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: narrow ? 42 : 48,
                height: narrow ? 42 : 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.deep],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: .22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  plan.stageEmoji,
                  style: TextStyle(fontSize: narrow ? 23 : 27),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.zoneTitle} • ${plan.phaseLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.deep,
                        fontWeight: FontWeight.w900,
                        fontSize: narrow ? 10.5 : 11.5,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.stageTitle,
                      maxLines: narrow ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: narrow ? 14 : 15.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MissionTypeBadge(plan: plan),
            ],
          );

          if (!showProgress) return identity;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: BrightAnimatedProgress(
                        value: plan.journeyProgress,
                        minHeight: 7,
                        backgroundColor: palette.primary.withValues(alpha: .12),
                        color: palette.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Quest ${plan.stageNumber}/${plan.stageCount}',
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return Semantics(
      container: true,
      label:
          '${plan.identity.worldTitle}. ${plan.zoneTitle}. ${plan.phaseLabel}. Quest ${plan.stageNumber} of ${plan.stageCount}.',
      child: BrightReveal(
        duration: const Duration(milliseconds: 260),
        beginScale: .99,
        offset: const Offset(0, -.015),
        child: content,
      ),
    );
  }
}

class WorldMissionBriefingCard extends StatelessWidget {
  const WorldMissionBriefingCard({
    required this.plan,
    super.key,
  });

  final WorldMissionPlan plan;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForSubject(plan.identity.subject);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.primary.withValues(alpha: .12),
            Colors.white.withValues(alpha: .96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.primary.withValues(alpha: .22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.identity.worldEmoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSION BRIEF',
                  style: TextStyle(
                    color: palette.deep,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  plan.briefing,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w700,
                    height: 1.38,
                    fontSize: 12.5,
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

class _MissionTypeBadge extends StatelessWidget {
  const _MissionTypeBadge({required this.plan});

  final WorldMissionPlan plan;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForSubject(plan.identity.subject);
    final label = switch (plan.phase) {
      WorldMissionPhase.training => 'TRAIN',
      WorldMissionPhase.challenge => 'QUEST',
      WorldMissionPhase.boss => 'BOSS',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: plan.isBoss
            ? const Color(0xFFFFE8A3)
            : palette.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: plan.isBoss
              ? const Color(0xFFE1A719)
              : palette.primary.withValues(alpha: .22),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: plan.isBoss ? const Color(0xFF825600) : palette.deep,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: .6,
        ),
      ),
    );
  }
}
