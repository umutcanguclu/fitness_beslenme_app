import 'package:flutter/material.dart';
import '../models/user.dart';
import '../util/labels.dart';

class SettingsScreen extends StatelessWidget {
  final User user;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.user,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _initials(user.fullName),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleLabel(user.role),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('Görünüm',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ),
          Card(
            child: Column(
              children: [
                _ThemeOption(
                  icon: Icons.smartphone,
                  title: 'Sistemle aynı',
                  subtitle: 'Cihazın tema ayarına göre değişir',
                  selected: themeMode == ThemeMode.system,
                  onTap: () => onThemeModeChanged(ThemeMode.system),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOption(
                  icon: Icons.light_mode,
                  title: 'Açık',
                  subtitle: 'Beyaz arka plan',
                  selected: themeMode == ThemeMode.light,
                  onTap: () => onThemeModeChanged(ThemeMode.light),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOption(
                  icon: Icons.dark_mode,
                  title: 'Koyu',
                  subtitle: 'Düşük ışık ortamı için',
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => onThemeModeChanged(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('Hakkında',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  title: const Text('fittrack mobil'),
                  subtitle: const Text('Sürüm 1.0.0 — alt lig + akademi futbolu için'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.cloud_outlined, color: theme.colorScheme.primary),
                  title: const Text('API'),
                  subtitle: const Text('http://10.0.2.2:3000 (geliştirme)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.onErrorContainer),
              title: Text('Çıkış yap',
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  )),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Çıkış'),
                    content: const Text('Çıkış yapmak istediğine emin misin?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Vazgeç')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Çıkış')),
                    ],
                  ),
                );
                if (ok == true) onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(title,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      subtitle: Text(subtitle,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: theme.colorScheme.outlineVariant),
      onTap: onTap,
    );
  }
}
