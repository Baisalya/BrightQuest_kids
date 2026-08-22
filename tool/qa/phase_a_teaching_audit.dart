import 'dart:io';

import 'package:brightquest_kids/core/qa/teaching_correctness_audit.dart';

import 'qa_fixture_loader.dart';

void main(List<String> args) {
  final seeds = _readIntOption(args, '--seeds', fallback: 128);
  final repository = loadQaContentRepository();
  final report = TeachingCorrectnessAudit(
    generatedSeedsPerSkill: seeds,
    generatedSeedsPerClassFamily: seeds,
  ).auditRepository(repository);

  stdout.writeln('BrightQuest Phase A teaching correctness audit');
  stdout.writeln('Checks run: ${report.checksRun}');
  stdout.writeln('Blockers: ${report.count(TeachingAuditSeverity.blocker)}');
  stdout.writeln('High: ${report.count(TeachingAuditSeverity.high)}');
  stdout.writeln('Medium: ${report.count(TeachingAuditSeverity.medium)}');
  stdout.writeln('Low: ${report.count(TeachingAuditSeverity.low)}');

  for (final finding in report.findings) {
    stdout.writeln(finding);
  }

  if (report.hasReleaseBlockingFindings) {
    stderr.writeln(
      'FAIL: release-blocking teaching correctness findings were detected.',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('PASS: no release-blocking teaching correctness findings.');
}

int _readIntOption(
  List<String> args,
  String name, {
  required int fallback,
}) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return fallback;
  final value = int.tryParse(args[index + 1]);
  if (value == null || value < 1 || value > 5000) {
    throw ArgumentError('$name must be an integer from 1 to 5000.');
  }
  return value;
}
