class ChildJourneyPresentation {
  const ChildJourneyPresentation({
    required this.label,
    required this.message,
  });

  final String label;
  final String message;
}

ChildJourneyPresentation describeChildJourney({
  required int completed,
  required int total,
}) {
  if (total <= 0 || completed <= 0) {
    return const ChildJourneyPresentation(
      label: 'Ready to explore',
      message: 'Your first quest is waiting on Today.',
    );
  }

  if (completed >= total) {
    return const ChildJourneyPresentation(
      label: 'World complete',
      message: 'You explored every quest in this world!',
    );
  }

  final ratio = completed / total;
  if (ratio < .34) {
    return const ChildJourneyPresentation(
      label: 'Getting started',
      message: 'A bright new journey is growing.',
    );
  }
  if (ratio < .75) {
    return const ChildJourneyPresentation(
      label: 'Growing strong',
      message: 'You are building this world one quest at a time.',
    );
  }

  return const ChildJourneyPresentation(
    label: 'Almost there',
    message: 'Only a few quests remain in this world.',
  );
}
