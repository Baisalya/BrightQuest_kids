import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 7+8 keeps one session flow and explicit Nursery stage', () {
    final stage = File('lib/core/models/learner_stage.dart').readAsStringSync();
    final snapshot =
        File('lib/core/models/progress_models.dart').readAsStringSync();
    final controller =
        File('lib/core/state/game_controller.dart').readAsStringSync();
    final shell = File('lib/app/brightquest_app.dart').readAsStringSync();
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final nursery = File('lib/features/nursery/nursery_home_screen.dart')
        .readAsStringSync();
    final summary = File('lib/widgets/bright_widgets.dart').readAsStringSync();
    final router =
        File('lib/features/games/game_router.dart').readAsStringSync();

    expect(stage, contains('enum LearnerStage'));
    expect(stage, contains('LearnerStage.nursery'));
    expect(stage, contains('LearnerStage.school'));

    expect(snapshot, contains("'learnerStage': learnerStage.name"));
    expect(snapshot, contains("learnerStageFromStorage(json['learnerStage'])"));
    expect(controller, contains('LearnerStage get learnerStage'));
    expect(controller, contains('void setLearnerStage(LearnerStage value)'));

    expect(shell, contains('controller.learnerStage == LearnerStage.nursery'));
    expect(shell, contains('NurseryHomeScreen('));
    expect(nursery, contains('this.rootMode = false'));
    expect(nursery, contains('final bool rootMode;'));
    expect(nursery, contains("Key('nursery_grown_up_area')"));

    expect(home, isNot(contains('NurseryHomeScreen')));
    expect(home, isNot(contains('open_nursery_garden')));

    expect(summary, contains('LearningSessionExit.continueToLevel'));
    expect(summary, contains("Key('mission_continue_button')"));
    expect(router, contains('push<LearningSessionExit>'));
    expect(router, contains('exit?.nextLevelId'));
    expect(router, contains('learningLevelById(nextLevelId)'));

    // Nursery is never encoded as a fake numeric class.
    expect(controller, isNot(contains('setClass(0)')));
    expect(controller, isNot(contains('selectedClass = 0')));
    expect(controller, contains('if (value == LearnerStage.nursery)'));
  });
}
