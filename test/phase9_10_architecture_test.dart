import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 9+10 separates child growth, parent analytics and rewards', () {
    final progress =
        File('lib/features/progress/progress_screen.dart').readAsStringSync();
    final profile =
        File('lib/features/profile/profile_screen.dart').readAsStringSync();
    final rewards =
        File('lib/features/games/rewards_room_screen.dart').readAsStringSync();
    final parentReport =
        File('lib/features/parent/parent_learning_report_screen.dart')
            .readAsStringSync();
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();

    expect(progress, contains("BrightHeader(title: 'My Journey')"));
    expect(progress, contains("title: 'Your worlds'"));
    expect(progress, contains('describeChildJourney'));
    expect(progress, isNot(contains('controller.accuracy')));
    expect(progress, isNot(contains('recommendedDifficulty')));
    expect(progress, isNot(contains('hintsUsed')));
    expect(progress, isNot(contains('Adventure mastery')));
    expect(progress, isNot(contains('Adaptive D')));

    expect(parentReport, contains("'Adventure diagnostics'"));
    expect(parentReport, contains('recommendedDifficulty(game.id)'));
    expect(parentReport, contains('stats.hintsUsed'));
    expect(parentReport, contains('stats.accuracy'));
    expect(parentReport, contains('controller.isNurseryLearner'));
    expect(parentReport, contains("Key('parent_nursery_learning_report')"));

    expect(profile, contains("BrightHeader(title: 'My Space')"));
    expect(profile, contains("Key('profile_rewards_card')"));
    expect(profile, contains("Key('open_rewards_from_profile')"));
    expect(profile, isNot(contains('class _AchievementBadge')));
    expect(profile, isNot(contains("title: 'Achievements'")));
    expect(profile, isNot(contains("title: 'Cosmetics owned'")));
    expect(profile, isNot(contains("label: 'Streak'")));
    expect(profile, isNot(contains("label: 'XP'")));

    expect(rewards, contains("title: 'My loadout'"));
    expect(rewards, contains("title: 'Choose a look'"));
    expect(rewards, contains("title: 'Celebrations'"));
    expect(rewards, contains("Key('reward_trophies_expansion')"));
    expect(rewards, contains("Key('reward_achievements_expansion')"));
    expect(rewards, contains('controller.buyReward'));
    expect(rewards, contains('controller.equipReward'));
    expect(rewards, contains('controller.unequipRewardForGame'));
    expect(rewards, isNot(contains('controller.learningPathProgress')));

    expect(home, isNot(contains("Key('open_rewards_room')")));
  });
}
