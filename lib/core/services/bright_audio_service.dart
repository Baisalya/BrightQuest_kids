import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_models.dart';
import 'windows_mci_audio_backend.dart';
import 'windows_speech_backend.dart';

class BrightVoiceOption {
  const BrightVoiceOption({
    required this.id,
    required this.name,
    required this.locale,
    this.gender = '',
  });

  final String id;
  final String name;
  final String locale;
  final String gender;

  bool get isFemale {
    final searchable = '$gender $name $id'.toLowerCase();
    const femaleMarkers = <String>[
      'female',
      'zira',
      'susan',
      'hazel',
      'heera',
      'samantha',
      'karen',
      'victoria',
      'moira',
    ];
    return femaleMarkers.any(searchable.contains);
  }

  String get label {
    final genderLabel = gender.isEmpty ? '' : ' • $gender';
    return '$name • $locale$genderLabel';
  }
}

enum BrightSfx {
  tap,
  correct,
  wrong,
  complete,
  coin,
  star,
  unlock,
  hint,
  levelStart,
}

/// The sound identity used by an interactive learning surface.
///
/// Global app chrome keeps the original generic effects, while every core
/// learning game and Nursery owns a separate pack so option taps, actions and
/// feedback sound like the activity the child is actually playing.
enum BrightSfxProfile {
  global,
  mathMarket,
  fractionPizza,
  scienceLab,
  storyBuilder,
  grammarPuzzle,
  mapQuest,
  codingMaze,
  recyclingChallenge,
  nursery,
}

/// Semantic interaction roles shared by the per-game sound packs.
enum BrightInteractionSfx {
  tap,
  option,
  action,
  correct,
  wrong,
  hint,
  complete,
  next,
  start,
}

class BrightAudioService extends ChangeNotifier with WidgetsBindingObserver {
  BrightAudioService._();

  static final BrightAudioService instance = BrightAudioService._();

  static const String menuMusicAsset = 'audio/bgm/mix_menu_explorer.mp3';

  /// Source themes folded into each longer background-music playlist.
  ///
  /// Home deliberately keeps the existing explorer mix. Every adventure now
  /// owns its own four-section composition so Math Market, Science Lab, Story
  /// Builder, Coding Maze, and the other games no longer share the same generic
  /// category loop. Nursery play also has a separate, gentler playlist.
  static const Map<String, List<String>> musicPlaylistSources =
      <String, List<String>>{
    'menu_explorer': <String>[
      'audio/bgm/menu.mp3',
      'audio/bgm/story_builder.mp3',
      'audio/bgm/map_quest.mp3',
      'audio/bgm/rewards_room.mp3',
    ],
    'game_math_market': <String>[
      'audio/bgm/game_math_market_theme_a.mp3',
      'audio/bgm/game_math_market_theme_b.mp3',
      'audio/bgm/game_math_market_theme_c.mp3',
      'audio/bgm/game_math_market_theme_d.mp3',
    ],
    'game_fraction_pizza': <String>[
      'audio/bgm/game_fraction_pizza_theme_a.mp3',
      'audio/bgm/game_fraction_pizza_theme_b.mp3',
      'audio/bgm/game_fraction_pizza_theme_c.mp3',
      'audio/bgm/game_fraction_pizza_theme_d.mp3',
    ],
    'game_science_lab': <String>[
      'audio/bgm/game_science_lab_theme_a.mp3',
      'audio/bgm/game_science_lab_theme_b.mp3',
      'audio/bgm/game_science_lab_theme_c.mp3',
      'audio/bgm/game_science_lab_theme_d.mp3',
    ],
    'game_story_builder': <String>[
      'audio/bgm/game_story_builder_theme_a.mp3',
      'audio/bgm/game_story_builder_theme_b.mp3',
      'audio/bgm/game_story_builder_theme_c.mp3',
      'audio/bgm/game_story_builder_theme_d.mp3',
    ],
    'game_grammar_puzzle': <String>[
      'audio/bgm/game_grammar_puzzle_theme_a.mp3',
      'audio/bgm/game_grammar_puzzle_theme_b.mp3',
      'audio/bgm/game_grammar_puzzle_theme_c.mp3',
      'audio/bgm/game_grammar_puzzle_theme_d.mp3',
    ],
    'game_map_quest': <String>[
      'audio/bgm/game_map_quest_theme_a.mp3',
      'audio/bgm/game_map_quest_theme_b.mp3',
      'audio/bgm/game_map_quest_theme_c.mp3',
      'audio/bgm/game_map_quest_theme_d.mp3',
    ],
    'game_coding_maze': <String>[
      'audio/bgm/game_coding_maze_theme_a.mp3',
      'audio/bgm/game_coding_maze_theme_b.mp3',
      'audio/bgm/game_coding_maze_theme_c.mp3',
      'audio/bgm/game_coding_maze_theme_d.mp3',
    ],
    'game_recycling_challenge': <String>[
      'audio/bgm/game_recycling_challenge_theme_a.mp3',
      'audio/bgm/game_recycling_challenge_theme_b.mp3',
      'audio/bgm/game_recycling_challenge_theme_c.mp3',
      'audio/bgm/game_recycling_challenge_theme_d.mp3',
    ],
    'game_rewards_room': <String>[
      'audio/bgm/game_rewards_room_theme_a.mp3',
      'audio/bgm/game_rewards_room_theme_b.mp3',
      'audio/bgm/game_rewards_room_theme_c.mp3',
      'audio/bgm/game_rewards_room_theme_d.mp3',
    ],
    'nursery_play': <String>[
      'audio/bgm/nursery_theme_a.mp3',
      'audio/bgm/nursery_theme_b.mp3',
      'audio/bgm/nursery_theme_c.mp3',
      'audio/bgm/nursery_theme_d.mp3',
    ],
  };

