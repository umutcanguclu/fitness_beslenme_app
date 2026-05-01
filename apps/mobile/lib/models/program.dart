import 'exercise.dart';

class TrainingProgram {
  final String id;
  final String? playerId;
  final String? teamId;
  final DateTime weekStartDate;
  final int? matchDayOfWeek;
  final String microcycleType;
  final String generatedBy;
  final List<TrainingSession> sessions;
  final DateTime createdAt;

  const TrainingProgram({
    required this.id,
    this.playerId,
    this.teamId,
    required this.weekStartDate,
    this.matchDayOfWeek,
    required this.microcycleType,
    required this.generatedBy,
    required this.sessions,
    required this.createdAt,
  });

  factory TrainingProgram.fromJson(Map<String, dynamic> json) {
    final sessions = (json['sessions'] as List?)
            ?.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <TrainingSession>[];
    sessions.sort((a, b) => a.date.compareTo(b.date));
    return TrainingProgram(
      id: json['id'] as String,
      playerId: json['playerId'] as String?,
      teamId: json['teamId'] as String?,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      matchDayOfWeek: json['matchDayOfWeek'] as int?,
      microcycleType: (json['microcycleType'] as String?) ?? 'match_week',
      generatedBy: (json['generatedBy'] as String?) ?? 'rule_engine_v1',
      sessions: sessions,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TrainingSession {
  final String id;
  final String programId;
  final DateTime date;
  final String type;     // 'team' | 'individual' | 'position_group' | 'recovery'
  final String category; // training category
  final int durationMinutes;
  final int intensity;   // 1-5
  final String? notes;
  final List<SessionExercise> exercises;
  final List<SessionLog> logs;

  const TrainingSession({
    required this.id,
    required this.programId,
    required this.date,
    required this.type,
    required this.category,
    required this.durationMinutes,
    required this.intensity,
    this.notes,
    required this.exercises,
    required this.logs,
  });

  bool get isOff => category == 'recovery' && exercises.isEmpty;

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final exercises = (json['exercises'] as List?)
            ?.map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <SessionExercise>[];
    exercises.sort((a, b) => a.order.compareTo(b.order));
    final logs = (json['logs'] as List?)
            ?.map((e) => SessionLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <SessionLog>[];
    return TrainingSession(
      id: json['id'] as String,
      programId: json['programId'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      category: json['category'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      intensity: (json['intensity'] as num).toInt(),
      notes: json['notes'] as String?,
      exercises: exercises,
      logs: logs,
    );
  }
}

class SessionExercise {
  final String id;
  final String sessionId;
  final int order;
  final ExerciseSummary exercise;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final int? distanceMeters;
  final int? restSeconds;
  final int? intensity;
  final String? notes;

  const SessionExercise({
    required this.id,
    required this.sessionId,
    required this.order,
    required this.exercise,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.restSeconds,
    this.intensity,
    this.notes,
  });

  factory SessionExercise.fromJson(Map<String, dynamic> json) => SessionExercise(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        order: (json['order'] as num).toInt(),
        exercise: ExerciseSummary.fromJson(json['exercise'] as Map<String, dynamic>),
        sets: (json['sets'] as num?)?.toInt(),
        reps: (json['reps'] as num?)?.toInt(),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
        restSeconds: (json['restSeconds'] as num?)?.toInt(),
        intensity: (json['intensity'] as num?)?.toInt(),
        notes: json['notes'] as String?,
      );
}

class SessionLog {
  final String id;
  final String sessionId;
  final String playerId;
  final int? rpe;
  final int? fatigue;
  final int? mood;
  final num? sleepHours;
  final String? notes;
  final DateTime loggedAt;

  const SessionLog({
    required this.id,
    required this.sessionId,
    required this.playerId,
    this.rpe,
    this.fatigue,
    this.mood,
    this.sleepHours,
    this.notes,
    required this.loggedAt,
  });

  factory SessionLog.fromJson(Map<String, dynamic> json) => SessionLog(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        playerId: json['playerId'] as String,
        rpe: (json['rpe'] as num?)?.toInt(),
        fatigue: (json['fatigue'] as num?)?.toInt(),
        mood: (json['mood'] as num?)?.toInt(),
        sleepHours: json['sleepHours'] as num?,
        notes: json['notes'] as String?,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
      );
}
