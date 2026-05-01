import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_exception.dart';
import '../api/teams_api.dart';
import '../models/invite.dart';
import '../models/team.dart';
import '../util/labels.dart';

const _positions = ['goalkeeper', 'defender', 'midfielder', 'forward'];
const _detailedByGroup = {
  'goalkeeper': ['GK'],
  'defender': ['CB', 'LB', 'RB', 'LWB', 'RWB'],
  'midfielder': ['CDM', 'CM', 'CAM', 'LM', 'RM'],
  'forward': ['LW', 'RW', 'ST', 'CF', 'SS'],
};
const _foots = ['right', 'left', 'both'];
const _employments = ['amateur', 'semi_pro', 'full_time_pro', 'student', 'working'];

class PlayerCreateScreen extends StatefulWidget {
  final TeamsApi teamsApi;
  final Team team;
  const PlayerCreateScreen({super.key, required this.teamsApi, required this.team});

  @override
  State<PlayerCreateScreen> createState() => _PlayerCreateScreenState();
}

class _PlayerCreateScreenState extends State<PlayerCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _jerseyCtrl = TextEditingController();
  String _position = 'midfielder';
  String? _detailedPosition;
  String _foot = 'right';
  String _employment = 'amateur';
  DateTime? _birthDate;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _jerseyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 17, 1, 1),
      firstDate: DateTime(1960),
      lastDate: now,
      helpText: 'Doğum tarihi',
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğum tarihi gerekli')));
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await widget.teamsApi.createPlayer(
        widget.team.id,
        CreatePlayerInput(
          fullName: _nameCtrl.text.trim(),
          birthDate: _birthDate!,
          position: _position,
          detailedPosition: _detailedPosition,
          preferredFoot: _foot,
          heightCm: int.parse(_heightCtrl.text.trim()),
          weightKg: int.parse(_weightCtrl.text.trim()),
          employmentStatus: _employment,
          jerseyNumber: _jerseyCtrl.text.trim().isEmpty
              ? null
              : int.parse(_jerseyCtrl.text.trim()),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      await _showInviteDialog(result);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showInviteDialog(CreatePlayerResult result) async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 48),
        title: const Text('Oyuncu eklendi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.fullName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Davet kodu (oyuncuya WhatsApp ile gönder):',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SelectableText(
                      result.invite.code,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Kopyala',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.invite.code));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Kod kopyalandı')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Son kullanma: ${_formatDate(result.invite.expiresAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailedItems = _detailedByGroup[_position] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.team.name} — yeni oyuncu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad gerekli' : null,
                  enabled: !_busy,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _busy ? null : _pickBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Doğum tarihi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    child: Text(_birthDate == null ? 'Seç' : _formatDate(_birthDate!)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _position,
                  decoration: const InputDecoration(
                    labelText: 'Mevki',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                  items: _positions
                      .map((p) => DropdownMenuItem(value: p, child: Text(positionLabel(p))))
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() {
                            _position = v;
                            _detailedPosition = null;
                          });
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _detailedPosition,
                  decoration: const InputDecoration(
                    labelText: 'Detay mevki (opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('—')),
                    ...detailedItems.map(
                      (d) => DropdownMenuItem(value: d, child: Text(detailedPositionLabel(d))),
                    ),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _detailedPosition = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Boy (cm)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _validateRange(v, 120, 230, 'Boy 120-230'),
                        enabled: !_busy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Kilo (kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _validateRange(v, 30, 150, 'Kilo 30-150'),
                        enabled: !_busy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _foot,
                        decoration: const InputDecoration(
                          labelText: 'Tercih ayak',
                          border: OutlineInputBorder(),
                        ),
                        items: _foots
                            .map((f) => DropdownMenuItem(value: f, child: Text(footLabel(f))))
                            .toList(),
                        onChanged: _busy ? null : (v) => setState(() => _foot = v ?? _foot),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _jerseyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Forma no',
                          helperText: '1-99',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null; // optional
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1 || n > 99) return '1-99';
                          return null;
                        },
                        enabled: !_busy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _employment,
                  decoration: const InputDecoration(
                    labelText: 'Statü',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _employments
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(employmentLabel(e))))
                      .toList(),
                  onChanged:
                      _busy ? null : (v) => setState(() => _employment = v ?? _employment),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta (opsiyonel)',
                    helperText: 'Davet bu adrese atfedilir, sonradan eklenebilir',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                    return ok ? null : 'Geçerli bir e-posta gir';
                  },
                  enabled: !_busy,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Oyuncuyu ekle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _validateRange(String? v, int min, int max, String label) {
  if (v == null || v.trim().isEmpty) return 'Gerekli';
  final n = int.tryParse(v.trim());
  if (n == null || n < min || n > max) return label;
  return null;
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
