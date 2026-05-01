import 'package:dio/dio.dart';
import '../models/health.dart';
import 'api_client.dart';
import 'api_exception.dart';

// Availability + injury + performance test endpoints all live under /players/:id/...
class HealthApi {
  final ApiClient client;
  HealthApi(this.client);

  Future<PlayerAvailability> setAvailability({
    required String playerId,
    required DateTime date,
    required String status,
    String? note,
  }) async {
    try {
      final res = await client.dio.post('/players/$playerId/availability', data: {
        'date': DateTime.utc(date.year, date.month, date.day).toIso8601String(),
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      ensureOk(res);
      return PlayerAvailability.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<PlayerAvailability>> listAvailability(String playerId, {DateTime? from, DateTime? to}) async {
    try {
      final res = await client.dio.get('/players/$playerId/availability', queryParameters: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      });
      ensureOk(res);
      final list = res.data as List<dynamic>;
      final items = list
          .map((e) => PlayerAvailability.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<InjuryRecord> createInjury({
    required String playerId,
    required String type,
    required String severity,
    required String bodyPart,
    required DateTime startedAt,
    DateTime? expectedReturn,
    String? description,
  }) async {
    try {
      final res = await client.dio.post('/players/$playerId/injuries', data: {
        'type': type,
        'severity': severity,
        'bodyPart': bodyPart,
        'startedAt': startedAt.toIso8601String(),
        if (expectedReturn != null) 'expectedReturn': expectedReturn.toIso8601String(),
        if (description != null && description.isNotEmpty) 'description': description,
      });
      ensureOk(res);
      return InjuryRecord.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<InjuryRecord>> listInjuries(String playerId, {bool includeResolved = true}) async {
    try {
      final res = await client.dio.get('/players/$playerId/injuries', queryParameters: {
        if (includeResolved) 'includeResolved': true,
      });
      ensureOk(res);
      final list = res.data as List<dynamic>;
      final items = list
          .map((e) => InjuryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return items;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<InjuryRecord> resolveInjury(String playerId, String injuryId, {DateTime? resolvedAt}) async {
    try {
      final res = await client.dio.patch('/players/$playerId/injuries/$injuryId', data: {
        if (resolvedAt != null) 'resolvedAt': resolvedAt.toIso8601String(),
      });
      ensureOk(res);
      return InjuryRecord.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<PerformanceTest> createPerformanceTest({
    required String playerId,
    required String type,
    required num value,
    required String unit,
    DateTime? testedAt,
    String? notes,
  }) async {
    try {
      final res = await client.dio.post('/players/$playerId/performance-tests', data: {
        'type': type,
        'value': value,
        'unit': unit,
        if (testedAt != null) 'testedAt': testedAt.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      ensureOk(res);
      return PerformanceTest.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<PerformanceTest>> listPerformanceTests(String playerId, {String? type}) async {
    try {
      final res = await client.dio.get('/players/$playerId/performance-tests', queryParameters: {
        if (type != null) 'type': type,
      });
      ensureOk(res);
      final list = res.data as List<dynamic>;
      final items = list
          .map((e) => PerformanceTest.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.testedAt.compareTo(a.testedAt));
      return items;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
