import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/chat_api.dart';
import '../api/health_api.dart';
import '../api/matches_api.dart';
import '../api/players_api.dart';
import '../api/programs_api.dart';
import '../api/teams_api.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../storage/token_storage.dart';
import '../util/labels.dart';
import 'availability_screen.dart';
import 'chat_room_screen.dart';
import 'injuries_screen.dart';
import 'matches_screen.dart';
import 'perf_tests_screen.dart';
import 'player_create_screen.dart';
import 'player_edit_screen.dart';
import 'player_stats_screen.dart';
import 'program_view_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final TeamsApi teamsApi;
  final PlayersApi playersApi;
  final ProgramsApi programsApi;
  final MatchesApi matchesApi;
  final HealthApi healthApi;
  final ChatApi chatApi;
  final TokenStorage tokenStorage;
  final Team team;

  const TeamDetailScreen({
    super.key,
    required this.teamsApi,
    required this.playersApi,
    required this.programsApi,
    required this.matchesApi,
    required this.healthApi,
    required this.chatApi,
    required this.tokenStorage,
    required this.team,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Future<List<TeamPlayer>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.teamsApi.listRoster(widget.team.id);
    });
  }

  Future<void> _addPlayer() async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PlayerCreateScreen(teamsApi: widget.teamsApi, team: widget.team),
    ));
    if (added == true && mounted) _load();
  }

  void _openPlayerPrograms(Player p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProgramViewScreen(
        programsApi: widget.programsApi,
        playerId: p.id,
        playerName: p.fullName,
        canGenerate: true,
        canLogRpe: false,
      ),
    ));
  }

  void _openInjuries(Player p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => InjuriesScreen(
        healthApi: widget.healthApi,
        playerId: p.id,
        playerName: p.fullName,
      ),
    ));
  }

  void _openPerfTests(Player p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PerfTestsScreen(
        healthApi: widget.healthApi,
        playerId: p.id,
        playerName: p.fullName,
        canEdit: true,
      ),
    ));
  }

  void _openAvailability(Player p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AvailabilityScreen(
        healthApi: widget.healthApi,
        playerId: p.id,
        canEdit: false,
      ),
    ));
  }

  Future<void> _editPlayer(Player p) async {
    final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PlayerEditScreen(playersApi: widget.playersApi, player: p),
    ));
    if (updated == true && mounted) _load();
  }

  void _openStats(Player p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerStatsScreen(
        programsApi: widget.programsApi,
        healthApi: widget.healthApi,
        playerId: p.id,
        playerName: p.fullName,
      ),
    ));
  }

  Future<void> _openChat(Player p) async {
    try {
      final thread = await widget.chatApi.startThreadWithPlayer(p.id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          chatApi: widget.chatApi,
          tokenStorage: widget.tokenStorage,
          threadId: thread.id,
          currentUserId: thread.coachId,
          otherPartyName: p.fullName,
        ),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmRemovePlayer(Player p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kadrodan çıkar'),
        content: Text('${p.fullName} bu takım kadrosundan çıkarılacak. (Oyuncu profili kulüpte kalır.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.teamsApi.removePlayerFromRoster(widget.team.id, p.id);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${p.fullName} kadrodan çıkarıldı')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.team;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.name),
        actions: [
          IconButton(
            tooltip: 'Maçlar',
            icon: const Icon(Icons.sports_soccer),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MatchesScreen(matchesApi: widget.matchesApi, team: widget.team),
            )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlayer,
        icon: const Icon(Icons.person_add),
        label: const Text('Oyuncu'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.name, style: theme.textTheme.titleLarge),
                        ),
                        if (!t.active)
                          const Chip(label: Text('Pasif'), visualDensity: VisualDensity.compact),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${teamCategoryLabel(t.category)} · Sezon ${t.season}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Kadro', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<TeamPlayer>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  final msg = snap.error is ApiException
                      ? (snap.error as ApiException).message
                      : snap.error.toString();
                  return Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                          const SizedBox(height: 8),
                          FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
                        ],
                      ),
                    ),
                  );
                }
                final roster = snap.data ?? const <TeamPlayer>[];
                if (roster.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('Kadroda oyuncu yok.',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ),
                  );
                }
                final sorted = [...roster]..sort((a, b) {
                  final ja = a.player.jerseyNumber ?? 999;
                  final jb = b.player.jerseyNumber ?? 999;
                  if (ja != jb) return ja.compareTo(jb);
                  return a.player.fullName.compareTo(b.player.fullName);
                });
                return Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < sorted.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _PlayerTile(
                          player: sorted[i].player,
                          onLongPress: () => _confirmRemovePlayer(sorted[i].player),
                          onPrograms: () => _openPlayerPrograms(sorted[i].player),
                          onInjuries: () => _openInjuries(sorted[i].player),
                          onPerfTests: () => _openPerfTests(sorted[i].player),
                          onAvailability: () => _openAvailability(sorted[i].player),
                          onEdit: () => _editPlayer(sorted[i].player),
                          onChat: () => _openChat(sorted[i].player),
                          onStats: () => _openStats(sorted[i].player),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback onLongPress;
  final VoidCallback onPrograms;
  final VoidCallback onInjuries;
  final VoidCallback onPerfTests;
  final VoidCallback onAvailability;
  final VoidCallback onEdit;
  final VoidCallback onChat;
  final VoidCallback onStats;
  const _PlayerTile({
    required this.player,
    required this.onLongPress,
    required this.onPrograms,
    required this.onInjuries,
    required this.onPerfTests,
    required this.onAvailability,
    required this.onEdit,
    required this.onChat,
    required this.onStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jersey = player.jerseyNumber;
    final pos = player.detailedPosition != null
        ? detailedPositionLabel(player.detailedPosition!)
        : positionLabel(player.position);
    final h = player.heightCm;
    final w = player.weightKg;
    String? subtitle = pos;
    if (h != null && w != null) {
      subtitle = '$pos · ${h.round()}cm / ${w.round()}kg';
    }
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          jersey != null ? '$jersey' : player.fullName.characters.first.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(player.fullName),
      subtitle: Text(subtitle),
      trailing: IconButton(
        tooltip: 'Programlar',
        icon: const Icon(Icons.calendar_month),
        onPressed: onPrograms,
      ),
      onTap: () => _showPlayerDetails(context, player),
      onLongPress: onLongPress,
    );
  }

  void _showPlayerDetails(BuildContext context, Player p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.fullName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(positionLabel(p.position),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                if (p.jerseyNumber != null) _kv('Forma', '${p.jerseyNumber}'),
                if (p.detailedPosition != null) _kv('Detay mevki', detailedPositionLabel(p.detailedPosition!)),
                _kv('Tercih ayak', footLabel(p.preferredFoot)),
                if (p.heightCm != null) _kv('Boy', '${p.heightCm!.round()} cm'),
                if (p.weightKg != null) _kv('Kilo', '${p.weightKg!.round()} kg'),
                _kv('Statü', employmentLabel(p.employmentStatus)),
                if (p.birthDate != null)
                  _kv('Doğum', '${p.birthDate!.day}.${p.birthDate!.month}.${p.birthDate!.year}'),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _ActionRow(icon: Icons.calendar_month, label: 'Programlar',
                    onTap: () { Navigator.pop(ctx); onPrograms(); }),
                _ActionRow(icon: Icons.bar_chart, label: 'İstatistikler',
                    onTap: () { Navigator.pop(ctx); onStats(); }),
                _ActionRow(icon: Icons.healing, label: 'Sakatlıklar',
                    onTap: () { Navigator.pop(ctx); onInjuries(); }),
                _ActionRow(icon: Icons.timer_outlined, label: 'Performans testleri',
                    onTap: () { Navigator.pop(ctx); onPerfTests(); }),
                _ActionRow(icon: Icons.directions_run, label: 'Hazırbulunuşluk geçmişi',
                    onTap: () { Navigator.pop(ctx); onAvailability(); }),
                _ActionRow(icon: Icons.chat_bubble_outline, label: 'Mesaj gönder',
                    onTap: () { Navigator.pop(ctx); onChat(); }),
                _ActionRow(icon: Icons.edit_outlined, label: 'Profili düzenle',
                    onTap: () { Navigator.pop(ctx); onEdit(); }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
