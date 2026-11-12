import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';
import 'widgets/profile_form.dart';

/// `/profile/edit`: change username, display name and avatar.
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final profile = ref.watch(myProfileProvider);
    return UiScaffold(
      key: const ValueKey('profile-edit-screen'),
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: () => _close(context),
            backLabel: MaterialLocalizations.of(context).backButtonTooltip,
            title: l10n.profile_editTitle,
          ),
          const SizedBox(height: UiSpace.lg),
          switch (profile) {
            AsyncData(:final value) => ProfileForm(
              initial: value,
              submitLabel: l10n.profile_save,
              onSaved: () => _close(context),
            ),
            AsyncError() => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiInlineError(message: l10n.profile_loadError),
                const SizedBox(height: UiSpace.md),
                UiButton.secondary(
                  label: AppLocalizations.of(context).common_retry,
                  onPressed: () => ref.invalidate(myProfileProvider),
                ),
              ],
            ),
            _ => const Padding(
              padding: EdgeInsets.all(UiSpace.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}
