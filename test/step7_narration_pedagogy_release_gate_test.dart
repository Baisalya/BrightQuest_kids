import 'dart:io';

import 'package:brightquest_kids/core/accessibility/learning_audio_director.dart';
import 'package:brightquest_kids/core/accessibility/learning_audio_models.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/gameplay_activity_resolver.dart';
import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/core/learning/mission_run_session_coordinator.dart';
import 'package:brightquest_kids/core/learning/mission_session_engine.dart';
import 'package:brightquest_kids/core/nursery/nursery_practice_generator.dart';
import 'package:brightquest_kids/core/nursery/nursery_spoken_labels.dart';
import 'package:brightquest_kids/core/qa/class_curriculum_hardening_audit.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_narration.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

String _normalise(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

void main() {
  group('Step 7 final narration and pedagogy release gate', () {
    test(
        'all 72 Learning World levels preserve distinct teaching roles and authored prompt narration',
        () {
      final repository = buildContentRepository();
      const runCoordinator = MissionRunSessionCoordinator();
      const lessonEngine = LessonEngine();
      const sessionEngine = MissionSessionEngine();
      const director = LearningAudioDirector();
      const resolver = GameplayActivityResolver();

      expect(learningLevels, hasLength(72));
      final start = DateTime.utc(2026, 9, 14);

      for (var levelIndex = 0; levelIndex < learningLevels.length; levelIndex++) {
        final level = learningLevels[levelIndex];
        final plan = runCoordinator.createOrRestoreForWorldLevel(
          repository: repository,
          level: level,
          now: start.add(Duration(minutes: levelIndex)),
        );
        final flow = lessonEngine.buildForLevel(
          repository: repository,
          level: level,
          missionRunPlan: plan,
        );
        final session = sessionEngine.build(flow);

        final objective = session.steps.firstWhere(
          (step) => step.lessonStep.kind == LessonStepKind.objective,
        );
        final explanation = session.steps.firstWhere(
          (step) => step.lessonStep.kind == LessonStepKind.explanation,
        );
        final worked = session.steps.firstWhere(
          (step) => step.lessonStep.kind == LessonStepKind.workedExample,
        );
        final teachingBodies = <String>{
          _normalise(objective.lessonStep.body),
          _normalise(explanation.lessonStep.body),
          _normalise(worked.lessonStep.body),
        };
        expect(teachingBodies, hasLength(3), reason: level.id);

        final objectiveCue = director.forLessonStep(sessionStep: objective);
        final explanationCue = director.forLessonStep(sessionStep: explanation);
        final workedCue = director.forLessonStep(sessionStep: worked);
        expect(objectiveCue.kind, LearningNarrationKind.missionGoal,
            reason: level.id);
        expect(explanationCue.kind, LearningNarrationKind.conceptTeaching,
            reason: level.id);
        expect(workedCue.kind, LearningNarrationKind.workedExample,
            reason: level.id);
        expect(objectiveCue.spokenText, objective.lessonStep.body,
            reason: level.id);
        expect(explanationCue.spokenText, explanation.lessonStep.body,
            reason: level.id);
        expect(workedCue.spokenText, worked.lessonStep.body,
            reason: level.id);

        for (final sessionStep in session.steps.where((step) => step.isInteractive)) {
          final activityId = sessionStep.lessonStep.activityId;
          expect(activityId, isNotNull, reason: '${level.id}/${sessionStep.lessonStep.id}');
          final activity = repository.activityById(activityId!);
          expect(activity, isNotNull, reason: '$activityId / ${level.id}');
          final spec = resolver.resolve(activity!);
          final cue = director.forLessonStep(
            sessionStep: sessionStep,
            activity: activity,
            activitySpec: spec,
          );

          expect(cue.kind, LearningNarrationKind.activityPrompt,
              reason: sessionStep.lessonStep.id);
          expect(cue.delivery, LearningNarrationDelivery.prompt,
              reason: sessionStep.lessonStep.id);
          expect(cue.spokenText, activity.narrationText,
              reason: sessionStep.lessonStep.id);
          expect(cue.visibleText, activity.prompt,
              reason: sessionStep.lessonStep.id);
          expect(
            cue.choices.toList(growable: false),
            spec.choiceValues.whereType<Object>().toList(growable: false),
            reason: sessionStep.lessonStep.id,
          );
          for (final hint in <String>[
            ...sessionStep.lessonStep.hints,
            ...activity.hints.map((item) => item.text),
          ]) {
            final normalisedHint = _normalise(hint);
            if (normalisedHint.isEmpty) continue;
            expect(
              _normalise(cue.spokenText),
              isNot(contains(normalisedHint)),
              reason: '${sessionStep.lessonStep.id} auto-read leaked hint: $hint',
            );
          }
        }
      }
    });

    test('automatic duplicate suppression never blocks learner Read again', () {
      const policy = LearningNarrationSequencePolicy();
      const first = LearningNarrationCue(
        id: 'first',
        kind: LearningNarrationKind.conceptTeaching,
        visibleText: 'A noun is a naming word.',
        spokenText: 'A noun is a naming word.',
      );
      const duplicate = LearningNarrationCue(
        id: 'second',
        kind: LearningNarrationKind.workedExample,
        visibleText: 'A NOUN IS A NAMING WORD.',
        spokenText: '  A NOUN   IS A NAMING WORD. ',
      );

      expect(
        policy.shouldSuppress(
          cue: duplicate,
          previousFingerprint: first.automaticRepeatKey,
          manual: false,
        ),
        isTrue,
      );
      expect(
        policy.shouldSuppress(
          cue: duplicate,
          previousFingerprint: first.automaticRepeatKey,
          manual: true,
        ),
        isFalse,
      );
    });

    test('automatic narration remains fail-closed for every preference gate', () {
      const policy = LearningAudioAccessibilityPolicy();
      const cue = LearningNarrationCue(
        id: 'release:auto',
        kind: LearningNarrationKind.conceptTeaching,
        visibleText: 'A clear lesson sentence.',
        spokenText: 'A clear lesson sentence.',
      );

      var allowedCombinations = 0;
      for (final soundEnabled in <bool>[false, true]) {
        for (final voiceEnabled in <bool>[false, true]) {
          for (final voiceAvailable in <bool>[false, true]) {
            for (final autoNarrationEnabled in <bool>[false, true]) {
              final allowed = policy.shouldAutoNarrate(
                cue: cue,
                soundEnabled: soundEnabled,
                voiceEnabled: voiceEnabled,
                voiceAvailable: voiceAvailable,
                autoNarrationEnabled: autoNarrationEnabled,
              );
              if (allowed) allowedCombinations += 1;
              expect(
                allowed,
                soundEnabled &&
                    voiceEnabled &&
                    voiceAvailable &&
                    autoNarrationEnabled,
              );
            }
          }
        }
      }
      expect(allowedCombinations, 1);
    });

    test('all 111 blueprints retain explanatory, non-repeated authored teaching',
        () {
      final repository = buildContentRepository();
      final blueprints = repository.learningBlueprints;
      expect(blueprints, hasLength(111));

      final objectives = <String>{};
      final teaching = <String>{};
      final worked = <String>{};
      final spacedName = RegExp(r'\br\s+i\s+y\s+a\b|\br\s+i\s+a\b', caseSensitive: false);

      for (final blueprint in blueprints) {
        final objective = _normalise(blueprint.objective);
        final teach = _normalise(blueprint.teach);
        final example = _normalise(blueprint.workedExample);
        final narration = _normalise(blueprint.narrationText);

        expect(objective, isNotEmpty, reason: blueprint.competencyId);
        expect(teach, isNotEmpty, reason: blueprint.competencyId);
        expect(example, isNotEmpty, reason: blueprint.competencyId);
        expect(teach, isNot(example), reason: blueprint.competencyId);
        expect(narration, teach, reason: blueprint.competencyId);
        expect(
          teach.split(' ').where((word) => word.isNotEmpty).length,
          greaterThanOrEqualTo(12),
          reason: '${blueprint.competencyId} needs explanatory teaching',
        );
        expect(objectives.add(objective), isTrue,
            reason: '${blueprint.competencyId} duplicates an objective');
        expect(teaching.add(teach), isTrue,
            reason: '${blueprint.competencyId} duplicates concept teaching');
        expect(worked.add(example), isTrue,
            reason: '${blueprint.competencyId} duplicates a worked example');

        final childFacingText = <String>[
          blueprint.objective,
          blueprint.teach,
          blueprint.workedExample,
          blueprint.guidedPrompt,
          blueprint.independentFallbackPrompt,
          blueprint.transferPrompt,
          blueprint.reviewPrompt,
          blueprint.narrationText,
        ].join(' ');
        expect(
          spacedName.hasMatch(childFacingText),
          isFalse,
          reason: '${blueprint.competencyId} must read Ria/Riya as a word, not letters',
        );
        expect(blueprint.review.status.name, isNot('approved'),
            reason: blueprint.competencyId);
      }
    });

    test('independent curriculum hardening audit has no release blocker', () {
      final repository = buildContentRepository();
      final report = const ClassCurriculumHardeningAudit().audit(repository);
      expect(
        report.releaseBlockingFindings,
        isEmpty,
        reason: report.findings.join('\n'),
      );
      expect(report.checksRun, greaterThan(0));
    });

    test('Nursery uses the same role model for board, teaching, play and review',
        () {
      final repository = buildContentRepository();
      final pack = repository.nurseryPack!;
      const narration = NurseryLessonNarration();
      const generator = NurseryPracticeGenerator();

      expect(pack.skills, hasLength(32));
      expect(pack.activities, hasLength(132));

      for (final skill in pack.skills) {
        final boardCue = narration.currentCue(
          reviewMode: false,
          generatedReview: null,
          pageIndex: -1,
          pack: pack,
          skill: skill,
          teachingText: null,
        );
        expect(boardCue.kind, LearningNarrationKind.missionGoal,
            reason: skill.id);
        expect(boardCue.autoEligible, isTrue, reason: skill.id);
        expect(
          narration.scopeKey(
            reviewMode: false,
            generatedReview: null,
            pageIndex: -1,
            pack: pack,
            skill: skill,
          ),
          'board:${skill.id}',
        );

        final teachingTexts = <String>[
          skill.objective,
          skill.explanation,
          '${skill.workedExample.headline}. ${skill.workedExample.caption}',
        ];
        final teachingKinds = <LearningNarrationKind>[
          LearningNarrationKind.missionGoal,
          LearningNarrationKind.conceptTeaching,
          LearningNarrationKind.workedExample,
        ];
        expect(
          teachingTexts.map(_normalise).toSet(),
          hasLength(3),
          reason: '${skill.id} teaching stages must be distinct',
        );
        for (var page = 0; page < 3; page += 1) {
          final cue = narration.currentCue(
            reviewMode: false,
            generatedReview: null,
            pageIndex: page,
            pack: pack,
            skill: skill,
            teachingText: teachingTexts[page],
          );
          expect(cue.kind, teachingKinds[page], reason: '${skill.id}/$page');
          expect(cue.spokenText, nurserySpeakableText(teachingTexts[page]),
              reason: '${skill.id}/$page');
          expect(cue.autoEligible, isTrue, reason: '${skill.id}/$page');
        }

        final activities = pack.activitiesForSkill(skill.id);
        for (var index = 0; index < activities.length; index += 1) {
          final activity = activities[index];
          final pageIndex = index + 3;
          final cue = narration.currentCue(
            reviewMode: false,
            generatedReview: null,
            pageIndex: pageIndex,
            pack: pack,
            skill: skill,
            teachingText: null,
          );
          expect(cue.kind, LearningNarrationKind.activityPrompt,
              reason: activity.id);
          expect(cue.spokenText, nurserySpeakableText(activity.narration),
              reason: activity.id);
          expect(
            cue.choices.toList(growable: false),
            activity.options
                .map((option) => nurserySpokenLabel(option.label))
                .toList(growable: false),
            reason: activity.id,
          );
          expect(nurseryContainsRawVisualToken(cue.spokenText), isFalse,
              reason: activity.id);
          expect(
            narration.scopeKey(
              reviewMode: false,
              generatedReview: null,
              pageIndex: pageIndex,
              pack: pack,
              skill: skill,
            ),
            'activity:${activity.id}',
          );
        }

        final review = generator.generate(pack: pack, skill: skill, seed: 7);
        final reviewCue = narration.currentCue(
          reviewMode: true,
          generatedReview: review,
          pageIndex: -1,
          pack: pack,
          skill: skill,
          teachingText: null,
        );
        expect(reviewCue.kind, LearningNarrationKind.activityPrompt,
            reason: '${skill.id}/review');
        expect(reviewCue.spokenText, nurserySpeakableText(review.narration),
            reason: '${skill.id}/review');
        expect(
          narration.scopeKey(
            reviewMode: true,
            generatedReview: review,
            pageIndex: -1,
            pack: pack,
            skill: skill,
          ),
          'review:${review.id}',
        );
      }
    });

    test('route, scope and delayed-feedback cancellation stay wired together',
        () {
      final coordinator = File(
        'lib/core/accessibility/learning_narration_coordinator.dart',
      ).readAsStringSync();
      final feedback =
          File('lib/core/services/feedback_service.dart').readAsStringSync();
      final lesson =
          File('lib/features/learning/lesson_flow_screen.dart').readAsStringSync();
      final nursery = File('lib/features/nursery/nursery_lesson_screen.dart')
          .readAsStringSync();

      for (final routeMethod in <String>[
        'void didPush(Route<dynamic> route',
        'void didPop(Route<dynamic> route',
        'void didRemove(Route<dynamic> route',
        'void didReplace({Route<dynamic>? newRoute',
      ]) {
        expect(coordinator, contains(routeMethod));
      }
      expect(coordinator, contains('LearningNarrationCoordinator.instance.stopAll()'));
      expect(coordinator, contains('void didPushNext()'));
      expect(coordinator, contains('_session.suspend()'));
      expect(coordinator, contains('void didPopNext()'));
      expect(coordinator, contains('_session.resume()'));
      expect(coordinator, contains('void didPop()'));
      expect(coordinator, contains('_session.stop()'));
      expect(coordinator, contains('_session.dispose()'));

      expect(feedback, contains('addGlobalInvalidationListener(turn.cancel)'));
      expect(feedback, contains('Timer(duration'));
      expect(feedback, contains('_delayTimer?.cancel()'));
      expect(feedback, isNot(contains('Future<void>.delayed(')));
      expect(lesson, contains('LearningNarrationBoundary('));
      expect(lesson, contains('narrationSession.captureGuard()'));
      expect(lesson, contains('narrationSession.isGuardCurrent(feedbackGuard)'));
      expect(nursery, contains('LearningNarrationBoundary('));
      expect(nursery, contains('LearningAutomaticNarrator('));
    });

    test('Android and Windows narration backends remain deliberately separated',
        () {
      final service =
          File('lib/core/services/bright_audio_service.dart').readAsStringSync();
      final windows =
          File('lib/core/services/windows_speech_backend.dart').readAsStringSync();
      final registrant = File('windows/flutter/generated_plugin_registrant.cc')
          .readAsStringSync()
          .toLowerCase();
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(service, contains("import 'package:flutter_tts/flutter_tts.dart';"));
      expect(service, contains("import 'windows_speech_backend.dart';"));
      expect(service, contains('if (Platform.isWindows)'));
      expect(service, contains('_windowsVoice.initialize()'));
      expect(service, contains('FlutterTts()'));
      expect(service, contains("tts.setLanguage('en-IN')"));
      expect(windows, contains('System.Speech'));
      expect(windows, contains('Process.start'));
      expect(registrant, isNot(contains('flutter_tts')));
      expect(pubspec, contains('third_party/flutter_tts_android'));
    });
  });
}
