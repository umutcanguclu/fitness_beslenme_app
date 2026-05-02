import 'package:flutter/material.dart';
import '../api/chat_api.dart';
import '../api/clubs_api.dart';
import '../api/health_api.dart';
import '../api/matches_api.dart';
import '../api/players_api.dart';
import '../api/programs_api.dart';
import '../api/teams_api.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'chat_threads_screen.dart';
import 'club_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  final TokenStorage tokenStorage;
  final ClubsApi clubsApi;
  final TeamsApi teamsApi;
  final PlayersApi playersApi;
  final ProgramsApi programsApi;
  final MatchesApi matchesApi;
  final HealthApi healthApi;
  final ChatApi chatApi;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.tokenStorage,
    required this.clubsApi,
    required this.teamsApi,
    required this.playersApi,
    required this.programsApi,
    required this.matchesApi,
    required this.healthApi,
    required this.chatApi,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _unreadTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUnread();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final threads = await widget.chatApi.listThreads();
      final total = threads.fold<int>(0, (sum, t) => sum + t.unreadCount);
      if (!mounted) return;
      setState(() => _unreadTotal = total);
    } catch (_) {/* silent */}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Ayarlar',
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      user: widget.user,
                      themeMode: widget.themeMode,
                      onThemeModeChanged: widget.onThemeModeChanged,
                      onLogout: widget.onLogout,
                    ),
                  ));
                  if (mounted) _refreshUnread();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 80, 16),
              title: Text(
                'fittrack',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              background: _HeroBackground(theme: theme, user: widget.user),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle('Antrenör paneli'),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.shield,
                  iconBg: const Color(0xFF388E3C),
                  title: 'Kulübüm',
                  subtitle: 'Kulüp, takımlar, oyuncular, tesis ve ekipman',
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ClubScreen(
                        clubsApi: widget.clubsApi,
                        teamsApi: widget.teamsApi,
                        playersApi: widget.playersApi,
                        programsApi: widget.programsApi,
                        matchesApi: widget.matchesApi,
                        healthApi: widget.healthApi,
                        chatApi: widget.chatApi,
                        tokenStorage: widget.tokenStorage,
                      ),
                    ));
                    if (mounted) _refreshUnread();
                  },
                ),
                _ActionCard(
                  icon: Icons.chat_bubble,
                  iconBg: const Color(0xFF1976D2),
                  title: 'Mesajlar',
                  subtitle: 'Oyuncularla yazışmalar, takım bildirimleri',
                  badge: _unreadTotal > 0 ? '$_unreadTotal' : null,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatThreadsScreen(
                        chatApi: widget.chatApi,
                        tokenStorage: widget.tokenStorage,
                        currentUser: widget.user,
                      ),
                    ));
                    if (mounted) _refreshUnread();
                  },
                ),
                const SizedBox(height: 24),
                _SectionTitle('Hızlı erişim'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.calendar_month,
                        color: const Color(0xFF7B1FA2),
                        label: 'Programlar',
                        hint: 'Oyuncuya gir → 📅',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.sports_soccer,
                        color: const Color(0xFFD32F2F),
                        label: 'Maçlar',
                        hint: 'Takım → ⚽',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.healing,
                        color: const Color(0xFFEF6C00),
                        label: 'Sakatlıklar',
                        hint: 'Oyuncu → 🩹',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.timer,
                        color: const Color(0xFF00838F),
                        label: 'Performans',
                        hint: 'Oyuncu → ⏱',
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final ThemeData theme;
  final User user;
  const _HeroBackground({required this.theme, required this.user});

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
            right: -60,
            top: -40,
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
            right: 20,
            top: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 56,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                  child: Text(
                    _initials(user.fullName),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoş geldin,',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                        )),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [iconBg, iconBg.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    if (badge != null)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: theme.colorScheme.surface, width: 2),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String hint;
  const _MiniCard({required this.icon, required this.color, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(hint,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}
