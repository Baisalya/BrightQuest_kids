import 'package:brightquest_kids/app/brightquest_app.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/widgets/bright_illustrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('visual identity renders on compact Android-sized window', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();

    expect(find.byType(BrightQuestLogo), findsWidgets);
    expect(find.byType(BrightLionMascot), findsOneWidget);
    expect(find.text('Choose Your Adventure!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visual identity renders on large Windows-sized window', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(BrightQuestApp(controller: GameController()));
    await tester.pumpAndSettle();

    expect(find.byType(BrightQuestLogo), findsOneWidget);
    expect(find.byType(BrightLionMascot), findsOneWidget);
    expect(find.text('Choose Your Adventure!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all illustrated game scenes render without layout exceptions', (tester) async {
    const ids = <String>[
      'math_market',
      'fraction_pizza',
      'science_lab',
      'story_builder',
      'grammar_puzzle',
      'map_quest',
      'coding_maze',
      'recycling_challenge',
      'rewards_room',
    ];

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final id in ids)
                  SizedBox(width: 250, child: BrightGameScene(gameId: id)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BrightGameScene), findsNWidgets(ids.length));
    expect(tester.takeException(), isNull);
  });
}
