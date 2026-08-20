import 'dart:convert';

import 'content_activity.dart';

class ContentDuplicateGroup {
  const ContentDuplicateGroup({
    required this.fingerprint,
    required this.activities,
  });

  final String fingerprint;
  final List<ContentActivity> activities;
}

String contentFingerprint(ContentActivity activity) {
  final prompt = activity.prompt
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  return '${activity.gameId}|$prompt|${_canonical(activity.correctResponseRule)}';
}

List<ContentDuplicateGroup> findDuplicateContentGroups(
  Iterable<ContentActivity> activities,
) {
  final byFingerprint = <String, List<ContentActivity>>{};
  for (final activity in activities) {
    final fingerprint = contentFingerprint(activity);
    byFingerprint
        .putIfAbsent(fingerprint, () => <ContentActivity>[])
        .add(activity);
  }
  final groups = byFingerprint.entries
      .where((entry) => entry.value.length > 1)
      .map(
        (entry) => ContentDuplicateGroup(
          fingerprint: entry.key,
          activities: List<ContentActivity>.unmodifiable(entry.value),
        ),
      )
      .toList();
  groups.sort((a, b) => a.fingerprint.compareTo(b.fingerprint));
  return List<ContentDuplicateGroup>.unmodifiable(groups);
}

String _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return '{${keys.map((key) => '$key:${_canonical(value[key])}').join(',')}}';
  }
  if (value is Iterable) {
    return '[${value.map(_canonical).join(',')}]';
  }
  return jsonEncode(value);
}
