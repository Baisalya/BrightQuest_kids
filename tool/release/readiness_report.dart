import 'dart:convert';
import 'dart:io';

bool _contains(String path, String text) =>
    File(path).existsSync() && File(path).readAsStringSync().contains(text);

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

void main() {
  final failures = <String>[];
  final androidManifests = Directory('android')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('AndroidManifest.xml'));
  for (final file in androidManifests) {
    final source = file.readAsStringSync();
    if (source.contains('com.google.android.gms.permission.AD_ID')) {
      failures.add('AD_ID permission present in ${file.path}.');
    }
  }

  final registrant = 'windows/flutter/generated_plugin_registrant.cc';
  if (_contains(registrant, 'flutter_tts')) {
    failures.add('Windows flutter_tts registration was restored.');
  }
  if (!_contains('lib/main.dart', 'ExcludeSemantics')) {
    failures.add('Windows semantics crash-isolation marker is missing.');
  }
  if (!_contains('lib/core/services/bright_audio_service.dart',
      'WindowsMciAudioBackend')) {
    failures.add('Crash-isolated Windows narration/audio boundary is missing.');
  }
  if (!_contains(
    'lib/core/services/bright_audio_service.dart',
    'WindowsSpeechBackend',
  )) {
    failures.add('Crash-isolated Windows speech boundary is missing.');
  }
  if (!File('PRIVACY_POLICY.md').existsSync()) {
    failures.add('PRIVACY_POLICY.md is missing.');
  }

  for (final classNumber in <int>[3, 4, 5]) {
    final pack = _json('assets/content/class_$classNumber/pack.json');
    final commercial = Map<String, dynamic>.from(pack['commercial'] as Map);
    final samples = (commercial['freeSampleUnitIds'] as List?) ?? const [];
    if (samples.isEmpty) failures.add('Class $classNumber has no free sample.');
    final review =
        Map<String, dynamic>.from(pack['review'] as Map? ?? const {});
    final paidEligible = commercial['paidEligibility'] == true;
    final approved = review['status'] == 'approved';
    if (paidEligible && !approved) {
      failures
          .add('Class $classNumber is paid-eligible without approved review.');
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('BrightQuest release safety checks FAILED:');
    for (final failure in failures) stderr.writeln('  - $failure');
    exitCode = 1;
    return;
  }

  stdout.writeln('BrightQuest static release-safety checks: PASS');
  stdout.writeln('External release gates still PENDING:');
  stdout.writeln('  - qualified teacher/content sign-off');
  stdout.writeln('  - supervised child usability sessions and evidence pilot');
  stdout.writeln(
      '  - production Google Play / Microsoft Store purchase verification');
  stdout.writeln('  - privacy/store listing review');
  stdout.writeln(
      '  - Android real-device and native Windows crash/accessibility soak');
  stdout.writeln(
    '  - signed store artifacts, screenshots and support/reviewer instructions',
  );
}
