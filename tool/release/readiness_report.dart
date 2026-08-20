import 'dart:convert';
import 'dart:io';

bool _contains(String path, String text) =>
    File(path).existsSync() && File(path).readAsStringSync().contains(text);

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

void main() {
  final failures = <String>[];
  var missingCompetencyCount = 0;
  var unreviewedActivityCount = 0;
  var unreviewedBlueprintCount = 0;
  final curriculum = _json('assets/content/curriculum_map.json');
  final curriculumClasses = (curriculum['classes'] as List?) ?? const [];
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
  if (!_contains('lib/main.dart', 'BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY')) {
    failures.add('Windows semantics canary switch is missing.');
  }
  if (_contains('lib/app/brightquest_app.dart', 'IndexedStack')) {
    failures.add('Eager shell IndexedStack restored Windows AXTree churn.');
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
    final samples = (commercial['freeSampleActivityIds'] as List?) ?? const [];
    final activities = (pack['activities'] as List?) ?? const [];
    unreviewedActivityCount += activities
        .whereType<Map>()
        .where(
          (activity) => activity['status'] != 'approved',
        )
        .length;
    final activityById = <String, Map<String, dynamic>>{
      for (final raw in activities.whereType<Map>())
        if (raw['id'] is String)
          raw['id'] as String: Map<String, dynamic>.from(raw),
    };
    final sampleGames = <String>{};
    for (final sampleId in samples.whereType<String>()) {
      final activity = activityById[sampleId];
      if (activity != null && activity['gameId'] is String) {
        sampleGames.add(activity['gameId'] as String);
      }
    }
    if (samples.length != 8 || sampleGames.length != 8) {
      failures.add(
        'Class $classNumber must expose exactly one free demo in each of 8 games.',
      );
    }
    final review =
        Map<String, dynamic>.from(pack['review'] as Map? ?? const {});
    final paidEligible = commercial['paidEligibility'] == true;
    final approved = review['status'] == 'approved';
    if (paidEligible && !approved) {
      failures
          .add('Class $classNumber is paid-eligible without approved review.');
    }

    final coveredCompetencies = <String>{};
    for (final activity in activities.whereType<Map>()) {
      if (activity['competencyId'] is String) {
        coveredCompetencies.add(activity['competencyId'] as String);
      }
      final related = activity['relatedCompetencyIds'];
      if (related is List) {
        coveredCompetencies.addAll(related.whereType<String>());
      }
    }
    final classContract = curriculumClasses.whereType<Map>().firstWhere(
          (value) => value['classNumber'] == classNumber,
        );
    final competencies = (classContract['competencies'] as List?) ?? const [];
    missingCompetencyCount += competencies
        .whereType<Map>()
        .where(
          (value) => !coveredCompetencies.contains(value['id']),
        )
        .length;

    final blueprints = _json(
      'assets/content/class_$classNumber/learning_blueprints.json',
    );
    unreviewedBlueprintCount +=
        ((blueprints['blueprints'] as List?) ?? const [])
            .whereType<Map>()
            .where(
              (value) => (value['review'] as Map?)?['status'] != 'approved',
            )
            .length;
  }

  if (failures.isNotEmpty) {
    stderr.writeln('BrightQuest release safety checks FAILED:');
    for (final failure in failures) stderr.writeln('  - $failure');
    exitCode = 1;
    return;
  }

  stdout.writeln('BrightQuest static release-safety checks: PASS');
  stdout.writeln('Commercial shipping eligibility: BLOCKED');
  stdout.writeln(
    '  - $missingCompetencyCount competencies still need authored scorable activities',
  );
  stdout.writeln(
    '  - $unreviewedActivityCount activities and $unreviewedBlueprintCount blueprints still need qualified review',
  );
  stdout.writeln(
    '  - production billing remains fail-closed until Google Play and Microsoft Store adapters are configured',
  );
  stdout.writeln(
    '  - Windows semantics remain off by default pending canary qualification',
  );
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
