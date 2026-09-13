import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/achievement_catalog.dart';
import '../../core/content/cosmetic_catalog.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_adaptive.dart';
import '../../widgets/bright_design_system.dart';
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

    final completedWorlds = learningWorlds.where((world) {
      final total = controller.totalLevelsForSubject(world.subject);
      return total > 0 &&
          controller.completedLevelsForSubject(world.subject) >= total;
    }).length;

    return GameScaffold(
      title: 'Rewards Room',
      subtitle: 'Looks • Badges • Trophies',
      color: const Color(0xFFF3B31E),
      voicePrompt:
          'Welcome to your Rewards Room. Your fun looks, badges, and trophies all live here.',
      child: ListView(
        key: const Key('rewards_room_scroll'),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          _RewardsHero(
            controller: controller,
            ownedCount: ownedCosmetics.length,
            equippedCount: equipped.length,
            badgeCount: unlockedAchievements.length,
          ),
          const SizedBox(height: 18),
          BrightSectionTitle(
            title: 'My loadout',
            subtitle:
                'These are the fun looks currently active in your adventures.',
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
                      'Nothing equipped yet. Choose a look below whenever you want.',
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
              spacing: 12,
              runSpacing: 12,
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
            title: 'Choose a look',
            subtitle:
                'Coins unlock visual fun only—never answers, stars, or learning progress.',
            icon: Icons.palette_rounded,
            trailing: BrightPill(
              icon: Icons.inventory_2_rounded,
              label: '${ownedCosmetics.length}/${cosmeticCatalog.length} OWNED',
            ),
          ),
          const SizedBox(height: 10),
          _RewardFilterBar(
            selected: _filter,
            gameIds: gameIds,
            onSelected: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 12),
          if (visibleCosmetics.isEmpty)
            const BrightSurface(
              child: Text(
                'No owned looks in this view yet.',
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
          const BrightSectionTitle(
            title: 'Celebrations',
            subtitle:
                'Trophies and badges stay together here so your reward space stays easy to explore.',
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 10),
          BrightSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ExpansionTile(
                  key: const Key('reward_trophies_expansion'),
                  leading: const Icon(Icons.emoji_events_rounded),
                  title: const Text(
                    'World trophies',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '$completedWorlds/${learningWorlds.length} complete • '
                    'Finish a world to turn its badge into a trophy.',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: BrightAdaptiveGrid(
                        minChildWidth: 220,
                        maxColumns: 4,
                        spacing: 10,
                        runSpacing: 10,
                        children: learningWorlds.map((world) {
                          final completed = controller
                              .completedLevelsForSubject(world.subject);
                          final total =
                              controller.totalLevelsForSubject(world.subject);
                          final stars =
                              controller.starsForSubject(world.subject);
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
                    ),
                  ],
                ),
                const Divider(height: 1),
                ExpansionTile(
                  key: const Key('reward_achievements_expansion'),
                  leading: const Icon(Icons.workspace_premium_rounded),
                  title: const Text(
                    'Achievement badges',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${unlockedAchievements.length}/${achievements.length} earned • '
                    'Badges come from learning, not spending.',
                  ),
                  children: [
                    if (unlockedAchievements.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your first badge will appear after your first Learning World clear.',
                            style: TextStyle(
                              color: AppTheme.inkMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: BrightAdaptiveGrid(
                          minChildWidth: 210,
                          maxColumns: 4,
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
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.verified_user_rounded,
            text:
                'Your owned looks and equipped choices stay saved per child profile. Rewards never change correctness or learning progress.',
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
    required this.badgeCount,
  });

  final GameController controller;
  final int ownedCount;
  final int equippedCount;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => Container(
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
            final compact = brightShouldStackForReadability(
              context: context,
              availableWidth: constraints.maxWidth,
              compactWidth: 650,
            );
            final copy = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                const BrightPill(
                  icon: Icons.card_giftcard_rounded,
                  label: 'MY REWARDS',
                  color: Color(0xFF765500),
                  background: Color(0xFFFFF2BD),
                ),
                const SizedBox(height: 9),
                Text(
                  'One place for everything you earn',
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
                  'Choose a look now, or open Celebrations when you want to see badges and trophies.',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment:
                      compact ? WrapAlignment.center : WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RewardHeroChip(
                      emoji: '🪙',
                      label: '${controller.coins} coins',
                    ),
                    _RewardHeroChip(
                      emoji: '🎨',
                      label: '$ownedCount looks',
                    ),
                    _RewardHeroChip(
                      emoji: '✨',
                      label: '$equippedCount equipped',
                    ),
                    _RewardHeroChip(
                      emoji: '🏅',
                      label: '$badgeCount badges',
                    ),
                  ],
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
                children: [
                  art,
                  const SizedBox(height: 10),
                  copy,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 18),
                art,
              ],
            );
          },
        ),
      );
}

class _RewardHeroChip extends StatelessWidget {
  const _RewardHeroChip({
    required this.emoji,
    required this.label,
  });

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .58),
          borderRadius: BorderRadius.circular(16),
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

class _RewardFilterBar extends StatelessWidget {
  const _RewardFilterBar({
    required this.selected,
    required this.gameIds,
    required this.onSelected,
  });

  final String selected;
  final List<String> gameIds;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedGameTitle = selected == 'all' || selected == 'owned'
        ? null
        : cosmeticsForGame(selected).first.gameTitle;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('All looks'),
          selected: selected == 'all',
          onSelected: (_) => onSelected('all'),
        ),
        ChoiceChip(
          avatar: const Icon(Icons.inventory_2_rounded, size: 16),
          label: const Text('Owned'),
          selected: selected == 'owned',
          onSelected: (_) => onSelected('owned'),
        ),
        PopupMenuButton<String>(
          key: const Key('reward_adventure_filter'),
          tooltip: 'Filter looks by adventure',
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final gameId in gameIds)
              PopupMenuItem<String>(
                value: gameId,
                child: Text(cosmeticsForGame(gameId).first.gameTitle),
              ),
          ],
          child: Chip(
            avatar: const Icon(Icons.sports_esports_rounded, size: 16),
            label: Text(selectedGameTitle ?? 'Adventure'),
          ),
        ),
      ],
    );
  }
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
        border: Border.all(
          color: accent.withValues(alpha: .28),
          width: 1.5,
        ),
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

    return Container(
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
                Icon(
                  Icons.check_circle_rounded,
                  color: accent,
                  size: 22,
                ),
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
              final compactActions = brightShouldStackForReadability(
                context: context,
                availableWidth: constraints.maxWidth,
                compactWidth: 340,
              );
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
                          onPressed: () => controller.equipReward(cosmetic.id),
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
    );
  }
}

class _CosmeticPreview extends StatelessWidget {
  const _CosmeticPreview({
    required this.cosmetic,
    required this.size,
  });

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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFFAE5),
                Colors.white,
              ],
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
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 27),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    finished
                        ? 'World complete • ⭐ $stars'
                        : '$completed of $total quests explored',
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
