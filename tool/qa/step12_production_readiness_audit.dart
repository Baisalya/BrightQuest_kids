import 'dart:convert';
import 'dart:io';

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

bool _contains(String path, String marker) =>
    File(path).existsSync() && File(path).readAsStringSync().contains(marker);

void main() {
  final blockers = <String>[];
  final notes = <String>[];

  void requireFile(String path) {
    if (!File(path).existsSync()) blockers.add('Missing required file: $path');
  }

  for (final path in <String>[
    'lib/app/app_persistence_boundary.dart',
    'lib/app/brightquest_app.dart',
    'lib/core/session/game_session_store.dart',
    'lib/core/services/bright_audio_service.dart',
    'test/step12_production_hardening_test.dart',
    'docs/STEP12_PRODUCTION_HARDENING.md',
    'tool/qa/run_step12.ps1',
    'tool/qa/run_step12.sh',
  ]) {
    requireFile(path);
  }

  if (!_contains('lib/app/brightquest_app.dart', 'AppPersistenceBoundary')) {
    blockers.add('Root app is missing the persistence lifecycle boundary.');
  }
  if (!_contains('lib/app/app_persistence_boundary.dart', 'flushAll()')) {
    blockers.add('Lifecycle boundary does not flush both persistence streams.');
  }
  for (final marker in <String>[
    'didChangeAppLifecycleState',
    'didHaveMemoryPressure',
  ]) {
    if (!_contains('lib/app/app_persistence_boundary.dart', marker)) {
      blockers.add('Lifecycle durability marker missing: $marker');
    }
  }
  if (!_contains('lib/core/services/bright_audio_service.dart',
      'AppLifecycleState.hidden')) {
    blockers.add(
        'Audio lifecycle does not pause on hidden desktop/free-form state.');
  }
  if (!_contains('lib/app/brightquest_app.dart', 'media.textScaler.scale(1)') ||
      !_contains(
          'lib/widgets/bright_adaptive.dart', 'brightEffectiveTextScale')) {
    blockers.add('System accessibility text scale is not preserved.');
  }
  if (!_contains('lib/widgets/bright_adaptive.dart', '.clamp(0.9, 2.0)')) {
    blockers.add('Step 12 tested text-scale ceiling marker is missing.');
  }
  if (!_contains('lib/app/brightquest_app.dart', 'severelyShort')) {
    blockers.add('Very-short free-form navigation hardening is missing.');
  }

  if (_contains('lib/app/brightquest_app.dart', 'IndexedStack')) {
    blockers.add('IndexedStack restored offstage Windows AXTree churn.');
  }
  if (_contains(
      'windows/flutter/generated_plugin_registrant.cc', 'flutter_tts')) {
    blockers
        .add('Unsafe Windows flutter_tts plugin registration was restored.');
  }
  if (!_contains('lib/main.dart', 'BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY') ||
      !_contains('lib/main.dart', 'ExcludeSemantics')) {
    blockers.add('Windows semantics fail-closed canary contract is missing.');
  }
  if (!_contains('lib/core/services/bright_audio_service.dart',
          'WindowsSpeechBackend') ||
      !_contains('lib/core/services/bright_audio_service.dart',
          'WindowsMciAudioBackend')) {
    blockers.add('Crash-isolated Windows audio boundaries are missing.');
  }

  if (!_contains('lib/core/session/shared_preferences_game_session_store.dart',
      'brightquest.active_game_sessions.v1')) {
    blockers.add('Resumable-session storage key changed unexpectedly.');
  }
  if (!_contains('lib/core/session/game_session_models.dart', 'slotKey')) {
    blockers.add('Independent multi-mission session slot identity is missing.');
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  for (final dependency in <String>[
    'google_mobile_ads:',
    'firebase_analytics:',
    'http:',
    'dio:',
  ]) {
    if (RegExp('^\\s+$dependency', multiLine: true).hasMatch(pubspec)) {
      blockers.add('Unexpected online/ads dependency present: $dependency');
    }
  }
  for (final file in Directory('android')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('AndroidManifest.xml'))) {
    if (file
        .readAsStringSync()
        .contains('com.google.android.gms.permission.AD_ID')) {
      blockers.add('Advertising ID permission present in ${file.path}.');
    }
  }

  final nursery = _json('assets/content/nursery/pack_v1.json');
  final nurserySkills = (nursery['skills'] as List?)?.length ?? 0;
  final nurseryActivities = (nursery['activities'] as List?)?.length ?? 0;
  final nurseryCommercial =
      Map<String, dynamic>.from(nursery['commercial'] as Map? ?? const {});
  if (nurserySkills != 32 || nurseryActivities != 132) {
    blockers.add(
      'Nursery authored coverage drifted: $nurserySkills skills / $nurseryActivities activities.',
    );
  }
  if (nurseryCommercial['paidEligibility'] == true) {
    blockers.add('Nursery paid eligibility must remain fail-closed.');
  }
  if (!_contains('lib/features/nursery/nursery_home_screen.dart',
          'Pick a game world') ||
      !_contains('lib/features/nursery/nursery_play_board.dart', 'Play Now')) {
    blockers.add('Simplified Nursery child play path is missing.');
  }
  if (!_contains(
          'lib/features/nursery/nursery_home_screen.dart', 'cacheWidth: 128') ||
      !_contains('lib/features/nursery/nursery_home_screen.dart',
          'cacheHeight: 128')) {
    blockers.add('Nursery bounded thumbnail decode contract drifted.');
  }

  final classActivityCounts = <int, int>{};
  for (final classNumber in <int>[3, 4, 5]) {
    final pack = _json('assets/content/class_$classNumber/pack.json');
    classActivityCounts[classNumber] =
        (pack['activities'] as List?)?.length ?? 0;
    final review =
        Map<String, dynamic>.from(pack['review'] as Map? ?? const {});
    final commercial =
        Map<String, dynamic>.from(pack['commercial'] as Map? ?? const {});
    if (commercial['paidEligibility'] == true &&
        review['status'] != 'approved') {
      blockers.add(
        'Class $classNumber is paid-eligible without approved content review.',
      );
    }
  }

  notes.add('Qualified teacher/content review is external evidence.');
  notes.add('Supervised child usability/pilot evidence is external.');
  notes.add(
      'Google Play and Microsoft Store production purchase verification is external.');
  notes.add(
      'Android real-device and native Windows crash/accessibility soak are external.');
  notes.add(
      'Signed store artifacts, screenshots, privacy/store review and reviewer instructions are external.');

  stdout.writeln('BrightQuest Step 12 production-readiness audit');
  stdout.writeln('Class activity counts: $classActivityCounts');
  stdout.writeln(
      'Nursery coverage: $nurserySkills skills / $nurseryActivities activities');
  stdout.writeln('Static blockers: ${blockers.length}');

  if (blockers.isNotEmpty) {
    for (final blocker in blockers) {
      stderr.writeln('[BLOCKER] $blocker');
    }
    stderr.writeln('FAIL: Step 12 static production-hardening audit failed.');
    exitCode = 1;
    return;
  }

  stdout.writeln('PASS: Step 12 static production-hardening audit is clean.');
  stdout.writeln(
      'Commercial shipping eligibility remains BLOCKED by external gates:');
  for (final note in notes) {
    stdout.writeln('  - $note');
  }
}
