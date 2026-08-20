import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/content_repository.dart';
import '../../core/entitlements/entitlement_models.dart';

class ClassPackScreen extends StatefulWidget {
  const ClassPackScreen({super.key});

  @override
  State<ClassPackScreen> createState() => _ClassPackScreenState();
}

class _ClassPackScreenState extends State<ClassPackScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final entitlements = BrightQuestScope.entitlementsOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Class packs')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Each class pack is planned as a permanent one-time ₹299 purchase. Purchase and restore controls live only in this parent-gated area. BrightQuest has no subscription and no child-facing paywall.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final classNumber in const <int>[3, 4, 5])
            Builder(
              builder: (context) {
                final pack = repository.packForClass(classNumber);
                final cached = controller.entitlementCache[classNumber];
                final verified = entitlements.entitlementFor(classNumber);
                final owned = entitlements.hasProductionAccess(classNumber);
                final commerciallyReady = pack.commercial.paidEligibility;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class $classNumber',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${pack.commercial.priceInr} • permanent one-time class entitlement',
                        ),
                        Text(
                          '${pack.commercial.freeSampleActivityIds.length} free demo activities (one per game)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${pack.activities.length} authored/migrated activities + ${ContentRepository.generatedPracticeVariantCountPerClass} deterministic practice variants',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          owned
                              ? 'Ownership verified through ${verified.store}.'
                              : cached != null
                                  ? 'A local ownership cache exists, but it does not unlock production content until the store verifies it again.'
                                  : 'Not owned / not verified.',
                        ),
                        if (!commerciallyReady)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Purchasing is locked because curriculum/content review and release gates are still pending.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _busy ||
                                  !commerciallyReady ||
                                  !entitlements.productionVerificationAvailable
                              ? null
                              : () => _purchase(classNumber),
                          child: Text(
                            entitlements.productionVerificationAvailable
                                ? 'Buy Class $classNumber'
                                : 'Store connection required',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy || !entitlements.productionVerificationAvailable
                ? null
                : _restore,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Restore purchases'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Android and Windows ownership are restored through the store where the pack was purchased. Cross-platform entitlement sharing requires a future secure parent account/backend verification service.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(int classNumber) async {
    setState(() => _busy = true);
    final controller = BrightQuestScope.of(context);
    final service = BrightQuestScope.entitlementsOf(context);
    final entitlement = await service.purchaseClass(classNumber);
    if (entitlement.grantsProductionAccess) {
      controller.cacheEntitlement(entitlement);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          entitlement.state == EntitlementState.owned
              ? 'Class $classNumber ownership verified.'
              : 'Purchase was not completed or verified.',
        ),
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final controller = BrightQuestScope.of(context);
    final restored = await BrightQuestScope.entitlementsOf(context).restore();
    for (final entitlement in restored) {
      if (entitlement.grantsProductionAccess) {
        controller.cacheEntitlement(entitlement);
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verified ${restored.length} class pack(s).')),
    );
  }
}
