import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 6 feedback and hint audio sequencing', () {
    test('latest learner feedback turn wins across async SFX and TTS work', () {
      final feedback =
          File('lib/core/services/feedback_service.dart').readAsStringSync();

      expect(feedback, contains('static int _feedbackSerial = 0;'));
      expect(feedback, contains('serial: ++_feedbackSerial'));
      expect(feedback, contains('captureGlobalGuard()'));
      expect(feedback, contains('narrationSession?.captureGuard()'));
      expect(feedback, contains('turn.serial != _feedbackSerial'));
      expect(
        RegExp(r'_isTurnCurrent\(turn\)').allMatches(feedback).length,
        greaterThanOrEqualTo(8),
      );
    });

    test('feedback interrupts a reading prompt without faking a scope change', () {
      final coordinator = File(
        'lib/core/accessibility/learning_narration_coordinator.dart',
      ).readAsStringSync();
      final feedback =
          File('lib/core/services/feedback_service.dart').readAsStringSync();

      expect(coordinator, contains('Future<void> interruptCurrentSpeech()'));
      expect(coordinator, contains('_interruptCurrentSpeech(this)'));
      expect(feedback, contains('await session.interruptCurrentSpeech();'));
      expect(feedback, contains('await audio.stopVoice();'));
    });

    test('hint, correct and wrong nursery audio use the shared sequencer', () {
      final nursery = File('lib/features/nursery/nursery_lesson_screen.dart')
          .readAsStringSync();
      final feedback =
          File('lib/core/services/feedback_service.dart').readAsStringSync();

      expect(nursery, contains('FeedbackService.correct('));
      expect(nursery, contains('FeedbackService.wrong('));
      expect(nursery, contains('FeedbackService.hint('));
      expect(nursery, contains('soundProfile: BrightSfxProfile.nursery'));
      expect(
        nursery,
        isNot(contains('BrightAudioService.instance.playSfx(BrightSfx.hint)')),
      );
      expect(nursery, isNot(contains('narrationSession.speakCorrect(')));
      expect(nursery, isNot(contains('narrationSession.speakWrong(')));

      expect(
        feedback,
        contains(
          'await audio.playProfileSfx(soundProfile, BrightInteractionSfx.hint);',
        ),
      );
      expect(feedback, contains('_playHintAudio('));
      expect(feedback, contains('session.speakCue(cue, manual: true)'));
    });

    test('lesson captures feedback ownership before async evidence persistence', () {
      final lesson = File('lib/features/learning/lesson_flow_screen.dart')
          .readAsStringSync();

      expect(
        lesson,
        contains('final feedbackGuard = narrationSession.captureGuard();'),
      );
      expect(lesson, contains('required LearningNarrationGuard feedbackGuard'));
      expect(
        lesson,
        contains('narrationSession.isGuardCurrent(feedbackGuard)'),
      );
    });

    test('lesson wrong-answer narration keeps answer-leak protection', () {
      final lesson = File('lib/features/learning/lesson_flow_screen.dart')
          .readAsStringSync();

      expect(lesson, contains('FeedbackService.wrong('));
      expect(
        lesson,
        contains("guidance: '\${feedback.message} \${feedback.strategy}'"),
      );
      expect(lesson, isNot(contains('correctAnswer:')));
      expect(
        lesson,
        contains('detail: activity.explanation'),
        reason: 'Correct feedback should retain the authored explanation.',
      );
    });
  });
}
