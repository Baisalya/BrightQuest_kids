import '../curriculum/content_contract.dart';

class LearningBlueprint {
  const LearningBlueprint({
    required this.competencyId,
    required this.classNumber,
    required this.subject,
    required this.unitId,
    required this.title,
    required this.objective,
    required this.teach,
    required this.workedExample,
    required this.guidedPrompt,
    required this.guidedHints,
    required this.independentSourceActivityIds,
    required this.independentFallbackPrompt,
    required this.transferPrompt,
    required this.transferRequiresUnseenWording,
    required this.transferHintAllowed,
    required this.reviewPrompt,
    required this.interactionSuggested,
    required this.narrationText,
    required this.locale,
    required this.review,
  });

  final String competencyId;
  final int classNumber;
  final String subject;
  final String unitId;
  final String title;
  final String objective;
  final String teach;
  final String workedExample;
  final String guidedPrompt;
  final List<String> guidedHints;
  final List<String> independentSourceActivityIds;
  final String independentFallbackPrompt;
  final String transferPrompt;
  final bool transferRequiresUnseenWording;
  final bool transferHintAllowed;
  final String reviewPrompt;
  final String interactionSuggested;
  final String narrationText;
  final String locale;
  final ReviewMetadata review;

  factory LearningBlueprint.fromJson(Map<String, dynamic> json) {
    final guided = Map<String, dynamic>.from(json['guidedTry'] as Map);
    final independent =
        Map<String, dynamic>.from(json['independentPractice'] as Map);
    final transfer = Map<String, dynamic>.from(json['masteryTransfer'] as Map);
    return LearningBlueprint(
      competencyId: json['competencyId'] as String,
      classNumber: json['classNumber'] as int,
      subject: json['subject'] as String,
      unitId: json['unitId'] as String,
      title: json['title'] as String,
      objective: json['objective'] as String,
      teach: json['teach'] as String,
      workedExample: json['workedExample'] as String,
      guidedPrompt: guided['prompt'] as String,
      guidedHints: <String>[
        guided['hintLevel1'] as String,
        guided['hintLevel2'] as String,
      ],
      independentSourceActivityIds:
          List<String>.from(independent['sourceActivityIds'] as List),
      independentFallbackPrompt: independent['fallbackPrompt'] as String,
      transferPrompt: transfer['prompt'] as String,
      transferRequiresUnseenWording: transfer['requireUnseenWording'] as bool,
      transferHintAllowed: transfer['hintAllowed'] as bool,
      reviewPrompt: json['reviewPrompt'] as String,
      interactionSuggested: json['interactionSuggested'] as String,
      narrationText: json['narrationText'] as String,
      locale: json['locale'] as String,
      review: ReviewMetadata.fromJson(
        Map<String, dynamic>.from(json['review'] as Map),
      ),
    );
  }
}

class LearningBlueprintPack {
  const LearningBlueprintPack({
    required this.schemaVersion,
    required this.classNumber,
    required this.status,
    required this.purpose,
    required this.competencyCount,
    required this.blueprints,
  });

  final int schemaVersion;
  final int classNumber;
  final String status;
  final String purpose;
  final int competencyCount;
  final List<LearningBlueprint> blueprints;

  factory LearningBlueprintPack.fromJson(Map<String, dynamic> json) =>
      LearningBlueprintPack(
        schemaVersion: json['schemaVersion'] as int,
        classNumber: json['classNumber'] as int,
        status: json['status'] as String,
        purpose: json['purpose'] as String,
        competencyCount: json['competencyCount'] as int,
        blueprints: (json['blueprints'] as List)
            .map(
              (value) => LearningBlueprint.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList(growable: false),
      );
}
