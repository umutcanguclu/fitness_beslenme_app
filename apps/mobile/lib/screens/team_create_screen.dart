import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/teams_api.dart';
import '../models/team.dart';
import '../util/labels.dart';

const _categories = [
  'u13', 'u14', 'u15', 'u16', 'u17', 'u18', 'u19', 'u21',
  'senior', 'amateur', 'veteran',
];

class TeamCreateScreen extends StatefulWidget {
  final TeamsApi teamsApi;
  const TeamCreateScreen({super.key, required this.teamsApi});

  @override
  State<TeamCreateScreen> createState() => _TeamCreateScreenState();
}

class _TeamCreateScreenState extends State<TeamCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _seasonCtrl = TextEditingController(text: _defaultSeason());
  String _category = 'u17';
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _seasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final team = await widget.teamsApi.createTeam(CreateTeamInput(
        name: _nameCtrl.text.trim(),
        category: _category,
        season: _seasonCtrl.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).pop<Team>(team);
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
      appBar: AppBar(title: const Text('Yeni takım')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Takım adı',
                        helperText: 'Örn. "U17 A", "Akademi U13", "Senior"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Takım adı gerekli' : null,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(teamCategoryLabel(c)),
                              ))
                          .toList(),
                      onChanged: _busy ? null : (v) => setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sezon',
                        helperText: 'Örn. "2026-2027"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Sezon gerekli';
                        if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(v.trim())) {
                          return 'Format: YYYY-YYYY';
                        }
                        return null;
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
                          : const Text('Takımı oluştur'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _defaultSeason() {
  final now = DateTime.now();
  // Sezon Temmuz'da başlar varsayımı.
  final start = now.month >= 7 ? now.year : now.year - 1;
  return '$start-${start + 1}';
}
