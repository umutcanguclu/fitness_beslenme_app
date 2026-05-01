import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/health_api.dart';
import '../api/players_api.dart';
import '../api/programs_api.dart';
import '../models/user.dart';
import '../util/labels.dart';
import 'availability_screen.dart';
import 'program_view_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  final User user;
  final PlayersApi playersApi;
  final ProgramsApi programsApi;
  final HealthApi healthApi;
  final VoidCallback onLogout;

  const PlayerHomeScreen({
    super.key,
    required this.user,
    required this.playersApi,
    required this.programsApi,
    required this.healthApi,
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
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('fittrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
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
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  Text(msg, textAlign: TextAlign.center),
                ],
              );
            }
            final info = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _profileCard(theme, info),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.calendar_month,
                  title: 'Bu haftaki programım',
                  subtitle: info.playerId == null
                      ? 'Profil bağlanmadı — antrenörünle iletişime geç'
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
                _ActionTile(
                  icon: Icons.directions_run,
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _profileCard(ThemeData theme, MyPlayerInfo info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                info.jerseyNumber != null ? '${info.jerseyNumber}' : _initials(widget.user.fullName),
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
                  Text(widget.user.fullName, style: theme.textTheme.titleLarge),
                  if (info.position != null)
                    Text(positionLabel(info.position!),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Chip(label: Text('Oyuncu')),
          ],
        ),
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
    if (ok == true) widget.onLogout();
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
