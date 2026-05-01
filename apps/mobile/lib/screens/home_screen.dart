import 'package:flutter/material.dart';
import '../api/clubs_api.dart';
import '../api/health_api.dart';
import '../api/matches_api.dart';
import '../api/programs_api.dart';
import '../api/teams_api.dart';
import '../models/user.dart';
import '../util/labels.dart';
import 'club_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  final ClubsApi clubsApi;
  final TeamsApi teamsApi;
  final ProgramsApi programsApi;
  final MatchesApi matchesApi;
  final HealthApi healthApi;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.clubsApi,
    required this.teamsApi,
    required this.programsApi,
    required this.matchesApi,
    required this.healthApi,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = roleLabel(user.role);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('fittrack'),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _initials(user.fullName),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hoş geldin,', style: theme.textTheme.bodyMedium),
                        Text(user.fullName, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Chip(label: Text(role)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (user.isCoach) ...[
            Text('Antrenör paneli', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.shield_outlined,
              title: 'Kulübüm',
              subtitle: 'Kulüp, takımlar, oyuncular, tesis ve ekipman',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ClubScreen(
                  clubsApi: clubsApi,
                  teamsApi: teamsApi,
                  programsApi: programsApi,
                  matchesApi: matchesApi,
                  healthApi: healthApi,
                ),
              )),
            ),
            _ActionTile(
              icon: Icons.calendar_month_outlined,
              title: 'Programlar',
              subtitle: 'Bir oyuncuya gir → 📅 ikon → haftalık program üret + görüntüle',
              enabled: false,
              trailing: const Chip(label: Text('İçeride')),
            ),
            _ActionTile(
              icon: Icons.sports_soccer,
              title: 'Maçlar',
              subtitle: 'Takıma gir → AppBar\'daki sahaya bas → fikstür yönetimi',
              enabled: false,
              trailing: const Chip(label: Text('İçeride')),
            ),
          ] else ...[
            Text('Oyuncu paneli', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.calendar_today_outlined,
              title: 'Haftalık programım',
              subtitle: 'Bu haftaki antrenman planın',
              enabled: false,
              trailing: const Chip(label: Text('Yakında')),
            ),
            _ActionTile(
              icon: Icons.directions_run,
              title: 'Hazırbulunuşluk',
              subtitle: 'RPE, sakatlık, devamsızlık bildirimi',
              enabled: false,
              trailing: const Chip(label: Text('Yakında')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış'),
        content: const Text('Çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkış')),
        ],
      ),
    );
    if (ok == true) onLogout();
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: enabled
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(icon,
              color: enabled
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant),
        ),
        title: Text(title,
            style: enabled
                ? null
                : TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        subtitle: Text(subtitle,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
