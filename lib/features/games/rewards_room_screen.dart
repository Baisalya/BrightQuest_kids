import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/achievement_catalog.dart';
import '../../core/content/cosmetic_catalog.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';

class RewardsRoomScreen extends StatefulWidget {
  const RewardsRoomScreen({super.key});

  @override
  State<RewardsRoomScreen> createState() => _RewardsRoomScreenState();
}

class _RewardsRoomScreenState extends State<RewardsRoomScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final unlockedAchievements = achievements
        .where(
          (achievement) => controller.isAchievementUnlocked(achievement.id),
        )
        .toList(growable: false);
    final ownedCosmetics = cosmeticCatalog
        .where((item) => controller.isRewardUnlocked(item.id))
        .toList(growable: false);
    final gameIds = cosmeticCatalog
        .map((item) => item.gameId)
        .toSet()
        .toList(growable: false);
    final equipped = <CosmeticDefinition>[];
    for (final gameId in gameIds) {
      final item = controller.equippedCosmeticForGame(gameId);
      if (item != null) equipped.add(item);
    }
    final visibleCosmetics = cosmeticCatalog.where((item) {
      if (_filter == 'all') return true;
      if (_filter == 'owned') return controller.isRewardUnlocked(item.id);
      return item.gameId == _filter;
    }).toList(growable: false);

    return GameScaffold(
      title: 'Rewards Room',
      subtitle: 'Collect • Equip • Make every adventure yours',
      color: const Color(0xFFF3B31E),
      voicePrompt:
          'Welcome to your Rewards Room. Choose a cosmetic and equip your favorite look!',
      child: ListView(
        key: const Key('rewards_room_scroll'),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          _RewardsHero(
            controller: controller,
            ownedCount: ownedCosmetics.length,
            equippedCount: equipped.length,
          ),
          const SizedBox(height: 18),
          BrightSectionTitle(
            title: 'My loadout',
            subtitle:
                'Owned looks are permanent. Equip or switch them any time for free.',
            icon: Icons.checkroom_rounded,
            trailing: BrightPill(
              icon: Icons.auto_awesome_rounded,
              label: '${equipped.length} EQUIPPED',
            ),
          ),
          const SizedBox(height: 10),
          if (equipped.isEmpty)
            const BrightSurface(
              child: Row(
                children: [
                  Text('🎨', style: TextStyle(fontSize: 34)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No cosmetic equipped yet. Unlock one below to apply it instantly.',
                      style: TextStyle(
                        color: AppTheme.inkMuted,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            BrightAdaptiveGrid(
              minChildWidth: 240,
              maxColumns: 4,
              children: equipped
                  .map(
                    (item) => _EquippedCard(
                      cosmetic: item,
                      controller: controller,
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 22),
          BrightSectionTitle(
            title: 'Cosmetic shop',
            subtitle:
                'Coins unlock visual fun only—never answers, stars, or learning progress.',
            icon: Icons.storefront_rounded,
            trailing: BrightPill(
              icon: Icons.inventory_2_rounded,
              label: '${ownedCosmetics.length}/${cosmeticCatalog.length} OWNED',
            ),
          ),
          const SizedBox(height: 10),
          _CosmeticFilters(
            selected: _filter,
            gameIds: gameIds,
            onSelected: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 12),
          if (visibleCosmetics.isEmpty)
            const BrightSurface(
              child: Text(
                'No owned cosmetics in this view yet.',
                style: TextStyle(color: AppTheme.inkMuted),
              ),
            )
          else
            BrightAdaptiveGrid(
              minChildWidth: 270,
              maxColumns: 4,
              spacing: 12,
              runSpacing: 12,
              children: visibleCosmetics
                  .map(
                    (item) => _CosmeticCard(
                      cosmetic: item,
                      controller: controller,
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 22),
          BrightSectionTitle(
            title: 'World trophies',
            subtitle:
                'Complete every core level in a world to turn its badge into a trophy.',
            icon: Icons.emoji_events_rounded,
            trailing: BrightPill(
              icon: Icons.star_rounded,
              label: '${controller.learningPathStars} STARS',
            ),
          ),
          const SizedBox(height: 10),
          BrightAdaptiveGrid(
            minChildWidth: 220,
            maxColumns: 5,
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
                finished: finished,
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 22),
          BrightSectionTitle(
            title: 'Achievement shelf',
            subtitle: 'Badges earned through learning—not spending.',
            icon: Icons.workspace_premium_rounded,
            trailing: BrightPill(
              icon: Icons.emoji_events_rounded,
              label: '${unlockedAchievements.length}/${achievements.length}',
            ),
          ),
          const SizedBox(height: 10),
          if (unlockedAchievements.isEmpty)
            const BrightSurface(
              child: Text(
                'Clear your first Learning World level to earn your first achievement badge.',
                style: TextStyle(color: AppTheme.inkMuted, height: 1.4),
              ),
            )
          else
            BrightAdaptiveGrid(
              minChildWidth: 210,
              maxColumns: 5,
              spacing: 10,
              runSpacing: 10,
              children: unlockedAchievements
                  .map(
                    (achievement) => _AchievementCard(
                      emoji: achievement.emoji,
                      title: achievement.title,
                      description: achievement.description,
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.verified_user_rounded,
            text:
                'Existing purchases stay owned after this redesign. Cosmetic ownership and equipped looks are saved per child profile on this device.',
          ),
        ],
      ),
    );
  }
}

class _RewardsHero extends StatelessWidget {
  const _RewardsHero({
    required this.controller,
    required this.ownedCount,
    required this.equippedCount,
  });

  final GameController controller;
  final int ownedCount;
  final int equippedCount;

  @override
  Widget build(BuildContext context) => BrightReveal(
        duration: const Duration(milliseconds: 420),
        beginScale: 0.97,
        curve: Curves.easeOutBack,
        child: Container(
          key: const Key('rewards_room_hero'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFE991),
                Color(0xFFFFC84B),
                Color(0xFFFFAA5C),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28E2A600),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final details = Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  const BrightPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'YOUR STYLE VAULT',
                    color: Color(0xFF765500),
                    background: Color(0xFFFFF2BD),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Collect it. Equip it. Play your way.',
                    textAlign: compact ? TextAlign.center : TextAlign.start,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.coins} coins • $ownedCount owned • $equippedCount equipped',
                    textAlign: compact ? TextAlign.center : TextAlign.start,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrightAnimatedProgress(
                    value: controller.learningPathProgress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: .48),
                    color: AppTheme.purple,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.completedLearningLevels}/${controller.totalLearningLevels} Class ${controller.selectedClass} core levels cleared',
                    textAlign: compact ? TextAlign.center : TextAlign.start,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
              final art = Container(
                width: compact ? 112 : 148,
                height: compact ? 90 : 116,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .34),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  ownedCount == 0 ? '🎁✨' : '🎨✨🏆',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: compact ? 38 : 48),
                ),
              );
              if (compact) {
                return Column(
                  children: [art, const SizedBox(height: 10), details],
                );
              }
              return Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 18),
                  art,
                ],
              );
            },
          ),
        ),
      );
}

