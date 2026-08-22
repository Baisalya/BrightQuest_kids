import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_repository.dart';

Map<String, dynamic> readProjectJson(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

ContentRepository buildContentRepository({
  DevelopmentPackAccessPolicy accessPolicy =
      DevelopmentPackAccessPolicy.disabled,
  bool Function(int classNumber)? verifiedAccessResolver,
}) =>
    ContentRepository.fromJsonPacks(
      curriculumJson: readProjectJson('assets/content/curriculum_map.json'),
      schemaJson: readProjectJson('assets/content/content_schema_v1.json'),
      packJson: <Map<String, dynamic>>[
        readProjectJson('assets/content/class_3/pack.json'),
        readProjectJson('assets/content/class_4/pack.json'),
        readProjectJson('assets/content/class_5/pack.json'),
      ],
      blueprintJson: <Map<String, dynamic>>[
        readProjectJson('assets/content/class_3/learning_blueprints.json'),
        readProjectJson('assets/content/class_4/learning_blueprints.json'),
        readProjectJson('assets/content/class_5/learning_blueprints.json'),
      ],
      nurseryJson: readProjectJson('assets/content/nursery/pack_v1.json'),
      accessPolicy: accessPolicy,
      verifiedAccessResolver: verifiedAccessResolver,
    );
