import 'entitlement_models.dart';

abstract interface class StoreBillingGateway {
  String get storeName;
  bool get productionVerificationAvailable;

  Future<List<StoreProductDetails>> queryProducts(Iterable<String> productIds);
  Future<StorePurchaseResult> purchase(String productId);
  Future<List<StorePurchaseResult>> restorePurchases();
}

/// Fail-closed gateway used until a real Google Play or Microsoft Store
/// integration is configured and verified. It can never unlock a paid pack.
class LockedStoreBillingGateway implements StoreBillingGateway {
  const LockedStoreBillingGateway(
      {this.reason = 'Store billing is not configured.'});

  final String reason;

  @override
  String get storeName => 'unconfigured';

  @override
  bool get productionVerificationAvailable => false;

  @override
  Future<List<StoreProductDetails>> queryProducts(
    Iterable<String> productIds,
  ) async =>
      productIds
          .map(
            (id) => StoreProductDetails(
              productId: id,
              title: _titleFor(id),
              localizedPrice: '₹299',
              currencyCode: 'INR',
              available: false,
            ),
          )
          .toList(growable: false);

  @override
  Future<StorePurchaseResult> purchase(String productId) async =>
      StorePurchaseResult(
        productId: productId,
        state: EntitlementState.locked,
        verification: EntitlementVerification.none,
        store: storeName,
        message: reason,
      );

  @override
  Future<List<StorePurchaseResult>> restorePurchases() async =>
      const <StorePurchaseResult>[];

  String _titleFor(String id) {
    if (id.endsWith('_3')) return 'BrightQuest Class 3';
    if (id.endsWith('_4')) return 'BrightQuest Class 4';
    if (id.endsWith('_5')) return 'BrightQuest Class 5';
    return 'BrightQuest Class Pack';
  }
}

/// Deterministic gateway for unit/widget tests only. This deliberately does not
/// inspect SharedPreferences, so tests can prove local edits cannot unlock a
/// production entitlement.
class TestStoreBillingGateway implements StoreBillingGateway {
  TestStoreBillingGateway({
    Set<String>? ownedProductIds,
    this.storeName = 'test-store',
  }) : _ownedProductIds = ownedProductIds ?? <String>{};

  final Set<String> _ownedProductIds;

  @override
  final String storeName;

  @override
  bool get productionVerificationAvailable => true;

  @override
  Future<List<StoreProductDetails>> queryProducts(
    Iterable<String> productIds,
  ) async =>
      productIds
          .map(
            (id) => StoreProductDetails(
              productId: id,
              title: id.replaceAll('_', ' '),
              localizedPrice: '₹299',
              currencyCode: 'INR',
              available: true,
            ),
          )
          .toList(growable: false);

  @override
  Future<StorePurchaseResult> purchase(String productId) async {
    _ownedProductIds.add(productId);
    return _owned(productId);
  }

  @override
  Future<List<StorePurchaseResult>> restorePurchases() async =>
      _ownedProductIds.map(_owned).toList(growable: false);

  StorePurchaseResult _owned(String productId) => StorePurchaseResult(
        productId: productId,
        state: EntitlementState.owned,
        verification: EntitlementVerification.storeVerified,
        store: storeName,
        purchaseTokenFingerprint: 'test:${productId.hashCode}',
      );

  void revoke(String productId) => _ownedProductIds.remove(productId);
}
