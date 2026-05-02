import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/api/api_client.dart';
import 'package:fittrack/api/auth_api.dart';
import 'package:fittrack/api/chat_api.dart';
import 'package:fittrack/api/clubs_api.dart';
import 'package:fittrack/api/health_api.dart';
import 'package:fittrack/api/matches_api.dart';
import 'package:fittrack/api/players_api.dart';
import 'package:fittrack/api/programs_api.dart';
import 'package:fittrack/api/teams_api.dart';
import 'package:fittrack/main.dart';
import 'package:fittrack/models/auth_tokens.dart';
import 'package:fittrack/storage/token_storage.dart';

void main() {
  testWidgets('boots into login when no token is stored', (tester) async {
    final storage = _MemoryTokenStorage();
    final api = ApiClient(tokenStorage: storage);

    await tester.pumpWidget(FittrackApp(
      apiClient: api,
      tokenStorage: storage,
      authApi: AuthApi(api),
      clubsApi: ClubsApi(api),
      teamsApi: TeamsApi(api),
      playersApi: PlayersApi(api),
      programsApi: ProgramsApi(api),
      matchesApi: MatchesApi(api),
      healthApi: HealthApi(api),
      chatApi: ChatApi(api),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Antrenör + Oyuncu Platformu'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Giriş yap'), findsOneWidget);
  });
}

class _MemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;
  String? _theme;
  @override
  Future<AuthTokens?> read() async => _tokens;
  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;
  @override
  Future<void> clear() async => _tokens = null;
  @override
  Future<String?> readThemeMode() async => _theme;
  @override
  Future<void> writeThemeMode(String mode) async => _theme = mode;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
