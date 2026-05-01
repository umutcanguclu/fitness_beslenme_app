import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/health_api.dart';
import '../models/health.dart';
import '../util/labels.dart';

const _testTypes = [
  'sprint_10m', 'sprint_20m', 'sprint_30m',
  'agility_505', 'agility_t_test',
  'yo_yo_ir1', 'yo_yo_ir2', 'beep_test', 'cooper_test',
  'vertical_jump', 'broad_jump',
  'bench_press_1rm', 'squat_1rm',
  'pull_ups_max', 'push_ups_max',
  'flexibility_sit_reach', 'body_fat_percent',
];

const _defaultUnit = {
  'sprint_10m': 's', 'sprint_20m': 's', 'sprint_30m': 's',
  'agility_505': 's', 'agility_t_test': 's',
  'yo_yo_ir1': 'm', 'yo_yo_ir2': 'm', 'beep_test': 'level', 'cooper_test': 'm',
  'vertical_jump': 'cm', 'broad_jump': 'cm',
  'bench_press_1rm': 'kg', 'squat_1rm': 'kg',
  'pull_ups_max': 'rep', 'push_ups_max': 'rep',
  'flexibility_sit_reach': 'cm', 'body_fat_percent': '%',
};

class PerfTestsScreen extends StatefulWidget {
  final HealthApi healthApi;
  final String playerId;
  final String playerName;
  final bool canEdit; // coach
  const PerfTestsScreen({
    super.key,
    required this.healthApi,
    required this.playerId,
    required this.playerName,
    required this.canEdit,
  });

  @override
  State<PerfTestsScreen> createState() => _PerfTestsScreenState();
}

class _PerfTestsScreenState extends State<PerfTestsScreen> {
  Future<List<PerformanceTest>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.healthApi.listPerformanceTests(widget.playerId);
    });
  }

  Future<void> _add() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _PerfTestForm(healthApi: widget.healthApi, playerId: widget.playerId),
      ),
    );
    if (ok == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.playerName} — testler')),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.timer),
              label: const Text('Test'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<PerformanceTest>>(
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
            final list = snap.data ?? const <PerformanceTest>[];
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const Icon(Icons.timer_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text('Test sonucu yok',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              );
            }
            // Grup by type
            final grouped = <String, List<PerformanceTest>>{};
            for (final t in list) {
              grouped.putIfAbsent(t.type, () => []).add(t);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final entry in grouped.entries)
                  _TestGroupCard(type: entry.key, tests: entry.value),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TestGroupCard extends StatelessWidget {
  final String type;
  final List<PerformanceTest> tests;
  const _TestGroupCard({required this.type, required this.tests});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = tests.first;
    final delta = tests.length > 1 ? latest.value - tests[1].value : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(perfTestLabel(type), style: theme.textTheme.titleMedium),
                ),
                Text('${latest.value} ${latest.unit}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(formatDate(latest.testedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                if (delta != null) ...[
                  const Spacer(),
                  Icon(delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: delta > 0 ? Colors.green : theme.colorScheme.error),
                  Text('${delta.abs()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: delta > 0 ? Colors.green : theme.colorScheme.error)),
                ],
              ],
            ),
            if (tests.length > 1) ...[
              const Divider(height: 24),
              Text('Geçmiş', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              ...tests.skip(1).take(5).map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(formatDate(t.testedAt), style: theme.textTheme.bodySmall),
                        const Spacer(),
                        Text('${t.value} ${t.unit}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _PerfTestForm extends StatefulWidget {
  final HealthApi healthApi;
  final String playerId;
  const _PerfTestForm({required this.healthApi, required this.playerId});

  @override
  State<_PerfTestForm> createState() => _PerfTestFormState();
}

class _PerfTestFormState extends State<_PerfTestForm> {
  final _formKey = GlobalKey<FormState>();
  final _valueCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'sprint_10m';
  DateTime _testedAt = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _unitCtrl.text = _defaultUnit[_type] ?? '';
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _unitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _testedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _testedAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.healthApi.createPerformanceTest(
        playerId: widget.playerId,
        type: _type,
        value: num.parse(_valueCtrl.text.trim()),
        unit: _unitCtrl.text.trim(),
        testedAt: _testedAt,
        notes: _notesCtrl.text.trim(),
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
              Text('Yeni performans testi', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Test', border: OutlineInputBorder()),
                items: _testTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(perfTestLabel(t))))
                    .toList(),
                onChanged: _busy ? null : (v) {
                  if (v == null) return;
                  setState(() {
                    _type = v;
                    _unitCtrl.text = _defaultUnit[v] ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Değer',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Değer gerekli';
                        if (num.tryParse(v.trim()) == null) return 'Sayı gir';
                        return null;
                      },
                      enabled: !_busy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Birim',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Birim gerekli' : null,
                      enabled: !_busy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _busy ? null : _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Test tarihi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(formatDate(_testedAt)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
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