  static const Map<String, String> musicPlaylistAssets = <String, String>{
    'menu_explorer': 'audio/bgm/mix_menu_explorer.mp3',
    'game_math_market': 'audio/bgm/mix_game_math_market.mp3',
    'game_fraction_pizza': 'audio/bgm/mix_game_fraction_pizza.mp3',
    'game_science_lab': 'audio/bgm/mix_game_science_lab.mp3',
    'game_story_builder': 'audio/bgm/mix_game_story_builder.mp3',
    'game_grammar_puzzle': 'audio/bgm/mix_game_grammar_puzzle.mp3',
    'game_map_quest': 'audio/bgm/mix_game_map_quest.mp3',
    'game_coding_maze': 'audio/bgm/mix_game_coding_maze.mp3',
    'game_recycling_challenge':
        'audio/bgm/mix_game_recycling_challenge.mp3',
    'game_rewards_room': 'audio/bgm/mix_game_rewards_room.mp3',
    'nursery_play': 'audio/bgm/mix_nursery_play.mp3',
  };

  static const Map<String, String> gameMusicAssets = <String, String>{
    'math_market': 'audio/bgm/mix_game_math_market.mp3',
    'fraction_pizza': 'audio/bgm/mix_game_fraction_pizza.mp3',
    'science_lab': 'audio/bgm/mix_game_science_lab.mp3',
    'story_builder': 'audio/bgm/mix_game_story_builder.mp3',
    'grammar_puzzle': 'audio/bgm/mix_game_grammar_puzzle.mp3',
    'map_quest': 'audio/bgm/mix_game_map_quest.mp3',
    'coding_maze': 'audio/bgm/mix_game_coding_maze.mp3',
    'recycling_challenge': 'audio/bgm/mix_game_recycling_challenge.mp3',
    'rewards_room': 'audio/bgm/mix_game_rewards_room.mp3',
  };

  static const String nurseryMusicAsset = 'audio/bgm/mix_nursery_play.mp3';

  static const Map<BrightSfx, String> sfxAssets = <BrightSfx, String>{
    BrightSfx.tap: 'audio/sfx/tap.mp3',
    BrightSfx.correct: 'audio/sfx/correct.mp3',
    BrightSfx.wrong: 'audio/sfx/wrong.mp3',
    BrightSfx.complete: 'audio/sfx/complete.mp3',
    BrightSfx.coin: 'audio/sfx/coin.mp3',
    BrightSfx.star: 'audio/sfx/star.mp3',
    BrightSfx.unlock: 'audio/sfx/unlock.mp3',
    BrightSfx.hint: 'audio/sfx/hint.mp3',
    BrightSfx.levelStart: 'audio/sfx/level_start.mp3',
  };

  static const Map<String, BrightSfxProfile> gameSfxProfiles =
      <String, BrightSfxProfile>{
    'math_market': BrightSfxProfile.mathMarket,
    'fraction_pizza': BrightSfxProfile.fractionPizza,
    'science_lab': BrightSfxProfile.scienceLab,
    'story_builder': BrightSfxProfile.storyBuilder,
    'grammar_puzzle': BrightSfxProfile.grammarPuzzle,
    'map_quest': BrightSfxProfile.mapQuest,
    'coding_maze': BrightSfxProfile.codingMaze,
    'recycling_challenge': BrightSfxProfile.recyclingChallenge,
  };

