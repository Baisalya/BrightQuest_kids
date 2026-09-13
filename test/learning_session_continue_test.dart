import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/session/learning_session_exit.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/widgets/bright_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets('first clear exposes Continue and returns the exact next level',
      (tester) async {
    final controller = GameController();
    await controller.load();

    final level = levelsForClass(controller.selectedClass).first;
    final subjectLevels =
        levelsForSubject(level.classNumber, level.subject).toList();
    final currentIndex =
        subjectLevels.indexWhere((candidate) => candidate.id == level.id);
    expect(currentIndex, greaterThanOrEqualTo(0));
    expect(currentIndex + 1, lessThan(subjectLevels.length));
    final expectedNext = subjectLevels[currentIndex + 1];

    LearningSessionExit? exit;

    await tester.pumpWidget(
      buildTestScope(
        controller: controller,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const Key('open_result'),
                  onPressed: () async {
                    exit =
                        await Navigator.of(context).push<LearningSessionExit>(
                      MaterialPageRoute<LearningSessionExit>(
                        builder: (_) => Scaffold(
                          body: SingleChildScrollView(
                            child: MissionSummaryCard(
                              learningLevel: level,
                              score: 5,
                              maxScore: 5,
                              reward: MissionReward(
                                firstCompletion: true,
                                coinsAwarded: 30,
                                xpAwarded: 40,
                                starsAwarded: 2,
                                levelId: level.id,
                                levelCompleted: true,
                                levelStars: 2,
                                levelStarsAwarded: 2,
                                unlockedNextLevel: true,
                              ),
                              onReplay: () {},
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open result'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_result')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mission_continue_button')), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Replay Mission'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mission_continue_button')));
    await tester.pumpAndSettle();

    expect(exit?.action, LearningSessionExitAction.continueNext);
    expect(exit?.nextLevelId, expectedNext.id);
  });

  testWidgets('a cleared terminal mission returns to its World',
      (tester) async {
    final controller = GameController();
    await controller.load();

    final firstLevel = levelsForClass(controller.selectedClass).first;
    final level =
        levelsForSubject(firstLevel.classNumber, firstLevel.subject).last;
    LearningSessionExit? exit;

    await tester.pumpWidget(
      buildTestScope(
        controller: controller,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                key: const Key('open_terminal_result'),
                onPressed: () async {
                  exit = await Navigator.of(context).push<LearningSessionExit>(
                    MaterialPageRoute<LearningSessionExit>(
                      builder: (_) => Scaffold(
                        body: SingleChildScrollView(
                          child: MissionSummaryCard(
                            learningLevel: level,
                            score: 5,
                            maxScore: 5,
                            reward: MissionReward(
                              firstCompletion: true,
                              coinsAwarded: 30,
                              xpAwarded: 40,
                              starsAwarded: 2,
                              levelId: level.id,
                              levelCompleted: true,
                              levelStars: 2,
                              levelStarsAwarded: 2,
                            ),
                            onReplay: () {},
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open terminal result'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_terminal_result')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mission_continue_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mission_continue_button')));
    await tester.pumpAndSettle();

    expect(exit?.action, LearningSessionExitAction.backToWorld);
    expect(exit?.nextLevelId, isNull);
  });
}
