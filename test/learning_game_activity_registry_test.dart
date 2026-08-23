import 'package:brightquest_kids/core/learning/gameplay_activity_models.dart';
import 'package:brightquest_kids/features/learning/gameplay/activity_game_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Step 3 registry owns every supported reusable gameplay family', () {
    expect(
      ActivityGameRegistry.supportedKinds,
      containsAll(<LearningGameActivityKind>{
        LearningGameActivityKind.themedChoice,
        LearningGameActivityKind.fractionBuilder,
        LearningGameActivityKind.sentenceBuilder,
        LearningGameActivityKind.grammarSort,
        LearningGameActivityKind.robotRoute,
        LearningGameActivityKind.experimentMixer,
        LearningGameActivityKind.recyclingSort,
      }),
    );
    expect(
      ActivityGameRegistry.supportedKinds,
      isNot(contains(LearningGameActivityKind.unsupported)),
    );
  });
}
