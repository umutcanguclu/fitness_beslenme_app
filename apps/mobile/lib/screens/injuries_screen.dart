import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/health_api.dart';
import '../models/health.dart';
import '../util/labels.dart';

const _injuryTypes = ['muscle', 'ligament', 'joint', 'bone', 'tendon', 'concussion', 'other'];
const _severities = ['minor', 'moderate', 'major', 'severe'];

class InjuriesScreen extends StatefulWidget {
  final HealthApi healthApi;
  final String playerId;
  final String playerName;
  const InjuriesScreen({
    super.key,
    required this.healthApi,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<InjuriesScreen> createState() => _InjuriesScreenState();
}

class _InjuriesScreenState extends State<InjuriesScreen> {
  Future<List<InjuryRecord>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.healthApi.listInjuries(widget.playerId);
    });
  }

  Future<void> _create() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _InjuryForm(healthApi: widget.healthApi, playerId: widget.playerId),
      ),
    );
    if (ok == true && mounted) _load();
  }

  Future<void> _resolve(InjuryRecord r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sakatlığı kapat'),
        content: const Text('Sakatlık iyileşti olarak işaretlensin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kapat')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.healthApi.resolveInjury(widget.playerId, r.id, resolvedAt: DateTime.now());
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.playerName} — sakatlıklar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.healing),
        label: const Text('Yeni'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<InjuryRecord>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final msg = snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : snap.error.toString();
              return ListView(padding: const EdgeInsets.all(24), children: [Text(msg)]);
            }
            final list = snap.data ?? const <InjuryRecord>[];
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const Icon(Icons.healing, size: 64),
                  const SizedBox(height: 16),
                  Text('Sakatlık kaydı yok',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _InjuryCard(item: list[i], onResolve: () => _resolve(list[i])),
            );
          },
        ),
      ),
    );
  }
}

class _InjuryCard extends StatelessWidget {
  final InjuryRecord item;
  final VoidCallback onResolve;
  const _InjuryCard({required this.item, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.isActive ? theme.colorScheme.error : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(Icons.healing, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${injuryTypeLabel(item.type)} · ${item.bodyPart}',
                          style: theme.textTheme.titleMedium),
                      Text(injurySeverityLabel(item.severity),
                          style: theme.textTheme.bodySmall?.copyWith(color: color)),
                    ],
                  ),
                ),
                if (item.isActive)
                  TextButton(onPressed: onResolve, child: const Text('Kapat'))
                else
                  Chip(label: Text('İyileşti'), visualDensity: VisualDensity.compact, backgroundColor: theme.colorScheme.surfaceContainerHighest),
              ],
            ),
            const SizedBox(height: 8),
            Text('Başlangıç: ${formatDate(item.startedAt)}',
                style: theme.textTheme.bodySmall),
            if (item.expectedReturn != null)
              Text('Tahmini dönüş: ${formatDate(item.expectedReturn!)}',
                  style: theme.textTheme.bodySmall),
            if (item.resolvedAt != null)
              Text('Kapanış: ${formatDate(item.resolvedAt!)}',
                  style: theme.textTheme.bodySmall),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InjuryForm extends StatefulWidget {
  final HealthApi healthApi;
  final String playerId;
  const _InjuryForm({required this.healthApi, required this.playerId});

  @override
  State<_InjuryForm> createState() => _InjuryFormState();
}

class _InjuryFormState extends State<_InjuryForm> {
  final _formKey = GlobalKey<FormState>();
  final _bodyPartCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'muscle';
  String _severity = 'minor';
  DateTime _startedAt = DateTime.now();
  DateTime? _expectedReturn;
  bool _busy = false;

  @override
  void dispose() {
    _bodyPartCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStarted() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _startedAt = picked);
  }

  Future<void> _pickReturn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedReturn ?? _startedAt.add(const Duration(days: 14)),
      firstDate: _startedAt,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _expectedReturn = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.healthApi.createInjury(
        playerId: widget.playerId,
        type: _type,
        severity: _severity,
        bodyPart: _bodyPartCtrl.text.trim(),
        startedAt: _startedAt,
        expectedReturn: _expectedReturn,
        description: _descCtrl.text.trim(),
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
              Text('Yeni sakatlık', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tür', border: OutlineInputBorder()),
                items: _injuryTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(injuryTypeLabel(t))))
                    .toList(),
                onChanged: _busy ? null : (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _severity,
                decoration: const InputDecoration(labelText: 'Şiddet', border: OutlineInputBorder()),
                items: _severities
                    .map((s) => DropdownMenuItem(value: s, child: Text(injurySeverityLabel(s))))
                    .toList(),
                onChanged: _busy ? null : (v) => setState(() => _severity = v ?? _severity),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyPartCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bölge',
                  helperText: 'Örn. "sağ arka adale", "sol diz"',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bölge gerekli' : null,
                enabled: !_busy,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _busy ? null : _pickStarted,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Başlangıç',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(formatDate(_startedAt)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _busy ? null : _pickReturn,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tahmini dönüş',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_expectedReturn == null ? '—' : formatDate(_expectedReturn!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
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
      ),
    );
  }
}
