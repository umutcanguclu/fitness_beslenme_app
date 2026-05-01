import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/clubs_api.dart';
import 'api/health_api.dart';
import 'api/matches_api.dart';
import 'api/players_api.dart';
import 'api/programs_api.dart';
import 'api/teams_api.dart';
import 'models/user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/player_home_screen.dart';
import 'storage/token_storage.dart';

void main() {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  runApp(FittrackApp(
    tokenStorage: tokenStorage,
    authApi: AuthApi(apiClient),
    clubsApi: ClubsApi(apiClient),
    teamsApi: TeamsApi(apiClient),
    playersApi: PlayersApi(apiClient),
    programsApi: ProgramsApi(apiClient),
    matchesApi: MatchesApi(apiClient),
    healthApi: HealthApi(apiClient),
  ));
}

class FittrackApp extends StatefulWidget {
  final TokenStorage tokenStorage;
  final AuthApi authApi;
  final ClubsApi clubsApi;
  final TeamsApi teamsApi;
  final PlayersApi playersApi;
  final ProgramsApi programsApi;
  final MatchesApi matchesApi;
  final HealthApi healthApi;

  const FittrackApp({
    super.key,
    required this.tokenStorage,
    required this.authApi,
    required this.clubsApi,
    required this.teamsApi,
    required this.playersApi,
    required this.programsApi,
    required this.matchesApi,
    required this.healthApi,
  });

  @override
  State<FittrackApp> createState() => _FittrackAppState();
}

class _FittrackAppState extends State<FittrackApp> {
  User? _user;
  bool _booting = true;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final tokens = await widget.tokenStorage.read();
    if (tokens == null) {
      setState(() => _booting = false);
      return;
    }
    try {
      final user = await widget.authApi.me();
      setState(() {
        _user = user;
        _booting = false;
      });
    } on AuthException {
      await widget.tokenStorage.clear();
      setState(() => _booting = false);
    }
  }

  void _onAuthenticated(User user) {
    setState(() => _user = user);
    _navigatorKey.currentState?.popUntil((r) => r.isFirst);
  }

  Future<void> _onLogout() async {
    final tokens = await widget.tokenStorage.read();
    if (tokens != null) {
      await widget.authApi.logout(tokens.refreshToken);
    }
    await widget.tokenStorage.clear();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fittrack',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _booting ? const _BootingScreen() : _routeForUser(),
    );
  }

  Widget _routeForUser() {
    final user = _user;
    if (user == null) {
      return LoginScreen(
        authApi: widget.authApi,
        tokenStorage: widget.tokenStorage,
        onAuthenticated: _onAuthenticated,
      );
    }
    if (user.isPlayer) {
      return PlayerHomeScreen(
        user: user,
        playersApi: widget.playersApi,
        programsApi: widget.programsApi,
        healthApi: widget.healthApi,
        onLogout: _onLogout,
      );
    }
    return HomeScreen(
      user: user,
      clubsApi: widget.clubsApi,
      teamsApi: widget.teamsApi,
      programsApi: widget.programsApi,
      matchesApi: widget.matchesApi,
      healthApi: widget.healthApi,
      onLogout: _onLogout,
    );
  }
}

class _BootingScreen extends StatelessWidget {
  const _BootingScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
