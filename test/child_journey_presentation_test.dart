import 'package:brightquest_kids/features/progress/child_journey_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('child journey labels stay qualitative and encouraging', () {
    expect(
      describeChildJourney(completed: 0, total: 12).label,
      'Ready to explore',
    );
    expect(
      describeChildJourney(completed: 2, total: 12).label,
      'Getting started',
    );
    expect(
      describeChildJourney(completed: 6, total: 12).label,
      'Growing strong',
    );
    expect(
      describeChildJourney(completed: 10, total: 12).label,
      'Almost there',
    );
    expect(
      describeChildJourney(completed: 12, total: 12).label,
      'World complete',
    );
  });

  test('invalid or empty totals never expose technical progress states', () {
    final view = describeChildJourney(completed: 0, total: 0);

    expect(view.label, 'Ready to explore');
    expect(view.message, isNotEmpty);
    expect(view.message.toLowerCase(), isNot(contains('accuracy')));
    expect(view.message.toLowerCase(), isNot(contains('mastery')));
    expect(view.message.toLowerCase(), isNot(contains('difficulty')));
  });
}
