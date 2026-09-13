import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/models/game_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/session/game_session_models.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_adaptive.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import '../games/game_router.dart';
import '../learning/applied_missions_screen.dart';
import '../learning/diagnostic_screen.dart';
import '../learning/power_review_screen.dart';
import 'home_primary_action.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final plan = _HomePlan.fromController(controller);

    return BrightPageBackground(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: BrightHeader()),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              builder: (context, breakpoint) => _PrimaryActionCard(
                controller: controller,
                plan: plan,
                breakpoint: breakpoint,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrightResponsive(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              builder: (context, breakpoint) {
                final compact = breakpoint == BrightBreakpoint.compact;
                final journey = _JourneyAtAGlance(controller: controller);
                final wins = _DailyWinsCard(controller: controller);

                if (compact) {
                  return Column(
                    children: [
                      journey,
                      const SizedBox(height: 12),
                      wins,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: journey),
                    const SizedBox(width: 14),
                    Expanded(child: wins),
                  ],
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _HomePlan {
  const _HomePlan({
    required this.kind,
    required this.session,
    required this.level,
    required this.dueReviewCount,
    required this.practiceGame,
  });

  final HomePrimaryActionKind kind;
  final GameSessionCheckpoint? session;
  final LearningLevel? level;
  final int dueReviewCount;
  final AdventureGame? practiceGame;

  factory _HomePlan.fromController(GameController controller) {
    final sessions = controller.resumableGameSessions;
    final session = sessions.isEmpty ? null : sessions.first;
    final diagnostic = controller.diagnosticProgress;
    final diagnosticInProgress =
        diagnostic.classNumber == controller.selectedClass &&
            diagnostic.started &&
            !diagnostic.completed;
    final hasClassEvidence = controller.attemptEvidence
        .any((evidence) => evidence.classNumber == controller.selectedClass);
    final diagnosticCompletedForClass =
        diagnostic.classNumber == controller.selectedClass &&
            diagnostic.completed;
    final needsStartingCheck = !diagnosticInProgress &&
        !diagnosticCompletedForClass &&
        !hasClassEvidence &&
        controller.completedLearningLevels == 0;
    final dueReviewCount = controller.dueReviewTasks(limit: 10).length;
    final nextLevel = controller.nextRecommendedLearningLevel();
    final corePathComplete = controller.totalLearningLevels > 0 &&
        controller.completedLearningLevels == controller.totalLearningLevels;
    final hasAppliedMissionEvidence = controller.projectEvidence
        .any((evidence) => evidence.classNumber == controller.selectedClass);

    final practiceIds = controller.weakestGameIds(limit: 1);
    AdventureGame? practiceGame;
    if (practiceIds.isNotEmpty) {
      practiceGame = _gameById(practiceIds.first);
    }
    if (practiceGame == null) {
      for (final game in games) {
        if (game.id != 'rewards_room') {
          practiceGame = game;
          break;
        }
      }
    }

    return _HomePlan(
      kind: chooseHomePrimaryAction(
        hasResumableSession: session != null,
        diagnosticInProgress: diagnosticInProgress,
        needsStartingCheck: needsStartingCheck,
        dueReviewCount: dueReviewCount,
        hasCurriculumMission: nextLevel != null,
        corePathComplete: corePathComplete,
        hasAppliedMissionEvidence: hasAppliedMissionEvidence,
      ),
      session: session,
      level: nextLevel,
      dueReviewCount: dueReviewCount,
      practiceGame: practiceGame,
    );
  }
}

AdventureGame? _gameById(String id) {
  for (final game in games) {
    if (game.id == id) return game;
  }
  return null;
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.controller,
    required this.plan,
    required this.breakpoint,
  });

  final GameController controller;
  final _HomePlan plan;
  final BrightBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final compact = breakpoint == BrightBreakpoint.compact;
    final presentation = _presentationFor(plan);

    void runPrimaryAction() {
      switch (plan.kind) {
        case HomePrimaryActionKind.resume:
          final session = plan.session;
          if (session != null) {
            unawaited(resumeGameSession(context, session));
          }
          return;
        case HomePrimaryActionKind.diagnostic:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DiagnosticScreen()),
          );
          return;
        case HomePrimaryActionKind.review:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PowerReviewScreen()),
          );
          return;
        case HomePrimaryActionKind.curriculum:
          final level = plan.level;
          if (level != null) openLearningLevel(context, level);
          return;
        case HomePrimaryActionKind.appliedMission:
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AppliedMissionsScreen(),
            ),
          );
          return;
        case HomePrimaryActionKind.freePractice:
          final game = plan.practiceGame;
          if (game != null) openGame(context, game.id);
          return;
      }
    }

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrightPill(
          icon: presentation.badgeIcon,
          label: presentation.badge,
          color: AppTheme.purpleDeep,
          background: const Color(0xFFF0E9FF),
        ),
        const SizedBox(height: 11),
        Text(
          presentation.title,
          key: const Key('home_primary_action_title'),
          style: TextStyle(
            color: AppTheme.navy,
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          presentation.subtitle,
          style: const TextStyle(
            color: AppTheme.inkMuted,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: compact ? double.infinity : null,
          child: FilledButton.icon(
            key: const Key('home_primary_action_button'),
            onPressed: runPrimaryAction,
            icon: Icon(presentation.buttonIcon),
            label: Text(presentation.buttonLabel),
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      label: '${presentation.title}. ${presentation.subtitle}',
      child: BrightReveal(
        child: Container(
          key: const Key('home_primary_action'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF6F1FF),
                Color(0xFFEAF8FF),
                Color(0xFFF3FCEB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F28455F),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stack = brightShouldStackForReadability(
                context: context,
                availableWidth: constraints.maxWidth,
                compactWidth: 720,
              );
              final mascot = Container(
                constraints: const BoxConstraints(minHeight: 150),
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const BrightLionMascot(size: 138),
              );

              if (stack) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 124, child: mascot),
                      const SizedBox(height: 14),
                      copy,
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(width: 220, child: mascot),
                    const SizedBox(width: 22),
                    Expanded(child: copy),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _PrimaryPresentation _presentationFor(_HomePlan plan) {
    switch (plan.kind) {
      case HomePrimaryActionKind.resume:
        final session = plan.session;
        final level = session?.learningLevelId == null
            ? null
            : learningLevelById(session!.learningLevelId!);
        final game = session == null ? null : _gameById(session.gameId);
        return _PrimaryPresentation(
          badge: 'CONTINUE',
          badgeIcon: Icons.restore_rounded,
          title: level?.title ?? game?.title ?? 'Continue your saved quest',
          subtitle: 'Pick up exactly where you stopped.',
          buttonLabel: 'Continue',
          buttonIcon: Icons.play_arrow_rounded,
        );
      case HomePrimaryActionKind.diagnostic:
        final diagnostic = controller.diagnosticProgress;
        final inProgress = diagnostic.classNumber == controller.selectedClass &&
            diagnostic.started &&
            !diagnostic.completed;
        return _PrimaryPresentation(
          badge: inProgress ? 'CONTINUE CHECK' : 'START HERE',
          badgeIcon: Icons.explore_rounded,
          title: inProgress
              ? 'Finish your starting check'
              : 'Find your starting point',
          subtitle: inProgress
              ? 'A few questions remain before your learning trail is ready.'
              : 'A short discovery check helps BrightQuest choose the right first quest.',
          buttonLabel: inProgress ? 'Continue check' : 'Start check',
          buttonIcon: Icons.arrow_forward_rounded,
        );
      case HomePrimaryActionKind.review:
        return _PrimaryPresentation(
          badge: 'QUICK REVIEW',
          badgeIcon: Icons.bolt_rounded,
          title: 'Give your memory a quick boost',
          subtitle:
              '${plan.dueReviewCount} ${plan.dueReviewCount == 1 ? 'skill is' : 'skills are'} ready for a short review.',
          buttonLabel: 'Review now',
          buttonIcon: Icons.refresh_rounded,
        );
      case HomePrimaryActionKind.curriculum:
        final level = plan.level;
        final game = level == null ? null : _gameById(level.gameId);
        return _PrimaryPresentation(
          badge: 'NEXT QUEST',
          badgeIcon: Icons.flag_rounded,
          title: level?.title ?? 'Your next quest',
          subtitle: game == null
              ? 'Continue your class learning trail.'
              : '${game.title} is the best next step on your class trail.',
          buttonLabel: 'Start quest',
          buttonIcon: Icons.play_arrow_rounded,
        );
      case HomePrimaryActionKind.appliedMission:
        return const _PrimaryPresentation(
          badge: 'TRY IT FOR REAL',
          badgeIcon: Icons.rocket_launch_rounded,
          title: 'Use your skills in a real-world mission',
          subtitle:
              'Your class trail is clear. Now combine what you learned in a practical challenge.',
          buttonLabel: 'Open mission',
          buttonIcon: Icons.arrow_forward_rounded,
        );
      case HomePrimaryActionKind.freePractice:
        final game = plan.practiceGame;
        return _PrimaryPresentation(
          badge: 'KEEP GROWING',
          badgeIcon: Icons.sports_esports_rounded,
          title: game == null
              ? 'Keep your skills fresh'
              : 'Practice ${game.title}',
          subtitle:
              'Your main trail is up to date. Play a short practice round whenever you want.',
          buttonLabel: 'Practice',
          buttonIcon: Icons.play_arrow_rounded,
        );
    }
  }
}

class _PrimaryPresentation {
  const _PrimaryPresentation({
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
  });

  final String badge;
  final IconData badgeIcon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
}

class _JourneyAtAGlance extends StatelessWidget {
  const _JourneyAtAGlance({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.learningPathProgress.clamp(0.0, 1.0).toDouble();

    return BrightSurface(
      tint: AppTheme.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrightSectionTitle(
            title: 'Your journey',
            subtitle: 'A quick look—your next action stays above.',
            icon: Icons.route_rounded,
            trailing: BrightPill(
              icon: Icons.school_rounded,
              label: 'Class ${controller.selectedClass}',
              color: AppTheme.purple,
            ),
          ),
          const SizedBox(height: 14),
          BrightAnimatedProgress(
            value: progress,
            minHeight: 10,
            color: AppTheme.purple,
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BrightPill(
                icon: Icons.flag_rounded,
                label:
                    '${controller.completedLearningLevels}/${controller.totalLearningLevels} quests',
                color: AppTheme.purpleDeep,
              ),
              BrightPill(
                icon: Icons.star_rounded,
                label: '${controller.learningPathStars} stars',
                color: const Color(0xFF9B6A00),
                background: const Color(0xFFFFF2C4),
              ),
              BrightPill(
                icon: Icons.schedule_rounded,
                label: '${controller.studyMinutesToday.floor()} min today',
                color: const Color(0xFF28724A),
                background: const Color(0xFFE7F7EC),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyWinsCard extends StatelessWidget {
  const _DailyWinsCard({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final challenges = controller.dailyChallenges;
    final claimed = challenges
        .where((challenge) => controller.isDailyChallengeClaimed(challenge.id))
        .length;
    final ready = challenges
        .where(
          (challenge) =>
              controller.isDailyChallengeReady(challenge) &&
              !controller.isDailyChallengeClaimed(challenge.id),
        )
        .length;

    return BrightSurface(
      tint: AppTheme.orange,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('home_daily_wins'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading:
              const Icon(Icons.emoji_events_rounded, color: AppTheme.orange),
          title: const Text(
            'Today’s wins',
            style: TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            ready > 0
                ? '$ready reward ${ready == 1 ? 'is' : 'are'} ready to claim.'
                : '$claimed/${challenges.length} optional goals complete.',
            style: const TextStyle(
              color: AppTheme.inkMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          children: [
            for (final challenge in challenges)
              _DailyWinRow(
                controller: controller,
                challenge: challenge,
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyWinRow extends StatelessWidget {
  const _DailyWinRow({
    required this.controller,
    required this.challenge,
  });

  final GameController controller;
  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final value = controller.dailyChallengeValue(challenge);
    final claimed = controller.isDailyChallengeClaimed(challenge.id);
    final ready = controller.isDailyChallengeReady(challenge);
    final ratio = (value / challenge.target).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Icon(
            claimed ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: claimed ? AppTheme.green : AppTheme.inkMuted,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                BrightAnimatedProgress(
                  value: ratio,
                  minHeight: 5,
                  color: claimed ? AppTheme.green : AppTheme.orange,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (ready && !claimed)
            FilledButton.tonal(
              onPressed: () {
                final claimedNow = controller.claimDailyChallenge(challenge.id);
                if (!claimedNow) return;
                unawaited(
                  BrightAudioService.instance.playSfx(BrightSfx.coin),
                );
              },
              child: Text('+${challenge.rewardCoins}'),
            )
          else
            Text(
              claimed
                  ? 'Done'
                  : '${value.clamp(0, challenge.target)}/${challenge.target}',
              style: const TextStyle(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
              ),
            ),
        ],
      ),
    );
  }
}
