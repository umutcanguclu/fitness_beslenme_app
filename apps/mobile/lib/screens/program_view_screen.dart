import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/programs_api.dart';
import '../models/program.dart';
import '../util/labels.dart';
import 'session_detail_screen.dart';

class ProgramViewScreen extends StatefulWidget {
  final ProgramsApi programsApi;
  final String playerId;
  final String playerName;
  final bool canGenerate;     // coach -> true, player -> false
  final bool canLogRpe;       // player -> true (own program), coach -> false

  const ProgramViewScreen({
    super.key,
    required this.programsApi,
    required this.playerId,
    required this.playerName,
    required this.canGenerate,
    required this.canLogRpe,
  });

  @override
  State<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

class _ProgramViewScreenState extends State<ProgramViewScreen> {
  Future<List<TrainingProgram>>? _future;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.programsApi.listForPlayer(widget.playerId);
    });
  }

  Future<void> _generateThisWeek() async {
    setState(() => _generating = true);
    try {
      final monday = _mondayOfThisWeek();
      await widget.programsApi.generateForPlayer(
        playerId: widget.playerId,
        weekStartDate: monday,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu haftanın programı üretildi (${formatDate(monday)})')),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.canLogRpe ? 'Programım' : '${widget.playerName} — programlar'),
      ),
      floatingActionButton: widget.canGenerate
          ? FloatingActionButton.extended(
              onPressed: _generating ? null : _generateThisWeek,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(_generating ? 'Üretiliyor…' : 'Bu haftaya üret'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<TrainingProgram>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorView(error: snap.error!, onRetry: _load);
            }
            final programs = snap.data ?? const <TrainingProgram>[];
            if (programs.isEmpty) {
              return _EmptyView(canGenerate: widget.canGenerate);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: programs.length,
              itemBuilder: (ctx, i) => _ProgramCard(
                program: programs[i],
                expandedByDefault: i == 0,
                onSessionTap: (s) => _openSession(s),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openSession(TrainingSession s) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionDetailScreen(
        programsApi: widget.programsApi,
        session: s,
        canLogRpe: widget.canLogRpe,
      ),
    ));
    if (mounted) _load();
  }
}

class _ProgramCard extends StatefulWidget {
  final TrainingProgram program;
  final bool expandedByDefault;
  final ValueChanged<TrainingSession> onSessionTap;
  const _ProgramCard({
    required this.program,
    required this.expandedByDefault,
    required this.onSessionTap,
  });

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  late bool _expanded = widget.expandedByDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.program;
    final weekEnd = p.weekStartDate.add(const Duration(days: 6));
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.calendar_month,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text('${formatDate(p.weekStartDate)} – ${formatDate(weekEnd)}'),
            subtitle: Text(microcycleLabel(p.microcycleType)),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...p.sessions.map((s) => _SessionRow(
                  session: s,
                  onTap: () => widget.onSessionTap(s),
                )),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final TrainingSession session;
  final VoidCallback onTap;
  const _SessionRow({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final off = session.isOff;
    final logged = session.logs.isNotEmpty;
    return InkWell(
      onTap: off ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    dayShort(session.date.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text('${session.date.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (off)
                    Text('Dinlenme',
                        style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant))
                  else
                    Text(trainingCategoryLabel(session.category),
                        style: theme.textTheme.titleSmall),
                  if (!off)
                    Text(
                      '${sessionTypeLabel(session.type)} · ${session.durationMinutes} dk · şiddet ${session.intensity}/5',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (!off) ...[
              if (logged)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else
                Text('${session.exercises.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool canGenerate;
  const _EmptyView({required this.canGenerate});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.calendar_today_outlined, size: 64),
        const SizedBox(height: 16),
        Text('Henüz program yok',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          canGenerate
              ? 'Sağ alttaki "Bu haftaya üret" ile haftalık program üretebilirsin.'
              : 'Antrenörün senin için program üretmedi. Üretildiğinde burada görünecek.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final msg = error is ApiException ? (error as ApiException).message : error.toString();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.error_outline,
            size: 48, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12),
        Text(msg, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(child: FilledButton(onPressed: onRetry, child: const Text('Tekrar dene'))),
      ],
    );
  }
}

DateTime _mondayOfThisWeek() {
  final now = DateTime.now();
  final day = now.weekday; // 1..7
  return DateTime(now.year, now.month, now.day - (day - 1));
}
