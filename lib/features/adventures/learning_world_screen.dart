import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/models/game_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import '../games/game_router.dart';

class LearningWorldScreen extends StatelessWidget {
  const LearningWorldScreen({required this.world, super.key});

  final LearningWorld world;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final levels = levelsForSubject(controller.selectedClass, world.subject);
    final completed = controller.completedLevelsForSubject(world.subject);
    final stars = controller.starsForSubject(world.subject);
    final palette = paletteForSubject(world.subject);

    return Scaffold(
      body: BrightPageBackground(
        primary: Color.lerp(palette.secondary, Colors.white, 0.72)!,
        secondary: const Color(0xFFFFFAE9),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: BrightHeader(showBack: true, title: world.title)),
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                builder: (context, _) => _WorldHero(
                  world: world,
                  palette: palette,
                  classNumber: controller.selectedClass,
                  completed: completed,
                  total: levels.length,
                  stars: stars,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                builder: (context, _) => BrightSectionTitle(
                  title: 'Learning road',
                  subtitle: 'Follow the path: Practice → Challenge → Mastery.',
                  icon: Icons.route_rounded,
                  trailing: Text('$completed/${levels.length} cleared', style: const TextStyle(color: AppTheme.inkMuted, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BrightResponsive(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                builder: (context, breakpoint) => Column(
                  children: List.generate(levels.length, (index) {
                    final level = levels[index];
                    final progress = controller.levelStatsFor(level.id);
                    final unlocked = controller.isLevelUnlocked(level);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoadLevel(
                        index: index,
                        level: level,
                        progress: progress,
                        unlocked: unlocked,
                        palette: palette,
                        compact: breakpoint == BrightBreakpoint.compact,
                        onPlay: unlocked ? () => openLearningLevel(context, level) : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldHero extends StatelessWidget {
  const _WorldHero({required this.world, required this.palette, required this.classNumber, required this.completed, required this.total, required this.stars});
  final LearningWorld world;
  final BrightWorldPalette palette;
  final int classNumber;
  final int completed;
  final int total;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final sceneId = _worldGameId(world.subject);
    return BrightReveal(
      duration: const Duration(milliseconds: 420),
      beginScale: 0.97,
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [palette.primary, palette.deep]),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: palette.primary.withValues(alpha: .26), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final scene = Container(
            height: compact ? 148 : 206,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: .58), width: 2)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                BrightGameScene(gameId: sceneId),
                const BrightGlint(),
                const BrightSparkles(),
                Positioned(left: 12, top: 12, child: BrightPill(icon: Icons.school_rounded, label: 'CLASS $classNumber', color: palette.deep, background: Colors.white.withValues(alpha: .91))),
                Positioned(right: 12, bottom: 4, child: Text(world.emoji, style: TextStyle(fontSize: compact ? 54 : 72))),
              ],
            ),
          );
          final copy = Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(world.title, style: TextStyle(color: Colors.white, fontSize: compact ? 26 : 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(world.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .93), fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 14),
                BrightAnimatedProgress(value: progress, minHeight: 10, backgroundColor: Colors.white.withValues(alpha: .24), color: const Color(0xFFB8FF7A)),
                const SizedBox(height: 9),
                Wrap(spacing: 8, runSpacing: 8, children: [_HeroChip(text: '$completed/$total levels'), _HeroChip(text: '⭐ $stars/${total * 3}')]),
              ],
            ),
          );
          if (compact) return Column(children: [scene, copy]);
          return Padding(padding: const EdgeInsets.all(14), child: Row(children: [Expanded(flex: 5, child: scene), Expanded(flex: 4, child: copy)]));
        },
      ),
      ),
    );
  }
}

String _worldGameId(SubjectWorld subject) => switch (subject) {
      SubjectWorld.maths => 'math_market',
      SubjectWorld.english => 'story_builder',
      SubjectWorld.science => 'science_lab',
      SubjectWorld.evs => 'recycling_challenge',
      SubjectWorld.social => 'map_quest',
      SubjectWorld.coding => 'coding_maze',
      SubjectWorld.art => 'rewards_room',
    };

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
      );
}

class _RoadLevel extends StatelessWidget {
  const _RoadLevel({required this.index, required this.level, required this.progress, required this.unlocked, required this.palette, required this.compact, required this.onPlay});
  final int index;
  final LearningLevel level;
  final LearningLevelProgress progress;
  final bool unlocked;
  final BrightWorldPalette palette;
  final bool compact;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final game = games.firstWhere((candidate) => candidate.id == level.gameId);
    final stars = progress.earnedStars;
    final bestPercent = (progress.bestRatio * 100).round();
    final isRight = index.isOdd && !compact;
    final stageEmoji = level.type == LearningLevelType.mastery ? '👑' : level.type == LearningLevelType.challenge ? '⚡' : '🌟';
    final node = Container(
      width: level.isMastery ? 70 : 60,
      height: level.isMastery ? 70 : 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: unlocked ? LinearGradient(colors: [palette.primary, palette.deep]) : const LinearGradient(colors: [Color(0xFFD9DEE8), Color(0xFFB8C0CE)]),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: (unlocked ? palette.primary : Colors.black12).withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Text(unlocked ? stageEmoji : '🔒', style: TextStyle(fontSize: level.isMastery ? 30 : 25)),
    );

    final card = Expanded(
      child: BrightSurface(
        borderColor: unlocked ? palette.primary.withValues(alpha: 0.18) : const Color(0x14000000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(level.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                BrightPill(
                  icon: level.isMastery ? Icons.workspace_premium_rounded : level.type == LearningLevelType.challenge ? Icons.bolt_rounded : Icons.school_rounded,
                  label: level.typeLabel,
                  color: level.isMastery ? const Color(0xFF8A6000) : palette.deep,
                  background: level.isMastery ? const Color(0xFFFFEDAF) : palette.primary.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${game.title} • Difficulty ${level.difficulty}', style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(level.summary, maxLines: compact ? 3 : 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.inkMuted, height: 1.3, fontSize: 12)),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: progress.completed
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text('${List<String>.filled(stars, '⭐').join()}${List<String>.filled(3 - stars, '☆').join()}', style: const TextStyle(fontSize: 18)),
                            Text('Best $bestPercent%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                          ],
                        )
                      : Text(unlocked ? 'Ready to play' : 'Clear the previous stage', style: TextStyle(color: unlocked ? Colors.green.shade700 : AppTheme.inkMuted, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onPlay,
                  child: Icon(progress.completed ? Icons.replay_rounded : Icons.play_arrow_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final revealMs = 300 + ((index > 5 ? 5 : index) * 35);
    return BrightReveal(
      duration: Duration(milliseconds: revealMs),
      beginScale: 0.985,
      offset: Offset(isRight ? 0.025 : -0.025, 0.015),
      child: BrightPressableScale(
        hoverScale: unlocked ? 1.006 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: isRight ? [card, const SizedBox(width: 12), node] : [node, const SizedBox(width: 12), card],
        ),
      ),
    );
  }
}
