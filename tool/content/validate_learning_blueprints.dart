import 'dart:convert';
import 'dart:io';

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

Never _fail(String message) {
  stderr.writeln('Learning blueprint validation FAILED: $message');
  exit(1);
}

void main() {
  final curriculum = _json('assets/content/curriculum_map.json');
  final classes = (curriculum['classes'] as List).whereType<Map>().toList();
  var total = 0;
  for (final rawClass in classes) {
    final classMap = Map<String, dynamic>.from(rawClass);
    final classNumber = classMap['classNumber'] as int;
    final expected = (classMap['competencies'] as List)
        .whereType<Map>()
        .map((value) => value['id'] as String)
        .toSet();
    final blueprint = _json(
      'assets/content/class_$classNumber/learning_blueprints.json',
    );
    if (blueprint['classNumber'] != classNumber) {
      _fail('Class $classNumber blueprint has the wrong class boundary.');
    }
    final rows = (blueprint['blueprints'] as List).whereType<Map>().toList();
    final ids = rows.map((value) => value['competencyId'] as String).toList();
    if (ids.toSet().length != ids.length) {
      _fail('Class $classNumber contains duplicate blueprint competency IDs.');
    }
    if (ids.toSet().difference(expected).isNotEmpty ||
        expected.difference(ids.toSet()).isNotEmpty) {
      _fail('Class $classNumber blueprint coverage does not match curriculum.');
    }
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);
      for (final field in <String>[
        'objective',
        'teach',
        'workedExample',
        'masteryTransfer',
        'reviewPrompt',
        'narrationText',
        'locale',
      ]) {
        final value = row[field];
        if (value == null || (value is String && value.trim().isEmpty)) {
          _fail('${row['competencyId']} is missing $field.');
        }
      }
      final guided = Map<String, dynamic>.from(row['guidedTry'] as Map);
      if ((guided['hintLevel1'] as String).trim().isEmpty ||
          (guided['hintLevel2'] as String).trim().isEmpty) {
        _fail('${row['competencyId']} must have a two-level hint ladder.');
      }
      final review = Map<String, dynamic>.from(row['review'] as Map);
      if (review['status'] == 'approved' && review['reviewedAt'] == null) {
        _fail('${row['competencyId']} cannot be approved without review time.');
      }
      total += 1;
    }
  }

  final transcripts = _json('assets/content/shared/audio_transcripts.json');
  final cues = Map<String, dynamic>.from(transcripts['cues'] as Map);
  for (final cue in <String>[
    'levelStart',
    'hint',
    'correct',
    'wrong',
    'unlock',
    'complete',
  ]) {
    if ((cues[cue] as String?)?.trim().isEmpty ?? true) {
      _fail('Missing visible transcript for audio cue $cue.');
    }
  }
  stdout.writeln(
    'Learning blueprint validation: PASS ($total competency blueprints, ${cues.length} audio cue transcripts).',
  );
  stdout.writeln(
    'Educational review gate: PENDING. Blueprint status is technical draft, not teacher approval.',
  );
}
