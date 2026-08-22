import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/qa/nursery_phonics_audit.dart';
import 'package:brightquest_kids/core/qa/teaching_correctness_audit.dart';

void main() {
  final raw = Map<String, dynamic>.from(
    jsonDecode(File('assets/content/nursery/pack_v1.json').readAsStringSync())
        as Map,
  );
  final pack = NurseryContentPack.fromJson(raw);
  const audit = NurseryPhonicsAudit(generatedSeedsPerSkill: 512);
  final report = audit.audit(pack);

  stdout.writeln('BrightQuest Phase B letters + sounds audit');
  stdout.writeln('Checks run: ${report.checksRun}');
  stdout.writeln('Blockers: ${report.count(TeachingAuditSeverity.blocker)}');
  stdout.writeln('High: ${report.count(TeachingAuditSeverity.high)}');
  stdout.writeln('Medium: ${report.count(TeachingAuditSeverity.medium)}');
  stdout.writeln('Low: ${report.count(TeachingAuditSeverity.low)}');
  for (final finding in report.findings) {
    stdout.writeln(finding);
  }
  if (report.hasReleaseBlockingFindings) {
    stderr.writeln('FAIL: Phase B letter/sound blockers detected.');
    exitCode = 1;
    return;
  }
  stdout.writeln('PASS: Phase B letter/sound audit is release-blocker free.');
}
