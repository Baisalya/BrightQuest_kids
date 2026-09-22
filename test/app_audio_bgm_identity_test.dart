import 'dart:io';

import 'package:brightquest_kids/core/models/game_models.dart';
import 'package:brightquest_kids/core/services/bright_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home keeps its explorer mix while every adventure gets unique BGM', () {
    expect(
      BrightAudioService.menuMusicAsset,
      'audio/bgm/mix_menu_explorer.mp3',
    );

    final gameAssets = <String>{};
    for (final game in games) {
      final asset = BrightAudioService.gameMusicAssets[game.id];
      expect(asset, isNotNull, reason: 'Missing game BGM for ${game.id}');
      expect(asset, isNot(BrightAudioService.menuMusicAsset));
      expect(gameAssets.add(asset!), isTrue,
          reason: '${game.id} shares BGM with another adventure');
      expect(File('assets/$asset').existsSync(), isTrue);

      final sources =
          BrightAudioService.musicPlaylistSources['game_${game.id}'];
      expect(sources, isNotNull,
          reason: '${game.id} has no dedicated playlist source set');
      expect(sources!.length, 4);
      expect(sources.toSet().length, 4);
      for (final source in sources) {
        expect(File('assets/$source').existsSync(), isTrue);
      }
    }
    expect(gameAssets.length, games.length);
  });

  test('Nursery play has its own gentle BGM identity', () {
    expect(
      BrightAudioService.nurseryMusicAsset,
      'audio/bgm/mix_nursery_play.mp3',
    );
    expect(File('assets/${BrightAudioService.nurseryMusicAsset}').existsSync(),
        isTrue);
    expect(
      BrightAudioService.gameMusicAssets.values,
      isNot(contains(BrightAudioService.nurseryMusicAsset)),
    );

    final nursery = BrightAudioService.musicPlaylistSources['nursery_play'];
    expect(nursery, isNotNull);
    expect(nursery!.length, 4);
    expect(nursery.toSet().length, 4);
  });

  test('parent audio screen owns device-wide channel mute and volume controls', () {
    final audioSettings = File(
      'lib/features/parent/parent_audio_settings_screen.dart',
    ).readAsStringSync();
    final service = File('lib/core/services/bright_audio_service.dart')
        .readAsStringSync();

    expect(audioSettings, contains("Key('app_wide_audio_controls')"));
    expect(audioSettings, contains("Key('app_audio_master')"));
    expect(audioSettings, contains("Key('app_bgm_mute')"));
    expect(audioSettings, contains("Key('app_bgm_volume')"));
    expect(audioSettings, contains("Key('app_sfx_mute')"));
    expect(audioSettings, contains("Key('app_sfx_volume')"));
    expect(audioSettings, contains("Key('app_narrator_mute')"));
    expect(audioSettings, contains("Key('app_narrator_volume')"));
    expect(audioSettings, contains('across the complete app'));

    expect(service, contains("bright_audio.app_enabled"));
    expect(service, contains('Future<void> setAppAudioEnabled(bool value)'));
    expect(service, contains('!appAudioEnabled'));
    expect(service, contains('appAudioEnabled &&'));
  });

  test('Nursery lesson switches to Nursery BGM and restores Home BGM', () {
    final nursery = File('lib/features/nursery/nursery_lesson_screen.dart')
        .readAsStringSync();
    expect(nursery, contains('playNurseryMusic(restart: true)'));
    expect(nursery, contains('playMenuMusic(restart: true)'));
  });
}
