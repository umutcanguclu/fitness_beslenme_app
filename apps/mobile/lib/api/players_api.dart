import 'package:dio/dio.dart';
import '../models/player.dart';
import 'api_client.dart';
import 'api_exception.dart';

class MyPlayerInfo {
  final String? playerId;
  final String? clubId;
  final String? fullName;
  final String? position;
  final int? jerseyNumber;
  const MyPlayerInfo({this.playerId, this.clubId, this.fullName, this.position, this.jerseyNumber});

  factory MyPlayerInfo.fromJson(Map<String, dynamic> json) {
    final p = json['player'] as Map<String, dynamic>?;
    return MyPlayerInfo(
      playerId: json['playerId'] as String?,
      clubId: p?['clubId'] as String?,
      fullName: p?['fullName'] as String?,
      position: p?['position'] as String?,
      jerseyNumber: p?['jerseyNumber'] as int?,
    );
  }
}

class PlayersApi {
  final ApiClient client;
  PlayersApi(this.client);

  Future<MyPlayerInfo> getMyPlayer() async {
    try {
      final res = await client.dio.get('/auth/me/player');
      ensureOk(res);
      return MyPlayerInfo.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Player> getPlayer(String playerId) async {
    try {
      final res = await client.dio.get('/players/$playerId');
      ensureOk(res);
      return Player.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Player> updatePlayer(String playerId, UpdatePlayerInput input) async {
    try {
      final res = await client.dio.patch('/players/$playerId', data: input.toJson());
      ensureOk(res);
      return Player.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

class UpdatePlayerInput {
  final String? position;
  final String? detailedPosition;
  final String? preferredFoot;
  final num? heightCm;
  final num? weightKg;
  final int? jerseyNumber;
  final String? employmentStatus;
  final DateTime? birthDate;

  const UpdatePlayerInput({
    this.position,
    this.detailedPosition,
    this.preferredFoot,
    this.heightCm,
    this.weightKg,
    this.jerseyNumber,
    this.employmentStatus,
    this.birthDate,
  });

  Map<String, dynamic> toJson() => {
        if (position != null) 'position': position,
        if (detailedPosition != null) 'detailedPosition': detailedPosition,
        if (preferredFoot != null) 'preferredFoot': preferredFoot,
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
        if (employmentStatus != null) 'employmentStatus': employmentStatus,
        if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
      };
}
