import 'package:brightquest_kids/widgets/bright_adaptive.dart';
import 'package:brightquest_kids/widgets/bright_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all viewport classes reserve a 48dp minimum interactive target', () {
    for (final size in const <Size>[
      Size(320, 568),
      Size(390, 700),
      Size(700, 800),
      Size(1024, 600),
      Size(1440, 900),
    ]) {
      expect(BrightLayoutMetrics.fromSize(size).minimumTapTarget, 48);
    }
  });

  test('large text increases the minimum readable grid tile width', () {
    final normal = brightReadableMinTileWidth(
      baseMinWidth: 250,
      textScale: 1,
    );
    final large = brightReadableMinTileWidth(
      baseMinWidth: 250,
      textScale: 2,
    );

    expect(normal, 250);
    expect(large, greaterThan(normal));
    expect(large, 337.5);
  });

  testWidgets('large text makes width-based layouts stack early',
      (tester) async {
    late bool shouldStack;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(900, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: Builder(
            builder: (context) {
              shouldStack = brightShouldStackForReadability(
                context: context,
                availableWidth: 900,
                compactWidth: 620,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(shouldStack, isTrue);
  });

  testWidgets('adaptive grid reduces columns when readable text gets large',
      (tester) async {
    Future<List<double>> tileWidths(double textScale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(800, 600),
              textScaler: TextScaler.linear(textScale),
            ),
            child: const SizedBox(
              width: 800,
              child: BrightAdaptiveGrid(
                minChildWidth: 240,
                maxColumns: 4,
                spacing: 10,
                children: [
                  SizedBox(key: Key('tile_1'), height: 40),
                  SizedBox(key: Key('tile_2'), height: 40),
                  SizedBox(key: Key('tile_3'), height: 40),
                  SizedBox(key: Key('tile_4'), height: 40),
                ],
              ),
            ),
          ),
        ),
      );

      return <double>[
        tester.getSize(find.byKey(const Key('tile_1'))).width,
        tester.getSize(find.byKey(const Key('tile_2'))).width,
      ];
    }

    final normal = await tileWidths(1);
    final large = await tileWidths(2);

    expect(large.first, greaterThan(normal.first));
    expect(large[1], greaterThan(normal[1]));
  });
}
