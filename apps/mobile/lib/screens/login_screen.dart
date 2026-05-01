import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'player_register_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthApi authApi;
  final TokenStorage tokenStorage;
  final ValueChanged<User> onAuthenticated;

  const LoginScreen({
    super.key,
    required this.authApi,
    required this.tokenStorage,
    required this.onAuthenticated,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final result = await widget.authApi.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await widget.tokenStorage.write(result.tokens);
      if (!mounted) return;
      widget.onAuthenticated(result.user);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RegisterScreen(
        authApi: widget.authApi,
        tokenStorage: widget.tokenStorage,
        onAuthenticated: widget.onAuthenticated,
      ),
    ));
  }

  void _goToPlayerRegister() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerRegisterScreen(
        authApi: widget.authApi,
        tokenStorage: widget.tokenStorage,
        onAuthenticated: widget.onAuthenticated,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('fittrack',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Antrenör + Oyuncu Platformu',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: _busy ? null : () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
                      enabled: !_busy,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Giriş yap'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy ? null : _goToRegister,
                      child: const Text('Antrenör olarak kayıt ol'),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : _goToPlayerRegister,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Davet kodum var (oyuncu)'),
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

String? _validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
  return ok ? null : 'Geçerli bir e-posta gir';
}
