import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final locale = ref.watch(localeControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings.appName,
                style: textTheme.displayLarge?.copyWith(color: colors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                strings.appTagline,
                style: textTheme.bodyLarge?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.dashboardWelcome,
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.dashboardNoData,
                      style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
                icon: const Icon(Icons.translate),
                label: Text('${locale.languageCode.toUpperCase()} ↔'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
