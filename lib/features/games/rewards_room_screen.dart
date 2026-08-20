import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/achievement_catalog.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';

class RewardsRoomScreen extends StatelessWidget {
  const RewardsRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final unlockedAchievements = achievements
        .where(
            (achievement) => controller.isAchievementUnlocked(achievement.id))
        .toList(growable: false);

    return GameScaffold(
      title: 'Rewards Room',
      subtitle: 'Treasure, badges & earned celebrations',
      color: const Color(0xFFF3B31E),
      voicePrompt:
          'Welcome to your Rewards Room. These treasures were earned by learning!',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          BrightReveal(
            duration: const Duration(milliseconds: 420),
            beginScale: 0.96,
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFFE991),
                  Color(0xFFFFC84B),
                  Color(0xFFFFA95C)
                ]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x28E2A600),
                      blurRadius: 24,
                      offset: Offset(0, 10))
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final details = Column(
                    crossAxisAlignment: compact
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      const BrightPill(
                          icon: Icons.auto_awesome_rounded,
                          label: 'YOUR TREASURE',
                          color: Color(0xFF765500),
                          background: Color(0xFFFFF2BD)),
                      const SizedBox(height: 10),
                      const Text('Treasure Room',
                          style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy)),
                      const SizedBox(height: 6),
                      Text(
                          '${controller.coins} coins • ${controller.learningPathStars} path stars',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy)),
                      const SizedBox(height: 12),
                      BrightAnimatedProgress(
                          value: controller.learningPathProgress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.45),
                          color: AppTheme.purple),
                      const SizedBox(height: 6),
                      Text(
                          '${controller.completedLearningLevels}/${controller.totalLearningLevels} Class ${controller.selectedClass} levels cleared',
                          style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ],
                  );
                  if (compact)
                    return Column(children: [
                      const Text('🎁✨🏆', style: TextStyle(fontSize: 62)),
                      const SizedBox(height: 8),
                      details
                    ]);
                  return Row(children: [
                    Expanded(child: details),
                    const Text('🎁✨🏆', style: TextStyle(fontSize: 72))
                  ]);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          BrightSectionTitle(
            title: 'Achievement shelf',
            subtitle: 'Badges earned through learning—not spending.',
            icon: Icons.workspace_premium_rounded,
            trailing: BrightPill(
                icon: Icons.emoji_events_rounded,
                label: '${unlockedAchievements.length}/${achievements.length}'),
          ),
          const SizedBox(height: 10),
          if (unlockedAchievements.isEmpty)
            const BrightSurface(
                child: Text(
                    'Clear your first Learning World level to earn your first achievement badge.',
                    style: TextStyle(color: AppTheme.inkMuted, height: 1.4)))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: unlockedAchievements
                  .map((achievement) => _AchievementCard(
                      emoji: achievement.emoji,
                      title: achievement.title,
                      description: achievement.description))
                  .toList(),
            ),
          const SizedBox(height: 20),
          const BrightSectionTitle(
              title: 'World trophies',
              subtitle:
                  'Complete every level in a world to turn its badge into a trophy.',
              icon: Icons.emoji_events_rounded),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: learningWorlds.map((world) {
              final completed =
                  controller.completedLevelsForSubject(world.subject);
              final total = controller.totalLevelsForSubject(world.subject);
              final stars = controller.starsForSubject(world.subject);
              final finished = total > 0 && completed >= total;
              return _WorldTrophy(
                  title: world.title,
                  emoji: finished ? '🏆' : world.emoji,
                  completed: completed,
                  total: total,
                  stars: stars,
                  color: paletteForSubject(world.subject).primary,
                  finished: finished);
            }).toList(),
          ),
          const SizedBox(height: 20),
          const BrightSectionTitle(
              title: 'Cosmetic unlockables',
              subtitle:
                  'Coins only unlock fun visual rewards. Learning progress is never pay-to-win.',
              icon: Icons.storefront_rounded),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RewardTile(
                  id: 'lion_lab_coat',
                  title: 'Lion Lab Coat',
                  emoji: '🥼🦁',
                  cost: 200,
                  controller: controller),
              _RewardTile(
                  id: 'galaxy_bot_skin',
                  title: 'Galaxy Bot Skin',
                  emoji: '🤖🌌',
                  cost: 350,
                  controller: controller),
              _RewardTile(
                  id: 'story_castle_badge',
                  title: 'Story Castle Badge',
                  emoji: '🏰⭐',
                  cost: 150,
                  controller: controller),
              _RewardTile(
                  id: 'eco_hero_crown',
                  title: 'Eco Hero Crown',
                  emoji: '♻️👑',
                  cost: 250,
                  controller: controller),
            ],
          ),
          const SizedBox(height: 14),
          const InfoBanner(
              icon: Icons.verified_user_rounded,
              text:
                  'Learning progress never requires spending coins. Cosmetic ownership is saved locally and remains owned after restarting.'),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard(
      {required this.emoji, required this.title, required this.description});
  final String emoji;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: description,
        child: BrightReveal(
          beginScale: 0.94,
          curve: Curves.easeOutBack,
          child: BrightPressableScale(
            hoverScale: 1.025,
            child: Container(
              width: 190,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFFAE5), Colors.white]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD878))),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, color: AppTheme.navy)))
              ]),
            ),
          ),
        ),
      );
}

class _WorldTrophy extends StatelessWidget {
  const _WorldTrophy(
      {required this.title,
      required this.emoji,
      required this.completed,
      required this.total,
      required this.stars,
      required this.color,
      required this.finished});
  final String title;
  final String emoji;
  final int completed;
  final int total;
  final int stars;
  final Color color;
  final bool finished;

  @override
  Widget build(BuildContext context) => BrightPressableScale(
        hoverScale: 1.018,
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: finished ? const Color(0xFFFFF8D7) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.18))),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: BrightValuePop(
                    value: '$finished:$stars',
                    child: Text(emoji, style: const TextStyle(fontSize: 28)))),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text('$completed/$total levels • ⭐ $stars',
                      style: const TextStyle(
                          color: AppTheme.inkMuted, fontSize: 11))
                ]))
          ]),
        ),
      );
}

class _RewardTile extends StatelessWidget {
  const _RewardTile(
      {required this.id,
      required this.title,
      required this.emoji,
      required this.cost,
      required this.controller});
  final String id;
  final String title;
  final String emoji;
  final int cost;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final unlocked = controller.isRewardUnlocked(id);
    return SizedBox(
      width: 280,
      child: BrightPressableScale(
        hoverScale: 1.012,
        child: BrightSurface(
          borderColor:
              unlocked ? const Color(0xFFFFD36A) : const Color(0x14000000),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        maxLines: 2,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(unlocked ? 'Unlocked permanently' : '🪙 $cost',
                        style: const TextStyle(
                            color: AppTheme.inkMuted, fontSize: 11))
                  ])),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: unlocked || controller.coins < cost
                    ? null
                    : () {
                        final bought =
                            controller.buyReward(rewardId: id, cost: cost);
                        if (bought)
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$title unlocked!')));
                      },
                child: Text(unlocked ? 'Owned' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
