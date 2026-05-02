import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_exception.dart';
import '../api/players_api.dart';
import '../models/player.dart';
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

class PlayerEditScreen extends StatefulWidget {
  final PlayersApi playersApi;
  final Player player;
  const PlayerEditScreen({super.key, required this.playersApi, required this.player});

  @override
  State<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends State<PlayerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _heightCtrl =
      TextEditingController(text: widget.player.heightCm?.round().toString() ?? '');
  late final _weightCtrl =
      TextEditingController(text: widget.player.weightKg?.round().toString() ?? '');
  late final _jerseyCtrl =
      TextEditingController(text: widget.player.jerseyNumber?.toString() ?? '');
  late String _position = widget.player.position;
  late String? _detailedPosition = widget.player.detailedPosition;
  late String _foot = widget.player.preferredFoot;
  late String _employment = widget.player.employmentStatus;
  late DateTime? _birthDate = widget.player.birthDate;
  bool _busy = false;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _jerseyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(DateTime.now().year - 17),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.playersApi.updatePlayer(
        widget.player.id,
        UpdatePlayerInput(
          position: _position,
          detailedPosition: _detailedPosition,
          preferredFoot: _foot,
          heightCm: int.tryParse(_heightCtrl.text.trim()),
          weightKg: int.tryParse(_weightCtrl.text.trim()),
          jerseyNumber: _jerseyCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(_jerseyCtrl.text.trim()),
          employmentStatus: _employment,
          birthDate: _birthDate,
        ),
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
    final detailedItems = _detailedByGroup[_position] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.player.fullName} — düzenle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _busy ? null : _pickBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Doğum tarihi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    child: Text(_birthDate == null ? 'Seç' : formatDate(_birthDate!)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _position,
                  decoration: const InputDecoration(
                      labelText: 'Mevki', border: OutlineInputBorder()),
                  items: _positions
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(positionLabel(p))))
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
                  initialValue:
                      detailedItems.contains(_detailedPosition) ? _detailedPosition : null,
                  decoration: const InputDecoration(
                      labelText: 'Detay mevki', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('—')),
                    ...detailedItems.map((d) => DropdownMenuItem(
                        value: d, child: Text(detailedPositionLabel(d)))),
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
                            labelText: 'Boy (cm)', border: OutlineInputBorder()),
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
                            labelText: 'Kilo (kg)', border: OutlineInputBorder()),
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
                            labelText: 'Tercih ayak', border: OutlineInputBorder()),
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
                            labelText: 'Forma no', border: OutlineInputBorder()),
                        enabled: !_busy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _employment,
                  decoration: const InputDecoration(
                      labelText: 'Statü', border: OutlineInputBorder()),
                  items: _employments
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(employmentLabel(e))))
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _employment = v ?? _employment),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Güncelle'),
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
  if (v == null || v.trim().isEmpty) return null; // optional in edit
  final n = int.tryParse(v.trim());
  if (n == null || n < min || n > max) return label;
  return null;
}
