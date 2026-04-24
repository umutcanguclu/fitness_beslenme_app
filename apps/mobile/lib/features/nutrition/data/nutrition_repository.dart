import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/nutrition.dart';

class NutritionRepository {
  NutritionRepository(this._dio);

  final Dio _dio;

  Future<NutritionPlan> generate(NutritionGenerateInput input) async {
    return _wrap(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/nutrition/plan/generate',
        data: input.toJson(),
      );
      return NutritionPlan.fromJson(response.data!);
    });
  }

  Future<NutritionPlan?> getActive() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/nutrition/plan/active');
      return NutritionPlan.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw ApiError.fromDio(error);
    }
  }

  Future<void> delete(String id) async {
    await _wrap(() => _dio.delete<void>('/nutrition/plan/$id'));
  }

  Future<List<FoodMeta>> foods() async {
    return _wrap(() async {
      final response = await _dio.get<List<dynamic>>('/nutrition/foods');
      return (response.data ?? const [])
          .map((e) => FoodMeta.fromJson(e as Map<String, dynamic>))
          .toList();
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

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(apiClientProvider).dio);
});

final activeNutritionPlanProvider = FutureProvider<NutritionPlan?>((ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  if (auth is! AuthAuthenticated) return null;
  return ref.watch(nutritionRepositoryProvider).getActive();
});

final foodCatalogProvider = FutureProvider<Map<String, FoodMeta>>((ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  if (auth is! AuthAuthenticated) return const {};
  final list = await ref.watch(nutritionRepositoryProvider).foods();
  return {for (final f in list) f.id: f};
});
