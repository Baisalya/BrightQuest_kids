import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

String _text(Object? value) => value is String ? value.trim() : '';

String _narrationText(Object? value) {
  if (value is! Map) return '';
  return _text(value['text']);
}

void main() {
  final failures = <String>[];
  var localizedRecords = 0;
  var narratedRecords = 0;
  var letterAssetBytes = 0;
  var largestLetterAssetBytes = 0;

  for (final classNumber in <int>[3, 4, 5]) {
    final packPath = 'assets/content/class_$classNumber/pack.json';
    final pack = _json(packPath);
    if (_text(pack['locale']) != 'en-IN') {
      failures.add('$packPath must remain authored in en-IN.');
    }
    for (final raw
        in (pack['activities'] as List? ?? const []).whereType<Map>()) {
      final activity = Map<String, dynamic>.from(raw);
      final id = _text(activity['id']);
      if (_text(activity['locale']) != 'en-IN') {
        failures.add('$id has an unsupported/mixed locale.');
      }
      localizedRecords += 1;
      for (final key in <String>['prompt', 'explanation']) {
        if (_text(activity[key]).isEmpty) {
          failures.add('$id is missing child-visible $key text.');
        }
      }
      if (_narrationText(activity['narration']).isEmpty) {
        failures.add('$id is missing child-visible/spoken narration.text.');
      }
      narratedRecords += 1;
    }

    final blueprints = _json(
      'assets/content/class_$classNumber/learning_blueprints.json',
    );
    for (final raw
        in (blueprints['blueprints'] as List? ?? const []).whereType<Map>()) {
      final blueprint = Map<String, dynamic>.from(raw);
      final id = _text(blueprint['id']).isNotEmpty
          ? _text(blueprint['id'])
          : _text(blueprint['competencyId']);
      if (_text(blueprint['locale']) != 'en-IN') {
        failures.add('$id has an unsupported/mixed blueprint locale.');
      }
      if (_text(blueprint['narrationText']).isEmpty) {
        failures.add('$id is missing blueprint narrationText.');
      }
      localizedRecords += 1;
    }
  }

  final nursery = _json('assets/content/nursery/pack_v1.json');
  if (_text(nursery['locale']) != 'en-IN') {
    failures.add('Nursery v1 must remain authored in en-IN.');
  }
  for (final raw in (nursery['skills'] as List? ?? const []).whereType<Map>()) {
    final skill = Map<String, dynamic>.from(raw);
    final id = _text(skill['id']);
    for (final key in <String>['title', 'objective', 'explanation']) {
      if (_text(skill[key]).isEmpty) {
        failures.add('$id is missing $key.');
      }
    }
    final worked = Map<String, dynamic>.from(
      skill['workedExample'] as Map? ?? const {},
    );
    if (_text(worked['headline']).isEmpty || _text(worked['caption']).isEmpty) {
      failures.add('$id is missing a visible worked-example headline/caption.');
    }
  }
  for (final raw
      in (nursery['activities'] as List? ?? const []).whereType<Map>()) {
    final activity = Map<String, dynamic>.from(raw);
    final id = _text(activity['id']);
    for (final key in <String>[
      'prompt',
      'narration',
      'hint',
      'successFeedback',
      'wrongFeedback',
    ]) {
      if (_text(activity[key]).isEmpty) {
        failures.add('$id is missing $key.');
      }
    }
    narratedRecords += 1;
  }

  final commercial = Map<String, dynamic>.from(
    nursery['commercial'] as Map? ?? const {},
  );
  if (commercial['paidEligibility'] == true) {
    failures.add('Nursery paidEligibility must remain fail-closed.');
  }
  final gates = Map<String, dynamic>.from(
    nursery['releaseGates'] as Map? ?? const {},
  );
  if (gates.values.any((value) => value == true)) {
    failures
        .add('An external Nursery release gate was pre-approved in source.');
  }

  final sourceFiles = Directory('lib/features/nursery')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);
  final nurserySource =
      sourceFiles.map((file) => file.readAsStringSync()).join('\n');
  for (final forbidden in <String>[
    'Timer.periodic(',
    '.repeat(',
    'AnimationController.repeat(',
  ]) {
    if (nurserySource.contains(forbidden)) {
      failures.add('Nursery contains repeating/scheduled motion: $forbidden');
    }
  }
  final loweredNurserySource = nurserySource.toLowerCase();
  for (final placeholder in <String>['coming soon', 'todo:']) {
    if (loweredNurserySource.contains(placeholder)) {
      failures.add(
          'Child-facing Nursery source contains placeholder text: $placeholder');
    }
  }

  final homeSource =
      File('lib/features/nursery/nursery_home_screen.dart').readAsStringSync();
  if (!homeSource.contains('cacheWidth: 128') ||
      !homeSource.contains('cacheHeight: 128')) {
    failures.add(
      'A-Z Letter Garden must decode thumbnails at 128px instead of full 512px cards.',
    );
  }

  final letterAssets = Directory('assets/nursery/letter_cards')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList(growable: false);
  if (letterAssets.length != 208) {
    failures.add('Expected exactly 208 bundled Nursery letter-card PNGs.');
  }
  for (final file in letterAssets) {
    final bytes = file.readAsBytesSync();
    letterAssetBytes += bytes.length;
    if (bytes.length > largestLetterAssetBytes) {
      largestLetterAssetBytes = bytes.length;
    }
    if (bytes.length > 128 * 1024) {
      failures.add('${file.path} exceeds the 128 KiB per-card asset budget.');
    }
    if (bytes.length < 24 ||
        bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4E ||
        bytes[3] != 0x47) {
      failures.add('${file.path} is not a valid PNG card.');
      continue;
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final width = data.getUint32(16, Endian.big);
    final height = data.getUint32(20, Endian.big);
    if (width > 512 || height > 512) {
      failures.add('${file.path} exceeds the 512x512 source-art budget.');
    }
  }
  if (letterAssetBytes > 6 * 1024 * 1024) {
    failures
        .add('Nursery letter-card bundle exceeds the 6 MiB source-art budget.');
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  for (final dependency in <String>[
    'http:',
    'dio:',
    'firebase_analytics:',
    'google_mobile_ads:',
  ]) {
    if (RegExp('^\\s+$dependency', multiLine: true).hasMatch(pubspec)) {
      failures.add('Unexpected online/analytics dependency found: $dependency');
    }
  }

  for (final requiredPath in <String>[
    'test/phase_d_release_candidate_test.dart',
    'test/phase_d_accessibility_polish_test.dart',
    'docs/PHASE_D_POLISH_RELEASE_QA.md',
    'docs/PHASE_D_RELEASE_CANDIDATE_CHECKLIST.md',
    'tool/qa/run_phase_d.ps1',
  ]) {
    if (!File(requiredPath).existsSync()) {
      failures.add('Phase D deliverable is missing: $requiredPath');
    }
  }

  stdout.writeln('BrightQuest Phase D release-candidate audit');
  stdout.writeln('Localized records checked: $localizedRecords');
  stdout.writeln('Narrated/feedback records checked: $narratedRecords');
  stdout.writeln('Nursery letter-card assets: ${letterAssets.length}');
  stdout.writeln(
    'Letter-card bundle bytes: $letterAssetBytes (largest: $largestLetterAssetBytes)',
  );
  stdout.writeln('Findings: ${failures.length}');

  if (failures.isNotEmpty) {
    for (final failure in failures) {
      stderr.writeln('[BLOCKER] $failure');
    }
    stderr.writeln('FAIL: Phase D technical release-candidate audit failed.');
    exitCode = 1;
    return;
  }

  stdout.writeln('PASS: Phase D technical release-candidate audit is clean.');
  stdout.writeln(
    'NOTE: teacher review, supervised child pilot, store verification, privacy review, and real-device/native Windows qualification remain external gates.',
  );
}
