import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/programs_api.dart';
import '../models/program.dart';
import '../util/exercise_visuals.dart';
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
          _SessionHeaderCard(session: s),
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

class _SessionHeaderCard extends StatelessWidget {
  final TrainingSession session;
  const _SessionHeaderCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualForCategory(session.category);
    final intensityClr = intensityColor(session.intensity);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [visual.color, visual.color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(visual.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trainingCategoryLabel(session.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 2),
                      Text('${dayLong(session.date.weekday)} · ${formatDate(session.date)}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MetricBox(
                    icon: Icons.timer_outlined,
                    value: '${session.durationMinutes}',
                    unit: 'dk',
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                _MetricBox(
                    icon: Icons.bolt_outlined,
                    value: '${session.intensity}/5',
                    unit: 'şiddet',
                    color: intensityClr),
                const SizedBox(width: 12),
                _MetricBox(
                    icon: Icons.group_outlined,
                    value: sessionTypeLabel(session.type),
                    unit: 'tip',
                    color: theme.colorScheme.secondary,
                    isText: true),
              ],
            ),
          ),
          if (session.notes != null && session.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(session.notes!)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;
  final bool isText;
  const _MetricBox({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isText ? 13 : 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(unit,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
          ],
        ),
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
    final visual = visualForCategory(item.exercise.category);
    final mediaUrl = item.exercise.thumbnailUrl;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [visual.color, visual.color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: mediaUrl != null && mediaUrl.isNotEmpty
                      ? Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          width: 64,
                          height: 64,
                          errorBuilder: (_, __, ___) =>
                              Icon(visual.icon, color: Colors.white, size: 32),
                          loadingBuilder: (_, child, prog) =>
                              prog == null
                                  ? child
                                  : Center(
                                      child: SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white.withValues(alpha: 0.8)),
                                      ),
                                    ),
                        )
                      : Icon(visual.icon, color: Colors.white, size: 32),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
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
