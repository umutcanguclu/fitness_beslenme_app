import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_exception.dart';
import '../api/matches_api.dart';
import '../models/match.dart';
import '../models/team.dart';
import '../util/labels.dart';

class MatchesScreen extends StatefulWidget {
  final MatchesApi matchesApi;
  final Team team;
  const MatchesScreen({super.key, required this.matchesApi, required this.team});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  Future<List<Match>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.matchesApi.listForTeam(widget.team.id);
    });
  }

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _MatchForm(
          matchesApi: widget.matchesApi,
          teamId: widget.team.id,
          existing: null,
        ),
      ),
    );
    if (created == true && mounted) _load();
  }

  Future<void> _editScore(Match m) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _MatchForm(
          matchesApi: widget.matchesApi,
          teamId: widget.team.id,
          existing: m,
        ),
      ),
    );
    if (updated == true && mounted) _load();
  }

  Future<void> _confirmDelete(Match m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Maçı sil'),
        content: Text('${formatDate(m.date)} ${m.opponent} maçı silinsin mi?'),
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
      await widget.matchesApi.delete(m.id);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maç silindi')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.team.name} — fikstür')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Maç'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<Match>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _errorView(context, snap.error!, _load);
            }
            final matches = snap.data ?? const <Match>[];
            if (matches.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const Icon(Icons.sports_soccer, size: 64),
                  const SizedBox(height: 16),
                  Text('Henüz maç eklenmemiş',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Sağ alttaki "+ Maç" ile ekle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: matches.length,
              itemBuilder: (ctx, i) => _MatchCard(
                match: matches[i],
                onTap: () => _editScore(matches[i]),
                onLongPress: () => _confirmDelete(matches[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _errorView(BuildContext context, Object error, VoidCallback onRetry) {
  final msg = error is ApiException ? error.message : error.toString();
  return ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
      const SizedBox(height: 12),
      Text(msg, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Center(child: FilledButton(onPressed: onRetry, child: const Text('Tekrar dene'))),
    ],
  );
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _MatchCard({required this.match, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final us = match.scoreUs;
    final them = match.scoreThem;
    final result = (us != null && them != null)
        ? (us > them ? 'G' : (us < them ? 'M' : 'B'))
        : null;
    final resultColor = result == 'G'
        ? Colors.green
        : (result == 'M' ? theme.colorScheme.error : Colors.orange);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(match.isHome ? Icons.home : Icons.flight_takeoff,
              color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text('vs ${match.opponent}'),
        subtitle: Text(
            '${formatDate(match.date)} · ${match.isHome ? 'Ev sahibi' : 'Deplasman'}${match.competition != null ? ' · ${match.competition}' : ''}'),
        trailing: result != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$us – $them',
                    style: TextStyle(color: resultColor, fontWeight: FontWeight.bold)),
              )
            : Text(match.isPast ? 'Skor gir' : 'Yaklaşan',
                style: theme.textTheme.bodySmall),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class _MatchForm extends StatefulWidget {
  final MatchesApi matchesApi;
  final String teamId;
  final Match? existing;
  const _MatchForm({required this.matchesApi, required this.teamId, this.existing});

  @override
  State<_MatchForm> createState() => _MatchFormState();
}

class _MatchFormState extends State<_MatchForm> {
  final _formKey = GlobalKey<FormState>();
  late final _opponentCtrl = TextEditingController(text: widget.existing?.opponent ?? '');
  late final _competitionCtrl = TextEditingController(text: widget.existing?.competition ?? '');
  late final _scoreUsCtrl = TextEditingController(
      text: widget.existing?.scoreUs?.toString() ?? '');
  late final _scoreThemCtrl = TextEditingController(
      text: widget.existing?.scoreThem?.toString() ?? '');
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  late DateTime _date = widget.existing?.date ?? DateTime.now().add(const Duration(days: 7));
  late TimeOfDay _time =
      TimeOfDay.fromDateTime(widget.existing?.date ?? DateTime.now());
  late bool _isHome = widget.existing?.isHome ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _opponentCtrl.dispose();
    _competitionCtrl.dispose();
    _scoreUsCtrl.dispose();
    _scoreThemCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  DateTime get _combinedDate => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (widget.existing == null) {
        await widget.matchesApi.create(widget.teamId, CreateMatchInput(
          opponent: _opponentCtrl.text.trim(),
          date: _combinedDate,
          isHome: _isHome,
          competition: _competitionCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        ));
      } else {
        final us = _scoreUsCtrl.text.trim();
        final them = _scoreThemCtrl.text.trim();
        await widget.matchesApi.update(widget.existing!.id, UpdateMatchInput(
          opponent: _opponentCtrl.text.trim(),
          date: _combinedDate,
          isHome: _isHome,
          competition: _competitionCtrl.text.trim(),
          scoreUs: us.isEmpty ? null : int.tryParse(us),
          scoreThem: them.isEmpty ? null : int.tryParse(them),
          notes: _notesCtrl.text.trim(),
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ))),
              const SizedBox(height: 16),
              Text(isEdit ? 'Maç güncelle' : 'Yeni maç',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _opponentCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Rakip',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shield),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Rakip gerekli' : null,
                enabled: !_busy,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _busy ? null : _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tarih',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(formatDate(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _busy ? null : _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Saat',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_time.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Ev sahibi'), icon: Icon(Icons.home)),
                  ButtonSegment(value: false, label: Text('Deplasman'), icon: Icon(Icons.flight_takeoff)),
                ],
                selected: {_isHome},
                onSelectionChanged: _busy ? null : (s) => setState(() => _isHome = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _competitionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lig / kupa (opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emoji_events),
                ),
                enabled: !_busy,
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scoreUsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Bizim skor',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_busy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _scoreThemCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Rakip skor',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_busy,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Not (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
                enabled: !_busy,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Güncelle' : 'Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
