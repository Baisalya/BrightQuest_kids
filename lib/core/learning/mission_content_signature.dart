import '../content/content_activity.dart';
import 'gameplay_activity_models.dart';

/// Canonical, child-visible content identity shared by Learning World,
/// Endless Practice, Skill Studio and diagnostic rotation.
///
/// This deliberately does not inspect or persist answers. The normalized
/// prompt is advisory selection metadata only; correctness remains owned by the
/// authored response rule and content repository.
String missionContentFingerprint(String prompt) =>
    prompt.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String missionActivityFingerprint(ContentActivity activity) =>
    missionContentFingerprint(activity.prompt);

/// Structural family identity built from authored metadata plus the existing
/// interaction resolver. It lets the selector rotate mission shape without
/// inventing relationships from prompt wording.
String missionArchetypeId(
  ContentActivity activity,
  LearningGameActivitySpec spec,
) {
  final responseRuleType =
      activity.correctResponseRule['type']?.toString() ?? 'unknown';
  return <String>[
    activity.gameId,
    activity.topicId,
    activity.activityType,
    responseRuleType,
    spec.mechanic.name,
  ].join(':');
}
