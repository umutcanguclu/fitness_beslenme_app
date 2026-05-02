import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_exception.dart';
import '../api/players_api.dart';
import '../models/player.dart';
import '../util/labels.dart';

// Oyuncu kendi profilini günceller — sadece fiziksel/donanım alanları.
// Mevki/detay-mevki/statü gibi koç-yetkisi alanlarını GÖSTERMEZ.

class PlayerSelfEditScreen extends StatefulWidget {
  final PlayersApi playersApi;
  final String playerId;
  const PlayerSelfEditScreen({
    super.key,
    required this.playersApi,
    required this.playerId,
  });

  @override
  State<PlayerSelfEditScreen> createState() => _PlayerSelfEditScreenState();
}

class _PlayerSelfEditScreenState extends State<PlayerSelfEditScreen> {
  Future<Player>? _loadFuture;
  final _formKey = GlobalKey<FormState>();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _jerseyCtrl = TextEditingController();
  String _foot = 'right';
  bool _busy = false;
  Player? _player;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.playersApi.getPlayer(widget.playerId).then((p) {
      _player = p;
      _heightCtrl.text = p.heightCm?.round().toString() ?? '';
      _weightCtrl.text = p.weightKg?.round().toString() ?? '';
      _jerseyCtrl.text = p.jerseyNumber?.toString() ?? '';
      _foot = p.preferredFoot;
      return p;
    });
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _jerseyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.playersApi.updatePlayer(
        widget.playerId,
        UpdatePlayerInput(
          heightCm: int.tryParse(_heightCtrl.text.trim()),
          weightKg: int.tryParse(_weightCtrl.text.trim()),
          jerseyNumber: _jerseyCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(_jerseyCtrl.text.trim()),
          preferredFoot: _foot,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profilimi düzenle')),
      body: FutureBuilder<Player>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final msg = snap.error is ApiException
                ? (snap.error as ApiException).message
                : snap.error.toString();
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(msg)));
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mevki, ad ve statü değişikliği için antrenörünle iletişime geç.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              prefixIcon: Icon(Icons.height),
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
                              prefixIcon: Icon(Icons.monitor_weight_outlined),
                            ),
                            validator: (v) => _validateRange(v, 30, 150, 'Kilo 30-150'),
                            enabled: !_busy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _foot,
                      decoration: const InputDecoration(
                        labelText: 'Tercih ayak',
                        prefixIcon: Icon(Icons.directions_walk),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'right', child: Text('Sağ')),
                        DropdownMenuItem(value: 'left', child: Text('Sol')),
                        DropdownMenuItem(value: 'both', child: Text('Her ikisi')),
                      ],
                      onChanged: _busy ? null : (v) => setState(() => _foot = v ?? _foot),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jerseyCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Forma numarası',
                        helperText: '1-99 (opsiyonel)',
                        prefixIcon: Icon(Icons.sports_soccer),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1 || n > 99) return '1-99';
                        return null;
                      },
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 24),
                    if (_player != null) ...[
                      _ReadOnlyRow(label: 'Ad Soyad', value: _player!.fullName),
                      _ReadOnlyRow(label: 'Mevki', value: positionLabel(_player!.position)),
                      if (_player!.detailedPosition != null)
                        _ReadOnlyRow(
                            label: 'Detay mevki',
                            value: detailedPositionLabel(_player!.detailedPosition!)),
                      _ReadOnlyRow(label: 'Statü', value: employmentLabel(_player!.employmentStatus)),
                      if (_player!.birthDate != null)
                        _ReadOnlyRow(
                            label: 'Doğum',
                            value:
                                '${_player!.birthDate!.day}.${_player!.birthDate!.month}.${_player!.birthDate!.year}'),
                      const SizedBox(height: 24),
                    ],
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String? _validateRange(String? v, int min, int max, String label) {
  if (v == null || v.trim().isEmpty) return null;
  final n = int.tryParse(v.trim());
  if (n == null || n < min || n > max) return label;
  return null;
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
