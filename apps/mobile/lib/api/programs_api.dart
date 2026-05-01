import 'package:dio/dio.dart';
import '../models/program.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ProgramsApi {
  final ApiClient client;
  ProgramsApi(this.client);

  Future<TrainingProgram> generateForPlayer({
    required String playerId,
    required DateTime weekStartDate,
    String? microcycleType,
  }) async {
    try {
      final res = await client.dio.post(
        '/players/$playerId/programs/generate',
        data: {
          'weekStartDate': _isoDate(weekStartDate),
          if (microcycleType != null) 'microcycleType': microcycleType,
        },
      );
      ensureOk(res);
      return TrainingProgram.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<TrainingProgram>> listForPlayer(
    String playerId, {
    DateTime? weekStartDate,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final res = await client.dio.get(
        '/players/$playerId/programs',
        queryParameters: {
          if (weekStartDate != null) 'weekStartDate': _isoDate(weekStartDate),
          if (from != null) 'from': _isoDate(from),
          if (to != null) 'to': _isoDate(to),
        },
      );
      ensureOk(res);
      final list = res.data as List<dynamic>;
      final items = list
          .map((e) => TrainingProgram.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
      return items;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<SessionLog> logSession({
    required String sessionId,
    int? rpe,
    int? fatigue,
    int? mood,
    num? sleepHours,
    String? notes,
  }) async {
    try {
      final res = await client.dio.post('/sessions/$sessionId/log', data: {
        if (rpe != null) 'rpe': rpe,
        if (fatigue != null) 'fatigue': fatigue,
        if (mood != null) 'mood': mood,
        if (sleepHours != null) 'sleepHours': sleepHours,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      ensureOk(res);
      return SessionLog.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

// Engine accepts ISO Monday-of-week. Send full ISO datetime.
String _isoDate(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).toIso8601String();
