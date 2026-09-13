import 'package:brightquest_kids/core/entitlements/entitlement_models.dart';
import 'package:brightquest_kids/core/entitlements/entitlement_service.dart';
import 'package:brightquest_kids/core/models/learner_stage.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> profileJson({
    String id = 'child-a',
    int selectedClass = 4,
    String? learnerStage,
  }) {
    return <String, Object?>{
      'id': id,
      'name': 'Explorer A',
      'selectedClass': selectedClass,
      if (learnerStage != null) 'learnerStage': learnerStage,
      'coins': 321,
      'stars': 12,
      'xp': 456,
      'unlockedRewards': <String>['cosmetic-a'],
      'equippedCosmetics': <String, String>{'math_market': 'cosmetic-a'},
    };
  }

  test('missing learnerStage migrates to School without losing progress', () {
    final profile = ChildProfileSnapshot.fromJson(profileJson());

    expect(profile.learnerStage, LearnerStage.school);
    expect(profile.selectedClass, 4);
    expect(profile.coins, 321);
    expect(profile.stars, 12);
    expect(profile.xp, 456);
    expect(profile.unlockedRewards, contains('cosmetic-a'));
  });

  test('Nursery stage and remembered School class survive JSON round-trip', () {
    final first = ChildProfileSnapshot.fromJson(
      profileJson(selectedClass: 5, learnerStage: 'nursery'),
    );
    final restored = ChildProfileSnapshot.fromJson(first.toJson());

    expect(restored.learnerStage, LearnerStage.nursery);
    expect(restored.selectedClass, 5);
    expect(restored.coins, 321);
  });

  test('unsupported persisted School class normalizes to safe Class 4', () {
    for (final value in <int>[0, 1, 2, 6, 99]) {
      final restored =
          ChildProfileSnapshot.fromJson(profileJson(selectedClass: value));
      expect(restored.selectedClass, 4, reason: 'stored class $value');
    }

    for (final value in <int>[3, 4, 5]) {
      final restored =
          ChildProfileSnapshot.fromJson(profileJson(selectedClass: value));
      expect(restored.selectedClass, value);
    }
  });

  test('persisted profile map key becomes authoritative profile identity', () {
    final snapshot = PlayerSnapshot.fromJson(<String, Object?>{
      'schemaVersion': 5,
      'activeProfileId': 'map-child',
      'profiles': <String, Object?>{
        'map-child': profileJson(id: 'stale-embedded-id'),
      },
    });

    expect(snapshot.activeProfileId, 'map-child');
    expect(snapshot.activeProfile.id, 'map-child');
    expect(snapshot.profiles.keys, contains('map-child'));
    expect(snapshot.profiles['map-child']?.id, 'map-child');
  });

  test('invalid active profile pointer repairs to an existing profile', () {
    final snapshot = PlayerSnapshot.fromJson(<String, Object?>{
      'schemaVersion': 5,
      'activeProfileId': 'missing-child',
      'profiles': <String, Object?>{
        'child-a': profileJson(id: 'child-a'),
        'child-b': profileJson(id: 'child-b', selectedClass: 5),
      },
    });

    expect(snapshot.profiles, isNotEmpty);
    expect(snapshot.profiles.containsKey(snapshot.activeProfileId), isTrue);
    expect(snapshot.activeProfile.id, snapshot.activeProfileId);
  });

  test('malformed entitlement cache identity is dropped on restore', () {
    final snapshot = PlayerSnapshot.fromJson(<String, Object?>{
      'schemaVersion': 6,
      'activeProfileId': 'child-a',
      'profiles': <String, Object?>{
        'child-a': profileJson(),
      },
      'entitlementCache': <String, Object?>{
        '3': <String, Object?>{
          'classNumber': 5,
          'productId': 'mismatched-cache',
          'state': EntitlementState.owned.name,
          'verification': EntitlementVerification.storeVerified.name,
        },
        '5': <String, Object?>{
          'classNumber': 5,
          'productId': 'valid-cache',
          'state': EntitlementState.owned.name,
          'verification': EntitlementVerification.storeVerified.name,
        },
        '6': <String, Object?>{
          'classNumber': 5,
          'productId': 'unsupported-key',
          'state': EntitlementState.owned.name,
          'verification': EntitlementVerification.storeVerified.name,
        },
      },
    });

    expect(snapshot.entitlementCache.keys, <int>[5]);
    expect(snapshot.entitlementCache[5]?.productId, 'valid-cache');
  });

  test('legacy single-child root migrates into the v6 profile container', () {
    final snapshot = PlayerSnapshot.fromJson(<String, Object?>{
      'selectedClass': 3,
      'coins': 654,
      'stars': 7,
      'xp': 222,
    });

    expect(snapshot.schemaVersion, 6);
    expect(snapshot.activeProfileId, 'child-1');
    expect(snapshot.profiles.keys, <String>['child-1']);
    expect(snapshot.activeProfile.selectedClass, 3);
    expect(snapshot.activeProfile.coins, 654);
    expect(snapshot.activeProfile.stars, 7);
    expect(snapshot.activeProfile.xp, 222);
    expect(snapshot.activeProfile.learnerStage, LearnerStage.school);
  });

  test('serialized verified entitlement is downgraded to local cache proof',
      () {
    final entitlement = ClassEntitlement(
      classNumber: 4,
      productId: 'brightquest_class_4',
      state: EntitlementState.owned,
      verification: EntitlementVerification.storeVerified,
      store: 'test-store',
    );

    final restored = ClassEntitlement.fromJson(entitlement.toJson());

    expect(restored.state, EntitlementState.owned);
    expect(
      restored.verification,
      EntitlementVerification.localCacheOnly,
    );
    expect(restored.grantsProductionAccess, isFalse);
  });

  test('local entitlement cache never becomes production access authority', () {
    final service = EntitlementService();
    final cache = <int, ClassEntitlement>{
      3: ClassEntitlement(
        classNumber: 3,
        productId: 'cached-only',
        state: EntitlementState.owned,
        verification: EntitlementVerification.storeVerified,
      ),
    };

    service.observeLocalCache(cache);

    expect(service.hasProductionAccess(3), isFalse);
  });
}
