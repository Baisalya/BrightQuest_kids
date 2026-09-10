import 'dart:io';

import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:brightquest_kids/core/session/game_session_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_screen.dart';
import 'package:brightquest_kids/widgets/bright_adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  group('Step 12 production hardening', () {
    test('system accessibility text scale is never suppressed by app setting', () {
      expect(
        brightEffectiveTextScale(systemTextScale: 1, appTextScale: 1.3),
        1.3,
      );
      expect(
        brightEffectiveTextScale(systemTextScale: 1.5, appTextScale: 1),
        1.5,
      );
      expect(
        brightEffectiveTextScale(systemTextScale: 2, appTextScale: .9),
        2,
      );
      expect(
        brightEffectiveTextScale(systemTextScale: 3, appTextScale: 1.3),
        2,
      );
    });

    test('qualification viewport matrix keeps minimum interaction targets', () {
      const sizes = <Size>[
        Size(360, 640),
        Size(640, 360),
        Size(700, 800),
        Size(800, 480),
        Size(1024, 600),
        Size(1280, 520),
        Size(1440, 900),
        Size(1920, 1080),
      ];
      for (final size in sizes) {
        final metrics = BrightLayoutMetrics.fromSize(size);
        expect(metrics.minimumTapTarget, greaterThanOrEqualTo(44));
        expect(metrics.contentMaxWidth, greaterThan(0));
      }
    });

    test('flushAll persists progress and multiple resumable session slots',
        () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      controller.setHighContrastEnabled(true);
      final levels = levelsForClass(controller.selectedClass);
      final first = levels.first;
      final second = levels.firstWhere((level) => level.gameId != first.gameId);

      controller.beginOrResumeGameSession(
        gameId: first.gameId,
        classNumber: first.classNumber,
        difficulty: first.difficulty,
        maxScore: 4,
        learningLevel: first,
      );
      controller.beginOrResumeGameSession(
        gameId: second.gameId,
        classNumber: second.classNumber,
        difficulty: second.difficulty,
        maxScore: 5,
        learningLevel: second,
      );
      await controller.flushAll();

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      expect(restored.highContrastEnabled, isTrue);
      expect(restored.resumableGameSessions, hasLength(2));
      expect(
        restored.gameSessionFor(
          gameId: first.gameId,
          classNumber: first.classNumber,
          learningLevelId: first.id,
        ),
        isNotNull,
      );
      expect(
        restored.gameSessionFor(
          gameId: second.gameId,
          classNumber: second.classNumber,
          learningLevelId: second.id,
        ),
        isNotNull,
      );
    });

    testWidgets('shell survives phone landscape and very short free-form windows',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const sizes = <Size>[
        Size(360, 640),
        Size(640, 360),
        Size(800, 480),
        Size(1024, 600),
        Size(1280, 520),
        Size(1440, 900),
      ];

      for (final size in sizes) {
        final controller = GameController()
          ..setTextScale(1.3)
          ..setHighContrastEnabled(true)
          ..setReducedMotionEnabled(true);
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(buildTestApp(controller));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Home'), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Unexpected shell exception at $size');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Nursery hub remains usable on compact and free-form surfaces',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const sizes = <Size>[Size(360, 640), Size(800, 480), Size(1024, 600)];
      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            home: buildTestScope(
              controller: GameController()..setReducedMotionEnabled(true),
              child: const NurseryHomeScreen(),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Choose a world'), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Unexpected Nursery exception at $size');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    test('root lifecycle durability and Windows crash isolation are wired', () {
      final app = File('lib/app/brightquest_app.dart').readAsStringSync();
      final boundary =
          File('lib/app/app_persistence_boundary.dart').readAsStringSync();
      final audio =
          File('lib/core/services/bright_audio_service.dart').readAsStringSync();
      final main = File('lib/main.dart').readAsStringSync();
      final registrant = File('windows/flutter/generated_plugin_registrant.cc')
          .readAsStringSync();

      expect(app, contains('AppPersistenceBoundary'));
      expect(app, contains('media.textScaler.scale(1)'));
      expect(boundary, contains('didChangeAppLifecycleState'));
      expect(boundary, contains('didHaveMemoryPressure'));
      expect(boundary, contains('controller.flushAll()'));
      expect(audio, contains('AppLifecycleState.hidden'));
      expect(main, contains('BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY'));
      expect(main, contains('ExcludeSemantics'));
      expect(app, isNot(contains('IndexedStack')));
      expect(registrant.toLowerCase(), isNot(contains('flutter_tts')));
    });

    test('Step 12 release runner and audit remain fail-closed', () {
      final audit =
          File('tool/qa/step12_production_readiness_audit.dart').readAsStringSync();
      final runner = File('tool/qa/run_step12.ps1').readAsStringSync();
      final docs = File('docs/STEP12_PRODUCTION_HARDENING.md').readAsStringSync();
      expect(audit, contains('Commercial shipping eligibility remains BLOCKED'));
      expect(runner, contains('flutter test'));
      expect(runner, contains('flutter analyze'));
      expect(docs, contains('real-device'));
      expect(docs, contains('external'));
    });
  });
}
