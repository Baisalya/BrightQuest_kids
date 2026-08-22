import 'dart:io';

import 'package:brightquest_kids/core/qa/class_curriculum_hardening_audit.dart';

import 'qa_fixture_loader.dart';

void main() {
  final repository = loadQaContentRepository();
  final report = const ClassCurriculumHardeningAudit().audit(repository);

  stdout.writeln('BrightQuest Phase E Classes 3–5 curriculum hardening audit');
  stdout.writeln('Checks run: ${report.checksRun}');
  stdout.writeln('Findings: ${report.findings.length}');
  stdout.writeln(
    'Constructed-response gaps kept fail-closed: ${report.constructedResponseGapIds.length}',
  );
  for (final id in report.constructedResponseGapIds.toList()..sort()) {
    stdout.writeln('  - $id');
  }
  for (final finding in report.findings) {
    stdout.writeln(finding);
  }

  if (report.releaseBlockingFindings.isNotEmpty) {
    stderr.writeln(
        'FAIL: Phase E curriculum hardening audit found release-blocking issues.');
    exitCode = 1;
    return;
  }

  stdout
      .writeln('PASS: Phase E technical curriculum hardening audit is clean.');
  stdout.writeln(
    'NOTE: This is automated technical hardening, not qualified-teacher approval.',
  );
}
