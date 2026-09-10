import 'dart:io';

/// Pure-Dart launcher for the Step 8 audit.
///
/// The audit implementation reaches Flutter-backed curriculum model types, so
/// it must execute under `flutter_tester`, not the standalone Dart VM. Keeping
/// this launcher pure Dart preserves the documented command while delegating
/// the real work to `flutter test`.
void main(List<String> args) {
  final seeds = _readSeeds(args);
  final flutterExecutable = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final result = Process.runSync(
    flutterExecutable,
    <String>[
      'test',
      'test/mission_step8_balance_quality_audit_test.dart',
      '--dart-define=STEP8_SEEDS=$seeds',
      '--reporter=expanded',
    ],
    runInShell: Platform.isWindows,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exitCode = result.exitCode;
}

int _readSeeds(List<String> args) {
  for (final arg in args) {
    if (!arg.startsWith('--seeds=')) continue;
    final value = int.tryParse(arg.substring('--seeds='.length));
    if (value != null && value > 0 && value <= 4096) return value;
  }
  return 64;
}
