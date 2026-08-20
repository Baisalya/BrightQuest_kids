import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WindowsSpeechVoice {
  const WindowsSpeechVoice({
    required this.name,
    required this.locale,
    required this.gender,
  });

  final String name;
  final String locale;
  final String gender;

  bool get isFemale => gender.toLowerCase() == 'female';
}

/// Crash-isolated Windows narration using the OS System.Speech engine.
///
/// Speech runs in a hidden Windows PowerShell child process. No TTS plugin or
/// speech DLL is loaded into Flutter, so a speech-engine failure cannot bring
/// down the learning application.
class WindowsSpeechBackend {
  Process? _speechProcess;
  String? _powerShellPath;
  bool _available = false;
  List<WindowsSpeechVoice> _voices = const <WindowsSpeechVoice>[];

  bool get available => _available;
  List<WindowsSpeechVoice> get voices =>
      List<WindowsSpeechVoice>.unmodifiable(_voices);
  WindowsSpeechVoice? get defaultVoice {
    if (_voices.isEmpty) return null;
    for (final voice in _voices) {
      if (voice.isFemale && voice.locale.toLowerCase().startsWith('en')) {
        return voice;
      }
    }
    for (final voice in _voices) {
      if (voice.isFemale) return voice;
    }
    return _voices.first;
  }

  Future<void> initialize() async {
    if (!Platform.isWindows || _available) return;
    final windowsDirectory = Platform.environment['WINDIR'] ?? r'C:\Windows';
    final candidate = File(
      '$windowsDirectory${Platform.pathSeparator}System32${Platform.pathSeparator}'
      'WindowsPowerShell${Platform.pathSeparator}v1.0${Platform.pathSeparator}powershell.exe',
    );
    if (!candidate.existsSync()) return;

    try {
      final result = await Process.run(
        candidate.path,
        <String>[
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-Sta',
          '-WindowStyle',
          'Hidden',
          '-EncodedCommand',
          encodePowerShellCommand(_availabilityScript),
        ],
        runInShell: false,
      ).timeout(const Duration(seconds: 6));
      if (result.exitCode == 0) {
        final output =
            result.stdout.toString().trim().replaceFirst('\ufeff', '');
        final decoded = jsonDecode(output);
        final values = decoded is List<dynamic> ? decoded : <dynamic>[decoded];
        _voices = values
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (voice) => WindowsSpeechVoice(
                name: '${voice['name'] ?? ''}'.trim(),
                locale: '${voice['locale'] ?? ''}'.trim(),
                gender: '${voice['gender'] ?? ''}'.trim(),
              ),
            )
            .where((voice) => voice.name.isNotEmpty)
            .toList(growable: false);
        if (_voices.isEmpty) return;
        _powerShellPath = candidate.path;
        _available = true;
      }
    } catch (_) {
      _available = false;
    }
  }

  Future<void> speak(
    String text, {
    required double volume,
    required double rate,
    String? voiceName,
  }) async {
    final executable = _powerShellPath;
    if (!_available || executable == null || text.trim().isEmpty) return;

    await stop();
    final encodedText = base64Encode(utf8.encode(text));
    final selectedVoice = voiceName?.trim().isNotEmpty == true
        ? voiceName!.trim()
        : defaultVoice?.name;
    final encodedVoice = base64Encode(utf8.encode(selectedVoice ?? ''));
    final nativeVolume = (volume.clamp(0.0, 1.0) * 100).round();
    final nativeRate = systemRateFor(rate);
    final script = '''
\$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
\$text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encodedText'))
\$voiceName = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encodedVoice'))
\$voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  \$voice.SetOutputToDefaultAudioDevice()
  if (\$voiceName.Length -gt 0) { \$voice.SelectVoice(\$voiceName) }
  \$voice.Volume = $nativeVolume
  \$voice.Rate = $nativeRate
  \$voice.Speak(\$text)
} finally {
  \$voice.Dispose()
}
''';

    Process? process;
    try {
      process = await Process.start(
        executable,
        <String>[
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-Sta',
          '-WindowStyle',
          'Hidden',
          '-EncodedCommand',
          encodePowerShellCommand(script),
        ],
        mode: ProcessStartMode.normal,
        runInShell: false,
      );
      _speechProcess = process;
      await process.exitCode.timeout(const Duration(seconds: 45));
    } on TimeoutException {
      process?.kill();
    } catch (_) {
      // Narration is optional; callers keep the learning flow running.
    } finally {
      if (identical(_speechProcess, process)) _speechProcess = null;
    }
  }

  Future<void> stop() async {
    final process = _speechProcess;
    _speechProcess = null;
    if (process == null) return;
    try {
      process.kill();
      await process.exitCode.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  static int systemRateFor(double value) {
    final normalized = (value.clamp(0.30, 0.62) - 0.30) / 0.32;
    return (-3 + (normalized * 5)).round().clamp(-3, 2);
  }

  /// PowerShell's `-EncodedCommand` requires UTF-16LE bytes.
  static String encodePowerShellCommand(String command) {
    final bytes = <int>[];
    for (final unit in command.codeUnits) {
      bytes
        ..add(unit & 0xff)
        ..add((unit >> 8) & 0xff);
    }
    return base64Encode(bytes);
  }

  static const String _availabilityScript = '''
\$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
\$voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  \$voices = @(\$voice.GetInstalledVoices() | Where-Object { \$_.Enabled } | ForEach-Object {
    [PSCustomObject]@{
      name = \$_.VoiceInfo.Name
      locale = \$_.VoiceInfo.Culture.Name
      gender = \$_.VoiceInfo.Gender.ToString()
    }
  })
  if (\$voices.Count -lt 1) { exit 2 }
  [Console]::OutputEncoding = [Text.Encoding]::UTF8
  ConvertTo-Json -InputObject \$voices -Compress
} finally {
  \$voice.Dispose()
}
''';
}
