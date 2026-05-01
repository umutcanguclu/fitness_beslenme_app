import 'package:dio/dio.dart';
import '../models/club.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ClubsApi {
  final ApiClient client;
  ClubsApi(this.client);

  Future<Club?> getMyClub() async {
    try {
      final res = await client.dio.get('/clubs/me');
      ensureOk(res);
      final data = res.data;
      if (data == null) return null;
      return Club.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Facility>> listFacilities(String clubId) async {
    try {
      final res = await client.dio.get('/clubs/$clubId/facilities');
      ensureOk(res);
      final list = res.data as List<dynamic>;
      return list.map((e) => Facility.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Equipment>> listEquipment(String clubId) async {
    try {
      final res = await client.dio.get('/clubs/$clubId/equipment');
      ensureOk(res);
      final list = res.data as List<dynamic>;
      return list.map((e) => Equipment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
