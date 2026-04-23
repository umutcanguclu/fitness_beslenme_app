import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../domain/workout.dart';

class WorkoutRepository {
  WorkoutRepository(this._dio);

  final Dio _dio;

  Future<WorkoutListPage> list({int limit = 20, String? cursor}) async {
    return _wrap(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/workouts',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      return WorkoutListPage.fromJson(response.data!);
    });
  }

  Future<Workout> get(String id) async {
    return _wrap(() async {
      final response = await _dio.get<Map<String, dynamic>>('/workouts/$id');
      return Workout.fromJson(response.data!);
    });
  }

  Future<Workout> start({String? name, String? notes, String? templateId}) {
    return _wrap(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/workouts',
        data: {
          'name': ?name,
          'notes': ?notes,
          'templateId': ?templateId,
        },
      );
      return Workout.fromJson(response.data!);
    });
  }

  Future<WorkoutSet> addSet({
    required String workoutId,
    required String exerciseId,
    double? weightKg,
    int? reps,
    int? timeSeconds,
    int? distanceMeters,
    double? rpe,
  }) {
    return _wrap(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/workouts/$workoutId/sets',
        data: {
          'exerciseId': exerciseId,
          'weightKg': ?weightKg,
          'reps': ?reps,
          'timeSeconds': ?timeSeconds,
          'distanceMeters': ?distanceMeters,
          'rpe': ?rpe,
        },
      );
      return WorkoutSet.fromJson(response.data!);
    });
  }

  Future<Workout> finish(String id, {String? notes}) {
    return _wrap(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/workouts/$id/finish',
        data: {'notes': ?notes},
      );
      return Workout.fromJson(response.data!);
    });
  }

  Future<void> delete(String id) async {
    await _wrap(() => _dio.delete<void>('/workouts/$id'));
  }

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiError.fromDio(error);
    }
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(apiClientProvider).dio);
});
