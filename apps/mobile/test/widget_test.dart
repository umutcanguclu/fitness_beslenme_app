import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/api/api_client.dart';
import 'package:fittrack/api/auth_api.dart';
import 'package:fittrack/api/clubs_api.dart';
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
      tokenStorage: storage,
      authApi: AuthApi(api),
      clubsApi: ClubsApi(api),
      teamsApi: TeamsApi(api),
      playersApi: PlayersApi(api),
      programsApi: ProgramsApi(api),
    ));
    await tester.pump();

    expect(find.text('fittrack'), findsOneWidget);
    expect(find.text('Antrenör + Oyuncu Platformu'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Giriş yap'), findsOneWidget);
  });
}

class _MemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;
  @override
  Future<AuthTokens?> read() async => _tokens;
  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;
  @override
  Future<void> clear() async => _tokens = null;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
