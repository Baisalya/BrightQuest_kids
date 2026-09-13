import '../capabilities/learner_capability_boundary.dart';
import 'entitlement_models.dart';
import 'store_billing_gateway.dart';

class EntitlementService {
  EntitlementService({StoreBillingGateway? gateway})
      : _gateway = gateway ?? const LockedStoreBillingGateway();

  final StoreBillingGateway _gateway;
  final Map<int, ClassEntitlement> _verifiedSession = <int, ClassEntitlement>{};

  StoreBillingGateway get gateway => _gateway;
  bool get productionVerificationAvailable =>
      _gateway.productionVerificationAvailable;

  bool hasProductionAccess(int classNumber) =>
      _verifiedSession[classNumber]?.grantsProductionAccess ?? false;

  ClassEntitlement entitlementFor(int classNumber) =>
      _verifiedSession[classNumber] ??
      ClassEntitlement(
        classNumber: classNumber,
        productId: classPackProductIds[classNumber] ?? 'unknown',
      );

  Future<List<StoreProductDetails>> productDetails() =>
      _gateway.queryProducts(classPackProductIds.values);

  Future<ClassEntitlement> purchaseClass(int classNumber) async {
    LearnerCapabilityBoundary.requireSupportedSchoolClass(classNumber);
    final productId = classPackProductIds[classNumber];
    if (productId == null) {
      throw StateError(
        'Missing product ID for supported Class $classNumber.',
      );
    }
    final result = await _gateway.purchase(productId);
    final entitlement = _fromResult(classNumber, result);
    _verifiedSession[classNumber] = entitlement;
    return entitlement;
  }

  Future<List<ClassEntitlement>> restore() async {
    final results = await _gateway.restorePurchases();
    final restored = <ClassEntitlement>[];
    for (final result in results) {
      final entry = classPackProductIds.entries
          .where((candidate) => candidate.value == result.productId)
          .toList();
      if (entry.isEmpty) continue;
      final entitlement = _fromResult(entry.first.key, result);
      _verifiedSession[entry.first.key] = entitlement;
      restored.add(entitlement);
    }
    return List<ClassEntitlement>.unmodifiable(restored);
  }

  void applyRevocation(int classNumber) {
    final current = entitlementFor(classNumber);
    _verifiedSession[classNumber] = current.copyWith(
      state: EntitlementState.revoked,
      verification: EntitlementVerification.storeVerified,
      lastVerifiedIso: DateTime.now().toIso8601String(),
    );
  }

  /// Local snapshots may be displayed as a cache in the parent area, but they
  /// are intentionally not copied into the verified session map.
  void observeLocalCache(Map<int, ClassEntitlement> cached) {}

  ClassEntitlement _fromResult(
    int classNumber,
    StorePurchaseResult result,
  ) =>
      ClassEntitlement(
        classNumber: classNumber,
        productId: result.productId,
        state: result.state,
        verification: result.verification,
        store: result.store,
        lastVerifiedIso: DateTime.now().toIso8601String(),
        purchaseTokenFingerprint: result.purchaseTokenFingerprint,
      );
}
