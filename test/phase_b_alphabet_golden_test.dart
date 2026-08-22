import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

const _goldensEnabled = bool.fromEnvironment(
  'BRIGHTQUEST_PHASE_B_GOLDENS',
  defaultValue: false,
);

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  testWidgets(
    'Phase B alphabet play board phone golden',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          GameController(),
          const NurseryLessonScreen(skillId: 'alpha_letter_sounds'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/phase_b/alphabet_sound_board_phone.png'),
      );
    },
    skip: !_goldensEnabled,
  );

  testWidgets(
    'Phase B alphabet play board Windows golden',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          GameController(),
          const NurseryLessonScreen(skillId: 'alpha_word_picture'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/phase_b/alphabet_picture_board_windows.png'),
      );
    },
    skip: !_goldensEnabled,
  );
}
