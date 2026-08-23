import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/core/theme/app_theme.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_screen.dart';
import 'package:brightquest_kids/features/nursery/nursery_interactions.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      ),
    );

Widget _host(GameController controller, Widget child) => MaterialApp(
      theme: AppTheme.light(
        highContrast: controller.highContrastEnabled,
        dyslexiaFriendlySpacing: controller.dyslexiaFriendlySpacing,
      ),
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(controller.textScale),
          ),
          child: appChild ?? const SizedBox.shrink(),
        );
      },
      home: buildTestScope(controller: controller, child: child),
    );

GameController _accessibilityController() {
  final controller = GameController();
  controller.setTextScale(1.3);
  controller.setHighContrastEnabled(true);
  controller.setReducedMotionEnabled(true);
  controller.setDyslexiaFriendlySpacing(true);
  controller.setCaptionsEnabled(true);
  return controller;
}

void main() {
  testWidgets(
      'Nursery remains usable at max text size, high contrast and reduced motion',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = <Size>[
      Size(360, 640),
      Size(700, 800),
      Size(1024, 768),
      Size(1440, 900),
    ];
    const skills = <String>[
      'alpha_word_picture',
      'math_count_6_10',
      'knowledge_animals',
      'thinking_patterns',
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      final controller = _accessibilityController();
      await tester.pumpWidget(
        _host(controller, const NurseryHomeScreen()),
      );
      await tester.pump();
      expect(find.text('Nursery Learning Garden'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Nursery hub at $size');

      for (final skillId in skills) {
        await tester.pumpWidget(
          _host(
            controller,
            NurseryLessonScreen(skillId: skillId),
          ),
        );
        await tester.pump();
        expect(find.text('Let’s play!'), findsOneWidget);
        expect(find.text('Next'), findsNothing);
        expect(
          tester.takeException(),
          isNull,
          reason: '$skillId at $size with accessibility settings',
        );
      }
    }
  });

  testWidgets('answer choices expose stable spoken semantics at max text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final activity = _pack().activityById('nursery.math_count_0_5.g1')!;
    final controller = _accessibilityController();
    Object? submitted;

    await tester.pumpWidget(
      _host(
        controller,
        Scaffold(
          body: SingleChildScrollView(
            child: NurseryActivityInteraction(
              activity: activity,
              enabled: true,
              reducedMotion: true,
              onSubmitted: (value) => submitted = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Answer 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Answer 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Answer 3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Answer 2'));
    await tester.pump();
    expect(submitted, '2');
    expect(tester.takeException(), isNull);
  });
}
