import 'package:brightquest_kids/features/nursery/nursery_asset_reaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nurseryReactionForWord', () {
    test('maps key Nursery examples to purposeful reactions', () {
      expect(nurseryReactionForWord('Apple'), NurseryAssetReactionKind.pop);
      expect(nurseryReactionForWord('Dog'), NurseryAssetReactionKind.wag);
      expect(nurseryReactionForWord('Drum'), NurseryAssetReactionKind.drumHit);
      expect(nurseryReactionForWord('Aeroplane'), NurseryAssetReactionKind.fly);
      expect(nurseryReactionForWord('Ball'), NurseryAssetReactionKind.bounce);
      expect(nurseryReactionForWord('Tree'), NurseryAssetReactionKind.sway);
    });

    test('normalizes case and whitespace and safely defaults to pop', () {
      expect(nurseryReactionForWord('  DOG '), NurseryAssetReactionKind.wag);
      expect(nurseryReactionForWord('Unknown'), NurseryAssetReactionKind.pop);
    });
  });

  testWidgets('reduced motion exposes a static picture semantic',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 180,
            child: NurseryAnimatedAsset(
              assetPath: '',
              word: 'Dog',
              reducedMotion: true,
              fallback: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Dog picture'), findsOneWidget);
    expect(find.bySemanticsLabel('Dog picture. Tap to animate.'), findsNothing);
  });

  testWidgets('motion-enabled picture can be tapped to replay', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 180,
            child: NurseryAnimatedAsset(
              assetPath: '',
              word: 'Drum',
              reducedMotion: false,
              fallback: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

    final target = find.bySemanticsLabel('Drum picture. Tap to animate.');
    expect(target, findsOneWidget);
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
