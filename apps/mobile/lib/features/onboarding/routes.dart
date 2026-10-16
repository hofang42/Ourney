import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../shared/empty_state.dart';
import 'l10n/generated/onboarding_localizations.dart';

/// PLACEHOLDER (A3): the onboarding feature agent (B2, Mobile UI A) replaces
/// the screens (FR-A3: at most 3 screens, no permission prompts here).
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> onboardingRoutes`; top-level paths must start with
/// `/onboarding`. Full-screen (outside the tab shell).
///
/// The router sends every location here until onboarding is complete. Finish
/// by calling `ref.read(onboardingCompleteProvider.notifier).complete()`; the
/// router redirect then moves on by itself (to `/auth` when a backend is
/// configured and nobody is signed in, else to the `?from=` target or
/// `/capture`). Do not navigate manually after completing.
final List<RouteBase> onboardingRoutes = [
  GoRoute(
    path: AppRoutes.onboarding,
    builder: (context, state) => const _OnboardingPlaceholder(),
  ),
];

class _OnboardingPlaceholder extends ConsumerWidget {
  const _OnboardingPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = OnboardingL10n.of(context);
    return Scaffold(
      key: const ValueKey('placeholder-onboarding'),
      body: SafeArea(
        child: EmptyState(
          icon: Icons.photo_camera_rounded,
          title: l10n.onboarding_title,
          actionLabel: l10n.onboarding_start,
          onAction: () =>
              ref.read(onboardingCompleteProvider.notifier).complete(),
        ),
      ),
    );
  }
}
