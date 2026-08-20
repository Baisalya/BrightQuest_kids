import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/achievement_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/game_controller.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final earned = achievements.where((achievement) => controller.isAchievementUnlocked(achievement.id)).toList();

    return BrightPageBackground(
      primary: const Color(0xFFF7F3FF),
      secondary: const Color(0xFFFFFAEB),
      child: Column(
        children: [
          const BrightHeader(title: 'Explorer Profile'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  builder: (context, _) => _ProfileHero(controller: controller),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  builder: (context, _) => BrightSectionTitle(
                    title: 'Achievements',
                    subtitle: 'Badges you have earned by learning and exploring.',
                    icon: Icons.workspace_premium_rounded,
                    trailing: BrightPill(icon: Icons.emoji_events_rounded, label: '${earned.length}/${achievements.length}'),
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  builder: (context, _) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: achievements.map((achievement) {
                      final unlocked = controller.isAchievementUnlocked(achievement.id);
                      return _AchievementBadge(title: achievement.title, description: achievement.description, emoji: achievement.emoji, unlocked: unlocked);
                    }).toList(),
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  builder: (context, _) => const BrightSectionTitle(title: 'Comfort & accessibility', subtitle: 'Make BrightQuest comfortable for your eyes, ears and hands.', icon: Icons.accessibility_new_rounded),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  builder: (context, _) => BrightSurface(
                    child: Column(
                      children: [
                        SwitchListTile(title: const Text('High contrast'), subtitle: const Text('Stronger outlines and darker primary controls.'), value: controller.highContrastEnabled, onChanged: controller.setHighContrastEnabled),
                        SwitchListTile(title: const Text('Reduce motion'), subtitle: const Text('Keeps transitions calm when motion is uncomfortable.'), value: controller.reducedMotionEnabled, onChanged: controller.setReducedMotionEnabled),
                        SwitchListTile(title: const Text('Haptic feedback'), subtitle: const Text('Gentle vibration feedback on supported devices.'), value: controller.hapticsEnabled, onChanged: controller.setHapticsEnabled),
                        ListTile(
                          title: Text('Text size: ${(controller.textScale * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Slider(value: controller.textScale, min: 0.9, max: 1.3, divisions: 4, label: '${(controller.textScale * 100).round()}%', onChanged: controller.setTextScale),
                        ),
                      ],
                    ),
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrightSectionTitle(title: 'Cosmetics owned', subtitle: 'Safe rewards that change how your explorer space looks.', icon: Icons.auto_awesome_rounded),
                      const SizedBox(height: 10),
                      BrightSurface(
                        child: Row(
                          children: [
                            const Text('🎁', style: TextStyle(fontSize: 42)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                controller.unlockedRewards.isEmpty
                                    ? 'No cosmetic rewards unlocked yet. Keep collecting stars!'
                                    : '${controller.unlockedRewards.length} reward${controller.unlockedRewards.length == 1 ? '' : 's'} unlocked.',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const InfoBanner(icon: Icons.family_restroom_rounded, text: 'Class, child profiles and daily limits are managed in the locked Parents area.'),
                    ],
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7351E9), Color(0xFF4EA7ED), Color(0xFF67CCA0)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x247351E9), blurRadius: 28, offset: Offset(0, 10))],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final avatar = Container(
              width: compact ? 92 : 118,
              height: compact ? 92 : 118,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFE48A), width: 5), boxShadow: const [BoxShadow(color: Color(0x25000000), blurRadius: 16, offset: Offset(0, 7))]),
              child: Text(controller.activeProfileAvatar, style: TextStyle(fontSize: compact ? 52 : 66)),
            );
            final details = Column(
              crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(controller.activeProfileName, textAlign: compact ? TextAlign.center : TextAlign.start, style: TextStyle(color: Colors.white, fontSize: compact ? 26 : 31, fontWeight: FontWeight.w900)),
                Text('Class ${controller.selectedClass} • Explorer Level ${controller.level}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  alignment: compact ? WrapAlignment.center : WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProfileStat(label: 'Coins', value: '${controller.coins}', emoji: '🪙'),
                    _ProfileStat(label: 'Path stars', value: '${controller.learningPathStars}', emoji: '⭐'),
                    _ProfileStat(label: 'Streak', value: '${controller.streak}', emoji: '🔥'),
                    _ProfileStat(label: 'XP', value: '${controller.xp}', emoji: '⚡'),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: controller.learningPathProgress, minHeight: 9, borderRadius: BorderRadius.circular(99), backgroundColor: Colors.white.withValues(alpha: 0.25), valueColor: const AlwaysStoppedAnimation(Colors.white)),
                const SizedBox(height: 6),
                Text('${controller.completedLearningLevels}/${controller.totalLearningLevels} levels cleared', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              ],
            );
            if (compact) return Column(children: [avatar, const SizedBox(height: 12), details]);
            return Row(children: [avatar, const SizedBox(width: 20), Expanded(child: details), const Text('🦁✨', style: TextStyle(fontSize: 58))]);
          },
        ),
      );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value, required this.emoji});
  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(17)),
        child: Text('$emoji $value $label', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
      );
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.title, required this.description, required this.emoji, required this.unlocked});
  final String title;
  final String description;
  final String emoji;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: description,
        child: Container(
          width: 178,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: unlocked ? const LinearGradient(colors: [Color(0xFFFFFAE6), Color(0xFFFFFFFF)]) : null,
            color: unlocked ? null : Colors.black.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: unlocked ? const Color(0xFFFFD36A) : Colors.black12, width: 1.3),
            boxShadow: unlocked ? const [BoxShadow(color: Color(0x12B8860B), blurRadius: 12, offset: Offset(0, 5))] : null,
          ),
          child: Row(
            children: [
              Text(unlocked ? emoji : '🔒', style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: unlocked ? AppTheme.navy : Colors.black38))),
            ],
          ),
        ),
      );
}
