class ProgramExercise {
  const ProgramExercise({
    required this.exerciseId,
    required this.order,
    required this.targetSets,
    required this.targetReps,
    required this.targetTimeSeconds,
    required this.restSeconds,
  });

  final String exerciseId;
  final int order;
  final int targetSets;
  final int? targetReps;
  final int? targetTimeSeconds;
  final int restSeconds;

  factory ProgramExercise.fromJson(Map<String, dynamic> json) => ProgramExercise(
        exerciseId: json['exerciseId'] as String,
        order: json['order'] as int,
        targetSets: json['targetSets'] as int,
        targetReps: json['targetReps'] as int?,
        targetTimeSeconds: json['targetTimeSeconds'] as int?,
        restSeconds: json['restSeconds'] as int,
      );
}

class ProgramDay {
  const ProgramDay({
    required this.id,
    required this.dayIndex,
    required this.name,
    required this.exercises,
  });

  final String id;
  final int dayIndex;
  final String name;
  final List<ProgramExercise> exercises;

  factory ProgramDay.fromJson(Map<String, dynamic> json) => ProgramDay(
        id: json['id'] as String,
        dayIndex: json['dayIndex'] as int,
        name: json['name'] as String,
        exercises: (json['exercises'] as List<dynamic>? ?? const [])
            .map((e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Program {
  const Program({
    required this.id,
    required this.name,
    required this.goal,
    required this.level,
    required this.equipment,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.targetMuscles,
    required this.active,
    required this.createdAt,
    required this.days,
  });

  final String id;
  final String name;
  final String goal;
  final String level;
  final String equipment;
  final int daysPerWeek;
  final int sessionMinutes;
  final List<String> targetMuscles;
  final bool active;
  final DateTime createdAt;
  final List<ProgramDay> days;

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] as String,
        name: json['name'] as String,
        goal: json['goal'] as String,
        level: json['level'] as String,
        equipment: json['equipment'] as String,
        daysPerWeek: json['daysPerWeek'] as int,
        sessionMinutes: json['sessionMinutes'] as int,
        targetMuscles: (json['targetMuscles'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        days: (json['days'] as List<dynamic>? ?? const [])
            .map((e) => ProgramDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ProgramGenerateInput {
  const ProgramGenerateInput({
    required this.goal,
    required this.level,
    required this.equipment,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.targetMuscles,
    this.name,
  });

  final String goal;
  final String level;
  final String equipment;
  final int daysPerWeek;
  final int sessionMinutes;
  final List<String> targetMuscles;
  final String? name;

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'level': level,
        'equipment': equipment,
        'daysPerWeek': daysPerWeek,
        'sessionMinutes': sessionMinutes,
        'targetMuscles': targetMuscles,
        if (name != null) 'name': name,
      };
}
