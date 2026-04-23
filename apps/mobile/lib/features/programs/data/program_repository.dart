import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../domain/program.dart';

class ProgramRepository {
  ProgramRepository(this._dio);

  final Dio _dio;

  Future<Program> generate(ProgramGenerateInput input) async {
    return _wrap(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/programs/generate',
        data: input.toJson(),
      );
      return Program.fromJson(response.data!);
    });
  }

  Future<Program?> getActive() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/programs/active');
      return Program.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw ApiError.fromDio(error);
    }
  }

  Future<List<Program>> list() async {
    return _wrap(() async {
      final response = await _dio.get<List<dynamic>>('/programs');
      return (response.data ?? const [])
          .map((e) => Program.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> delete(String id) async {
    await _wrap(() => _dio.delete<void>('/programs/$id'));
  }

  Future<Program> activate(String id) async {
    return _wrap(() async {
      final response = await _dio.post<Map<String, dynamic>>('/programs/$id/activate');
      return Program.fromJson(response.data!);
    });
  }

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiError.fromDio(error);
    }
  }
}

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository(ref.watch(apiClientProvider).dio);
});

final activeProgramProvider = FutureProvider<Program?>((ref) {
  return ref.watch(programRepositoryProvider).getActive();
});
