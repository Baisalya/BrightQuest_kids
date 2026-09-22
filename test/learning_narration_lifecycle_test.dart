import 'dart:io';

import 'package:brightquest_kids/core/accessibility/learning_narration_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 1 narration ownership generations', () {
    test('step scope changes invalidate delayed narration work', () async {
      final session = LearningNarrationCoordinator.instance.createSession(
        ownerLabel: 'step-change-test',
      );
      addTearDown(session.dispose);

      final beforeStepChange = session.captureGuard();
      expect(session.isGuardCurrent(beforeStepChange), isTrue);

      await session.advanceScope();

      expect(session.isGuardCurrent(beforeStepChange), isFalse);
      expect(session.isGuardCurrent(session.captureGuard()), isTrue);
    });

    test('covered routes cannot reuse narration captured before suspension',
        () async {
      final session = LearningNarrationCoordinator.instance.createSession(
        ownerLabel: 'route-cover-test',
      );
      addTearDown(session.dispose);

      final beforeCover = session.captureGuard();
      await session.suspend();

      expect(session.isSuspended, isTrue);
      expect(session.isGuardCurrent(beforeCover), isFalse);

      session.resume();
      expect(session.isSuspended, isFalse);
      expect(session.isGuardCurrent(beforeCover), isFalse);
      expect(session.isGuardCurrent(session.captureGuard()), isTrue);
    });

    test('top-level narration boundary invalidates every pending owner',
        () async {
      final first = LearningNarrationCoordinator.instance.createSession(
        ownerLabel: 'global-boundary-first',
      );
      final second = LearningNarrationCoordinator.instance.createSession(
        ownerLabel: 'global-boundary-second',
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final coordinator = LearningNarrationCoordinator.instance;
      final firstGuard = first.captureGuard();
      final secondGuard = second.captureGuard();
      final globalGuard = coordinator.captureGlobalGuard();

      await coordinator.stopAll();

      expect(first.isGuardCurrent(firstGuard), isFalse);
      expect(second.isGuardCurrent(secondGuard), isFalse);
      expect(coordinator.isGlobalGuardCurrent(globalGuard), isFalse);
    });

    test('global invalidation listeners fire on ownership boundaries', () async {
      final coordinator = LearningNarrationCoordinator.instance;
      var notifications = 0;
      final removeListener = coordinator.addGlobalInvalidationListener(
        () => notifications += 1,
      );

      await coordinator.stopAll();
      expect(notifications, 1);

      removeListener();
      await coordinator.stopAll();
      expect(notifications, 1);
    });
  });

  group('Step 1 static lifecycle integration', () {
    test('automatic narration is requested outside LearningNarrationBar build',
        () {
      final source =
          File('lib/widgets/learning_accessibility_widgets.dart').readAsStringSync();
      final barStart = source.indexOf('class _LearningNarrationBarState');
      final buildStart = source.indexOf('Widget build(BuildContext context)', barStart);
      final denseStart = source.indexOf('Widget _buildDenseTranscript', buildStart);
      expect(buildStart, greaterThanOrEqualTo(0));
      expect(denseStart, greaterThan(buildStart));
      final buildBody = source.substring(buildStart, denseStart);

      expect(buildBody, isNot(contains('_requestAutoNarration()')));
      expect(source, contains('void _requestAutoNarration()'));
      expect(source, contains('didUpdateWidget'));
    });

    test('lesson and nursery share the reusable narration boundary', () {
      final lesson = File('lib/features/learning/lesson_flow_screen.dart')
          .readAsStringSync();
      final nursery = File('lib/features/nursery/nursery_lesson_screen.dart')
          .readAsStringSync();
      final nurseryNarration = File(
        'lib/features/nursery/nursery_lesson_narration.dart',
      ).readAsStringSync();
      final boundary = File(
        'lib/core/accessibility/learning_narration_coordinator.dart',
      ).readAsStringSync();
      final app = File('lib/app/brightquest_app.dart').readAsStringSync();

      expect(boundary, contains('with WidgetsBindingObserver, RouteAware'));
      expect(boundary, contains('void didPushNext()'));
      expect(boundary, contains('void didPopNext()'));
      expect(boundary, contains('void didPop()'));

      expect(lesson, contains('LearningNarrationBoundary('));
      expect(lesson, contains('scopeKey: narrationCue.id'));
      expect(lesson, contains('narrationSession: narrationSession'));
      expect(lesson, isNot(contains('with WidgetsBindingObserver, RouteAware')));
      expect(lesson, isNot(contains('createSession(')));

      expect(nursery, contains('LearningNarrationBoundary('));
      expect(nursery, contains('LearningAutomaticNarrator('));
      expect(nursery, contains('const narration = NurseryLessonNarration();'));
      expect(nursery, contains('narration.scopeKey('));
      expect(nursery, contains('narration.currentCue('));
      expect(nurseryNarration, contains('Object scopeKey({'));
      expect(nurseryNarration, contains('LearningNarrationCue currentCue({'));
      expect(nursery, contains('narrationSession.speakCue('));
      expect(nursery, isNot(contains('RouteAware')));
      expect(nursery, isNot(contains('createSession(')));

      final widgets = File('lib/widgets/bright_widgets.dart').readAsStringSync();
      expect(app, contains('learningNarrationRouteObserver'));
      expect(widgets, contains('LearningNarrationBoundary('));
      expect(widgets, contains('scopeKey: narrationCue?.id'));
      expect(widgets, contains('narrationSession.speakCue('));
    });

    test('director cues are spoken through session continuity policy', () {
      final coordinator = File(
        'lib/core/accessibility/learning_narration_coordinator.dart',
      ).readAsStringSync();
      final widgets = File(
        'lib/widgets/learning_accessibility_widgets.dart',
      ).readAsStringSync();

      expect(
        coordinator,
        contains('_lastAutomaticNarrationFingerprint'),
      );
      expect(coordinator, contains('shouldSuppress('));
      expect(coordinator, contains('LearningNarrationDelivery.prompt'));
      expect(widgets, contains('_narrationSession.speakCue('));
      expect(widgets, contains('_narrate(manual: false)'));
      expect(widgets, contains('_narrate(manual: true)'));
    });

    test('delayed correctness feedback accepts an ownership guard', () {
      final feedback =
          File('lib/core/services/feedback_service.dart').readAsStringSync();
      expect(feedback, contains('LearningNarrationSession? narrationSession'));
      expect(feedback, contains('captureGuard()'));
      expect(feedback, contains('captureGlobalGuard()'));
      expect(feedback, contains('isGuardCurrent(guard)'));
      expect(feedback, contains('isGlobalGuardCurrent(turn.globalGuard)'));
      expect(feedback, contains('addGlobalInvalidationListener(turn.cancel)'));
      expect(feedback, contains('if (!await turn.wait('));
      expect(feedback, isNot(contains('Future<void>.delayed(')));
    });
  });

  group('Step 5 unified learning narration surfaces', () {
    test('Nursery stage changes are boundary scope changes, not ad-hoc stops', () {
      final nursery = File('lib/features/nursery/nursery_lesson_screen.dart')
          .readAsStringSync();
      final narration = File(
        'lib/features/nursery/nursery_lesson_narration.dart',
      ).readAsStringSync();

      expect(nursery, contains('scopeKey: narrationScopeKey'));
      expect(nursery, contains('narration.scopeKey('));
      expect(narration, contains(r"return 'board:${skill.id}'"));
      expect(narration, contains(r"return 'teaching:${skill.id}:$pageIndex'"));
      expect(
        narration,
        contains(r"return 'activity:${activities[activityIndex].id}'"),
      );
      expect(narration, contains(r"'review:${review.id}'"));
      expect(nursery, isNot(contains('_announceCurrent()')));
      expect(nursery, isNot(contains('_syncNarrationRoute()')));
      expect(nursery, isNot(contains('_narrationSession.advanceScope()')));
    });

    test('Nursery auto and manual reads use director cues on the shared session',
        () {
      final nursery = File('lib/features/nursery/nursery_lesson_screen.dart')
          .readAsStringSync();
      final director = File(
        'lib/core/accessibility/learning_audio_director.dart',
      ).readAsStringSync();

      expect(director, contains('forNurseryStatement('));
      expect(director, contains('forNurseryPrompt('));
      expect(nursery, contains('forNurseryStatement('));
      expect(nursery, contains('forNurseryPrompt('));
      expect(nursery, contains('narrationSession.speakCue(cue, manual: true)'));
      expect(nursery, contains('nurserySpokenLabel(option.label)'));
    });

    test('headless auto narrator performs no speech side effect from build', () {
      final widgets = File(
        'lib/widgets/learning_accessibility_widgets.dart',
      ).readAsStringSync();

      final classStart = widgets.indexOf('class _LearningAutomaticNarratorState');
      final barStart = widgets.indexOf('class LearningNarrationBar', classStart);
      expect(classStart, greaterThanOrEqualTo(0));
      expect(barStart, greaterThan(classStart));
      final autoNarratorSource = widgets.substring(classStart, barStart);
      expect(
        autoNarratorSource,
        contains('Widget build(BuildContext context) => widget.child;'),
      );
      expect(autoNarratorSource, contains('addPostFrameCallback'));
      expect(autoNarratorSource, contains('widget.narrationSession.speakCue('));
    });

    test('external narration bars leave scope invalidation to their boundary', () {
      final widgets = File(
        'lib/widgets/learning_accessibility_widgets.dart',
      ).readAsStringSync();

      expect(
        widgets,
        contains(
          'if (_ownsSession) {\n        unawaited(_narrationSession.advanceScope());',
        ),
      );
    });
  });
}
