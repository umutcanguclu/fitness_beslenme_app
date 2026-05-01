import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/clubs_api.dart';
import '../api/health_api.dart';
import '../api/matches_api.dart';
import '../api/programs_api.dart';
import '../api/teams_api.dart';
import '../models/club.dart';
import '../models/team.dart';
import '../util/labels.dart';
import 'team_create_screen.dart';
import 'team_detail_screen.dart';

class ClubScreen extends StatefulWidget {
  final ClubsApi clubsApi;
  final TeamsApi teamsApi;
  final ProgramsApi programsApi;
  final MatchesApi matchesApi;
  final HealthApi healthApi;

  const ClubScreen({
    super.key,
    required this.clubsApi,
    required this.teamsApi,
    required this.programsApi,
    required this.matchesApi,
    required this.healthApi,
  });

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  Future<_ClubData>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<_ClubData> _fetch() async {
    final club = await widget.clubsApi.getMyClub();
    if (club == null) {
      return _ClubData(club: null, facilities: const [], equipment: const [], teams: const []);
    }
    final results = await Future.wait([
      widget.clubsApi.listFacilities(club.id),
      widget.clubsApi.listEquipment(club.id),
      widget.teamsApi.listMyTeams(),
    ]);
    return _ClubData(
      club: club,
      facilities: results[0] as List<Facility>,
      equipment: results[1] as List<Equipment>,
      teams: results[2] as List<Team>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kulübüm')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<_ClubData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorView(error: snap.error!, onRetry: _load);
            }
            final data = snap.data!;
            if (data.club == null) return const _NoClubView();
            return _ClubBody(
              data: data,
              onTeamTap: _openTeam,
              onTeamLongPress: _confirmDeleteTeam,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTeam,
        icon: const Icon(Icons.add),
        label: const Text('Takım'),
      ),
    );
  }

  Future<void> _openTeam(Team team) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TeamDetailScreen(
        teamsApi: widget.teamsApi,
        programsApi: widget.programsApi,
        matchesApi: widget.matchesApi,
        healthApi: widget.healthApi,
        team: team,
      ),
    ));
    if (mounted) _load();
  }

  Future<void> _createTeam() async {
    final created = await Navigator.of(context).push<Team>(MaterialPageRoute(
      builder: (_) => TeamCreateScreen(teamsApi: widget.teamsApi),
    ));
    if (created != null && mounted) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${created.name}" oluşturuldu')));
    }
  }

  Future<void> _confirmDeleteTeam(Team team) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Takımı sil'),
        content: Text('"${team.name}" silinecek. Devam edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.teamsApi.deleteTeam(team.id);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${team.name}" silindi')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _ClubData {
  final Club? club;
  final List<Facility> facilities;
  final List<Equipment> equipment;
  final List<Team> teams;
  const _ClubData({
    required this.club,
    required this.facilities,
    required this.equipment,
    required this.teams,
  });
}

class _ClubBody extends StatelessWidget {
  final _ClubData data;
  final ValueChanged<Team> onTeamTap;
  final ValueChanged<Team> onTeamLongPress;
  const _ClubBody({
    required this.data,
    required this.onTeamTap,
    required this.onTeamLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final club = data.club!;
    return ListView(
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
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shield, color: theme.colorScheme.onPrimaryContainer, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(club.name, style: theme.textTheme.titleLarge),
                          if (club.league != null && club.league!.isNotEmpty)
                            Text(club.league!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (club.city != null && club.city!.isNotEmpty)
                  _InfoLine(icon: Icons.location_on_outlined, text: club.city!),
                if (club.foundedYear != null)
                  _InfoLine(icon: Icons.calendar_today_outlined, text: 'Kuruluş: ${club.foundedYear}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Takımlar', count: data.teams.length),
        const SizedBox(height: 8),
        if (data.teams.isEmpty)
          const _EmptyCard(message: 'Henüz takım eklenmemiş. Sağ alttaki "+ Takım" ile oluştur.')
        else
          ...data.teams.map((t) => _TeamTile(
                team: t,
                onTap: () => onTeamTap(t),
                onLongPress: () => onTeamLongPress(t),
              )),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Tesisler', count: data.facilities.length),
        const SizedBox(height: 8),
        if (data.facilities.isEmpty)
          const _EmptyCard(message: 'Tesis kaydı yok.')
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < data.facilities.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.stadium_outlined),
                    title: Text(data.facilities[i].name),
                    subtitle: Text(facilityTypeLabel(data.facilities[i].type)),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Ekipman', count: data.equipment.length),
        const SizedBox(height: 8),
        if (data.equipment.isEmpty)
          const _EmptyCard(message: 'Ekipman kaydı yok.')
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in data.equipment)
                    Chip(
                      avatar: const Icon(Icons.fitness_center, size: 16),
                      label: Text('${equipmentLabel(e.item)} × ${e.quantity}'),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: theme.textTheme.labelSmall),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _TeamTile({
    required this.team,
    required this.onTap,
    required this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(team.name.characters.first.toUpperCase())),
        title: Text(team.name),
        subtitle: Text('${teamCategoryLabel(team.category)} · ${team.season}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = error is ApiException ? (error as ApiException).message : error.toString();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 12),
        Text(msg, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(child: FilledButton(onPressed: onRetry, child: const Text('Tekrar dene'))),
      ],
    );
  }
}

class _NoClubView extends StatelessWidget {
  const _NoClubView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.shield_outlined, size: 64),
        const SizedBox(height: 16),
        Text('Henüz bir kulübün yok',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Kulüp oluşturmak için bir sonraki sürümde "Kulüp oluştur" akışı eklenecek.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
