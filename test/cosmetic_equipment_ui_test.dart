import 'package:brightquest_kids/core/content/cosmetic_catalog.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/games/coding_maze_screen.dart';
import 'package:brightquest_kids/features/games/rewards_room_screen.dart';
import 'package:brightquest_kids/features/games/science_lab_screen.dart';
import 'package:brightquest_kids/widgets/bright_illustrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

Future<GameController> _controllerWithProfile({
  required MemoryProgressStore store,
  int coins = 1000,
  Set<String> unlockedRewards = const <String>{},
  Map<String, String> equippedCosmetics = const <String, String>{},
}) async {
  final profile = ChildProfileSnapshot(
    id: 'child-1',
    name: 'Explorer',
    selectedClass: 4,
    coins: coins,
    unlockedRewards: Set<String>.from(unlockedRewards),
    equippedCosmetics: Map<String, String>.from(equippedCosmetics),
  );
  await store.write(
    PlayerSnapshot(
      activeProfileId: profile.id,
      profiles: <String, ChildProfileSnapshot>{profile.id: profile},
    ).toJson(),
  );
  final controller = GameController(store: store);
  await controller.load();
  controller.setReducedMotionEnabled(true);
  return controller;
}

void main() {
  test('catalog has three safe visual choices for every main game', () {
    const expectedGameIds = <String>{
      'math_market',
      'fraction_pizza',
      'story_builder',
      'grammar_puzzle',
      'science_lab',
      'map_quest',
      'coding_maze',
      'recycling_challenge',
    };

    expect(cosmeticCatalog.length, 24);
    expect(cosmeticCatalog.map((item) => item.id).toSet().length, 24);
    expect(cosmeticCatalog.map((item) => item.gameId).toSet(), expectedGameIds);
    for (final gameId in expectedGameIds) {
      expect(cosmeticsForGame(gameId), hasLength(3), reason: gameId);
    }

    expect(cosmeticById('galaxy_bot_skin')?.cost, 350);
    expect(cosmeticById('lion_lab_coat')?.cost, 200);
    expect(cosmeticById('story_castle_badge')?.cost, 150);
    expect(cosmeticById('eco_hero_crown')?.cost, 250);
  });

  test('old profile JSON without an equip map stays schema-compatible', () {
    final profile = ChildProfileSnapshot.fromJson(<String, Object?>{
      'id': 'child-1',
      'name': 'Explorer',
      'selectedClass': 4,
      'coins': 160,
      'unlockedRewards': <String>['galaxy_bot_skin'],
    });

    expect(profile.unlockedRewards, contains('galaxy_bot_skin'));
    expect(profile.equippedCosmetics, isEmpty);
    expect(PlayerSnapshot().schemaVersion, 6);
  });

  test('legacy Galaxy ownership auto-equips and explicit loadout persists',
      () async {
    final store = MemoryProgressStore();
    final controller = await _controllerWithProfile(
      store: store,
      unlockedRewards: <String>{'galaxy_bot_skin'},
    );

    expect(controller.isRewardUnlocked('galaxy_bot_skin'), isTrue);
    expect(
        controller.equippedRewardIdForGame('coding_maze'), 'galaxy_bot_skin');

    expect(controller.unequipRewardForGame('coding_maze'), isTrue);
    expect(controller.equippedRewardIdForGame('coding_maze'), isNull);
    await controller.flush();

    final restored = GameController(store: store);
    await restored.load();
    expect(restored.isRewardUnlocked('galaxy_bot_skin'), isTrue);
    expect(restored.equippedRewardIdForGame('coding_maze'), isNull);

    final coinsBefore = restored.coins;
    expect(restored.equipReward('galaxy_bot_skin'), isTrue);
    expect(restored.coins, coinsBefore);
    expect(restored.equippedRewardIdForGame('coding_maze'), 'galaxy_bot_skin');

    // Known catalog pricing is authoritative even if an old caller supplies a
    // stale cost. Buying also equips the new visual immediately.
    expect(restored.buyReward(rewardId: 'neon_bot_skin', cost: 1), isTrue);
    expect(restored.coins, coinsBefore - 220);
    expect(restored.equippedRewardIdForGame('coding_maze'), 'neon_bot_skin');

    expect(restored.equipReward('galaxy_bot_skin'), isTrue);
    expect(restored.coins, coinsBefore - 220);
    await restored.flush();

    final roundTrip = GameController(store: store);
    await roundTrip.load();
    expect(roundTrip.equippedRewardIdForGame('coding_maze'), 'galaxy_bot_skin');
  });

  test('cosmetic ownership and equipped loadouts stay isolated per child',
      () async {
    final store = MemoryProgressStore();
    final controller = await _controllerWithProfile(
      store: store,
      coins: 1000,
      unlockedRewards: <String>{'galaxy_bot_skin'},
    );
    final firstId = controller.activeProfileId;

    final secondId = controller.createProfile(
      name: 'Mira',
      classNumber: 5,
      avatarEmoji: '👧',
    );
    expect(controller.buyReward(rewardId: 'neon_bot_skin', cost: 220), isTrue);
    expect(controller.equippedRewardIdForGame('coding_maze'), 'neon_bot_skin');

    expect(controller.switchProfile(firstId), isTrue);
    expect(controller.isRewardUnlocked('neon_bot_skin'), isFalse);
    expect(
        controller.equippedRewardIdForGame('coding_maze'), 'galaxy_bot_skin');

    expect(controller.switchProfile(secondId), isTrue);
    expect(controller.isRewardUnlocked('galaxy_bot_skin'), isFalse);
    expect(controller.equippedRewardIdForGame('coding_maze'), 'neon_bot_skin');
  });

  testWidgets(
      'Rewards Room stays overflow-free on Android, free-form and Windows sizes',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = <Size>[
      Size(360, 640),
      Size(600, 700),
      Size(900, 600),
      Size(1024, 700),
      Size(1440, 900),
      Size(1920, 1080),
    ];

    for (final size in sizes) {
      final controller = await _controllerWithProfile(
        store: MemoryProgressStore(),
        coins: 1000,
        unlockedRewards: <String>{'galaxy_bot_skin'},
      );
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            );
          },
          home: buildTestScope(
            controller: controller,
            child: const RewardsRoomScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rewards_room_hero')), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Rewards Room hero overflowed at $size');

      final scroll = find.byKey(const Key('rewards_room_scroll'));
      for (var attempt = 0;
          attempt < 5 && find.text('My loadout').evaluate().isEmpty;
          attempt++) {
        await tester.drag(scroll, const Offset(0, -140));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Rewards Room overflowed while scrolling at $size');
      }
      expect(find.text('My loadout'), findsOneWidget);

      for (var attempt = 0;
          attempt < 5 &&
              find
                  .byKey(const Key('equipped_cosmetic_galaxy_bot_skin'))
                  .evaluate()
                  .isEmpty;
          attempt++) {
        await tester.drag(scroll, const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Rewards Room loadout overflowed at $size');
      }
      expect(find.byKey(const Key('equipped_cosmetic_galaxy_bot_skin')),
          findsOneWidget);

      // Exercise the remaining lazily built shop/trophy content as well.
      for (var attempt = 0; attempt < 12; attempt++) {
        await tester.drag(scroll, const Offset(0, -260));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Rewards Room overflowed near the bottom at $size');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('owned Galaxy skin changes the actual Coding Maze robot marker',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(900, 760));
    final controller = await _controllerWithProfile(
      store: MemoryProgressStore(),
      unlockedRewards: <String>{'galaxy_bot_skin'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: buildTestScope(
          controller: controller,
          child: const CodingMazeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        controller.equippedRewardIdForGame('coding_maze'), 'galaxy_bot_skin');
    final robot = tester.widget<Text>(
      find.byKey(const Key('coding_robot_marker')),
    );
    expect(robot.data, '🤖🌌');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Science Lab applies the equipped mascot coat and goggles',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(900, 800));
    final controller = await _controllerWithProfile(
      store: MemoryProgressStore(),
      unlockedRewards: <String>{'science_nebula_coat'},
      equippedCosmetics: <String, String>{
        'science_lab': 'science_nebula_coat',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: buildTestScope(
          controller: controller,
          child: const ScienceLabScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mascot = tester.widget<BrightLionMascot>(
      find.byType(BrightLionMascot).first,
    );
    expect(mascot.scientist, isTrue);
    expect(mascot.scientistCoatColor, const Color(0xFF574590));
    expect(mascot.scientistGoggleColor, const Color(0xFF64DCEB));
    expect(tester.takeException(), isNull);
  });
}
