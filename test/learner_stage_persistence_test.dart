import 'package:brightquest_kids/core/models/learner_stage.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('persisted learner stage', () {
    test('legacy profiles without a stage stay in School mode', () {
      final profile = ChildProfileSnapshot.fromJson(
        <String, Object?>{
          'id': 'legacy-child',
          'name': 'Legacy',
          'selectedClass': 4,
        },
      );

      expect(profile.learnerStage, LearnerStage.school);
      expect(profile.selectedClass, 4);
    });

    test('Nursery stage round-trips without inventing a fake class number',
        () async {
      final store = MemoryProgressStore();
      final controller = GameController(store: store);
      await controller.load();

      controller.setLearnerStage(LearnerStage.nursery);
      await controller.flush();

      expect(controller.learnerStage, LearnerStage.nursery);
      expect(controller.selectedClass, inInclusiveRange(3, 5));

      final raw = await store.read();
      final profiles = raw!['profiles'] as Map;
      final active = profiles[raw['activeProfileId']] as Map;
      expect(active['learnerStage'], 'nursery');
      expect((active['selectedClass'] as num).toInt(), inInclusiveRange(3, 5));

      final restored = GameController(store: store);
      await restored.load();
      expect(restored.learnerStage, LearnerStage.nursery);
      expect(restored.selectedClass, controller.selectedClass);
    });

    test('new Nursery child profiles keep an underlying valid school class',
        () async {
      final controller = GameController();
      await controller.load();

      final id = controller.createProfile(
        name: 'Nia',
        classNumber: 3,
        learnerStage: LearnerStage.nursery,
      );

      expect(id, isNotEmpty);
      expect(controller.learnerStage, LearnerStage.nursery);
      expect(controller.selectedClass, 3);
      expect(
        controller.profiles
            .singleWhere((profile) => profile.id == id)
            .learnerStage,
        LearnerStage.nursery,
      );
    });
  });
}
