import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _serverError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _serverError = null);

    await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      setState(() => _serverError = mapAuthError(context, state.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;

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
                    Text(
                      strings.authSignInTitle,
                      style: textTheme.displaySmall?.copyWith(color: colors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.authSignInSubtitle,
                      style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: strings.authEmailLabel),
                      validator: (value) => _validateEmail(value, strings),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: strings.authPasswordLabel),
                      validator: (value) => _validatePassword(value, strings),
                    ),
                    if (_serverError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _serverError!,
                        style: textTheme.bodySmall?.copyWith(color: colors.danger),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.authSignInAction),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          strings.authNoAccountPrompt,
                          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go(AppRoute.signUp),
                          child: Text(strings.authSignUpAction),
                        ),
                      ],
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

String? _validateEmail(String? value, AppLocalizations strings) {
  final v = value?.trim() ?? '';
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (v.isEmpty || !emailRegex.hasMatch(v)) return strings.authErrorInvalidEmail;
  return null;
}

String? _validatePassword(String? value, AppLocalizations strings) {
  if (value == null || value.length < 8) return strings.authErrorPasswordTooShort;
  return null;
}

String mapAuthError(BuildContext context, Object? error) {
  final strings = AppLocalizations.of(context);
  if (error is ApiError) {
    return switch (error.code) {
      ApiErrorCode.unauthorized => strings.authErrorInvalidCredentials,
      ApiErrorCode.conflict => strings.authErrorEmailTaken,
      ApiErrorCode.network => strings.authErrorNetwork,
      _ => error.message.isNotEmpty ? error.message : strings.authErrorGeneric,
    };
  }
  return strings.authErrorGeneric;
}
