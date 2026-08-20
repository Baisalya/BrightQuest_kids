import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/models/game_models.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_widgets.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final accuracy = (controller.accuracy * 100).round();

    return BrightPageBackground(
      primary: const Color(0xFFF2F8FF),
      secondary: const Color(0xFFFFFBEC),
      child: Column(
        children: [
          const BrightHeader(title: 'My Progress'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  builder: (context, _) => _ProgressHero(controller: controller, accuracy: accuracy),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  builder: (context, _) => const BrightSectionTitle(title: 'World progress', subtitle: 'See which learning worlds are growing strongest.', icon: Icons.public_rounded),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  builder: (context, breakpoint) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: learningWorlds.map((world) {
                      final total = controller.totalLevelsForSubject(world.subject);
                      return SizedBox(
                        width: breakpoint == BrightBreakpoint.compact ? double.infinity : 360,
                        child: _WorldProgressCard(
                          emoji: world.emoji,
                          title: world.title,
                          completed: controller.completedLevelsForSubject(world.subject),
                          total: total,
                          stars: controller.starsForSubject(world.subject),
                          progress: controller.progressForSubject(world.subject),
                          color: paletteForSubject(world.subject).primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  builder: (context, _) => const BrightSectionTitle(title: 'Adventure mastery', subtitle: 'Accuracy, hints and adaptive difficulty for each game.', icon: Icons.auto_graph_rounded),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                  builder: (context, breakpoint) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: games.where((game) => game.id != 'rewards_room').map((game) {
                      final stats = controller.statsFor(game.id);
                      final difficulty = controller.recommendedDifficulty(game.id);
                      final weakTopics = stats.topicProgress.entries.toList()..sort((a, b) => a.value.accuracy.compareTo(b.value.accuracy));
                      final weakest = weakTopics.where((entry) => entry.value.attempts >= 2).take(2).toList();
                      return SizedBox(
                        width: breakpoint == BrightBreakpoint.compact ? double.infinity : 365,
                        child: _MasteryCard(
                          game: game,
                          mastery: stats.mastery,
                          masteryStars: stats.masteryStars,
                          correct: stats.correctAnswers,
                          attempts: stats.attempts,
                          hints: stats.hintsUsed,
                          difficulty: difficulty,
                          weakest: weakest.map((entry) => _prettyTopic(entry.key)).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _prettyTopic(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.controller, required this.accuracy});
  final GameController controller;
  final int accuracy;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5D4CE7), Color(0xFF3EA4EA), Color(0xFF5ACB9A)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x245D4CE7), blurRadius: 28, offset: Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrightMascotBubble(message: 'Look how much you have learned!', compact: true),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: Text('Class ${controller.selectedClass} Adventure', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))), Text('${(controller.learningPathProgress * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: controller.learningPathProgress, minHeight: 10, borderRadius: BorderRadius.circular(99), backgroundColor: Colors.white.withValues(alpha: 0.24), valueColor: const AlwaysStoppedAnimation(Colors.white)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroMetric(icon: Icons.bolt_rounded, value: '${controller.xp}', label: 'XP'),
                _HeroMetric(icon: Icons.track_changes_rounded, value: '$accuracy%', label: 'Accuracy'),
                _HeroMetric(icon: Icons.star_rounded, value: '${controller.learningPathStars}', label: 'Path stars'),
                _HeroMetric(icon: Icons.schedule_rounded, value: '${controller.studyMinutesToday.floor()}m', label: 'Today'),
              ],
            ),
          ],
        ),
      );
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFFFFE36F), size: 18), const SizedBox(width: 5), Text('$value $label', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))]),
      );
}

class _WorldProgressCard extends StatelessWidget {
  const _WorldProgressCard({required this.emoji, required this.title, required this.completed, required this.total, required this.stars, required this.progress, required this.color});
  final String emoji;
  final String title;
  final int completed;
  final int total;
  final int stars;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => BrightSurface(
        child: Row(
          children: [
            Container(width: 54, height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)), child: Text(emoji, style: const TextStyle(fontSize: 30))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))), Text('⭐ $stars/${total * 3}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(value: progress, minHeight: 7, borderRadius: BorderRadius.circular(99), color: color),
                  const SizedBox(height: 5),
                  Text('$completed/$total levels cleared', style: const TextStyle(color: AppTheme.inkMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.game, required this.mastery, required this.masteryStars, required this.correct, required this.attempts, required this.hints, required this.difficulty, required this.weakest});
  final AdventureGame game;
  final double mastery;
  final int masteryStars;
  final int correct;
  final int attempts;
  final int hints;
  final int difficulty;
  final List<String> weakest;

  @override
  Widget build(BuildContext context) => BrightSurface(
        borderColor: game.color.withValues(alpha: 0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: game.color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(15)), child: Icon(game.icon, color: game.color)), const SizedBox(width: 10), Expanded(child: Text(game.title, style: const TextStyle(fontWeight: FontWeight.w900))), Text('$masteryStars/4 ⭐', style: const TextStyle(fontWeight: FontWeight.w900))]),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: mastery, minHeight: 8, borderRadius: BorderRadius.circular(99), color: game.color),
            const SizedBox(height: 7),
            Text('$correct/$attempts correct • Adaptive D$difficulty • $hints hints', style: const TextStyle(color: AppTheme.inkMuted, fontSize: 11, fontWeight: FontWeight.w700)),
            if (weakest.isNotEmpty) ...[const SizedBox(height: 7), Text('Practice next: ${weakest.join(' • ')}', style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w900))],
          ],
        ),
      );
}
