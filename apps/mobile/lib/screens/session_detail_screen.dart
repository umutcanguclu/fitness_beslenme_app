import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/programs_api.dart';
import '../models/program.dart';
import '../util/labels.dart';

class SessionDetailScreen extends StatefulWidget {
  final ProgramsApi programsApi;
  final TrainingSession session;
  final bool canLogRpe;

  const SessionDetailScreen({
    super.key,
    required this.programsApi,
    required this.session,
    required this.canLogRpe,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late SessionLog? _existingLog = widget.session.logs.isNotEmpty ? widget.session.logs.first : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.session;
    return Scaffold(
      appBar: AppBar(
        title: Text(trainingCategoryLabel(s.category)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayLong(s.date.weekday), style: theme.textTheme.titleSmall),
                  Text(formatDate(s.date),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Chip(icon: Icons.timer_outlined, label: '${s.durationMinutes} dk'),
                      const SizedBox(width: 8),
                      _Chip(icon: Icons.bolt_outlined, label: 'Şiddet ${s.intensity}/5'),
                      const SizedBox(width: 8),
                      _Chip(icon: Icons.group_outlined, label: sessionTypeLabel(s.type)),
                    ],
                  ),
                  if (s.notes != null && s.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(s.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Egzersizler', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (s.exercises.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bu seansta egzersiz yok.'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < s.exercises.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ExerciseRow(item: s.exercises[i], index: i + 1),
                  ],
                ],
              ),
            ),
          if (widget.canLogRpe) ...[
            const SizedBox(height: 24),
            _RpeForm(
              programsApi: widget.programsApi,
              sessionId: s.id,
              existing: _existingLog,
              onSaved: (log) => setState(() => _existingLog = log),
            ),
          ] else if (_existingLog != null) ...[
            const SizedBox(height: 24),
            Text('Oyuncu geri bildirimi', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _LogReadOnlyCard(log: _existingLog!),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final SessionExercise item;
  final int index;
  const _ExerciseRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$index',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.exercise.nameTr, style: theme.textTheme.titleSmall),
                if (item.exercise.description != null && item.exercise.description!.isNotEmpty)
                  Text(item.exercise.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _buildMetricChips(item, theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetricChips(SessionExercise item, ThemeData theme) {
    final chips = <Widget>[];
    if (item.sets != null && item.reps != null) {
      chips.add(_metric('${item.sets}×${item.reps}', theme));
    } else if (item.sets != null) {
      chips.add(_metric('${item.sets} set', theme));
    } else if (item.reps != null) {
      chips.add(_metric('${item.reps} tekrar', theme));
    }
    if (item.durationSeconds != null) {
      chips.add(_metric('${item.durationSeconds} sn', theme));
    }
    if (item.distanceMeters != null) {
      chips.add(_metric('${item.distanceMeters} m', theme));
    }
    if (item.restSeconds != null && item.restSeconds! > 0) {
      chips.add(_metric('${item.restSeconds}s dinlenme', theme));
    }
    if (item.intensity != null) {
      chips.add(_metric('Şiddet ${item.intensity}/5', theme));
    }
    return chips;
  }

  Widget _metric(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer)),
    );
  }
}

class _RpeForm extends StatefulWidget {
  final ProgramsApi programsApi;
  final String sessionId;
  final SessionLog? existing;
  final ValueChanged<SessionLog> onSaved;

  const _RpeForm({
    required this.programsApi,
    required this.sessionId,
    required this.existing,
    required this.onSaved,
  });

  @override
  State<_RpeForm> createState() => _RpeFormState();
}

class _RpeFormState extends State<_RpeForm> {
  late int? _rpe = widget.existing?.rpe;
  late int? _fatigue = widget.existing?.fatigue;
  late int? _mood = widget.existing?.mood;
  final _notesCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = widget.existing?.notes ?? '';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rpe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RPE değeri gir (1-10)')));
      return;
    }
    setState(() => _busy = true);
    try {
      final log = await widget.programsApi.logSession(
        sessionId: widget.sessionId,
        rpe: _rpe,
        fatigue: _fatigue,
        mood: _mood,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      widget.onSaved(log);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri bildirim kaydedildi')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'Antrenman sonrası geri bildirim' : 'Geri bildirim (güncelle)',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('RPE — efor seviyesi (1=çok hafif, 10=maksimum)',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            _NumberPicker(
              value: _rpe,
              min: 1,
              max: 10,
              onChanged: _busy ? null : (v) => setState(() => _rpe = v),
            ),
            const SizedBox(height: 16),
            Text('Yorgunluk (1=dinç, 5=çok yorgun)', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            _NumberPicker(
              value: _fatigue,
              min: 1,
              max: 5,
              onChanged: _busy ? null : (v) => setState(() => _fatigue = v),
            ),
            const SizedBox(height: 16),
            Text('Mood (1=kötü, 5=harika)', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            _NumberPicker(
              value: _mood,
              min: 1,
              max: 5,
              onChanged: _busy ? null : (v) => setState(() => _mood = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                border: OutlineInputBorder(),
              ),
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.existing == null ? 'Kaydet' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final int? value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;
  const _NumberPicker({required this.value, required this.min, required this.max, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      children: [
        for (var i = min; i <= max; i++)
          ChoiceChip(
            label: Text('$i'),
            selected: value == i,
            onSelected: onChanged == null ? null : (sel) {
              if (sel) onChanged!(i);
            },
            labelStyle: TextStyle(
              fontWeight: value == i ? FontWeight.bold : FontWeight.normal,
              color: value == i ? theme.colorScheme.onPrimary : null,
            ),
            selectedColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _LogReadOnlyCard extends StatelessWidget {
  final SessionLog log;
  const _LogReadOnlyCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(k, style: theme.textTheme.bodySmall)),
              Text(v, style: theme.textTheme.bodyMedium),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.rpe != null) kv('RPE', '${log.rpe}/10'),
            if (log.fatigue != null) kv('Yorgunluk', '${log.fatigue}/5'),
            if (log.mood != null) kv('Mood', '${log.mood}/5'),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Not:', style: theme.textTheme.bodySmall),
              Text(log.notes!),
            ],
          ],
        ),
      ),
    );
  }
}
