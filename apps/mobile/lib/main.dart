import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/chat_api.dart';
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

const seedColor = Color(0xFF1B5E20);

void main() {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  runApp(FittrackApp(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
    authApi: AuthApi(apiClient),
    clubsApi: ClubsApi(apiClient),
    teamsApi: TeamsApi(apiClient),
    playersApi: PlayersApi(apiClient),
    programsApi: ProgramsApi(apiClient),
    matchesApi: MatchesApi(apiClient),
    healthApi: HealthApi(apiClient),
    chatApi: ChatApi(apiClient),
  ));
}

class FittrackApp extends StatefulWidget {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final AuthApi authApi;
  final ClubsApi clubsApi;
  final TeamsApi teamsApi;
  final PlayersApi playersApi;
  final ProgramsApi programsApi;
  final MatchesApi matchesApi;
  final HealthApi healthApi;
  final ChatApi chatApi;

  const FittrackApp({
    super.key,
    required this.apiClient,
    required this.tokenStorage,
    required this.authApi,
    required this.clubsApi,
    required this.teamsApi,
    required this.playersApi,
    required this.programsApi,
    required this.matchesApi,
    required this.healthApi,
    required this.chatApi,
  });

  @override
  State<FittrackApp> createState() => _FittrackAppState();
}

class _FittrackAppState extends State<FittrackApp> {
  User? _user;
  bool _booting = true;
  ThemeMode _themeMode = ThemeMode.system;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.apiClient.onAuthExpired = () {
      if (mounted) setState(() => _user = null);
    };
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final themeStr = await widget.tokenStorage.readThemeMode();
    final mode = _parseTheme(themeStr);
    final tokens = await widget.tokenStorage.read();
    if (tokens == null) {
      setState(() {
        _themeMode = mode;
        _booting = false;
      });
      return;
    }
    try {
      final user = await widget.authApi.me();
      setState(() {
        _user = user;
        _themeMode = mode;
        _booting = false;
      });
    } on AuthException {
      await widget.tokenStorage.clear();
      setState(() {
        _themeMode = mode;
        _booting = false;
      });
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

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await widget.tokenStorage.writeThemeMode(_themeToString(mode));
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0E1411)
          : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF14201A)
            : scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: brightness == Brightness.dark
            ? const Color(0xFF1A2620)
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
      ),
    );
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
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _booting ? const _BootingScreen() : _routeForUser(),
      ),
    );
  }

  Widget _routeForUser() {
    final user = _user;
    if (user == null) {
      return LoginScreen(
        key: const ValueKey('login'),
        authApi: widget.authApi,
        tokenStorage: widget.tokenStorage,
        onAuthenticated: _onAuthenticated,
      );
    }
    if (user.isPlayer) {
      return PlayerHomeScreen(
        key: ValueKey('player_${user.id}'),
        user: user,
        tokenStorage: widget.tokenStorage,
        playersApi: widget.playersApi,
        programsApi: widget.programsApi,
        healthApi: widget.healthApi,
        chatApi: widget.chatApi,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        onLogout: _onLogout,
      );
    }
    return HomeScreen(
      key: ValueKey('coach_${user.id}'),
      user: user,
      tokenStorage: widget.tokenStorage,
      clubsApi: widget.clubsApi,
      teamsApi: widget.teamsApi,
      playersApi: widget.playersApi,
      programsApi: widget.programsApi,
      matchesApi: widget.matchesApi,
      healthApi: widget.healthApi,
      chatApi: widget.chatApi,
      themeMode: _themeMode,
      onThemeModeChanged: _setThemeMode,
      onLogout: _onLogout,
    );
  }
}

class _BootingScreen extends StatelessWidget {
  const _BootingScreen();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.sports_soccer, size: 48, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 24),
            Text('fittrack',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )),
            const SizedBox(height: 16),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

ThemeMode _parseTheme(String? s) {
  switch (s) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
  }
  return ThemeMode.system;
}

String _themeToString(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}
