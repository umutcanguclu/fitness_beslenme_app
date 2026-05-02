import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/auth_api.dart';

// 2 adımlı şifremi unuttum:
// 1) Email gir → token üret (dev'de UI'a düşer)
// 2) Token + yeni şifre → reset

class ForgotPasswordScreen extends StatefulWidget {
  final AuthApi authApi;
  const ForgotPasswordScreen({super.key, required this.authApi});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _step1Busy = false;
  bool _step2Busy = false;
  bool _emailSent = false;
  String? _devToken;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir e-posta gir')));
      return;
    }
    setState(() => _step1Busy = true);
    try {
      final devToken = await widget.authApi.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _devToken = devToken;
        if (devToken != null) _tokenCtrl.text = devToken;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(devToken != null
              ? 'Geliştirme modu: token aşağıda hazır'
              : 'Bu e-posta kayıtlıysa sıfırlama bağlantısı gönderildi.'),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _step1Busy = false);
    }
  }

  Future<void> _doReset() async {
    final token = _tokenCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    if (token.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token en az 8 karakter')));
      return;
    }
    if (pwd.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni şifre en az 8 karakter')));
      return;
    }
    setState(() => _step2Busy = true);
    try {
      await widget.authApi.resetPassword(token: token, newPassword: pwd);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre güncellendi. Şimdi giriş yapabilirsin.')));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _step2Busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi unuttum')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _emailSent ? theme.colorScheme.primary : theme.colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('1',
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'E-posta adresini gir',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (_emailSent)
                        Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  enabled: !_step1Busy && !_emailSent,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: (_step1Busy || _emailSent) ? null : _requestReset,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _step1Busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_emailSent ? 'Token gönderildi' : 'Sıfırlama tokeni gönder'),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('2',
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Token + yeni şifre',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_devToken != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bug_report,
                            size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Geliştirme modu: token otomatik dolduruldu. Production\'da bu, e-posta ile gönderilir.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sıfırlama tokeni',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(64)],
                  enabled: !_step2Busy && _emailSent,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Yeni şifre (en az 8)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  enabled: !_step2Busy && _emailSent,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: (_step2Busy || !_emailSent) ? null : _doReset,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _step2Busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Şifreyi sıfırla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
