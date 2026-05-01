import 'package:dio/dio.dart';
import '../models/match.dart';
import 'api_client.dart';
import 'api_exception.dart';

class CreateMatchInput {
  final String opponent;
  final DateTime date;
  final bool isHome;
  final String? competition;
  final String? notes;
  const CreateMatchInput({
    required this.opponent,
    required this.date,
    required this.isHome,
    this.competition,
    this.notes,
  });
}

class UpdateMatchInput {
  final String? opponent;
  final DateTime? date;
  final bool? isHome;
  final String? competition;
  final int? scoreUs;
  final int? scoreThem;
  final String? notes;
  const UpdateMatchInput({
    this.opponent,
    this.date,
    this.isHome,
    this.competition,
    this.scoreUs,
    this.scoreThem,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        if (opponent != null) 'opponent': opponent,
        if (date != null) 'date': date!.toIso8601String(),
        if (isHome != null) 'isHome': isHome,
        if (competition != null) 'competition': competition,
        if (scoreUs != null) 'scoreUs': scoreUs,
        if (scoreThem != null) 'scoreThem': scoreThem,
        if (notes != null) 'notes': notes,
      };
}

class MatchesApi {
  final ApiClient client;
  MatchesApi(this.client);

  Future<List<Match>> listForTeam(String teamId) async {
    try {
      final res = await client.dio.get('/teams/$teamId/matches');
      ensureOk(res);
      final list = res.data as List<dynamic>;
      final items = list.map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Match> create(String teamId, CreateMatchInput input) async {
    try {
      final res = await client.dio.post('/teams/$teamId/matches', data: {
        'opponent': input.opponent,
        'date': input.date.toIso8601String(),
        'isHome': input.isHome,
        if (input.competition != null && input.competition!.isNotEmpty)
          'competition': input.competition,
        if (input.notes != null && input.notes!.isNotEmpty) 'notes': input.notes,
      });
      ensureOk(res);
      return Match.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Match> update(String matchId, UpdateMatchInput input) async {
    try {
      final res = await client.dio.patch('/matches/$matchId', data: input.toJson());
      ensureOk(res);
      return Match.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(String matchId) async {
    try {
      final res = await client.dio.delete('/matches/$matchId');
      ensureOk(res);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
