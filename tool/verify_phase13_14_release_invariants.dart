import 'dart:io';

class _Check {
  const _Check(this.path, this.label, this.pattern);

  final String path;
  final String label;
  final RegExp pattern;
}

void main() {
  var failures = 0;
  for (final check in _checks) {
    final file = File(check.path.replaceAll('/', Platform.pathSeparator));
    if (!file.existsSync()) {
      stderr.writeln('FAIL: ${check.label} — missing ${check.path}');
      failures += 1;
      continue;
    }

    final source = file.readAsStringSync();
    final matches = check.pattern.allMatches(source).length;
    if (matches < 1) {
      stderr.writeln(
        'FAIL: ${check.label} — no matching contract found',
      );
      failures += 1;
    } else {
      stdout.writeln('PASS: ${check.label}');
    }
  }

  if (failures != 0) {
    stderr.writeln('');
    stderr.writeln('Phase 13+14 invariant verification failed: $failures');
    exitCode = 2;
    return;
  }

  stdout.writeln('');
  stdout.writeln('Phase 13+14 invariant verification PASSED.');
}

final _checks = <_Check>[
  _Check(
    'lib/core/persistence/shared_preferences_progress_store.dart',
    'Current progress key is v6',
    RegExp(r'brightquest\.player_snapshot\.v6'),
  ),
  _Check(
    'lib/core/persistence/shared_preferences_progress_store.dart',
    'Legacy v5 fallback retained',
    RegExp(r'brightquest\.player_snapshot\.v5'),
  ),
  _Check(
    'lib/core/persistence/shared_preferences_progress_store.dart',
    'Legacy v3 fallback retained',
    RegExp(r'brightquest\.player_snapshot\.v3'),
  ),
  _Check(
    'lib/core/persistence/shared_preferences_progress_store.dart',
    'Legacy v2 fallback retained',
    RegExp(r'brightquest\.player_snapshot\.v2'),
  ),
  _Check(
    'lib/core/session/shared_preferences_game_session_store.dart',
    'Session store remains schema v1',
    RegExp(r"'schemaVersion'\s*:\s*1"),
  ),
  _Check(
    'lib/core/models/progress_models.dart',
    'Snapshot restores as schema v6',
    RegExp(r'schemaVersion\s*:\s*6'),
  ),
  _Check(
    'lib/core/models/progress_models.dart',
    'Persisted School class normalizer remains active',
    RegExp(r'_supportedClassFromStorage\s*\('),
  ),
  _Check(
    'lib/core/models/progress_models.dart',
    'Profile map key is authoritative identity',
    RegExp(r'profile\.id\s*=\s*profileId'),
  ),
  _Check(
    'lib/core/models/progress_models.dart',
    'Entitlement cache class identity must match',
    RegExp(r'entitlement\.classNumber\s*==\s*classNumber'),
  ),
  _Check(
    'lib/core/models/progress_models.dart',
    'Entitlement cache stays inside shipped class boundary',
    RegExp(
      r'LearnerCapabilityBoundary\s*\.\s*isSupportedSchoolClass'
      r'\s*\(\s*classNumber\s*\)',
    ),
  ),
  _Check(
    'lib/core/entitlements/entitlement_service.dart',
    'Local entitlement cache never seeds verified access',
    RegExp(
      r'void\s+observeLocalCache\s*\([^)]*\)\s*\{\s*\}',
      multiLine: true,
    ),
  ),
  _Check(
    'lib/core/state/game_controller.dart',
    'Controller discards invalid restored sessions',
    RegExp(r'_discardInvalidSessionCheckpoints\s*\('),
  ),
  _Check(
    'lib/core/capabilities/learner_capability_boundary.dart',
    'Supported School classes remain 3/4/5',
    RegExp(r'supportedSchoolClasses\s*=\s*<int>\[3,\s*4,\s*5\]'),
  ),
  _Check(
    'lib/core/models/learner_stage.dart',
    'Legacy learner stage defaults to School',
    RegExp(r'return\s+LearnerStage\.school'),
  ),
];
