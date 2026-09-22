import 'dart:io';

import 'package:brightquest_kids/core/services/bright_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const coreGameFiles = <String, String>{
    'math_market': 'math_market_screen.dart',
    'fraction_pizza': 'fraction_pizza_screen.dart',
    'science_lab': 'science_lab_screen.dart',
    'story_builder': 'story_builder_screen.dart',
    'grammar_puzzle': 'grammar_puzzle_screen.dart',
    'map_quest': 'map_quest_screen.dart',
    'coding_maze': 'coding_maze_screen.dart',
    'recycling_challenge': 'recycling_challenge_screen.dart',
  };

  test('every core game owns a complete non-generic sound pack', () {
    expect(
      BrightAudioService.gameSfxProfiles.keys.toSet(),
      coreGameFiles.keys.toSet(),
    );

    final global = BrightAudioService.profileSfxAssets[BrightSfxProfile.global]!;
    final themedAssets = <String>{};
    for (final entry in BrightAudioService.gameSfxProfiles.entries) {
      final profile = entry.value;
      final pack = BrightAudioService.profileSfxAssets[profile];
      expect(pack, isNotNull, reason: 'Missing SFX pack for ${entry.key}');
      expect(
        pack!.length,
        BrightInteractionSfx.values.length,
        reason: '${entry.key} must implement every interaction role',
      );
      expect(
        pack.values.toSet().length,
        pack.length,
        reason: '${entry.key} should not alias multiple roles to one file',
      );
      for (final effect in BrightInteractionSfx.values) {
        final asset = pack[effect];
        expect(asset, isNotNull, reason: '${entry.key} missing $effect');
        expect(
          asset,
          isNot(global[effect]),
          reason: '${entry.key} $effect fell back to the generic app sound',
        );
        expect(
          File('assets/$asset').existsSync(),
          isTrue,
          reason: 'Missing bundled SFX assets/$asset',
        );
        expect(
          themedAssets.add(asset!),
          isTrue,
          reason: 'Two game interactions share the same themed asset: $asset',
        );
      }
    }
    expect(
      themedAssets.length,
      coreGameFiles.length * BrightInteractionSfx.values.length,
    );
  });

  test('Nursery owns a softer complete sound identity', () {
    final nursery =
        BrightAudioService.profileSfxAssets[BrightSfxProfile.nursery];
    expect(nursery, isNotNull);
    expect(nursery!.length, BrightInteractionSfx.values.length);
    expect(nursery.values.toSet().length, nursery.length);
    expect(
      BrightAudioService.profileVolumeScale[BrightSfxProfile.nursery],
      lessThan(1.0),
    );
    for (final asset in nursery.values) {
      expect(asset, contains('audio/sfx/nursery_'));
      expect(File('assets/$asset').existsSync(), isTrue);
    }
  });

  test('game screens route interaction and feedback through their own profile', () {
    final expectedProfiles = <String, String>{
      'math_market': 'BrightSfxProfile.mathMarket',
      'fraction_pizza': 'BrightSfxProfile.fractionPizza',
      'science_lab': 'BrightSfxProfile.scienceLab',
      'story_builder': 'BrightSfxProfile.storyBuilder',
      'grammar_puzzle': 'BrightSfxProfile.grammarPuzzle',
      'map_quest': 'BrightSfxProfile.mapQuest',
      'coding_maze': 'BrightSfxProfile.codingMaze',
      'recycling_challenge': 'BrightSfxProfile.recyclingChallenge',
    };

    for (final entry in coreGameFiles.entries) {
      final source = File('lib/features/games/${entry.value}').readAsStringSync();
      expect(source, contains(expectedProfiles[entry.key]!));
      expect(source, contains('playProfileSfx(_soundProfile, effect)'));
      expect(source, contains('soundProfile: _soundProfile'));
      expect(
        source,
        contains('BrightInteractionSfx.option'),
        reason: '${entry.key} should sonify answer/choice selection',
      );
      expect(
        source,
        contains('BrightInteractionSfx.next'),
        reason: '${entry.key} should sonify manual progression',
      );
    }
  });

  test('Nursery choice, matching, sorting and tracing use the Nursery pack', () {
    final screen = File('lib/features/nursery/nursery_lesson_screen.dart')
        .readAsStringSync();
    final value = File('lib/features/nursery/nursery_game_value.dart')
        .readAsStringSync();
    final chrome = File('lib/features/nursery/nursery_game_chrome.dart')
        .readAsStringSync();
    final sort = File('lib/features/nursery/nursery_sort_game.dart')
        .readAsStringSync();
    final trace = File('lib/features/nursery/nursery_trace_game.dart')
        .readAsStringSync();

    expect(screen, contains('soundProfile: BrightSfxProfile.nursery'));
    expect(screen, contains('playNurseryStartSound()'));
    expect(screen, contains('playNurseryNextSound()'));
    expect(value, contains('playNurseryOptionSound()'));
    expect(chrome, contains('playNurseryOptionSound()'));
    expect(sort, contains('playNurseryActionSound()'));
    expect(trace, contains('playNurseryOptionSound()'));
  });

  test('game launch cue uses the matching game sound profile', () {
    final router = File('lib/features/games/game_router.dart').readAsStringSync();
    expect(
      router,
      contains('audio.playGameSfx(gameId, BrightInteractionSfx.start)'),
    );
  });
}
