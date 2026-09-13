import 'dart:io';

class _Check {
  const _Check({
    required this.path,
    required this.label,
    required this.pattern,
    this.minimumMatches = 1,
  });

  final String path;
  final String label;
  final RegExp pattern;
  final int minimumMatches;
}

void main() {
  final root = Directory.current;
  var failures = 0;

  for (final check in _checks) {
    final file = File(
      '${root.path}${Platform.pathSeparator}'
      '${check.path.replaceAll('/', Platform.pathSeparator)}',
    );

    if (!file.existsSync()) {
      stderr.writeln('FAIL: ${check.label} — missing ${check.path}');
      failures += 1;
      continue;
    }

    final text = file.readAsStringSync();
    final matches = check.pattern.allMatches(text).length;
    if (matches < check.minimumMatches) {
      stderr.writeln(
        'FAIL: ${check.label} — found $matches, '
        'expected at least ${check.minimumMatches}',
      );
      failures += 1;
      continue;
    }

    stdout.writeln('PASS: ${check.label}');
  }

  if (failures > 0) {
    stderr.writeln('');
    stderr.writeln(
      'Phase 11+12 semantic verification failed: $failures contract(s).',
    );
    exitCode = 2;
    return;
  }

  stdout.writeln('');
  stdout.writeln('Phase 11+12 semantic verification PASSED.');
}

final _checks = <_Check>[
  _Check(
    path: 'lib/core/capabilities/learner_capability_boundary.dart',
    label: 'Capability registry exists',
    pattern: RegExp(r'class LearnerCapability'),
  ),
  _Check(
    path: 'lib/core/capabilities/learner_capability_boundary.dart',
    label: 'Supported School classes are 3/4/5',
    pattern: RegExp(r'supportedSchoolClasses\s*=\s*<int>\[3,\s*4,\s*5\]'),
  ),
  _Check(
    path: 'lib/core/capabilities/learner_capability_boundary.dart',
    label: 'Unshipped School classes are 1/2/6',
    pattern: RegExp(r'unavailableSchoolClasses\s*=\s*<int>\[1,\s*2,\s*6\]'),
  ),
  _Check(
    path: 'lib/app/learner_shell_policy.dart',
    label: 'Learner shell fails closed for unsupported classes',
    pattern: RegExp(r'requireSupportedSchoolClass\s*\(\s*classNumber\s*\)'),
  ),
  _Check(
    path: 'lib/core/state/game_controller.dart',
    label: 'GameController imports capability boundary',
    pattern: RegExp(r"capabilities/learner_capability_boundary\.dart"),
  ),
  _Check(
    path: 'lib/core/state/game_controller.dart',
    label: 'GameController guards unsupported School classes',
    pattern: RegExp(r'isSupportedSchoolClass\s*\('),
    minimumMatches: 4,
  ),
  _Check(
    path: 'lib/features/parent/parent_dashboard_screen.dart',
    label: 'Parent selectors use central supported-class registry',
    pattern: RegExp(
      r'items\s*:\s*LearnerCapabilityBoundary\s*\.\s*'
      r'supportedSchoolClasses',
    ),
    minimumMatches: 2,
  ),
  _Check(
    path: 'lib/features/parent/class_pack_screen.dart',
    label: 'Class Packs use central supported-class registry',
    pattern: RegExp(
      r'for\s*\(\s*final\s+classNumber\s+in\s+'
      r'LearnerCapabilityBoundary\.supportedSchoolClasses\s*\)',
    ),
  ),
  _Check(
    path: 'lib/core/entitlements/entitlement_service.dart',
    label: 'Purchases reject unsupported School classes',
    pattern: RegExp(r'requireSupportedSchoolClass\s*\(\s*classNumber\s*\)'),
  ),
  _Check(
    path: 'lib/core/content/content_repository.dart',
    label: 'Development pack locks use capability boundary',
    pattern: RegExp(
      r'\.where\s*\(\s*'
      r'LearnerCapabilityBoundary\.isSupportedSchoolClass\s*\)',
    ),
  ),
  _Check(
    path: 'lib/core/models/progress_models.dart',
    label: 'Persisted class restore uses migration normalizer',
    pattern: RegExp(
      r'selectedClass\s*:\s*_supportedClassFromStorage\s*\(',
    ),
  ),
  _Check(
    path: 'lib/core/models/progress_models.dart',
    label: 'Persisted unsupported class falls back through capability boundary',
    pattern: RegExp(
      r'_supportedClassFromStorage[\s\S]*?'
      r'LearnerCapabilityBoundary\.isSupportedSchoolClass',
    ),
  ),
  _Check(
    path: 'lib/widgets/bright_adaptive.dart',
    label: '48dp global minimum target policy',
    pattern: RegExp(r'minimumTapTarget\s*:\s*48'),
  ),
  _Check(
    path: 'lib/widgets/bright_adaptive.dart',
    label: 'Large-text stacking helper exists',
    pattern: RegExp(r'brightShouldStackForReadability\s*\('),
  ),
  _Check(
    path: 'lib/widgets/bright_adaptive.dart',
    label: 'Readable grid-width helper exists',
    pattern: RegExp(r'brightReadableMinTileWidth\s*\('),
  ),
  _Check(
    path: 'lib/widgets/bright_design_system.dart',
    label: 'Adaptive grid uses readable minimum width',
    pattern: RegExp(r'readableMinChildWidth'),
  ),
  _Check(
    path: 'lib/widgets/bright_widgets.dart',
    label: 'Header has semantic Back label',
    pattern: RegExp(r"label\s*:\s*'Back'"),
  ),
  _Check(
    path: 'lib/widgets/bright_widgets.dart',
    label: 'Header uses large-text-aware stacking',
    pattern: RegExp(r'brightShouldStackForReadability\s*\('),
  ),
  _Check(
    path: 'lib/widgets/learning_accessibility_widgets.dart',
    label: 'Narration controls contain 48dp targets',
    pattern: RegExp(r'(minWidth|width)\s*:\s*48'),
    minimumMatches: 4,
  ),
  _Check(
    path: 'lib/app/brightquest_app.dart',
    label: 'Learner navigation contains 48dp minimum target',
    pattern: RegExp(r'(minHeight|height)\s*:\s*48'),
    minimumMatches: 2,
  ),
  _Check(
    path: 'lib/features/home/home_screen.dart',
    label: 'Today hero stacks for readable large text',
    pattern: RegExp(r'brightShouldStackForReadability\s*\('),
  ),
  _Check(
    path: 'lib/features/progress/progress_screen.dart',
    label: 'Journey hero stacks for readable large text',
    pattern: RegExp(r'brightShouldStackForReadability\s*\('),
  ),
  _Check(
    path: 'lib/features/profile/profile_screen.dart',
    label: 'My Space readable stack boundaries applied',
    pattern: RegExp(r'brightShouldStackForReadability\s*\('),
    minimumMatches: 2,
  ),
  _Check(
    path: 'lib/features/games/rewards_room_screen.dart',
    label: 'Rewards readable stack boundaries applied',
    pattern: RegExp(r'brightShouldStackForReadability\s*\('),
    minimumMatches: 2,
  ),
];
