import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/theme/tokens.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';
import 'widgets/profile_form.dart';

/// Profile setup after the first sign-in (FR-A2), at `/profile/setup`.
///
/// The auth flow opens it when `ProfileRepository.watchMe()` yields null
/// right after `verifyOtp`. (It cannot live under `/auth`: the router leaves
/// `/auth/*` as soon as a user id exists.) On save it continues to [from]
/// (a sanitized in-app path) or `/capture`.
class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({this.from, super.key});

  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    final existing = ref.watch(myProfileProvider).value;
    return Scaffold(
      key: const ValueKey('profile-setup-screen'),
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: OurneySpacing.lg),
              Semantics(
                header: true,
                child: Text(l10n.profile_setupTitle, style: text.displayLarge),
              ),
              const SizedBox(height: OurneySpacing.sm),
              Text(
                l10n.profile_setupSubtitle,
                style: text.bodyLarge?.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: OurneySpacing.xl),
              ProfileForm(
                initial: existing,
                submitLabel: l10n.profile_continue,
                onSaved: () => context.go(from ?? AppRoutes.capture),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
