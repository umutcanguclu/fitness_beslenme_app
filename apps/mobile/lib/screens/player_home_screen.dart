import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/chat_api.dart';
import '../api/health_api.dart';
import '../api/players_api.dart';
import '../api/programs_api.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import '../util/labels.dart';
import 'availability_screen.dart';
import 'chat_threads_screen.dart';
import 'player_self_edit_screen.dart';
import 'player_stats_screen.dart';
import 'program_view_screen.dart';
import 'settings_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  final User user;
  final TokenStorage tokenStorage;
  final PlayersApi playersApi;
  final ProgramsApi programsApi;
  final HealthApi healthApi;
  final ChatApi chatApi;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onLogout;

  const PlayerHomeScreen({
    super.key,
    required this.user,
    required this.tokenStorage,
    required this.playersApi,
    required this.programsApi,
    required this.healthApi,
    required this.chatApi,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLogout,
  });

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  Future<MyPlayerInfo>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.playersApi.getMyPlayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<MyPlayerInfo>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final msg = snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : snap.error.toString();
              return _ErrorView(error: msg, onRetry: _load);
            }
            final info = snap.data!;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  actions: [
                    if (info.playerId != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Profilimi düzenle',
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PlayerSelfEditScreen(
                              playersApi: widget.playersApi,
                              playerId: info.playerId!,
                            ),
                          ));
                          if (mounted) _load();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Ayarlar',
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          user: widget.user,
                          themeMode: widget.themeMode,
                          onThemeModeChanged: widget.onThemeModeChanged,
                          onLogout: widget.onLogout,
                        ),
                      )),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.fromLTRB(16, 0, 80, 16),
                    title: Text('fittrack',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        )),
                    background: _PlayerHero(theme: theme, user: widget.user, info: info),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ActionCard(
                        icon: Icons.calendar_month,
                        iconBg: const Color(0xFF1976D2),
                        title: 'Bu haftaki programım',
                        subtitle: info.playerId == null
                            ? 'Profil bağlanmadı'
                            : 'Antrenmanlar, egzersizler, RPE girişi',
                        enabled: info.playerId != null,
                        onTap: info.playerId == null
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ProgramViewScreen(
                                    programsApi: widget.programsApi,
                                    playerId: info.playerId!,
                                    playerName: widget.user.fullName,
                                    canGenerate: false,
                                    canLogRpe: true,
                                  ),
                                )),
                      ),
                      _ActionCard(
                        icon: Icons.directions_run,
                        iconBg: const Color(0xFFEF6C00),
                        title: 'Hazırbulunuşluk',
                        subtitle: 'Bugün hazır mısın? Sakat/izin durumu bildir',
                        enabled: info.playerId != null,
                        onTap: info.playerId == null
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => AvailabilityScreen(
                                    healthApi: widget.healthApi,
                                    playerId: info.playerId!,
                                    canEdit: true,
                                  ),
                                )),
                      ),
                      _ActionCard(
                        icon: Icons.bar_chart,
                        iconBg: const Color(0xFF388E3C),
                        title: 'İstatistiklerim',
                        subtitle: 'RPE trendi, antrenman dağılımı, hazırbulunuşluk',
                        enabled: info.playerId != null,
                        onTap: info.playerId == null
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PlayerStatsScreen(
                                    programsApi: widget.programsApi,
                                    healthApi: widget.healthApi,
                                    playerId: info.playerId!,
                                    playerName: widget.user.fullName,
                                  ),
                                )),
                      ),
                      _ActionCard(
                        icon: Icons.chat_bubble,
                        iconBg: const Color(0xFF7B1FA2),
                        title: 'Mesajlar',
                        subtitle: 'Antrenörünle yazışmalar',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatThreadsScreen(
                            chatApi: widget.chatApi,
                            tokenStorage: widget.tokenStorage,
                            currentUser: widget.user,
                          ),
                        )),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlayerHero extends StatelessWidget {
  final ThemeData theme;
  final User user;
  final MyPlayerInfo info;
  const _PlayerHero({required this.theme, required this.user, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
            const Color(0xFF0F3D14),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 56,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      info.jerseyNumber != null ? '${info.jerseyNumber}' : _initials(user.fullName),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        )),
                    if (info.position != null)
                      Text(positionLabel(info.position!),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                            fontSize: 13,
                          )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled ? iconBg : theme.colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: enabled
                        ? LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: enabled ? null : color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: enabled
                                  ? null
                                  : theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline,
            size: 64, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
            child: FilledButton(onPressed: onRetry, child: const Text('Tekrar dene'))),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}
