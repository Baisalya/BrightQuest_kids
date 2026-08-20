enum EntitlementState { locked, pending, owned, revoked }

enum EntitlementVerification {
  none,
  localCacheOnly,
  storeVerified,
  backendVerified
}

class ClassEntitlement {
  const ClassEntitlement({
    required this.classNumber,
    required this.productId,
    this.state = EntitlementState.locked,
    this.verification = EntitlementVerification.none,
    this.store = 'none',
    this.lastVerifiedIso,
    this.purchaseTokenFingerprint,
  });

  final int classNumber;
  final String productId;
  final EntitlementState state;
  final EntitlementVerification verification;
  final String store;
  final String? lastVerifiedIso;
  final String? purchaseTokenFingerprint;

  /// Persisted preferences are only a cache. Production access requires a
  /// current store/backend verification signal, never a hand-edited local flag.
  bool get grantsProductionAccess =>
      state == EntitlementState.owned &&
      (verification == EntitlementVerification.storeVerified ||
          verification == EntitlementVerification.backendVerified);

  ClassEntitlement copyWith({
    EntitlementState? state,
    EntitlementVerification? verification,
    String? store,
    String? lastVerifiedIso,
    String? purchaseTokenFingerprint,
  }) =>
      ClassEntitlement(
        classNumber: classNumber,
        productId: productId,
        state: state ?? this.state,
        verification: verification ?? this.verification,
        store: store ?? this.store,
        lastVerifiedIso: lastVerifiedIso ?? this.lastVerifiedIso,
        purchaseTokenFingerprint:
            purchaseTokenFingerprint ?? this.purchaseTokenFingerprint,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'classNumber': classNumber,
        'productId': productId,
        'state': state.name,
        // Deliberately downgrade proof when serialising. Restored local data
        // must be re-verified with the originating store before it grants access.
        'verification': grantsProductionAccess
            ? EntitlementVerification.localCacheOnly.name
            : verification.name,
        'store': store,
        'lastVerifiedIso': lastVerifiedIso,
        'purchaseTokenFingerprint': purchaseTokenFingerprint,
      };

  factory ClassEntitlement.fromJson(Map<String, Object?> json) {
    final stateName = json['state'] as String?;
    final verificationName = json['verification'] as String?;
    return ClassEntitlement(
      classNumber:
          ((json['classNumber'] as num?)?.toInt() ?? 4).clamp(3, 5).toInt(),
      productId: json['productId'] as String? ?? 'unknown',
      state: EntitlementState.values.firstWhere(
        (candidate) => candidate.name == stateName,
        orElse: () => EntitlementState.locked,
      ),
      verification: EntitlementVerification.values.firstWhere(
        (candidate) => candidate.name == verificationName,
        orElse: () => EntitlementVerification.localCacheOnly,
      ),
      store: json['store'] as String? ?? 'unknown',
      lastVerifiedIso: json['lastVerifiedIso'] as String?,
      purchaseTokenFingerprint: json['purchaseTokenFingerprint'] as String?,
    );
  }
}

class StoreProductDetails {
  const StoreProductDetails({
    required this.productId,
    required this.title,
    required this.localizedPrice,
    required this.currencyCode,
    required this.available,
  });

  final String productId;
  final String title;
  final String localizedPrice;
  final String currencyCode;
  final bool available;
}

class StorePurchaseResult {
  const StorePurchaseResult({
    required this.productId,
    required this.state,
    required this.verification,
    required this.store,
    this.purchaseTokenFingerprint,
    this.message,
  });

  final String productId;
  final EntitlementState state;
  final EntitlementVerification verification;
  final String store;
  final String? purchaseTokenFingerprint;
  final String? message;
}

const classPackProductIds = <int, String>{
  3: 'brightquest_class_3',
  4: 'brightquest_class_4',
  5: 'brightquest_class_5',
};
