class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.order,
    this.weightKg,
    this.reps,
    this.timeSeconds,
    this.distanceMeters,
    this.rpe,
    this.completedAt,
  });

  final String id;
  final String exerciseId;
  final int order;
  final double? weightKg;
  final int? reps;
  final int? timeSeconds;
  final int? distanceMeters;
  final double? rpe;
  final DateTime? completedAt;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        order: json['order'] as int,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        reps: json['reps'] as int?,
        timeSeconds: json['timeSeconds'] as int?,
        distanceMeters: json['distanceMeters'] as int?,
        rpe: (json['rpe'] as num?)?.toDouble(),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}

class Workout {
  const Workout({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.templateId,
    this.name,
    this.notes,
    this.finishedAt,
    this.sets = const [],
  });

  final String id;
  final String userId;
  final DateTime startedAt;
  final String? templateId;
  final String? name;
  final String? notes;
  final DateTime? finishedAt;
  final List<WorkoutSet> sets;

  bool get isFinished => finishedAt != null;

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        userId: json['userId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        templateId: json['templateId'] as String?,
        name: json['name'] as String?,
        notes: json['notes'] as String?,
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
        sets: (json['sets'] as List<dynamic>? ?? [])
            .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutListPage {
  const WorkoutListPage({required this.items, this.nextCursor});

  final List<Workout> items;
  final String? nextCursor;

  factory WorkoutListPage.fromJson(Map<String, dynamic> json) => WorkoutListPage(
        items: (json['items'] as List<dynamic>)
            .map((e) => Workout.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}