  /// Complete thematic SFX packs for core games and Nursery.
  ///
  /// Keeping this data explicit makes missing roles fail in QA instead of
  /// silently turning a child interaction back into the same generic click.
  static const Map<BrightSfxProfile, Map<BrightInteractionSfx, String>>
      profileSfxAssets =
      <BrightSfxProfile, Map<BrightInteractionSfx, String>>{
    BrightSfxProfile.global: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/tap.mp3',
      BrightInteractionSfx.action: 'audio/sfx/tap.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/tap.mp3',
      BrightInteractionSfx.start: 'audio/sfx/level_start.mp3',
    },
    BrightSfxProfile.mathMarket: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_math_market_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_math_market_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_math_market_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_math_market_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_math_market_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_math_market_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_math_market_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_math_market_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_math_market_start.mp3',
    },
    BrightSfxProfile.fractionPizza: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_fraction_pizza_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_fraction_pizza_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_fraction_pizza_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_fraction_pizza_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_fraction_pizza_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_fraction_pizza_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_fraction_pizza_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_fraction_pizza_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_fraction_pizza_start.mp3',
    },
    BrightSfxProfile.scienceLab: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_science_lab_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_science_lab_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_science_lab_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_science_lab_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_science_lab_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_science_lab_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_science_lab_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_science_lab_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_science_lab_start.mp3',
    },
    BrightSfxProfile.storyBuilder: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_story_builder_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_story_builder_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_story_builder_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_story_builder_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_story_builder_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_story_builder_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_story_builder_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_story_builder_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_story_builder_start.mp3',
    },
    BrightSfxProfile.grammarPuzzle: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_grammar_puzzle_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_grammar_puzzle_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_grammar_puzzle_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_grammar_puzzle_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_grammar_puzzle_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_grammar_puzzle_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_grammar_puzzle_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_grammar_puzzle_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_grammar_puzzle_start.mp3',
    },
    BrightSfxProfile.mapQuest: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_map_quest_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_map_quest_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_map_quest_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_map_quest_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_map_quest_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_map_quest_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_map_quest_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_map_quest_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_map_quest_start.mp3',
    },
    BrightSfxProfile.codingMaze: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_coding_maze_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_coding_maze_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_coding_maze_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_coding_maze_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_coding_maze_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_coding_maze_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_coding_maze_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_coding_maze_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_coding_maze_start.mp3',
    },
    BrightSfxProfile.recyclingChallenge: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/game_recycling_challenge_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/game_recycling_challenge_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/game_recycling_challenge_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/game_recycling_challenge_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/game_recycling_challenge_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/game_recycling_challenge_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/game_recycling_challenge_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/game_recycling_challenge_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/game_recycling_challenge_start.mp3',
    },
    BrightSfxProfile.nursery: <BrightInteractionSfx, String>{
      BrightInteractionSfx.tap: 'audio/sfx/nursery_tap.mp3',
      BrightInteractionSfx.option: 'audio/sfx/nursery_option.mp3',
      BrightInteractionSfx.action: 'audio/sfx/nursery_action.mp3',
      BrightInteractionSfx.correct: 'audio/sfx/nursery_correct.mp3',
      BrightInteractionSfx.wrong: 'audio/sfx/nursery_wrong.mp3',
      BrightInteractionSfx.hint: 'audio/sfx/nursery_hint.mp3',
      BrightInteractionSfx.complete: 'audio/sfx/nursery_complete.mp3',
      BrightInteractionSfx.next: 'audio/sfx/nursery_next.mp3',
      BrightInteractionSfx.start: 'audio/sfx/nursery_start.mp3',
    },
  };

  static const Map<BrightSfxProfile, double> profileVolumeScale =
      <BrightSfxProfile, double>{
    BrightSfxProfile.global: 1.0,
    BrightSfxProfile.mathMarket: 0.92,
    BrightSfxProfile.fractionPizza: 0.90,
    BrightSfxProfile.scienceLab: 0.90,
    BrightSfxProfile.storyBuilder: 0.88,
    BrightSfxProfile.grammarPuzzle: 0.88,
    BrightSfxProfile.mapQuest: 0.90,
    BrightSfxProfile.codingMaze: 0.86,
    BrightSfxProfile.recyclingChallenge: 0.90,
    BrightSfxProfile.nursery: 0.76,
  };

  static const Map<String, String> gameIntroLines = <String, String>{
    'math_market':
        'Welcome to Math Market! Solve the question, then shop smart.',
    'fraction_pizza':
        'Pizza time! Build the fraction by choosing the right number of slices.',
    'science_lab':
        'Welcome, scientist! Mix, observe, and answer the science challenge.',
    'story_builder':
        'Let us build a story. Read the clue, then put the words in order.',
    'grammar_puzzle':
        'Ready for a word puzzle? Find the noun, verb, and adjective.',
    'map_quest': 'Compass ready! Read the clue and explore the map.',
    'coding_maze':
        'Robot ready! Build a command sequence and guide the bot to the goal.',
    'recycling_challenge':
        'Green Planet needs you! Sort each item into the right bin.',
    'rewards_room':
        'Welcome to your Rewards Room. Look at the treasures you earned by learning!',
  };

  AudioPlayer? _musicPlayer;
  AudioPlayer? _sfxPlayer;
  final WindowsMciAudioBackend _windowsAudio = WindowsMciAudioBackend();
  final WindowsSpeechBackend _windowsVoice = WindowsSpeechBackend();
  FlutterTts? _tts;

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _ttsConfigured = false;
  bool _sessionEnabled = true;
  bool _pausedByLifecycle = false;
  String _requestedMusic = menuMusicAsset;
  String? _playingMusic;
  bool _voiceDucked = false;
  int _speechGeneration = 0;
  int _feedbackIndex = 0;
  String? _preferredVoiceId;

  /// Device-wide parent audio master. This sits above the legacy per-profile
  /// session gate so a parent can silence the complete app without editing
  /// every child profile separately.
  bool appAudioEnabled = true;
  bool musicEnabled = true;
  bool sfxEnabled = true;
  bool voiceEnabled = true;
  bool autoNarrationEnabled = true;
  bool voiceFeedbackEnabled = true;
  double musicVolume = 0.20;
  double sfxVolume = 0.70;
  double voiceVolume = 0.90;
  double voiceRate = 0.42;
  double voicePitch = 1.08;
  List<BrightVoiceOption> availableVoices = const <BrightVoiceOption>[];
  String? selectedVoiceId;

  bool get initialized => _initialized;
  bool get sessionEnabled => _sessionEnabled;
  bool get audioOutputEnabled => appAudioEnabled && _sessionEnabled;
  bool get voiceAvailable => !Platform.isWindows || _windowsVoice.available;
  bool get voicePitchAvailable => !Platform.isWindows;
  BrightVoiceOption? get selectedVoice {
    for (final voice in availableVoices) {
      if (voice.id == selectedVoiceId) return voice;
    }
    return null;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final prefs = _prefs!;
      appAudioEnabled = prefs.getBool('bright_audio.app_enabled') ?? true;
      musicEnabled = prefs.getBool('bright_audio.music_enabled') ?? true;
      sfxEnabled = prefs.getBool('bright_audio.sfx_enabled') ?? true;
      voiceEnabled = prefs.getBool('bright_audio.voice_enabled') ?? true;
      autoNarrationEnabled =
          prefs.getBool('bright_audio.auto_narration') ?? true;
      voiceFeedbackEnabled =
          prefs.getBool('bright_audio.voice_feedback') ?? true;
      musicVolume =
          _clamp01(prefs.getDouble('bright_audio.music_volume') ?? 0.20);
      sfxVolume = _clamp01(prefs.getDouble('bright_audio.sfx_volume') ?? 0.70);
      voiceVolume =
          _clamp01(prefs.getDouble('bright_audio.voice_volume') ?? 0.90);
      voiceRate = (prefs.getDouble('bright_audio.voice_rate') ?? 0.42)
          .clamp(0.30, 0.62)
          .toDouble();
      voicePitch = (prefs.getDouble('bright_audio.voice_pitch') ?? 1.08)
          .clamp(0.80, 1.30)
          .toDouble();
      _preferredVoiceId = prefs.getString('bright_audio.voice_id');

      _initialized = true;
      try {
        if (Platform.isWindows) {
          await _windowsAudio.initialize();
          await _windowsVoice.initialize();
          _loadWindowsVoices();
        } else {
          _tts = FlutterTts();
          _musicPlayer = AudioPlayer(playerId: 'brightquest_music');
          _sfxPlayer = AudioPlayer(playerId: 'brightquest_sfx');
          await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
          await _sfxPlayer!.setReleaseMode(ReleaseMode.stop);
        }
      } catch (_) {
        // Keep TTS/settings available even if an audio backend is unavailable.
      }
      if (!Platform.isWindows) {
        await _configureTts();
      }
      WidgetsBinding.instance.addObserver(this);
      notifyListeners();
    } catch (_) {
      // Audio is enhancement-only. The learning app must still run if local
      // preference loading fails on an unusual device.
      _initialized = false;
    }
  }

  Future<void> _configureTts() async {
    if (_ttsConfigured || !voiceAvailable) return;
    try {
      final tts = _tts ??= FlutterTts();
      await tts.setLanguage('en-IN');
      await tts.awaitSpeakCompletion(true);
      await tts.setSpeechRate(voiceRate);
      await tts.setPitch(voicePitch);
      await tts.setVolume(voiceVolume);
      await _loadAndroidVoices(tts);
      _ttsConfigured = true;
    } catch (_) {
      // Some Windows/Android installations expose fewer TTS options.
    }
  }

  void _loadWindowsVoices() {
    availableVoices = _windowsVoice.voices
        .map(
          (voice) => BrightVoiceOption(
            id: 'windows:${voice.name}',
            name: voice.name,
            locale: voice.locale,
            gender: voice.gender,
          ),
        )
        .toList(growable: false);
    _chooseInitialVoice();
  }

  Future<void> _loadAndroidVoices(FlutterTts tts) async {
    try {
      final result = await tts.getVoices;
      if (result is! List) return;
      availableVoices = result
          .whereType<Map>()
          .map((voice) {
            final name = '${voice['name'] ?? ''}'.trim();
            final locale = '${voice['locale'] ?? ''}'.trim();
            final gender = '${voice['gender'] ?? ''}'.trim();
            return BrightVoiceOption(
              id: 'android:$locale:$name',
              name: name,
              locale: locale,
              gender: gender,
            );
          })
          .where(
            (voice) =>
                voice.name.isNotEmpty &&
                voice.locale.toLowerCase().startsWith('en'),
          )
          .toList(growable: false);
      _chooseInitialVoice();
      final voice = selectedVoice;
      if (voice != null) {
        await tts.setVoice(<String, String>{
          'name': voice.name,
          'locale': voice.locale,
        });
      }
    } catch (_) {
      // Keep the device default voice if enumeration is unavailable.
    }
  }

  void _chooseInitialVoice() {
    if (availableVoices.isEmpty) {
      selectedVoiceId = null;
      return;
    }
    final preferred = _preferredVoiceId;
    if (preferred != null &&
        availableVoices.any((voice) => voice.id == preferred)) {
      selectedVoiceId = preferred;
      return;
    }
    final englishFemale = availableVoices.where(
      (voice) => voice.isFemale && voice.locale.toLowerCase().startsWith('en'),
    );
    selectedVoiceId =
        (englishFemale.isNotEmpty ? englishFemale.first : availableVoices.first)
            .id;
  }

  Future<void> setVoice(String id) async {
    BrightVoiceOption? voice;
    for (final candidate in availableVoices) {
      if (candidate.id == id) {
        voice = candidate;
        break;
      }
    }
    if (voice == null || selectedVoiceId == id) return;
    await stopVoice();
    selectedVoiceId = id;
    _preferredVoiceId = id;
    await _prefs?.setString('bright_audio.voice_id', id);
    if (!Platform.isWindows) {
      try {
        await _tts?.setVoice(<String, String>{
          'name': voice.name,
          'locale': voice.locale,
        });
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setSessionEnabled(bool value) async {
    if (_sessionEnabled == value) return;
    _sessionEnabled = value;
    if (!value) {
      await stopVoice();
      await _safeMusicPause();
    } else if (_initialized &&
        appAudioEnabled &&
        musicEnabled &&
        !_pausedByLifecycle) {
      await _playMusicAsset(_requestedMusic, restart: false);
    }
  }

  Future<void> setAppAudioEnabled(bool value) async {
    if (appAudioEnabled == value) return;
    appAudioEnabled = value;
    await _prefs?.setBool('bright_audio.app_enabled', value);
    if (!value) {
      // Stop every audible channel immediately. Windows MCI needs an explicit
      // close to stop a currently playing one-shot SFX; Android uses the two
      // dedicated players. The requested BGM identity is intentionally kept so
      // re-enabling resumes the correct Home/game/Nursery music.
      await stopVoice();
      if (Platform.isWindows) {
        await _windowsAudio.stopAll();
        _playingMusic = null;
      } else {
        try {
          await _sfxPlayer?.stop();
        } catch (_) {}
        await _safeMusicPause();
      }
    } else if (_initialized &&
        _sessionEnabled &&
        musicEnabled &&
        !_pausedByLifecycle) {
      await _playMusicAsset(_requestedMusic, restart: false);
    }
    notifyListeners();
  }

  Future<void> playMenuMusic({bool restart = false}) async {
    _requestedMusic = menuMusicAsset;
    if (!_canPlayMusic) return;
    await _playMusicAsset(_requestedMusic, restart: restart);
  }

  Future<void> playGameMusic(String gameId, {bool restart = false}) async {
    _requestedMusic = gameMusicAssets[gameId] ?? menuMusicAsset;
    if (!_canPlayMusic) return;
    await _playMusicAsset(_requestedMusic, restart: restart);
  }

  Future<void> playNurseryMusic({bool restart = false}) async {
    _requestedMusic = nurseryMusicAsset;
    if (!_canPlayMusic) return;
    await _playMusicAsset(_requestedMusic, restart: restart);
  }

  Future<void> _playMusicAsset(String asset, {required bool restart}) async {
    if (!_initialized) return;
    try {
      if (Platform.isWindows) {
        final targetVolume = _voiceDucked ? musicVolume * 0.32 : musicVolume;
        await _windowsAudio.playMusic(
          asset,
          volume: targetVolume,
          restart: restart,
        );
        if (_windowsAudio.currentMusicAsset == asset) {
          _playingMusic = asset;
        }
        return;
      }

      final player = _musicPlayer;
      if (player == null) return;
      if (!restart && _playingMusic == asset) {
        await player.setVolume(musicVolume);
        if (player.state == PlayerState.playing) return;
        if (player.state == PlayerState.paused) {
          await player.resume();
          return;
        }
      }
      await player.stop();
      await player.play(AssetSource(asset), volume: musicVolume);
      _playingMusic = asset;
    } catch (_) {
      // Never block gameplay because of an audio backend problem.
    }
  }

  static BrightSfxProfile sfxProfileForGame(String gameId) =>
      gameSfxProfiles[gameId] ?? BrightSfxProfile.global;

  String? profileSfxAsset(
    BrightSfxProfile profile,
    BrightInteractionSfx effect,
  ) =>
      profileSfxAssets[profile]?[effect] ??
      profileSfxAssets[BrightSfxProfile.global]?[effect];

  Future<void> playGameSfx(
    String gameId,
    BrightInteractionSfx effect,
  ) =>
      playProfileSfx(sfxProfileForGame(gameId), effect);

  Future<void> playNurserySfx(BrightInteractionSfx effect) =>
      playProfileSfx(BrightSfxProfile.nursery, effect);

  Future<void> playProfileSfx(
    BrightSfxProfile profile,
    BrightInteractionSfx effect,
  ) async {
    if (!_initialized || !appAudioEnabled || !_sessionEnabled || !sfxEnabled) return;
    final asset = profileSfxAsset(profile, effect);
    if (asset == null) return;
    final volume = _clamp01(
      sfxVolume * (profileVolumeScale[profile] ?? 1.0),
    );
    try {
      if (Platform.isWindows) {
        await _windowsAudio.playSfx(asset, volume: volume);
        return;
      }
      final player = _sfxPlayer;
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {}
  }

  Future<void> playSfx(BrightSfx effect) async {
    if (!_initialized || !appAudioEnabled || !_sessionEnabled || !sfxEnabled) return;
    final asset = sfxAssets[effect];
    if (asset == null) return;
    try {
      if (Platform.isWindows) {
        await _windowsAudio.playSfx(asset, volume: sfxVolume);
        return;
      }
      final player = _sfxPlayer;
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource(asset), volume: sfxVolume);
    } catch (_) {}
  }

  Future<void> speak(String text, {bool manual = false}) async {
    final clean = _speechText(text);
    if (clean.isEmpty ||
        !_initialized ||
        !appAudioEnabled ||
        !_sessionEnabled ||
        !voiceEnabled ||
        !voiceAvailable) return;
    if (!manual && !autoNarrationEnabled) return;
    final generation = ++_speechGeneration;
    try {
      if (Platform.isWindows) {
        await _duckMusicForVoice();
        await _windowsVoice.speak(
          clean,
          volume: voiceVolume,
          rate: voiceRate,
          voiceName: selectedVoice?.name,
        );
        return;
      }
      await _configureTts();
      final tts = _tts;
      if (tts == null) return;
      await tts.stop();
      await _duckMusicForVoice();
      await tts.setSpeechRate(voiceRate);
      await tts.setPitch(voicePitch);
      await tts.setVolume(voiceVolume);
      await tts.speak(clean);
    } catch (_) {
      // Speech engines are optional. Keep the learning flow uninterrupted.
    } finally {
      if (generation == _speechGeneration) {
        await _restoreMusicAfterVoice();
      }
    }
  }

  Future<void> speakGameIntro(String gameId) async {
    final line = gameIntroLines[gameId];
    if (line != null) await speak(line);
  }

  Future<void> speakPrompt(
    String prompt, {
    Iterable<Object> choices = const <Object>[],
  }) async {
    final readableChoices = choices
        .map((choice) => _speechText('$choice'))
        .where((choice) => choice.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final choicesLine = readableChoices.isEmpty
        ? ''
        : ' Your choices are ${_spokenList(readableChoices)}.';
    await speak('$prompt$choicesLine', manual: true);
  }

  Future<void> speakCorrect({String? answer, String? detail}) async {
    if (!voiceFeedbackEnabled) return;
    const happyLeads = <String>[
      'Fantastic!',
      'Brilliant work!',
      'Yes, you got it!',
      'Amazing job!',
    ];
    final lead = happyLeads[_feedbackIndex++ % happyLeads.length];
    final answerLine = answer == null || answer.trim().isEmpty
        ? ''
        : ' You chose ${answer.trim()}, and that is correct.';
    final detailLine =
        detail == null || detail.trim().isEmpty ? '' : ' ${detail.trim()}';
    await speak('$lead$answerLine$detailLine', manual: true);
  }

  Future<void> speakWrong({
    String? answer,
    String? correctAnswer,
    String? guidance,
  }) async {
    if (!voiceFeedbackEnabled) return;
    const gentleLeads = <String>[
      'Good try!',
      'Almost there!',
      'Nice effort!',
      'Keep going, explorer!',
    ];
    final lead = gentleLeads[_feedbackIndex++ % gentleLeads.length];
    final answerLine = answer == null || answer.trim().isEmpty
        ? ' That answer is not correct yet.'
        : ' You chose ${answer.trim()}.';
    final correctionLine = correctAnswer == null || correctAnswer.trim().isEmpty
        ? ''
        : ' The correct answer is ${correctAnswer.trim()}.';
    final guidanceLine = guidance == null || guidance.trim().isEmpty
        ? ' Try once more.'
        : ' ${guidance.trim()}';
    await speak(
      '$lead$answerLine$correctionLine$guidanceLine',
      manual: true,
    );
  }

  Future<void> speakComplete({MissionReward? reward}) async {
    if (!voiceFeedbackEnabled) return;
    final earnedStars = reward == null
        ? 0
        : reward.levelStarsAwarded > 0
            ? reward.levelStarsAwarded
            : reward.starsAwarded;
    final starLine = earnedStars <= 0
        ? ''
        : ' You earned $earnedStars ${earnedStars == 1 ? 'star' : 'stars'}!';
    final unlockLine =
        reward?.unlockedNextLevel == true ? ' A new level is unlocked!' : '';
    await speak('Amazing work! Adventure complete!$starLine$unlockLine',
        manual: true);
  }

  Future<void> stopVoice() async {
    if (!_initialized) return;
    _speechGeneration += 1;
    try {
      if (Platform.isWindows) {
        await _windowsVoice.stop();
      } else {
        await _tts?.stop();
      }
    } catch (_) {}
    await _restoreMusicAfterVoice();
  }

  Future<void> _duckMusicForVoice() async {
    if (!_canPlayMusic) return;
    try {
      if (Platform.isWindows) {
        if (!_windowsAudio.musicPlaying) return;
        await _windowsAudio.setMusicVolume(
          (musicVolume * 0.32).clamp(0.0, 1.0).toDouble(),
        );
        _voiceDucked = true;
        return;
      }
      final player = _musicPlayer;
      if (player == null || player.state != PlayerState.playing) return;
      await player.setVolume((musicVolume * 0.32).clamp(0.0, 1.0).toDouble());
      _voiceDucked = true;
    } catch (_) {}
  }

  Future<void> _restoreMusicAfterVoice() async {
    if (!_voiceDucked) return;
    _voiceDucked = false;
    if (!_initialized) return;
    try {
      if (Platform.isWindows) {
        await _windowsAudio.setMusicVolume(musicVolume);
        return;
      }
      await _musicPlayer?.setVolume(musicVolume);
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool value) async {
    if (musicEnabled == value) return;
    musicEnabled = value;
    await _prefs?.setBool('bright_audio.music_enabled', value);
    if (!value) {
      await _safeMusicPause();
    } else if (appAudioEnabled &&
        _sessionEnabled &&
        !_pausedByLifecycle) {
      await _playMusicAsset(_requestedMusic, restart: false);
    }
    notifyListeners();
  }

  Future<void> setSfxEnabled(bool value) async {
    if (sfxEnabled == value) return;
    sfxEnabled = value;
    await _prefs?.setBool('bright_audio.sfx_enabled', value);
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool value) async {
    if (voiceEnabled == value) return;
    voiceEnabled = value;
    await _prefs?.setBool('bright_audio.voice_enabled', value);
    if (!value) await stopVoice();
    notifyListeners();
  }

  Future<void> setAutoNarrationEnabled(bool value) async {
    if (autoNarrationEnabled == value) return;
    autoNarrationEnabled = value;
    await _prefs?.setBool('bright_audio.auto_narration', value);
    notifyListeners();
  }

  Future<void> setVoiceFeedbackEnabled(bool value) async {
    if (voiceFeedbackEnabled == value) return;
    voiceFeedbackEnabled = value;
    await _prefs?.setBool('bright_audio.voice_feedback', value);
    notifyListeners();
  }

  Future<void> setMusicVolume(double value) async {
    musicVolume = _clamp01(value);
    await _prefs?.setDouble('bright_audio.music_volume', musicVolume);
    if (_initialized) {
      try {
        final effectiveVolume = _voiceDucked ? musicVolume * 0.32 : musicVolume;
        if (Platform.isWindows) {
          await _windowsAudio.setMusicVolume(effectiveVolume);
        } else {
          await _musicPlayer?.setVolume(effectiveVolume);
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setSfxVolume(double value) async {
    sfxVolume = _clamp01(value);
    await _prefs?.setDouble('bright_audio.sfx_volume', sfxVolume);
    notifyListeners();
  }

  Future<void> setVoiceVolume(double value) async {
    voiceVolume = _clamp01(value);
    await _prefs?.setDouble('bright_audio.voice_volume', voiceVolume);
    try {
      await _tts?.setVolume(voiceVolume);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setVoiceRate(double value) async {
    voiceRate = value.clamp(0.30, 0.62).toDouble();
    await _prefs?.setDouble('bright_audio.voice_rate', voiceRate);
    try {
      await _tts?.setSpeechRate(voiceRate);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setVoicePitch(double value) async {
    voicePitch = value.clamp(0.80, 1.30).toDouble();
    await _prefs?.setDouble('bright_audio.voice_pitch', voicePitch);
    try {
      await _tts?.setPitch(voicePitch);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> testVoice() => speak(
        'Hi explorer! I am your BrightQuest guide. Let us learn, play, and discover together!',
        manual: true,
      );

  bool get _canPlayMusic =>
      _initialized &&
      appAudioEnabled &&
      _sessionEnabled &&
      musicEnabled &&
      !_pausedByLifecycle;

  Future<void> _safeMusicPause() async {
    if (!_initialized) return;
    try {
      if (Platform.isWindows) {
        await _windowsAudio.pauseMusic();
        return;
      }
      final player = _musicPlayer;
      if (player != null && player.state == PlayerState.playing) {
        await player.pause();
      }
    } catch (_) {}
  }

  static String _speechText(String value) {
    return value
        .replaceAll('÷', ' divided by ')
        .replaceAll('×', ' times ')
        .replaceAll('=', ' equals ')
        .replaceAll('•', '. ')
        .replaceAll('→', ' to ')
        .replaceAll('%', ' percent ')
        .replaceAll('₹', ' rupees ')
        .replaceAllMapped(
          RegExp(r'\b(\d+)\s*/\s*(\d+)\b'),
          (match) => '${match.group(1)} out of ${match.group(2)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _spokenList(List<String> values) {
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first}, or ${values.last}';
    return '${values.take(values.length - 1).join(', ')}, or ${values.last}';
  }

  static double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized) return;
    if (state == AppLifecycleState.resumed) {
      _pausedByLifecycle = false;
      if (appAudioEnabled && _sessionEnabled && musicEnabled) {
        unawaited(_playMusicAsset(_requestedMusic, restart: false));
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pausedByLifecycle = true;
      unawaited(_safeMusicPause());
      unawaited(stopVoice());
    }
  }
}
