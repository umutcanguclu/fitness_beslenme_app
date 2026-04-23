import 'package:flutter/material.dart';

import '../../../core/theme/fittrack_colors.dart';

/// Placeholder until Faz 1 replaces it with a real sign-in form.
class SignInPlaceholderScreen extends StatelessWidget {
  const SignInPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Scaffold(
      body: Center(
        child: Text(
          'Sign in — coming in Faz 1',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textMuted,
              ),
        ),
      ),
    );
  }
}
