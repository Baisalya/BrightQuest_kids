import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/accessibility/learning_audio_director.dart';
import 'package:brightquest_kids/core/accessibility/learning_audio_models.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_resolver.dart';
import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/core/learning/mission_session_engine.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/learning/lesson_flow_screen.dart';
import 'package:brightquest_kids/widgets/bright_adaptive.dart';
import 'package:brightquest_kids/widgets/bright_widgets.dart';
import 'package:brightquest_kids/widgets/learning_accessibility_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';
import 'support/content_fixture.dart';

void main() {
  group('Step 11 learning narration director', () {
    test('interactive lesson cues use authored narration and authored choices',
        () {
      final repository = buildContentRepository();
      final flow = const LessonEngine().buildForCompetency(
        repository: repository,
        classNumber: 3,
        competencyId: 'c3_math_equal_sharing_division',
      );
      final session = const MissionSessionEngine().build(flow);
      final guided = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.guidedTry,
      );
      final activity = repository.activityById(guided.lessonStep.activityId!)!;
      final spec = const GameplayActivityResolver().resolve(activity);

      final cue = const LearningAudioDirector().forLessonStep(
        sessionStep: guided,
        activity: activity,
        activitySpec: spec,
      );

      expect(cue.kind, LearningNarrationKind.activityPrompt);
      expect(cue.spokenText, activity.narrationText);
      expect(cue.visibleText, activity.prompt);
      expect(
          cue.choices.toList(), spec.choiceValues.whereType<Object>().toList());
      expect(cue.autoEligible, isTrue);
      expect(cue.delivery, LearningNarrationDelivery.prompt);
    });

    test('teaching cues keep goal, concept and worked reasoning roles distinct',
        () {
      final repository = buildContentRepository();
      final flow = const LessonEngine().buildForCompetency(
        repository: repository,
        classNumber: 4,
        competencyId: 'c4_math_fraction_models_equiv',
      );
      final session = const MissionSessionEngine().build(flow);
      final objective = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.objective,
      );
      final explanation = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.explanation,
      );
      final worked = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.workedExample,
      );
      const director = LearningAudioDirector();

      final objectiveCue = director.forLessonStep(sessionStep: objective);
      final explanationCue = director.forLessonStep(sessionStep: explanation);
      final workedCue = director.forLessonStep(sessionStep: worked);

      expect(objectiveCue.kind, LearningNarrationKind.missionGoal);
      expect(explanationCue.kind, LearningNarrationKind.conceptTeaching);
      expect(workedCue.kind, LearningNarrationKind.workedExample);
      expect(objectiveCue.spokenText, objective.lessonStep.body);
      expect(explanationCue.spokenText, explanation.lessonStep.body);
      expect(workedCue.spokenText, worked.lessonStep.body);
      expect(objectiveCue.delivery, LearningNarrationDelivery.statement);
      expect(explanationCue.delivery, LearningNarrationDelivery.statement);
      expect(workedCue.delivery, LearningNarrationDelivery.statement);
    });

    test('teaching cues repeat only the authored visible lesson text', () {
      final repository = buildContentRepository();
      final flow = const LessonEngine().buildForCompetency(
        repository: repository,
        classNumber: 4,
        competencyId: 'c4_math_fraction_models_equiv',
      );
      final session = const MissionSessionEngine().build(flow);
      final objective = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.objective,
      );

      final cue = const LearningAudioDirector().forLessonStep(
        sessionStep: objective,
      );

      expect(cue.kind, LearningNarrationKind.missionGoal);
      expect(cue.visibleText, objective.lessonStep.body);
      expect(cue.spokenText, objective.lessonStep.body);
      expect(cue.choices, isEmpty);
    });

    test('main-game prompt narration stays manual to avoid racing game intro',
        () {
      final cue = const LearningAudioDirector().forGamePrompt(
        gameId: 'math_market',
        prompt: '24 ÷ 6 = ?',
        choices: <Object>[3, 4, 5, 6],
      );

      expect(cue.kind, LearningNarrationKind.gamePrompt);
      expect(cue.visibleText, '24 ÷ 6 = ?');
      expect(cue.spokenText, '24 ÷ 6 = ?');
      expect(cue.autoEligible, isFalse);
      expect(cue.delivery, LearningNarrationDelivery.prompt);
      expect(cue.semanticLabel, contains('Choices: 3, 4, 5, 6'));
    });

    test('independent narration never auto-includes authored hints', () {
      final repository = buildContentRepository();
      final flow = const LessonEngine().buildForCompetency(
        repository: repository,
        classNumber: 3,
        competencyId: 'c3_math_equal_sharing_division',
      );
      final session = const MissionSessionEngine().build(flow);
      final independent = session.steps.firstWhere(
        (step) =>
            step.lessonStep.kind == LessonStepKind.independentPractice,
      );
      final activity =
          repository.activityById(independent.lessonStep.activityId!)!;
      final spec = const GameplayActivityResolver().resolve(activity);
      final cue = const LearningAudioDirector().forLessonStep(
        sessionStep: independent,
        activity: activity,
        activitySpec: spec,
      );

      expect(cue.kind, LearningNarrationKind.activityPrompt);
      expect(cue.spokenText, isNotEmpty);
      for (final hint in independent.lessonStep.hints) {
        expect(cue.spokenText, isNot(contains(hint)));
      }
      for (final hint in activity.hints) {
        expect(cue.spokenText, isNot(contains(hint.text)));
      }
    });

    test('hint narration is manual-only and uses only the revealed authored hint',
        () {
      final cue = const LearningAudioDirector().forHint(
        ownerId: 'lesson-1:0',
        text: 'Count equal groups one at a time.',
      );

      expect(cue.kind, LearningNarrationKind.hint);
      expect(cue.spokenText, 'Count equal groups one at a time.');
      expect(cue.visibleText, cue.spokenText);
      expect(cue.autoEligible, isFalse);
      expect(cue.delivery, LearningNarrationDelivery.statement);
    });

    test('Nursery statement cues use the same narration role model', () {
      final cue = const LearningAudioDirector().forNurseryStatement(
        ownerId: 'teaching:alpha_uppercase:2',
        kind: LearningNarrationKind.workedExample,
        visibleText: 'A is for apple.',
        spokenText: 'A is for apple.',
      );

      expect(cue.kind, LearningNarrationKind.workedExample);
      expect(cue.visibleText, 'A is for apple.');
      expect(cue.spokenText, 'A is for apple.');
      expect(cue.autoEligible, isTrue);
      expect(cue.delivery, LearningNarrationDelivery.statement);
    });

    test('Nursery prompt cues keep choices separate from prompt text', () {
      final cue = const LearningAudioDirector().forNurseryPrompt(
        ownerId: 'activity:alpha-choice',
        visibleText: 'Find A.',
        spokenText: 'Find A.',
        choices: <Object>['A', 'B', 'C'],
      );

      expect(cue.kind, LearningNarrationKind.activityPrompt);
      expect(cue.spokenText, 'Find A.');
      expect(cue.choices.toList(), <Object>['A', 'B', 'C']);
      expect(cue.delivery, LearningNarrationDelivery.prompt);
      expect(cue.semanticLabel, contains('Choices: A, B, C'));
    });

    test('automatic continuity normalizes adjacent duplicate narration', () {
      const policy = LearningNarrationSequencePolicy();
      const first = LearningNarrationCue(
        id: 'lesson:first',
        kind: LearningNarrationKind.conceptTeaching,
        visibleText: 'Use equal groups.',
        spokenText: 'Use   equal groups.',
      );
      const second = LearningNarrationCue(
        id: 'lesson:second',
        kind: LearningNarrationKind.workedExample,
        visibleText: 'USE EQUAL GROUPS.',
        spokenText: 'USE EQUAL GROUPS.',
      );

      expect(first.automaticRepeatKey, 'use equal groups.');
      expect(
        policy.isAutomaticRepeat(
          cue: second,
          previousFingerprint: first.automaticRepeatKey,
        ),
        isTrue,
      );
    });

    test('automatic narration policy fails closed unless every gate is open',
        () {
      const policy = LearningAudioAccessibilityPolicy();
      const cue = LearningNarrationCue(
        id: 'lesson:test',
        kind: LearningNarrationKind.conceptTeaching,
        visibleText: 'Visible lesson',
        spokenText: 'Visible lesson',
      );

      expect(
        policy.shouldAutoNarrate(
          cue: cue,
          soundEnabled: true,
          voiceEnabled: true,
          voiceAvailable: true,
          autoNarrationEnabled: true,
        ),
        isTrue,
      );
      for (final flags in <List<bool>>[
        <bool>[false, true, true, true],
        <bool>[true, false, true, true],
        <bool>[true, true, false, true],
        <bool>[true, true, true, false],
      ]) {
        expect(
          policy.shouldAutoNarrate(
            cue: cue,
            soundEnabled: flags[0],
            voiceEnabled: flags[1],
            voiceAvailable: flags[2],
            autoNarrationEnabled: flags[3],
          ),
          isFalse,
        );
      }
      const visibleOnlyCue = LearningNarrationCue(
        id: 'lesson:visible-only',
        kind: LearningNarrationKind.conceptTeaching,
        visibleText: 'Visible fallback',
        spokenText: '',
      );
      expect(
        policy.shouldAutoNarrate(
          cue: visibleOnlyCue,
          soundEnabled: true,
          voiceEnabled: true,
          voiceAvailable: true,
          autoNarrationEnabled: true,
        ),
        isFalse,
      );
    });

    test('reading focus keeps text visible even if captions are turned off',
        () {
      const policy = LearningAudioAccessibilityPolicy();
      expect(
        policy.shouldShowTranscript(
          captionsEnabled: false,
          readingFocusEnabled: true,
        ),
        isTrue,
      );
      expect(
        policy.shouldShowTranscript(
          captionsEnabled: false,
          readingFocusEnabled: false,
        ),
        isFalse,
      );
    });
  });

  group('Step 11 visible narration UI', () {
    const cue = LearningNarrationCue(
      id: 'game:test',
      kind: LearningNarrationKind.gamePrompt,
      visibleText: 'Which answer fits?',
      spokenText: 'Which answer fits?',
      choices: <Object>['A', 'B', 'C'],
      autoEligible: false,
    );

    testWidgets('captions expose prompt and choices without requiring audio',
        (tester) async {
      final controller = GameController();
      controller.setCaptionsEnabled(true);
      controller.setReadingFocusEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: buildTestScope(
            controller: controller,
            child: const Scaffold(
              body: LearningNarrationBar(cue: cue),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('NARRATION TRANSCRIPT'), findsOneWidget);
      expect(find.text('Which answer fits?'), findsOneWidget);
      expect(find.text('Choices: A • B • C'), findsOneWidget);
      expect(
          find.byKey(const Key('learning_read_aloud_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reading focus restores visible text when captions are off',
        (tester) async {
      final controller = GameController();
      controller.setCaptionsEnabled(false);
      controller.setReadingFocusEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: buildTestScope(
            controller: controller,
            child: const Scaffold(
              body: LearningNarrationBar(cue: cue),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('READING FOCUS'), findsOneWidget);
      expect(find.text('Which answer fits?'), findsOneWidget);
      expect(find.text('Choices: A • B • C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'caption-off mode keeps manual read control without duplication',
        (tester) async {
      final controller = GameController();
      controller.setCaptionsEnabled(false);
      controller.setReadingFocusEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: buildTestScope(
            controller: controller,
            child: const Scaffold(
              body: LearningNarrationBar(cue: cue),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('NARRATION TRANSCRIPT'), findsNothing);
      expect(find.text('READING FOCUS'), findsNothing);
      expect(find.text('Read this learning prompt aloud'), findsOneWidget);
      expect(
          find.byKey(const Key('learning_read_aloud_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'interactive captions do not push short-wide response controls off-screen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = GameController();
      controller.setSoundEnabled(false);
      controller.setCaptionsEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: buildTestScope(
            controller: controller,
            child: const LessonFlowScreen.forCompetency(
              classNumber: 3,
              competencyId: 'c3_eng_short_composition',
              title: 'Short composition',
            ),
          ),
        ),
      );
      await tester.pump();

      for (var step = 0; step < 3; step += 1) {
        await tester.tap(find.text('Continue'));
        await tester.pump();
      }

      const answer = 'One morning, I heard a soft bark near the gate.';
      expect(find.text('NARRATION TRANSCRIPT'), findsOneWidget);
      expect(tester.getCenter(find.text(answer)).dy, lessThan(760));

      await tester.tap(find.text(answer));
      await tester.pump();
      await tester.tap(find.text('Check my answer'));
      await tester.pump();

      expect(find.textContaining('Yes.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GameScaffold keeps narration UI responsive across viewports',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in <Size>[
        const Size(360, 640),
        const Size(900, 760),
        const Size(1440, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        final controller = GameController();
        controller.setCaptionsEnabled(true);

        await tester.pumpWidget(
          MaterialApp(
            home: buildTestScope(
              controller: controller,
              child: const BrightLayoutHost(
                child: GameScaffold(
                  title: 'Math Market',
                  subtitle: 'Narration layout contract',
                  color: Color(0xFF3E88F7),
                  voicePrompt: '24 ÷ 6 = ?',
                  voiceChoices: <Object>[3, 4, 5, 6],
                  child: SingleChildScrollView(
                    child: SizedBox(height: 320),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('game_read_aloud_button')), findsOneWidget);
        expect(find.text('NARRATION TRANSCRIPT'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'viewport $size');
      }
    });
  });

  group('Step 11 static safety contract', () {
    test('all Class 3-5 authored activities keep visible narration text', () {
      final repository = buildContentRepository();
      for (final classNumber in <int>[3, 4, 5]) {
        for (final activity in repository.activitiesForClass(classNumber)) {
          expect(activity.prompt.trim(), isNotEmpty, reason: activity.id);
          expect(activity.narrationText.trim(), isNotEmpty,
              reason: activity.id);
          expect(activity.locale, 'en-IN', reason: activity.id);
        }
      }
    });

    test('audio transcript catalog covers speech as well as sound effects', () {
      final json = Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/shared/audio_transcripts.json')
              .readAsStringSync(),
        ) as Map,
      );
      final cues = Map<String, dynamic>.from(json['cues'] as Map);
      for (final cue in <String>[
        'levelStart',
        'hint',
        'correct',
        'wrong',
        'complete',
        'gameIntro',
        'lessonNarration',
        'promptNarration',
        'voiceFeedback',
      ]) {
        expect('${cues[cue] ?? ''}'.trim(), isNotEmpty, reason: cue);
      }
    });

    test('Windows narration and semantics crash-isolation remain untouched',
        () {
      final registrant = File('windows/flutter/generated_plugin_registrant.cc')
          .readAsStringSync();
      final main = File('lib/main.dart').readAsStringSync();
      final shell = File('lib/app/brightquest_app.dart').readAsStringSync();
      final speech = File('lib/core/services/windows_speech_backend.dart')
          .readAsStringSync();

      expect(registrant.toLowerCase(), isNot(contains('flutter_tts')));
      expect(main, contains('BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY'));
      expect(main, contains('ExcludeSemantics'));
      expect(shell, isNot(contains('IndexedStack')));
      expect(speech, contains('System.Speech'));
      expect(speech, contains('Process.start'));
    });

    test('parent controls describe the integrated narration behaviour', () {
      final audioSettings = File(
        'lib/features/parent/parent_audio_settings_screen.dart',
      ).readAsStringSync();
      final accessibility = File(
        'lib/features/parent/parent_accessibility_screen.dart',
      ).readAsStringSync();
      expect(audioSettings, contains('Automatic learning narration'));
      expect(accessibility, contains('current narration transcript and choices'));
      expect(accessibility, contains('Highlights the current learning text'));
    });
  });
}
