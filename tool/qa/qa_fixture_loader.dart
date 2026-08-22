import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_repository.dart';

Map<String, dynamic> readQaJson(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

ContentRepository loadQaContentRepository() => ContentRepository.fromJsonPacks(
      curriculumJson: readQaJson('assets/content/curriculum_map.json'),
      schemaJson: readQaJson('assets/content/content_schema_v1.json'),
      packJson: <Map<String, dynamic>>[
        readQaJson('assets/content/class_3/pack.json'),
        readQaJson('assets/content/class_4/pack.json'),
        readQaJson('assets/content/class_5/pack.json'),
      ],
      blueprintJson: <Map<String, dynamic>>[
        readQaJson('assets/content/class_3/learning_blueprints.json'),
        readQaJson('assets/content/class_4/learning_blueprints.json'),
        readQaJson('assets/content/class_5/learning_blueprints.json'),
      ],
      nurseryJson: readQaJson('assets/content/nursery/pack_v1.json'),
    );