class _CosmeticFilters extends StatelessWidget {
  const _CosmeticFilters({
    required this.selected,
    required this.gameIds,
    required this.onSelected,
  });

  final String selected;
  final List<String> gameIds;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == 'all',
            onSelected: (_) => onSelected('all'),
          ),
          ChoiceChip(
            avatar: const Icon(Icons.inventory_2_rounded, size: 16),
            label: const Text('Owned'),
            selected: selected == 'owned',
            onSelected: (_) => onSelected('owned'),
          ),
          for (final gameId in gameIds)
            ChoiceChip(
              label: Text(cosmeticsForGame(gameId).first.gameTitle),
              selected: selected == gameId,
              onSelected: (_) => onSelected(gameId),
            ),
        ],
      );
}

class _EquippedCard extends StatelessWidget {
  const _EquippedCard({
    required this.cosmetic,
    required this.controller,
  });

  final CosmeticDefinition cosmetic;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final accent = Color(cosmetic.accentColorValue);
    return Container(
      key: Key('equipped_cosmetic_${cosmetic.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(accent, Colors.white, .80)!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .28), width: 1.5),
      ),
      child: Row(
        children: [
          _CosmeticPreview(cosmetic: cosmetic, size: 56),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cosmetic.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cosmetic.gameTitle,
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('unequip_${cosmetic.id}'),
            tooltip: 'Unequip ${cosmetic.title}',
            onPressed: () => controller.unequipRewardForGame(cosmetic.gameId),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.cosmetic,
    required this.controller,
  });

  final CosmeticDefinition cosmetic;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final owned = controller.isRewardUnlocked(cosmetic.id);
    final equipped = controller.isRewardEquipped(cosmetic.id);
    final affordable = controller.coins >= cosmetic.cost;
    final accent = Color(cosmetic.accentColorValue);
    final missingCoins =
        (cosmetic.cost - controller.coins).clamp(0, cosmetic.cost);

    return BrightPressableScale(
      hoverScale: 1.01,
      child: Container(
        key: Key('cosmetic_card_${cosmetic.id}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: equipped
                ? accent.withValues(alpha: .72)
                : owned
                    ? const Color(0xFFFFD36A)
                    : const Color(0x16000000),
            width: equipped ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F173B55),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CosmeticPreview(cosmetic: cosmetic, size: 68),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cosmetic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cosmetic.gameTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (equipped)
                  Icon(Icons.check_circle_rounded, color: accent, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              cosmetic.description,
              style: const TextStyle(
                color: AppTheme.inkMuted,
                height: 1.35,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compactActions = constraints.maxWidth < 340;
                final status = Text(
                  equipped
                      ? '✓ Equipped'
                      : owned
                          ? 'Owned permanently'
                          : '🪙 ${cosmetic.cost}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: equipped ? accent : AppTheme.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                );
                final Widget action = equipped
                    ? OutlinedButton(
                        key: Key('unequip_shop_${cosmetic.id}'),
                        onPressed: () =>
                            controller.unequipRewardForGame(cosmetic.gameId),
                        child: const Text('Unequip'),
                      )
                    : owned
                        ? FilledButton.tonal(
                            key: Key('equip_${cosmetic.id}'),
                            onPressed: () =>
                                controller.equipReward(cosmetic.id),
                            child: const Text('Equip'),
                          )
                        : Tooltip(
                            message: affordable
                                ? 'Unlock and equip ${cosmetic.title}'
                                : 'Need $missingCoins more coins',
                            child: FilledButton.tonal(
                              key: Key('unlock_${cosmetic.id}'),
                              onPressed: affordable
                                  ? () {
                                      final bought = controller.buyReward(
                                        rewardId: cosmetic.id,
                                        cost: cosmetic.cost,
                                      );
                                      if (bought) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${cosmetic.title} unlocked and equipped!',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              child: Text(
                                affordable ? 'Unlock' : 'Need $missingCoins',
                              ),
                            ),
                          );

                if (compactActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      status,
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: action,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 8),
                    action,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CosmeticPreview extends StatelessWidget {
  const _CosmeticPreview({required this.cosmetic, required this.size});

  final CosmeticDefinition cosmetic;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = Color(cosmetic.accentColorValue);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(accent, Colors.white, .72)!,
            Color.lerp(accent, Colors.white, .88)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: accent.withValues(alpha: .22)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            cosmetic.emoji,
            style: TextStyle(fontSize: size * .43),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String emoji;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: description,
        child: BrightReveal(
          beginScale: .96,
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFAE5), Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD878)),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _WorldTrophy extends StatelessWidget {
  const _WorldTrophy({
    required this.title,
    required this.emoji,
    required this.completed,
    required this.total,
    required this.stars,
    required this.color,
    required this.finished,
  });

  final String title;
  final String emoji;
  final int completed;
  final int total;
  final int stars;
  final Color color;
  final bool finished;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: finished ? const Color(0xFFFFF8D7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: BrightValuePop(
                value: '$finished:$stars',
                child: Text(emoji, style: const TextStyle(fontSize: 27)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$completed/$total levels • ⭐ $stars',
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
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
