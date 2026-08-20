import 'dart:io';

import 'package:brightquest_kids/core/learning/diagnostic_engine.dart';
import 'package:brightquest_kids/core/learning/evidence_engine.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/learning/recommendation_engine.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

AttemptEvidence _evidence({
  required String id,
  required bool correct,
  LearningAttemptKind kind = LearningAttemptKind.diagnostic,
  int hintLevel = 0,
  int retries = 0,
  String competencyId = 'c3_math_equal_sharing_division',
}) =>
    AttemptEvidence(
      id: id,
      profileId: 'child-a',
      classNumber: 3,
      competencyId: competencyId,
      itemId: 'item-$id',
      kind: kind,
      correct: correct,
      hintLevel: hintLevel,
      retries: retries,
      responseTimeMs: 4200,
      confidence: 0.85,
      recordedAtIso: DateTime.utc(2026, 8, 20, 10).toIso8601String(),
      misconceptionId: correct ? null : 'arithmetic_error',
    );

void main() {
  group('Phase 2 diagnostic and evidence', () {
    test('one wrong answer never labels a child needs support', () {
      const engine = EvidenceEngine();
      var state = const LearningProfileState();
      state = engine.record(state, _evidence(id: '1', correct: false));
      expect(
        state.skillMastery['c3_math_equal_sharing_division']!.state,
        isNot(LearningEvidenceState.needsSupport),
      );
      state = engine.record(state, _evidence(id: '2', correct: false));
      expect(
        state.skillMastery['c3_math_equal_sharing_division']!.state,
        LearningEvidenceState.needsSupport,
      );
    });

    test(
        'diagnostic is deterministic, resumable and only selects scorable items',
        () {
      final repository = buildContentRepository();
      const engine = DiagnosticEngine(targetItemCount: 12);
      final first = engine.start(
        repository: repository,
        classNumber: 3,
        now: DateTime.utc(2026, 8, 20),
      );
      final again = engine.start(
        repository: repository,
        classNumber: 3,
        now: DateTime.utc(2026, 8, 20),
      );
      expect(first.itemIds, again.itemIds);
      expect(first.itemIds.length, lessThanOrEqualTo(12));
      expect(first.itemIds.length, greaterThanOrEqualTo(6));
      for (final id in first.itemIds) {
        final activity = repository.activityById(id)!;
        expect(activity.payload['choices'], isA<List>());
        expect(
          activity.correctResponseRule['value'] ?? activity.payload['answer'],
          isNotNull,
        );
      }
      final resumed = DiagnosticProgress.fromJson(first.toJson());
      expect(resumed.itemIds, first.itemIds);
      expect(resumed.currentIndex, first.currentIndex);
    });

    test('different evidence produces different starting recommendations', () {
      const evidence = EvidenceEngine();
      var support = const LearningProfileState();
      support = evidence.record(support, _evidence(id: 's1', correct: false));
      support = evidence.record(support, _evidence(id: 's2', correct: false));

      var ready = const LearningProfileState();
      ready = evidence.record(ready, _evidence(id: 'r1', correct: true));
      ready = evidence.record(
        ready,
        _evidence(
            id: 'r2', correct: true, kind: LearningAttemptKind.independent),
      );

      const recommender = RecommendationEngine();
      expect(
        recommender.recommend(support.skillMastery).first.state,
        LearningEvidenceState.needsSupport,
      );
      expect(
        recommender.recommend(ready.skillMastery).first.state,
        isNot(LearningEvidenceState.needsSupport),
      );
    });

    test('schema v5 store still reads the accepted Phase 1 v3 preference key',
        () {
      final source = File(
        'lib/core/persistence/shared_preferences_progress_store.dart',
      ).readAsStringSync();
      expect(source, contains("brightquest.player_snapshot.v5"));
      expect(source, contains("brightquest.player_snapshot.v3"));
      expect(source, contains("brightquest.player_snapshot.v2"));
      expect(
        source.indexOf("_decodeKey(_keyV5)"),
        lessThan(source.indexOf("_decodeKey(_legacyKeyV3)")),
      );
    });

    test(
        'schema v5 keeps learning evidence profile-isolated and migrates older profile maps',
        () {
      final snapshot = PlayerSnapshot(
        activeProfileId: 'child-a',
        profiles: <String, ChildProfileSnapshot>{
          'child-a': ChildProfileSnapshot(id: 'child-a', name: 'A'),
          'child-b': ChildProfileSnapshot(id: 'child-b', name: 'B'),
        },
      );
      snapshot.profiles['child-a']!.learning = const EvidenceEngine().record(
        snapshot.profiles['child-a']!.learning,
        _evidence(id: 'profile', correct: true),
      );
      final json = snapshot.toJson()..['schemaVersion'] = 4;
      final restored = PlayerSnapshot.fromJson(json);
      expect(restored.schemaVersion, 5);
      expect(restored.profiles['child-a']!.learning.attemptEvidence.length, 1);
      expect(restored.profiles['child-b']!.learning.attemptEvidence, isEmpty);
    });
  });
}
