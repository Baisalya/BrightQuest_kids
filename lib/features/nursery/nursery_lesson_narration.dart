import '../../core/accessibility/learning_audio_director.dart';
import '../../core/accessibility/learning_audio_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_practice_generator.dart';
import '../../core/nursery/nursery_spoken_labels.dart';

/// Pure narration policy for a nursery lesson.
///
/// The lesson screen owns navigation, progress, and learner state. This class
/// only maps that state to a narration scope and cue so narration policy stays
/// out of the orchestration widget.
class NurseryLessonNarration {
  const NurseryLessonNarration();

  Object scopeKey({
    required bool reviewMode,
    required NurseryGeneratedPractice? generatedReview,
    required int pageIndex,
    required NurseryContentPack pack,
    required NurserySkill skill,
  }) {
    if (reviewMode) {
      final review = generatedReview;
      return review == null ? 'review:${skill.id}:loading' : 'review:${review.id}';
    }
    if (pageIndex < 0) return 'board:${skill.id}';
    if (pageIndex < 3) return 'teaching:${skill.id}:$pageIndex';

    final activities = pack.activitiesForSkill(skill.id);
    final activityIndex = pageIndex - 3;
    if (activityIndex >= 0 && activityIndex < activities.length) {
      return 'activity:${activities[activityIndex].id}';
    }
    return 'lesson:${skill.id}:$pageIndex';
  }

  LearningNarrationCue currentCue({
    required bool reviewMode,
    required NurseryGeneratedPractice? generatedReview,
    required int pageIndex,
    required NurseryContentPack pack,
    required NurserySkill skill,
    required String? teachingText,
  }) {
    const director = LearningAudioDirector();

    if (reviewMode) {
      final review = generatedReview;
      if (review == null) {
        return director.forNurseryStatement(
          ownerId: 'review:${skill.id}:loading',
          kind: LearningNarrationKind.conceptTeaching,
          visibleText: 'Memory game',
          spokenText: '',
          autoEligible: false,
        );
      }
      return director.forNurseryPrompt(
        ownerId: 'review:${review.id}',
        visibleText: review.prompt,
        spokenText: nurserySpeakableText(review.narration),
        choices: review.options.map(
          (option) => nurserySpokenLabel(option.label),
        ),
      );
    }

    if (pageIndex < 0) {
      const boardNarration =
          'Three easy steps. Study first, then Guided Play, then Independent Game.';
      return director.forNurseryStatement(
        ownerId: 'board:${skill.id}',
        kind: LearningNarrationKind.missionGoal,
        visibleText: boardNarration,
        spokenText: boardNarration,
      );
    }

    if (pageIndex < 3) {
      assert(teachingText != null);
      final text = teachingText!;
      return director.forNurseryStatement(
        ownerId: 'teaching:${skill.id}:$pageIndex',
        kind: switch (pageIndex) {
          0 => LearningNarrationKind.missionGoal,
          1 => LearningNarrationKind.conceptTeaching,
          _ => LearningNarrationKind.workedExample,
        },
        visibleText: text,
        spokenText: nurserySpeakableText(text),
      );
    }

    final activities = pack.activitiesForSkill(skill.id);
    final activityIndex = pageIndex - 3;
    if (activityIndex >= 0 && activityIndex < activities.length) {
      final activity = activities[activityIndex];
      return director.forNurseryPrompt(
        ownerId: 'activity:${activity.id}',
        visibleText: activity.prompt,
        spokenText: nurserySpeakableText(activity.narration),
        choices: activity.options.map(
          (option) => nurserySpokenLabel(option.label),
        ),
      );
    }

    return director.forNurseryStatement(
      ownerId: 'lesson:${skill.id}:$pageIndex',
      kind: LearningNarrationKind.conceptTeaching,
      visibleText: skill.title,
      spokenText: '',
      autoEligible: false,
    );
  }
}
