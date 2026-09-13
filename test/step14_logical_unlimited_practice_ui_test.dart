import 'package:brightquest_kids/core/learning/diagnostic_engine.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/learning/class_skill_studio_screen.dart';
import 'package:brightquest_kids/features/learning/diagnostic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';
import 'support/content_fixture.dart';

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  testWidgets('Skill Studio labels safely generated extended practice',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = GameController()..setClass(3);

    await tester.pumpWidget(_host(controller, const ClassSkillStudioScreen()));
    await tester.pump();

    expect(find.text('Class 3 Skill Studio'), findsOneWidget);
    expect(find.text('Extended fresh practice'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed Discovery Check exposes a recent-aware re-check',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = buildContentRepository();
    final controller = GameController()..setClass(4);
    controller.startOrRestartDiagnostic(
      repository,
      now: DateTime.utc(2026, 8, 23, 10),
    );
    final firstIds = List<String>.from(controller.diagnosticProgress.itemIds);
    while (!controller.diagnosticProgress.completed) {
      final activity = const DiagnosticEngine().currentActivity(
        repository,
        controller.diagnosticProgress,
      );
      expect(activity, isNotNull);
      expect(
        controller.recordDiagnosticEvidence(
          repository: repository,
          correct: true,
          responseTimeMs: 1200,
          confidence: 0.8,
          now: DateTime.utc(2026, 8, 23, 10).add(
            Duration(minutes: controller.diagnosticProgress.currentIndex),
          ),
        ),
        isTrue,
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: buildTestScope(
          controller: controller,
          contentRepository: repository,
          child: const DiagnosticScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Starting trail ready'), findsOneWidget);
    final recheckButton =
        find.byKey(const ValueKey<String>('discovery_check_again'));
    expect(recheckButton, findsOneWidget);
    await tester.ensureVisible(recheckButton);
    await tester.pumpAndSettle();
    await tester.tap(recheckButton);
    await tester.pump();

    expect(controller.diagnosticProgress.completed, isFalse);
    expect(controller.diagnosticProgress.itemIds, hasLength(12));
    expect(controller.diagnosticProgress.itemIds, isNot(firstIds));
    expect(
      controller.diagnosticProgress.itemIds
          .toSet()
          .intersection(firstIds.toSet())
          .length,
      lessThan(12),
    );
    expect(find.textContaining('Question 1 of'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
