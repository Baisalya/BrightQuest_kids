import 'dart:ffi';
import 'dart:io';

/// Small Windows-only audio backend used by BrightQuest.
///
/// It deliberately avoids Flutter event channels. Windows MCI plays the bundled
/// MP3 files directly, which keeps BrightQuest compatible with Flutter 3.41.x
/// and Visual Studio 18 without loading the older audioplayers Windows plugin.
class WindowsMciAudioBackend {
  WindowsMciAudioBackend();

  static const String _musicAlias = 'brightquest_music';
  static const String _sfxAlias = 'brightquest_sfx';

  DynamicLibrary? _winmm;
  DynamicLibrary? _crt;
  _MciSendStringDart? _mciSendString;
  _MallocDart? _malloc;
  _FreeDart? _free;

  bool _available = false;
  bool _musicOpen = false;
  bool _musicPaused = false;
  String? _currentMusicAsset;
  double _musicVolume = 0.20;

  bool get available => _available;
  bool get musicPlaying => _musicOpen && !_musicPaused;
  bool get musicPaused => _musicOpen && _musicPaused;
  String? get currentMusicAsset => _currentMusicAsset;

  Future<void> initialize() async {
    if (!Platform.isWindows || _available) return;
    try {
      _winmm = DynamicLibrary.open('winmm.dll');
      _crt = DynamicLibrary.open('msvcrt.dll');
      _mciSendString = _winmm!.lookupFunction<_MciSendStringNative, _MciSendStringDart>(
        'mciSendStringW',
      );
      _malloc = _crt!.lookupFunction<_MallocNative, _MallocDart>('malloc');
      _free = _crt!.lookupFunction<_FreeNative, _FreeDart>('free');
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  Future<void> playMusic(
    String asset, {
    required double volume,
    required bool restart,
  }) async {
    if (!_available) return;
    final normalizedVolume = _clamp01(volume);
    _musicVolume = normalizedVolume;

    if (!restart && _musicOpen && _currentMusicAsset == asset) {
      await setMusicVolume(normalizedVolume);
      if (_musicPaused) {
        _send('resume $_musicAlias');
        _musicPaused = false;
      }
      return;
    }

    _closeAlias(_musicAlias);
    _musicOpen = false;
    _musicPaused = false;
    _currentMusicAsset = null;

    final filePath = _resolveAssetFile(asset);
    if (filePath == null) return;

    final openCode = _send('open "${_escapePath(filePath)}" type mpegvideo alias $_musicAlias');
    if (openCode != 0) return;

    _musicOpen = true;
    _currentMusicAsset = asset;
    await setMusicVolume(normalizedVolume);
    final playCode = _send('play $_musicAlias repeat');
    if (playCode != 0) {
      _closeAlias(_musicAlias);
      _musicOpen = false;
      _currentMusicAsset = null;
    }
  }

  Future<void> pauseMusic() async {
    if (!_available || !_musicOpen || _musicPaused) return;
    if (_send('pause $_musicAlias') == 0) {
      _musicPaused = true;
    }
  }

  Future<void> resumeMusic() async {
    if (!_available || !_musicOpen || !_musicPaused) return;
    if (_send('resume $_musicAlias') == 0) {
      _musicPaused = false;
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = _clamp01(volume);
    if (!_available || !_musicOpen) return;
    final nativeVolume = (_musicVolume * 1000).round().clamp(0, 1000);
    _send('setaudio $_musicAlias volume to $nativeVolume');
  }

  Future<void> playSfx(String asset, {required double volume}) async {
    if (!_available) return;
    final filePath = _resolveAssetFile(asset);
    if (filePath == null) return;

    _closeAlias(_sfxAlias);
    final openCode = _send('open "${_escapePath(filePath)}" type mpegvideo alias $_sfxAlias');
    if (openCode != 0) return;

    final nativeVolume = (_clamp01(volume) * 1000).round().clamp(0, 1000);
    _send('setaudio $_sfxAlias volume to $nativeVolume');
    final playCode = _send('play $_sfxAlias from 0');
    if (playCode != 0) {
      _closeAlias(_sfxAlias);
    }
  }

  Future<void> stopAll() async {
    if (!_available) return;
    _closeAlias(_sfxAlias);
    _closeAlias(_musicAlias);
    _musicOpen = false;
    _musicPaused = false;
    _currentMusicAsset = null;
  }

  String? _resolveAssetFile(String asset) {
    final separator = Platform.pathSeparator;
    final relative = asset.replaceAll('/', separator);
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final bundled = File(
      '$executableDir${separator}data${separator}flutter_assets${separator}assets${separator}$relative',
    );
    if (bundled.existsSync()) return bundled.path;

    // Helpful for uncommon local/debug launch arrangements.
    final workingCopy = File('assets${separator}$relative').absolute;
    if (workingCopy.existsSync()) return workingCopy.path;
    return null;
  }

  int _send(String command) {
    final send = _mciSendString;
    final malloc = _malloc;
    final free = _free;
    if (!_available || send == null || malloc == null || free == null) return -1;

    final units = command.codeUnits;
    final raw = malloc((units.length + 1) * sizeOf<Uint16>());
    if (raw == nullptr) return -1;
    final pointer = raw.cast<Uint16>();
    final buffer = pointer.asTypedList(units.length + 1);
    buffer.setRange(0, units.length, units);
    buffer[units.length] = 0;
    try {
      return send(pointer, nullptr.cast<Uint16>(), 0, 0);
    } catch (_) {
      return -1;
    } finally {
      free(raw);
    }
  }

  void _closeAlias(String alias) {
    _send('stop $alias');
    _send('close $alias');
  }

  static String _escapePath(String value) => value.replaceAll('"', '');
  static double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();
}

typedef _MciSendStringNative = Uint32 Function(
  Pointer<Uint16> command,
  Pointer<Uint16> returnBuffer,
  Uint32 returnBufferLength,
  IntPtr callbackWindow,
);
typedef _MciSendStringDart = int Function(
  Pointer<Uint16> command,
  Pointer<Uint16> returnBuffer,
  int returnBufferLength,
  int callbackWindow,
);

typedef _MallocNative = Pointer<Void> Function(UintPtr size);
typedef _MallocDart = Pointer<Void> Function(int size);
typedef _FreeNative = Void Function(Pointer<Void> pointer);
typedef _FreeDart = void Function(Pointer<Void> pointer);
