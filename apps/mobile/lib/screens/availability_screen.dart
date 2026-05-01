import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/health_api.dart';
import '../models/health.dart';
import '../util/labels.dart';

const _statusOptions = ['ready', 'doubtful', 'limited', 'injured', 'ill', 'suspended', 'away'];

class AvailabilityScreen extends StatefulWidget {
  final HealthApi healthApi;
  final String playerId;
  final bool canEdit; // player or coach can edit; coach view-only for others
  const AvailabilityScreen({
    super.key,
    required this.healthApi,
    required this.playerId,
    required this.canEdit,
  });

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  Future<List<PlayerAvailability>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.healthApi.listAvailability(
        widget.playerId,
        from: DateTime.now().subtract(const Duration(days: 30)),
        to: DateTime.now().add(const Duration(days: 14)),
      );
    });
  }

  Future<void> _addOrUpdate() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AvailabilityForm(
          healthApi: widget.healthApi,
          playerId: widget.playerId,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hazırbulunuşluk')),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _addOrUpdate,
              icon: const Icon(Icons.add_task),
              label: const Text('Bildir'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<PlayerAvailability>>(
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
                children: [Text(msg, textAlign: TextAlign.center)],
              );
            }
            final list = snap.data ?? const <PlayerAvailability>[];
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const Icon(Icons.directions_run, size: 64),
                  const SizedBox(height: 16),
                  Text('Henüz kayıt yok',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    widget.canEdit
                        ? 'Sağ alttaki "+ Bildir" ile bugünkü durumunu kaydet.'
                        : 'Oyuncu henüz hazırbulunuşluk girmemiş.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _AvailabilityCard(item: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final PlayerAvailability item;
  const _AvailabilityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(item.status, theme);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_statusIcon(item.status), color: color),
        ),
        title: Text(availabilityLabel(item.status)),
        subtitle: Text(formatDate(item.date)),
        trailing: item.note != null && item.note!.isNotEmpty
            ? const Icon(Icons.sticky_note_2_outlined)
            : null,
        onTap: item.note != null && item.note!.isNotEmpty
            ? () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('${availabilityLabel(item.status)} — ${formatDate(item.date)}'),
                    content: Text(item.note!),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
                  ),
                )
            : null,
      ),
    );
  }
}

Color _statusColor(String s, ThemeData theme) {
  switch (s) {
    case 'ready':
      return Colors.green;
    case 'doubtful':
    case 'limited':
      return Colors.orange;
    case 'injured':
    case 'ill':
    case 'suspended':
      return theme.colorScheme.error;
    case 'away':
      return theme.colorScheme.secondary;
  }
  return theme.colorScheme.onSurfaceVariant;
}

IconData _statusIcon(String s) {
  switch (s) {
    case 'ready':
      return Icons.check_circle;
    case 'doubtful':
      return Icons.help_outline;
    case 'limited':
      return Icons.warning_amber;
    case 'injured':
      return Icons.healing;
    case 'ill':
      return Icons.sick;
    case 'suspended':
      return Icons.gavel;
    case 'away':
      return Icons.flight;
  }
  return Icons.circle;
}

class _AvailabilityForm extends StatefulWidget {
  final HealthApi healthApi;
  final String playerId;
  const _AvailabilityForm({required this.healthApi, required this.playerId});

  @override
  State<_AvailabilityForm> createState() => _AvailabilityFormState();
}

class _AvailabilityFormState extends State<_AvailabilityForm> {
  DateTime _date = DateTime.now();
  String _status = 'ready';
  final _noteCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.healthApi.setAvailability(
        playerId: widget.playerId,
        date: _date,
        status: _status,
        note: _noteCtrl.text.trim(),
      );
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ))),
            const SizedBox(height: 16),
            Text('Hazırbulunuşluk bildir',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            InkWell(
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Durum',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(availabilityLabel(s))))
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
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
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
