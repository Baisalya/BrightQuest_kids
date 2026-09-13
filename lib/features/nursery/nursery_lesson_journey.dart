import '../../core/nursery/nursery_content.dart';

enum NurseryLessonJourneyStage {
  study,
  guidedPlay,
  independentGame,
}

class NurseryLessonJourneyPlan {
  const NurseryLessonJourneyPlan({
    required this.guidedActivity,
    required this.independentActivities,
    required this.recommendedIndependentActivity,
    required this.guidedComplete,
    required this.independentCompletedCount,
    required this.recommendedStage,
    required this.allActivitiesComplete,
  });

  final NurseryActivity? guidedActivity;
  final List<NurseryActivity> independentActivities;
  final NurseryActivity? recommendedIndependentActivity;
  final bool guidedComplete;
  final int independentCompletedCount;
  final NurseryLessonJourneyStage recommendedStage;
  final bool allActivitiesComplete;

  bool get independentStarted => independentCompletedCount > 0;
  bool get independentComplete =>
      independentActivities.isNotEmpty &&
      independentCompletedCount == independentActivities.length;
}

class NurseryLessonJourneyPlanner {
  const NurseryLessonJourneyPlanner._();

  static NurseryLessonJourneyPlan build({
    required List<NurseryActivity> activities,
    required Set<String> completedActivityIds,
    required bool studyVisited,
  }) {
    NurseryActivity? guidedActivity;
    for (final activity in activities) {
      if (activity.phase == 'guided') {
        guidedActivity = activity;
        break;
      }
    }
    guidedActivity ??= activities.isEmpty ? null : activities.first;

    final independentActivities = <NurseryActivity>[
      for (final activity in activities)
        if (guidedActivity == null || activity.id != guidedActivity.id)
          activity,
    ];

    final guidedComplete = guidedActivity != null &&
        completedActivityIds.contains(guidedActivity.id);
    final independentCompletedCount = independentActivities
        .where((activity) => completedActivityIds.contains(activity.id))
        .length;

    NurseryActivity? recommendedIndependentActivity;
    for (final activity in independentActivities) {
      if (!completedActivityIds.contains(activity.id)) {
        recommendedIndependentActivity = activity;
        break;
      }
    }
    if (recommendedIndependentActivity == null &&
        independentActivities.isNotEmpty) {
      recommendedIndependentActivity = independentActivities.first;
    }

    final completedAuthoredCount = activities
        .where((activity) => completedActivityIds.contains(activity.id))
        .length;
    final allActivitiesComplete =
        activities.isNotEmpty && completedAuthoredCount == activities.length;
    final hasAnyCompletedActivity = completedAuthoredCount > 0;

    final recommendedStage = !studyVisited && !hasAnyCompletedActivity
        ? NurseryLessonJourneyStage.study
        : !guidedComplete
            ? NurseryLessonJourneyStage.guidedPlay
            : NurseryLessonJourneyStage.independentGame;

    return NurseryLessonJourneyPlan(
      guidedActivity: guidedActivity,
      independentActivities: List<NurseryActivity>.unmodifiable(
        independentActivities,
      ),
      recommendedIndependentActivity: recommendedIndependentActivity,
      guidedComplete: guidedComplete,
      independentCompletedCount: independentCompletedCount,
      recommendedStage: recommendedStage,
      allActivitiesComplete: allActivitiesComplete,
    );
  }
}

String nurseryJourneyStageTitle(NurseryLessonJourneyStage stage) =>
    switch (stage) {
      NurseryLessonJourneyStage.study => 'Study',
      NurseryLessonJourneyStage.guidedPlay => 'Guided Play',
      NurseryLessonJourneyStage.independentGame => 'Independent Game',
    };

int nurseryJourneyStageNumber(NurseryLessonJourneyStage stage) =>
    switch (stage) {
      NurseryLessonJourneyStage.study => 1,
      NurseryLessonJourneyStage.guidedPlay => 2,
      NurseryLessonJourneyStage.independentGame => 3,
    };
