import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/core/learning/mission_session_engine.dart';
import 'package:brightquest_kids/core/learning/mission_session_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  group('MissionSessionEngine', () {
    test('turns the authored lesson into the four-stage play loop', () {
      final repository = buildContentRepository();
      final flow = const LessonEngine().buildForCompetency(
        repository: repository,
        classNumber: 3,
        competencyId: 'c3_math_add_sub_3digit',
      );

      final session = const MissionSessionEngine().build(flow);

      expect(session.steps, hasLength(7));
      expect(
        session.steps.map((step) => step.lessonStep.kind),
        <LessonStepKind>[
          LessonStepKind.objective,
          LessonStepKind.explanation,
          LessonStepKind.workedExample,
          LessonStepKind.guidedTry,
          LessonStepKind.independentPractice,
          LessonStepKind.transfer,
          LessonStepKind.exitTicket,
        ],
      );
      expect(
        session.steps.map((step) => step.phase).toSet(),
        MissionSessionPhase.values.toSet(),
      );
      expect(session.reteachStep?.kind, LessonStepKind.reteach);
      expect(session.reviewStep?.kind, LessonStepKind.review);
      expect(
        session.steps.any(
          (step) =>
              step.lessonStep.kind == LessonStepKind.reteach ||
              step.lessonStep.kind == LessonStepKind.review,
        ),
        isFalse,
      );
    });

    test(
        'guided play is coached while solo, transfer and checkpoint stay independent',
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
      final independent = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.independentPractice,
      );
      final transfer = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.transfer,
      );
      final checkpoint = session.steps.firstWhere(
        (step) => step.lessonStep.kind == LessonStepKind.exitTicket,
      );

      expect(guided.supportMode, MissionSupportMode.coached);
      expect(guided.allowsPreAttemptCoaching, isTrue);
      expect(guided.requiresIndependentWork, isFalse);
      expect(independent.supportMode, MissionSupportMode.independent);
      expect(independent.requiresIndependentWork, isTrue);
      expect(transfer.supportMode, MissionSupportMode.transfer);
      expect(transfer.phase, MissionSessionPhase.applyInGame);
      expect(checkpoint.supportMode, MissionSupportMode.checkpoint);
      expect(checkpoint.phase, MissionSessionPhase.applyInGame);
    });

    test(
        'all Class 3-5 competency flows keep authored support but do not force it into the current session',
        () {
      final repository = buildContentRepository();
      const lessons = LessonEngine();
      const sessions = MissionSessionEngine();

      for (final classNumber in <int>[3, 4, 5]) {
        for (final flow in lessons.buildClassDraftCoverage(
          repository: repository,
          classNumber: classNumber,
        )) {
          final session = sessions.build(flow);
          expect(session.steps, hasLength(7), reason: flow.competencyId);
          expect(session.reteachStep, isNotNull, reason: flow.competencyId);
          expect(session.reviewStep, isNotNull, reason: flow.competencyId);
          expect(
            session.steps.first.phase,
            MissionSessionPhase.seeIt,
            reason: flow.competencyId,
          );
          expect(
            session.steps.last.supportMode,
            MissionSupportMode.checkpoint,
            reason: flow.competencyId,
          );
        }
      }
    });
  });
}
