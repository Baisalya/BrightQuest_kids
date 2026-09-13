import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/achievement_catalog.dart';
import '../../core/content/cosmetic_catalog.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_adaptive.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_widgets.dart';
import '../games/rewards_room_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final earnedAchievements = achievements
        .where(
          (achievement) => controller.isAchievementUnlocked(achievement.id),
        )
        .length;
    final ownedLooks = cosmeticCatalog
        .where((item) => controller.isRewardUnlocked(item.id))
        .length;
    final gameIds = cosmeticCatalog.map((item) => item.gameId).toSet();
    final equippedLooks = gameIds
        .where((gameId) => controller.equippedRewardIdForGame(gameId) != null)
        .length;

    return BrightPageBackground(
      primary: const Color(0xFFF7F3FF),
      secondary: const Color(0xFFFFFAEB),
      child: Column(
        children: [
          const BrightHeader(title: 'My Space'),
          Expanded(
            child: ListView(
              key: const Key('profile_scroll'),
              padding: EdgeInsets.zero,
              children: [
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  builder: (context, _) => _ProfileHero(
                    controller: controller,
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  builder: (context, _) => const BrightSectionTitle(
                    title: 'My rewards',
                    subtitle:
                        'Badges, trophies and fun looks live together in one place.',
                    icon: Icons.card_giftcard_rounded,
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  builder: (context, _) => _RewardDoorway(
                    controller: controller,
                    earnedAchievements: earnedAchievements,
                    ownedLooks: ownedLooks,
                    equippedLooks: equippedLooks,
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  builder: (context, _) => const BrightSectionTitle(
                    title: 'Comfort & accessibility',
                    subtitle:
                        'Make BrightQuest comfortable for your eyes, ears and hands.',
                    icon: Icons.accessibility_new_rounded,
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  builder: (context, _) => BrightSurface(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('High contrast'),
                          subtitle: const Text(
                            'Stronger outlines and darker primary controls.',
                          ),
                          value: controller.highContrastEnabled,
                          onChanged: controller.setHighContrastEnabled,
                        ),
                        SwitchListTile(
                          title: const Text('Reduce motion'),
                          subtitle: const Text(
                            'Keeps transitions calm when motion is uncomfortable.',
                          ),
                          value: controller.reducedMotionEnabled,
                          onChanged: controller.setReducedMotionEnabled,
                        ),
                        SwitchListTile(
                          title: const Text('Haptic feedback'),
                          subtitle: const Text(
                            'Gentle vibration feedback on supported devices.',
                          ),
                          value: controller.hapticsEnabled,
                          onChanged: controller.setHapticsEnabled,
                        ),
                        ListTile(
                          title: Text(
                            'Text size: ${(controller.textScale * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Slider(
                            value: controller.textScale,
                            min: 0.9,
                            max: 1.3,
                            divisions: 4,
                            label: '${(controller.textScale * 100).round()}%',
                            onChanged: controller.setTextScale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BrightResponsive(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                  builder: (context, _) => const InfoBanner(
                    icon: Icons.family_restroom_rounded,
                    text:
                        'Class, child profiles, detailed learning reports and daily limits are managed in the locked Grown-up area.',
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
        key: const Key('profile_identity_hero'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7351E9),
              Color(0xFF4EA7ED),
              Color(0xFF67CCA0),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x247351E9),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = brightShouldStackForReadability(
              context: context,
              availableWidth: constraints.maxWidth,
              compactWidth: 620,
            );
            final avatar = Container(
              width: compact ? 92 : 118,
              height: compact ? 92 : 118,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFE48A),
                  width: 5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x25000000),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Text(
                controller.activeProfileAvatar,
                style: TextStyle(fontSize: compact ? 52 : 66),
              ),
            );

            final details = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  controller.activeProfileName,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 27 : 31,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Class ${controller.selectedClass} Explorer',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .90),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: controller.learningPathProgress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: Colors.white.withValues(alpha: .25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                const SizedBox(height: 7),
                Text(
                  '${controller.completedLearningLevels} quests explored',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                children: [
                  avatar,
                  const SizedBox(height: 12),
                  details,
                ],
              );
            }

            return Row(
              children: [
                avatar,
                const SizedBox(width: 20),
                Expanded(child: details),
                const Text('🦁✨', style: TextStyle(fontSize: 58)),
              ],
            );
          },
        ),
      );
}

class _RewardDoorway extends StatelessWidget {
  const _RewardDoorway({
    required this.controller,
    required this.earnedAchievements,
    required this.ownedLooks,
    required this.equippedLooks,
  });

  final GameController controller;
  final int earnedAchievements;
  final int ownedLooks;
  final int equippedLooks;

  @override
  Widget build(BuildContext context) => BrightSurface(
        key: const Key('profile_rewards_card'),
        borderColor: const Color(0xFFFFD36A),
        tint: const Color(0xFFFFF7D9),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = brightShouldStackForReadability(
              context: context,
              availableWidth: constraints.maxWidth,
              compactWidth: 650,
            );
            final summary = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.center : WrapAlignment.start,
              children: [
                _RewardSummaryChip(
                  emoji: '🏅',
                  label: '$earnedAchievements badges',
                ),
                _RewardSummaryChip(
                  emoji: '🎨',
                  label: '$ownedLooks looks',
                ),
                _RewardSummaryChip(
                  emoji: '✨',
                  label: '$equippedLooks equipped',
                ),
                _RewardSummaryChip(
                  emoji: '🪙',
                  label: '${controller.coins} coins',
                ),
              ],
            );

            final button = FilledButton.icon(
              key: const Key('open_rewards_from_profile'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const RewardsRoomScreen(),
                ),
              ),
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('Open my rewards'),
            );

            final copy = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'Everything you earn, one happy place',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'See your badges and trophies, or choose a fun look for an adventure.',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                summary,
              ],
            );

            if (compact) {
              return Column(
                children: [
                  const Text('🎁✨', style: TextStyle(fontSize: 46)),
                  const SizedBox(height: 8),
                  copy,
                  const SizedBox(height: 14),
                  button,
                ],
              );
            }

            return Row(
              children: [
                const Text('🎁✨', style: TextStyle(fontSize: 50)),
                const SizedBox(width: 16),
                Expanded(child: copy),
                const SizedBox(width: 14),
                button,
              ],
            );
          },
        ),
      );
}

class _RewardSummaryChip extends StatelessWidget {
  const _RewardSummaryChip({
    required this.emoji,
    required this.label,
  });

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1F6B4E00)),
        ),
        child: Text(
          '$emoji $label',
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}
