import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/health_api.dart';
import '../api/programs_api.dart';
import '../models/health.dart';
import '../models/program.dart';
import '../util/exercise_visuals.dart';
import '../util/labels.dart';

// Aggregates RPE values + availability into a quick visual summary.
// Pulls last ~4 weeks of programs (per-player) and last 30 days of availability.

class PlayerStatsScreen extends StatefulWidget {
  final ProgramsApi programsApi;
  final HealthApi healthApi;
  final String playerId;
  final String playerName;
  const PlayerStatsScreen({
    super.key,
    required this.programsApi,
    required this.healthApi,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _StatsData {
  final List<TrainingProgram> programs;
  final List<PlayerAvailability> availability;
  const _StatsData({required this.programs, required this.availability});
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  Future<_StatsData>? _future;

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

  Future<_StatsData> _fetch() async {
    final from = DateTime.now().subtract(const Duration(days: 28));
    final results = await Future.wait([
      widget.programsApi.listForPlayer(widget.playerId, from: from),
      widget.healthApi.listAvailability(widget.playerId,
          from: DateTime.now().subtract(const Duration(days: 30)),
          to: DateTime.now()),
    ]);
    return _StatsData(
      programs: results[0] as List<TrainingProgram>,
      availability: results[1] as List<PlayerAvailability>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.playerName} — istatistik')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<_StatsData>(
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
            return _StatsBody(data: snap.data!);
          },
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final _StatsData data;
  const _StatsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Collect RPE values + dates
    final rpeEntries = <_RpeEntry>[];
    int totalSessions = 0;
    int loggedSessions = 0;
    final categoryCount = <String, int>{};
    int totalMinutes = 0;
    for (final p in data.programs) {
      for (final s in p.sessions) {
        if (s.isOff) continue;
        totalSessions++;
        totalMinutes += s.durationMinutes;
        categoryCount[s.category] = (categoryCount[s.category] ?? 0) + 1;
        for (final log in s.logs) {
          if (log.rpe != null) {
            rpeEntries.add(_RpeEntry(s.date, log.rpe!));
            loggedSessions++;
          }
        }
      }
    }
    rpeEntries.sort((a, b) => a.date.compareTo(b.date));
    final avgRpe = rpeEntries.isEmpty
        ? 0.0
        : rpeEntries.map((e) => e.rpe).reduce((a, b) => a + b) / rpeEntries.length;

    // Availability stats
    final availCount = <String, int>{};
    for (final a in data.availability) {
      availCount[a.status] = (availCount[a.status] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                label: 'Antrenman',
                value: '$totalSessions',
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.timer,
                label: 'Toplam dakika',
                value: '$totalMinutes',
                color: const Color(0xFF7B1FA2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.bolt,
                label: 'Ort. RPE',
                value: rpeEntries.isEmpty ? '—' : avgRpe.toStringAsFixed(1),
                color: rpeEntries.isEmpty ? Colors.grey : intensityColor(avgRpe.round()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                label: 'Geri bildirim',
                value: '$loggedSessions/$totalSessions',
                color: const Color(0xFF388E3C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionHeader('RPE trendi (son ${rpeEntries.length} kayıt)'),
        const SizedBox(height: 12),
        if (rpeEntries.isEmpty)
          _emptyCard(context, 'Henüz RPE kaydı yok')
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _RpeChart(entries: rpeEntries),
            ),
          ),
        const SizedBox(height: 24),
        _SectionHeader('Antrenman dağılımı'),
        const SizedBox(height: 12),
        if (categoryCount.isEmpty)
          _emptyCard(context, 'Henüz antrenman yok')
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: categoryCount.entries
                    .toList()
                    .where((e) => e.value > 0)
                    .map((e) => _CategoryBar(
                          category: e.key,
                          count: e.value,
                          maxCount: categoryCount.values.reduce((a, b) => a > b ? a : b),
                        ))
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 24),
        _SectionHeader('Hazırbulunuşluk dağılımı (son 30 gün)'),
        const SizedBox(height: 12),
        if (availCount.isEmpty)
          _emptyCard(context, 'Henüz kayıt yok')
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availCount.entries
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _availColor(e.key, theme).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_availIcon(e.key),
                                  size: 14, color: _availColor(e.key, theme)),
                              const SizedBox(width: 6),
                              Text('${availabilityLabel(e.key)} · ${e.value}',
                                  style: TextStyle(color: _availColor(e.key, theme))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyCard(BuildContext context, String msg) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(msg,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
}

class _RpeEntry {
  final DateTime date;
  final int rpe;
  const _RpeEntry(this.date, this.rpe);
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  maxLines: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _RpeChart extends StatelessWidget {
  final List<_RpeEntry> entries;
  const _RpeChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const chartHeight = 180.0;
    const barMax = 120.0;
    const labelHeight = 28.0;
    return SizedBox(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y-axis labels — sabit yükseklikli (chart - label area).
          SizedBox(
            height: chartHeight - labelHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('10', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text('5', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text('1', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.reversed.take(20).toList().reversed.map((e) {
                  final h = (e.rpe / 10) * barMax;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                intensityColor(e.rpe),
                                intensityColor(e.rpe).withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 16,
                          child: Text('${e.date.day}/${e.date.month}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final int count;
  final int maxCount;
  const _CategoryBar({
    required this.category,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualForCategory(category);
    final ratio = count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(visual.icon, size: 16, color: visual.color),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(trainingCategoryLabel(category),
                style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: visual.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold, color: visual.color)),
          ),
        ],
      ),
    );
  }
}

Color _availColor(String s, ThemeData theme) {
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
  }
  return theme.colorScheme.secondary;
}

IconData _availIcon(String s) {
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
  }
  return Icons.flight;
}
