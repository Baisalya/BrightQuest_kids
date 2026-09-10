import 'package:brightquest_kids/core/qa/mission_content_quality_audit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/qa/qa_fixture_loader.dart';

void main() {
  test('Step 8 large deterministic mission balance/content quality audit', () {
    const rawSeeds = String.fromEnvironment(
      'STEP8_SEEDS',
      defaultValue: '128',
    );
    final parsedSeeds = int.tryParse(rawSeeds);
    final seeds = parsedSeeds != null && parsedSeeds > 0 && parsedSeeds <= 4096
        ? parsedSeeds
        : 128;

    final repository = loadQaContentRepository();
    final report = MissionContentQualityAudit(
      simulationSeedsPerLevel: seeds,
    ).audit(repository);

    // Keep this output intentionally human-readable: the wrapper and CI scripts
    // surface it directly when a release-blocking quality gate fails.
    // ignore: avoid_print
    print('BrightQuest Step 8 mission balance + content quality audit');
    // ignore: avoid_print
    print('Learning World levels audited: ${report.levelsAudited}');
    // ignore: avoid_print
    print(
      'Generated activities audited: ${report.generatedActivitiesAudited}',
    );
    // ignore: avoid_print
    print('Deterministic mission runs simulated: ${report.simulationRuns}');
    // ignore: avoid_print
    print('Checks run: ${report.checksRun}');
    // ignore: avoid_print
    print('Findings: ${report.findings.length}');
    // ignore: avoid_print
    print(
      '  blockers=${report.count(MissionQualitySeverity.blocker)} '
      'high=${report.count(MissionQualitySeverity.high)} '
      'medium=${report.count(MissionQualitySeverity.medium)} '
      'low=${report.count(MissionQualitySeverity.low)}',
    );

    final weakest = report.snapshots.toList()
      ..sort((a, b) => a.candidateCount.compareTo(b.candidateCount));
    // ignore: avoid_print
    print('Lowest exact-tier candidate capacities:');
    for (final item in weakest.take(8)) {
      // ignore: avoid_print
      print(
        '  ${item.levelId}: ${item.candidateCount} candidates '
        '(${item.authoredCount} authored + ${item.generatedCount} generated), '
        '${item.topicCount} topics, '
        '${item.uniquePlanSignatures} simulated run signatures',
      );
    }

    for (final finding in report.findings) {
      // ignore: avoid_print
      print(finding);
    }

    expect(report.levelsAudited, 72);
    expect(report.generatedActivitiesAudited, greaterThanOrEqualTo(864));
    expect(report.simulationRuns, 72 * seeds);
    expect(
      report.releaseBlockingFindings,
      isEmpty,
      reason: report.releaseBlockingFindings.join('\n'),
    );
  });
}
