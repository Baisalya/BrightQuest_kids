import 'dart:io';

import 'package:brightquest_kids/core/qa/teaching_correctness_audit.dart';

import 'qa_fixture_loader.dart';

void main(List<String> args) {
  final repository = loadQaContentRepository();
  final nursery = repository.nurseryPack;
  if (nursery == null) {
    stderr.writeln('FAIL: bundled Nursery pack is unavailable.');
    exitCode = 1;
    return;
  }
  final seeds = _seeds(args);
  final report = TeachingCorrectnessAudit(
    generatedSeedsPerSkill: seeds,
  ).auditNurseryPack(
    nursery,
    includeSkill: (skill) => skill.domainId == 'alphabet',
  );

  stdout.writeln('Nursery letter + phonics simulator');
  stdout.writeln('Seeds per alphabet skill: $seeds');
  stdout.writeln('Checks run: ${report.checksRun}');
  for (final finding in report.findings) {
    stdout.writeln(finding);
  }
  if (report.hasReleaseBlockingFindings) {
    stderr.writeln('FAIL: letter/phonics correctness findings detected.');
    exitCode = 1;
  } else {
    stdout
        .writeln('PASS: letter/phonics simulations are release-blocker free.');
  }
}

int _seeds(List<String> args) {
  final index = args.indexOf('--seeds');
  if (index < 0 || index + 1 >= args.length) return 256;
  final value = int.tryParse(args[index + 1]);
  if (value == null || value < 1 || value > 5000) {
    throw ArgumentError('--seeds must be an integer from 1 to 5000.');
  }
  return value;
}
