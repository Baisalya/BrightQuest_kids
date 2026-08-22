import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/qa/nursery_math_world_audit.dart';
import 'package:brightquest_kids/core/qa/teaching_correctness_audit.dart';

void main() {
  final raw = Map<String, dynamic>.from(
    jsonDecode(File('assets/content/nursery/pack_v1.json').readAsStringSync())
        as Map,
  );
  final pack = NurseryContentPack.fromJson(raw);
  const audit = NurseryMathWorldAudit(generatedSeedsPerSkill: 256);
  final report = audit.audit(pack);

  stdout.writeln('BrightQuest Phase C Math + My World audit');
  stdout.writeln('Checks run: ${report.checksRun}');
  stdout.writeln('Blockers: ${report.count(TeachingAuditSeverity.blocker)}');
  stdout.writeln('High: ${report.count(TeachingAuditSeverity.high)}');
  stdout.writeln('Medium: ${report.count(TeachingAuditSeverity.medium)}');
  stdout.writeln('Low: ${report.count(TeachingAuditSeverity.low)}');
  for (final finding in report.findings) {
    stdout.writeln(finding);
  }

  if (report.hasReleaseBlockingFindings) {
    stderr
        .writeln('FAIL: Phase C Math/My World correctness findings detected.');
    exitCode = 1;
    return;
  }
  stdout.writeln('PASS: Phase C Math/My World audit is release-blocker free.');
}
