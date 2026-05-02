import 'package:dio/dio.dart';
import '../models/invite.dart';
import '../models/player.dart';
import '../models/team.dart';
import 'api_client.dart';
import 'api_exception.dart';

class CreateTeamInput {
  final String name;
  final String category;
  final String season;
  const CreateTeamInput({required this.name, required this.category, required this.season});
}

class UpdateTeamInput {
  final String? name;
  final String? category;
  final String? season;
  final bool? active;
  const UpdateTeamInput({this.name, this.category, this.season, this.active});

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (season != null) 'season': season,
        if (active != null) 'active': active,
      };
}

class CreatePlayerInput {
  final String fullName;
  final DateTime birthDate;
  final String position;
  final String preferredFoot;
  final num heightCm;
  final num weightKg;
  final String employmentStatus;
  final int? jerseyNumber;
  final String? detailedPosition;
  final String? email;

  const CreatePlayerInput({
    required this.fullName,
    required this.birthDate,
    required this.position,
    required this.preferredFoot,
    required this.heightCm,
    required this.weightKg,
    required this.employmentStatus,
    this.jerseyNumber,
    this.detailedPosition,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'birthDate': birthDate.toIso8601String(),
        'position': position,
        'preferredFoot': preferredFoot,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'employmentStatus': employmentStatus,
        if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
        if (detailedPosition != null && detailedPosition!.isNotEmpty)
          'detailedPosition': detailedPosition,
        if (email != null && email!.isNotEmpty) 'email': email,
      };
}

class TeamsApi {
  final ApiClient client;
  TeamsApi(this.client);

  Future<List<Team>> listMyTeams({bool includeInactive = false}) async {
    try {
      final res = await client.dio.get('/teams', queryParameters: {
        if (includeInactive) 'includeInactive': true,
      });
      ensureOk(res);
      final list = res.data as List<dynamic>;
      return list.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Team> getTeam(String teamId) async {
    try {
      final res = await client.dio.get('/teams/$teamId');
      ensureOk(res);
      return Team.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Team> updateTeam(String teamId, UpdateTeamInput input) async {
    try {
      final res = await client.dio.patch('/teams/$teamId', data: input.toJson());
      ensureOk(res);
      return Team.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Team> createTeam(CreateTeamInput input) async {
    try {
      final res = await client.dio.post('/teams', data: {
        'name': input.name,
        'category': input.category,
        'season': input.season,
      });
      ensureOk(res);
      return Team.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      final res = await client.dio.delete('/teams/$teamId');
      ensureOk(res);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<TeamPlayer>> listRoster(String teamId) async {
    try {
      final res = await client.dio.get('/teams/$teamId/players');
      ensureOk(res);
      final list = res.data as List<dynamic>;
      return list.map((e) => TeamPlayer.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<CreatePlayerResult> createPlayer(String teamId, CreatePlayerInput input) async {
    try {
      final res = await client.dio.post('/teams/$teamId/players', data: input.toJson());
      ensureOk(res);
      return CreatePlayerResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> removePlayerFromRoster(String teamId, String playerId) async {
    try {
      final res = await client.dio.delete('/teams/$teamId/players/$playerId');
      ensureOk(res);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
