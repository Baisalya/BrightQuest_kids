import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/entitlements/entitlement_models.dart';
import 'package:brightquest_kids/core/entitlements/entitlement_service.dart';
import 'package:brightquest_kids/core/entitlements/store_billing_gateway.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8 language and accessibility safeguards', () {
    test('learning preferences default to English India with visible captions',
        () {
      const learning = LearningProfileState();
      expect(learning.localeCode, 'en-IN');
      expect(learning.captionsEnabled, isTrue);
      expect(learning.dyslexiaFriendlySpacing, isFalse);
    });

    test('meaningful audio cues have visible text equivalents', () {
      final json = Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/shared/audio_transcripts.json')
              .readAsStringSync(),
        ) as Map,
      );
      final cues = Map<String, dynamic>.from(json['cues'] as Map);
      for (final cue in <String>[
        'levelStart',
        'hint',
        'correct',
        'wrong',
        'unlock',
        'complete',
      ]) {
        expect((cues[cue] as String).trim(), isNotEmpty);
      }
    });

    test('Windows crash-isolation decisions remain intact', () {
      final registrant = File('windows/flutter/generated_plugin_registrant.cc')
          .readAsStringSync();
      final main = File('lib/main.dart').readAsStringSync();
      final shell = File('lib/app/brightquest_app.dart').readAsStringSync();
      expect(registrant.toLowerCase(), isNot(contains('flutter_tts')));
      expect(main, contains('ExcludeSemantics'));
      expect(main, contains('BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY'));
      expect(shell, isNot(contains('IndexedStack')));
    });
  });

  group('Phase 9 fail-closed entitlements', () {
    test('product IDs remain stable and one per class', () {
      expect(classPackProductIds, <int, String>{
        3: 'brightquest_class_3',
        4: 'brightquest_class_4',
        5: 'brightquest_class_5',
      });
    });

    test('persisted local entitlement can never be production proof', () {
      const verified = ClassEntitlement(
        classNumber: 3,
        productId: 'brightquest_class_3',
        state: EntitlementState.owned,
        verification: EntitlementVerification.storeVerified,
        store: 'test-store',
      );
      expect(verified.grantsProductionAccess, isTrue);
      final restored = ClassEntitlement.fromJson(verified.toJson());
      expect(restored.state, EntitlementState.owned);
      expect(restored.verification, EntitlementVerification.localCacheOnly);
      expect(restored.grantsProductionAccess, isFalse);
    });

    test('verified test-store purchase and restore work without local flags',
        () async {
      final gateway = TestStoreBillingGateway();
      final service = EntitlementService(gateway: gateway);
      expect(service.hasProductionAccess(4), isFalse);
      final purchased = await service.purchaseClass(4);
      expect(purchased.grantsProductionAccess, isTrue);
      expect(service.hasProductionAccess(4), isTrue);

      final restoredService = EntitlementService(gateway: gateway);
      expect(restoredService.hasProductionAccess(4), isFalse);
      final restored = await restoredService.restore();
      expect(restored.single.classNumber, 4);
      expect(restoredService.hasProductionAccess(4), isTrue);
      restoredService.applyRevocation(4);
      expect(restoredService.hasProductionAccess(4), isFalse);
    });
  });

  group('Phase 10 static child-safety release contract', () {
    test('shipping manifests do not request advertising ID', () {
      final manifests = Directory('android')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('AndroidManifest.xml'));
      for (final manifest in manifests) {
        expect(
          manifest.readAsStringSync(),
          isNot(contains('com.google.android.gms.permission.AD_ID')),
          reason: manifest.path,
        );
      }
    });

    test('privacy and release-gate documents are present', () {
      for (final path in <String>[
        'PRIVACY_POLICY.md',
        'docs/RELEASE_QA_CHECKLIST.md',
        'docs/CONTENT_PILOT_PROTOCOL.md',
        'docs/STORE_BILLING_INTEGRATION.md',
        'docs/WINDOWS_ACCESSIBILITY_SAFETY.md',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });
}
