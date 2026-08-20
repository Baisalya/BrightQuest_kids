import '../curriculum/content_contract.dart';

class AppliedMissionDefinition {
  const AppliedMissionDefinition({
    required this.id,
    required this.classNumber,
    required this.subject,
    required this.title,
    required this.brief,
    required this.competencyIds,
    required this.reflection,
    this.safeLocalInputOnly = true,
  });

  final String id;
  final int classNumber;
  final String subject;
  final String title;
  final String brief;
  final List<String> competencyIds;
  final String reflection;
  final bool safeLocalInputOnly;
}

class AppliedMissionCatalog {
  const AppliedMissionCatalog();

  List<AppliedMissionDefinition> forClass(
      CurriculumContract curriculum, int classNumber) {
    final classPack = curriculum.classPack(classNumber);
    if (classPack == null) return const <AppliedMissionDefinition>[];
    final bySubject = <String, List<CompetencyContract>>{};
    for (final competency in classPack.competencies) {
      bySubject
          .putIfAbsent(competency.subject, () => <CompetencyContract>[])
          .add(competency);
    }

    final result = <AppliedMissionDefinition>[];
    final subjects = bySubject.keys.toList()..sort();
    for (final subject in subjects) {
      final competencies = bySubject[subject]!;
      if (competencies.length < 2) continue;
      for (var index = 0; index < 3; index += 1) {
        final first = competencies[(index * 2) % competencies.length];
        final second = competencies[(index * 2 + 1) % competencies.length];
        result.add(
          AppliedMissionDefinition(
            id: 'c${classNumber}_${subject}_mission_${index + 1}',
            classNumber: classNumber,
            subject: subject,
            title: _title(subject, index),
            brief: _brief(subject, index, first.objective, second.objective),
            competencyIds: <String>[first.id, second.id],
            reflection:
                'After the mission, explain which strategy helped, what evidence checked the result, and what you would change next time.',
          ),
        );
      }
    }
    return List<AppliedMissionDefinition>.unmodifiable(result);
  }

  String _title(String subject, int index) {
    final titles = <String, List<String>>{
      'maths': <String>[
        'Market Budget Mission',
        'Sharing Plan Mission',
        'Measure & Plan Mission'
      ],
      'english': <String>[
        'Story Evidence Mission',
        'Editor Mission',
        'Explain It Clearly'
      ],
      'science': <String>[
        'Claim Investigator',
        'Predict–Observe–Explain',
        'Evidence Lab'
      ],
      'evs': <String>[
        'Waste Audit',
        'Resource Rescue',
        'Healthy Community Plan'
      ],
      'social': <String>[
        'Map Route Mission',
        'Place Clue Mission',
        'Journey Planner'
      ],
      'coding': <String>[
        'Robot Debug Mission',
        'Efficient Route Mission',
        'Pattern Programmer'
      ],
    };
    final values = titles[subject] ??
        <String>['Applied Mission', 'Evidence Mission', 'Transfer Mission'];
    return values[index % values.length];
  }

  String _brief(
    String subject,
    int index,
    String firstObjective,
    String secondObjective,
  ) {
    final context = switch (subject) {
      'maths' =>
        'Solve a realistic planning problem and check the result in a second way.',
      'english' =>
        'Read or build a short text, then justify a language choice with evidence.',
      'science' =>
        'Make a prediction, inspect observations, and explain what the evidence supports.',
      'evs' =>
        'Use a safe household or community scenario to make and justify a responsible choice.',
      'social' =>
        'Plan a route or interpret place clues using direction and map reasoning.',
      'coding' =>
        'Trace a robot algorithm, find an error, correct it, and explain why the fix works.',
      _ =>
        'Combine two skills in one applied problem and explain the reasoning.',
    };
    return '$context Skill 1: $firstObjective Skill 2: $secondObjective';
  }
}
