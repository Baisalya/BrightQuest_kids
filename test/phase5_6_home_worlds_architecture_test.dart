import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 5+6 keeps Home recommendation-first and Worlds exploration-only',
      () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final worlds = File('lib/features/adventures/adventures_screen.dart')
        .readAsStringSync();

    expect(home, contains("Key('home_primary_action')"));
    expect(home, contains('chooseHomePrimaryAction('));
    // Phase 10 moves the reward doorway out of learning Home and into Me.
    expect(home, isNot(contains("Key('open_rewards_room')")));
    // Phase 8 supersedes the temporary Nursery bridge: Nursery is now a
    // persisted learner stage owned by the root shell.
    expect(home, isNot(contains("Key('open_nursery_garden')")));

    expect(home, isNot(contains('Explorer shortcuts')));
    expect(home, isNot(contains('Explore by Subject / World')));
    expect(home, isNot(contains('All Adventures')));
    expect(home, isNot(contains('ClassSkillStudioScreen')));
    expect(home, isNot(contains('_WorldMiniCard')));

    expect(worlds, contains('world_card_'));
    expect(worlds, contains('Paused missions remain inside the world'));
    expect(worlds, isNot(contains('Quick Play')));
    expect(worlds, isNot(contains('AdventureCard(')));
    expect(worlds, isNot(contains('_ResumeMissionCard')));
    expect(worlds, isNot(contains('show_all_saved_missions')));
  });
}
