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
      final payload = activity['payload'];
      if (payload is Map && payload['masteryEligible'] == false) continue;
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

  final nursery = _json('assets/content/nursery/pack_v1.json');
  final nurseryCommercial =
      Map<String, dynamic>.from(nursery['commercial'] as Map? ?? const {});
  final nurseryGates =
      Map<String, dynamic>.from(nursery['releaseGates'] as Map? ?? const {});
  final nurseryReview =
      Map<String, dynamic>.from(nursery['review'] as Map? ?? const {});
  final nurseryActivities = (nursery['activities'] as List?) ?? const [];
  final nurserySkills = (nursery['skills'] as List?) ?? const [];
  final nurseryLetters = (nursery['letterAssociations'] as List?) ?? const [];
  final nurseryLetterAssets = <String>{};
  for (final rawLetter in nurseryLetters.whereType<Map>()) {
    final examples = (rawLetter['examples'] as List?) ?? const [];
    if (examples.length < 8) {
      failures.add(
        'Nursery letter ${rawLetter['uppercase']} has fewer than eight discovery examples.',
      );
    }
    for (final rawExample in examples.whereType<Map>()) {
      final assetPath = rawExample['assetPath'];
      if (assetPath is! String ||
          !assetPath.startsWith('assets/nursery/letter_cards/') ||
          !File(assetPath).existsSync()) {
        failures.add(
          'Nursery letter asset is missing or invalid: $assetPath.',
        );
      } else if (!nurseryLetterAssets.add(assetPath)) {
        failures.add('Nursery letter asset path is duplicated: $assetPath.');
      }
    }
  }
  if (nurseryLetterAssets.length < 200) {
    failures
        .add('Nursery must bundle at least 200 unique A–Z discovery cards.');
  }
  if (!_contains('pubspec.yaml', 'assets/nursery/letter_cards/')) {
    failures.add(
        'Nursery letter-card asset directory is not registered in pubspec.yaml.');
  }
  if (nurseryCommercial['permanentOneTimePriceInr'] != 299) {
    failures.add('Nursery planned permanent price drifted from ₹299.');
  }
  if (nurseryCommercial['paidEligibility'] == true) {
    failures.add(
        'Nursery paid eligibility must remain fail-closed in this source.');
  }
  if (nurseryReview['status'] == 'approved') {
    failures.add('Nursery pack was marked approved without external evidence.');
  }
  if (nurseryGates.values.any((value) => value == true)) {
    failures.add('Nursery external release gate was pre-approved in source.');
  }
  if (nurserySkills.length != 32 || nurseryActivities.length != 132) {
    failures.add(
        'Nursery authored coverage must remain 32 skills / 132 activities.');
  }
  if (nurseryActivities.whereType<Map>().any(
        (activity) =>
            activity['interaction'] == 'trace' &&
            activity['masteryEligible'] == true,
      )) {
    failures.add('Nursery tracing may not be mastery eligible.');
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
    '  - $missingCompetencyCount competencies still need constructed-response or otherwise authored scorable evidence',
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
  stdout.writeln('Nursery commercial shipping eligibility: BLOCKED');
  stdout.writeln(
      '  - teacher review, supervised child pilot, production billing, and Android/Windows qualification remain unrecorded');
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
