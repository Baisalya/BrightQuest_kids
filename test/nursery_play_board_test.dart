import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/features/nursery/nursery_play_board.dart';
import 'package:flutter_test/flutter_test.dart';

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      ),
    );

void main() {
  test('global Nursery portal skins cover every learning domain', () {
    final pack = _pack();

    final alphabet = pack.skillById('alpha_uppercase')!;
    final alphabetStyle = nurseryPortalStyleFor(
      alphabet,
      pack.activitiesForSkill(alphabet.id).first,
    );
    expect(alphabetStyle.title, 'Letter Hunt');

    final math = pack.skillById('math_add_objects')!;
    final mathActivities = pack.activitiesForSkill(math.id);
    expect(
      nurseryPortalStyleFor(math, mathActivities.first).title,
      'Number Hunt',
    );
    expect(
      nurseryPortalStyleFor(math, mathActivities.last).title,
      'Math Mission',
    );

    final world = pack.skillById('knowledge_colours')!;
    final worldActivities = pack.activitiesForSkill(world.id);
    expect(
      nurseryPortalStyleFor(world, worldActivities.first).title,
      'Picture Hunt',
    );
    expect(
      nurseryPortalStyleFor(world, worldActivities.last).title,
      'World Quest',
    );

    final thinking = pack.skillById('thinking_patterns')!;
    final thinkingActivities = pack.activitiesForSkill(thinking.id);
    expect(
      nurseryPortalStyleFor(thinking, thinkingActivities.first).title,
      'Puzzle Pop',
    );
    expect(
      nurseryPortalStyleFor(thinking, thinkingActivities.last).title,
      'Brain Boost',
    );
  });

  test('interaction-specific games override domain skin consistently', () {
    final pack = _pack();
    final matchSkill = pack.skillById('alpha_case_match')!;
    final matchActivity = pack
        .activitiesForSkill(matchSkill.id)
        .firstWhere((activity) => activity.interaction == 'pairMatch');
    expect(
      nurseryPortalStyleFor(matchSkill, matchActivity).title,
      'Match Magic',
    );

    final sortSkill = pack.skillById('thinking_sorting')!;
    final sortActivity = pack
        .activitiesForSkill(sortSkill.id)
        .firstWhere((activity) => activity.interaction == 'sortBuckets');
    expect(
      nurseryPortalStyleFor(sortSkill, sortActivity).title,
      'Sort Safari',
    );

    final traceSkill = pack.skillById('alpha_trace_upper')!;
    final traceActivity = pack
        .activitiesForSkill(traceSkill.id)
        .firstWhere((activity) => activity.isTrace);
    expect(
      nurseryPortalStyleFor(traceSkill, traceActivity).title,
      'Trace Trail',
    );
  });
}
