import '../content/content_activity.dart';
import '../content/content_repository.dart';
import '../content/game_content.dart';
import 'mission_run_models.dart';
import 'mission_run_planner.dart';

/// Typed adapter from a persisted [MissionRunPlan] to the legacy view models
/// already rendered by each BrightQuest game screen.
///
/// Selection stays centralized in [MissionRunPlanner]. This adapter only reads
/// the same structured payload fields that [ContentRepository] already uses;
/// it never derives answers from prompt text or creates new curriculum data.
class MissionRunGameContent {
  const MissionRunGameContent({
    this.planner = const MissionRunPlanner(),
  });

  final MissionRunPlanner planner;

  List<MathQuestion> mathQuestions({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<MathQuestion>.unmodifiable(
        _activities(repository, plan, 'math_market').map((activity) {
          final answer = activity.payload['answer'];
          final choices = activity.payload['choices'];
          final hint = activity.payload['hint'];
          if (answer is! int || choices is! List || hint is! String) {
            throw StateError('Invalid Math Market payload for ${activity.id}.');
          }
          return MathQuestion(
            activity.prompt,
            answer,
            choices.whereType<num>().map((value) => value.toInt()).toList(),
            hint,
            id: activity.legacyContentId,
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<FractionMission> fractionMissions({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<FractionMission>.unmodifiable(
        _activities(repository, plan, 'fraction_pizza').map((activity) {
          final totalSlices = activity.payload['totalSlices'];
          final numerator = activity.payload['numerator'];
          final denominator = activity.payload['denominator'];
          if (totalSlices is! int || numerator is! int || denominator is! int) {
            throw StateError(
                'Invalid Fraction Pizza payload for ${activity.id}.');
          }
          return FractionMission(
            id: activity.legacyContentId,
            totalSlices: totalSlices,
            numerator: numerator,
            denominator: denominator,
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<StoryMission> storyMissions({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<StoryMission>.unmodifiable(
        _activities(repository, plan, 'story_builder').map((activity) {
          final words = activity.payload['words'];
          if (words is! List || !words.every((value) => value is String)) {
            throw StateError(
                'Invalid Story Builder payload for ${activity.id}.');
          }
          return StoryMission(
            id: activity.legacyContentId,
            prompt: activity.prompt,
            words: List<String>.from(words),
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<GrammarMission> grammarMissions({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<GrammarMission>.unmodifiable(
        _activities(repository, plan, 'grammar_puzzle').map((activity) {
          final sentence = activity.payload['sentence'];
          final noun = activity.payload['noun'];
          final verb = activity.payload['verb'];
          final adjective = activity.payload['adjective'];
          if (sentence is! String ||
              noun is! String ||
              verb is! String ||
              adjective is! String) {
            throw StateError(
                'Invalid Grammar Puzzle payload for ${activity.id}.');
          }
          return GrammarMission(
            id: activity.legacyContentId,
            sentence: sentence,
            noun: noun,
            verb: verb,
            adjective: adjective,
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<ScienceQuizQuestion> scienceQuestions({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<ScienceQuizQuestion>.unmodifiable(
        _activities(repository, plan, 'science_lab').map((activity) {
          if (activity.payload.containsKey('reactionId')) {
            throw StateError(
              'Science experiment ${activity.id} cannot be rendered as a quiz question.',
            );
          }
          final answer = activity.payload['answer'];
          final choices = activity.payload['choices'];
          if (answer is! String ||
              choices is! List ||
              !choices.every((value) => value is String)) {
            throw StateError(
                'Invalid Science Lab quiz payload for ${activity.id}.');
          }
          return ScienceQuizQuestion(
            activity.prompt,
            answer,
            List<String>.from(choices),
            activity.explanation,
            id: activity.legacyContentId,
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<MapQuestion> mapQuestions({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<MapQuestion>.unmodifiable(
        _activities(repository, plan, 'map_quest').map((activity) {
          final answer = activity.payload['answer'];
          final choices = activity.payload['choices'];
          final hint = activity.payload['hint'];
          if (answer is! String ||
              choices is! List ||
              !choices.every((value) => value is String) ||
              hint is! String) {
            throw StateError('Invalid Map Quest payload for ${activity.id}.');
          }
          return MapQuestion(
            activity.legacyContentId,
            activity.prompt,
            answer,
            List<String>.from(choices),
            hint,
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<CodingMission> codingMissions({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<CodingMission>.unmodifiable(
        _activities(repository, plan, 'coding_maze').map((activity) {
          final payload = activity.payload;
          final width = payload['width'];
          final height = payload['height'];
          final startX = payload['startX'];
          final startY = payload['startY'];
          final goalX = payload['goalX'];
          final goalY = payload['goalY'];
          final direction = payload['startDirection'];
          final obstacles = payload['obstacles'];
          final maxCommands = payload['maxCommands'];
          if (width is! int ||
              height is! int ||
              startX is! int ||
              startY is! int ||
              goalX is! int ||
              goalY is! int ||
              direction is! String ||
              obstacles is! List ||
              maxCommands is! int) {
            throw StateError('Invalid Coding Maze payload for ${activity.id}.');
          }
          return CodingMission(
            id: activity.legacyContentId,
            width: width,
            height: height,
            startX: startX,
            startY: startY,
            goalX: goalX,
            goalY: goalY,
            startDirection: _facingDirection(direction, activity.id),
            obstacles: Set<String>.from(obstacles),
            maxCommands: maxCommands,
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<RecyclingItem> recyclingItems({
    required ContentRepository repository,
    required MissionRunPlan plan,
  }) =>
      List<RecyclingItem>.unmodifiable(
        _activities(repository, plan, 'recycling_challenge').map((activity) {
          final name = activity.payload['name'];
          final emoji = activity.payload['emoji'];
          final bin = activity.payload['bin'];
          if (name is! String || emoji is! String || bin is! String) {
            throw StateError(
              'Invalid Recycling Challenge payload for ${activity.id}.',
            );
          }
          return RecyclingItem(
            activity.legacyContentId,
            name,
            emoji,
            bin,
            topicId: activity.topicId,
            difficulty: activity.difficulty,
          );
        }),
      );

  List<ContentActivity> _activities(
    ContentRepository repository,
    MissionRunPlan plan,
    String expectedGameId,
  ) {
    if (plan.gameId != expectedGameId) {
      throw StateError(
        'Mission plan ${plan.levelId} belongs to ${plan.gameId}, not $expectedGameId.',
      );
    }
    return List<ContentActivity>.unmodifiable(
      plan.gameItems.map(
        (item) => planner.resolveCandidateActivity(
          repository: repository,
          candidate: item.candidate,
        ),
      ),
    );
  }

  FacingDirection _facingDirection(String value, String activityId) =>
      switch (value) {
        'north' => FacingDirection.north,
        'east' => FacingDirection.east,
        'south' => FacingDirection.south,
        'west' => FacingDirection.west,
        _ => throw StateError(
            'Invalid Coding Maze direction for $activityId: $value.',
          ),
      };
}
