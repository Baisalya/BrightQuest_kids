import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_duplicate_detector.dart';
import 'package:brightquest_kids/core/content/content_repository.dart';

Map<String, dynamic> _readJson(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

void main(List<String> args) {
  final repository = ContentRepository.fromJsonPacks(
    curriculumJson: _readJson('assets/content/curriculum_map.json'),
    schemaJson: _readJson('assets/content/content_schema_v1.json'),
    packJson: <Map<String, dynamic>>[
      _readJson('assets/content/class_3/pack.json'),
      _readJson('assets/content/class_4/pack.json'),
      _readJson('assets/content/class_5/pack.json'),
    ],
  );

  final groups = findDuplicateContentGroups(repository.allActivities);
  stdout.writeln('BrightQuest Kids — exact content duplicate report');
  stdout.writeln('Groups: ${groups.length}');
  for (final group in groups) {
    stdout.writeln(
      '  - ${group.activities.map((activity) => '${activity.id} [C${activity.classNumber}]').join(' <-> ')}',
    );
  }
  stdout.writeln(
    'Duplicate IDs are fatal in validate_content.dart; repeated prompt/answer content is reported here for reviewer disposition.',
  );
}
