import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import '../social/social.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';
import 'widgets/delete_account_dialog.dart';
import 'widgets/profile_avatar.dart';

/// Route of the profile setup screen (sub-path of `/profile`).
const String profileSetupPath = '${AppRoutes.profile}/setup';

/// Route of the edit profile screen (sub-path of `/profile`).
const String profileEditPath = '${AppRoutes.profile}/edit';

/// `/profile` (App.tsx `ProfileSheet`): who I am, friends, settings links,
/// sign out and account deletion. In local-only mode (FR-A5) it shows a
/// guest state without account actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.capture);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final profile = localOnly ? null : ref.watch(myProfileProvider);

    return UiScaffold(
      key: const ValueKey('profile-screen'),
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: () => _close(context),
            backLabel: MaterialLocalizations.of(context).backButtonTooltip,
            title: l10n.profile_title,
          ),
          const SizedBox(height: UiSpace.sm),
          if (profile == null)
            const _GuestHeader()
          else
            _ProfileHeader(profile: profile),
          if (!localOnly) ...[
            const SizedBox(height: UiSpace.sm),
            const FriendsProfileTile(),
          ],
          const SizedBox(height: UiSpace.xl),
          UiListHeading(title: l10n.profile_sectionSettings),
          const _SettingsSection(),
          if (!localOnly) ...[
            const SizedBox(height: UiSpace.xl),
            UiListHeading(title: l10n.profile_sectionAccount),
            _AccountSection(username: profile?.value?.username),
          ],
        ],
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    return UiCard(
      key: const ValueKey('profile-guest'),
      radius: UiRadius.card,
      padding: const EdgeInsets.all(UiSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UiAvatar(
                name: l10n.profile_guestName,
                colorIndex: UiAvatar.indexFor(l10n.profile_guestName),
                size: UiSize.avatarLarge + 8,
              ),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Text(
                  l10n.profile_guestName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.h2(color: ui.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.lg),
          Row(
            children: [
              Icon(Icons.phone_iphone_rounded, color: ui.ink, size: 20),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Text(
                  l10n.profile_guestTitle,
                  style: UiText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    color: ui.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.xs),
          Text(
            l10n.profile_guestMessage,
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile});

  final AsyncValue<Profile?> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    return switch (profile) {
      AsyncData(value: final Profile p) => _ProfileCard(profile: p),
      AsyncData() => UiCard(
        key: const ValueKey('profile-incomplete'),
        radius: UiRadius.card,
        padding: const EdgeInsets.all(UiSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profile_completeTitle,
              style: UiText.h2(color: context.ui.ink),
            ),
            const SizedBox(height: UiSpace.xs),
            Text(
              l10n.profile_completeMessage,
              style: UiText.muted(color: context.ui.inkMuted, size: 14),
            ),
            const SizedBox(height: UiSpace.lg),
            UiButton(
              key: const ValueKey('profile-complete'),
              label: l10n.profile_completeTitle,
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => context.push(profileSetupPath),
            ),
          ],
        ),
      ),
      AsyncError() => Column(
        key: const ValueKey('profile-load-error'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiInlineError(message: l10n.profile_loadError),
          const SizedBox(height: UiSpace.md),
          UiButton.secondary(
            key: const ValueKey('profile-retry'),
            label: AppLocalizations.of(context).common_retry,
            icon: Icons.refresh_rounded,
            onPressed: () => ref.invalidate(myProfileProvider),
          ),
        ],
      ),
      _ => Semantics(
        label: AppLocalizations.of(context).common_loading,
        child: const SizedBox(
          key: ValueKey('profile-loading'),
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}

/// `.profile-person`: avatar, name and @username, with an edit button.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    return Column(
      key: const ValueKey('profile-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ProfileAvatar(
              name: profile.displayName,
              storagePath: profile.avatarPath,
              size: 64,
            ),
            const SizedBox(width: UiSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.h2(color: ui.ink),
                  ),
                  Text(
                    '@${profile.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(size: 13, color: ui.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: UiSpace.lg),
        UiButton.secondary(
          key: const ValueKey('profile-edit'),
          label: l10n.profile_editTitle,
          icon: Icons.edit_outlined,
          compact: true,
          onPressed: () => context.push(profileEditPath),
        ),
      ],
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final haptics = ref.watch(hapticsEnabledProvider);
    return Column(
      children: [
        UiRow(
          key: const ValueKey('profile-reminders'),
          leading: const Icon(Icons.notifications_none_rounded),
          title: l10n.profile_reminders,
          subtitle: _sub(context, l10n.profile_remindersSubtitle),
          onPressed: () => context.push(AppRoutes.reminders),
        ),
        UiSwitchRow(
          key: const ValueKey('profile-haptics'),
          label: l10n.profile_haptics,
          value: haptics,
          onChanged: (v) {
            unawaited(
              ref.read(hapticsEnabledProvider.notifier).set(enabled: v),
            );
            if (v) OurneyHaptics.selection();
          },
        ),
        UiRow(
          key: const ValueKey('profile-language'),
          leading: const Icon(Icons.translate_rounded),
          title: l10n.profile_language,
          subtitle: _sub(context, l10n.profile_languageNote),
          showChevron: false,
        ),
        UiRow(
          key: const ValueKey('profile-safety'),
          leading: const Icon(Icons.shield_outlined),
          title: l10n.profile_safety,
          divider: false,
          onPressed: () => context.push(AppRoutes.safety),
        ),
      ],
    );
  }

  static Widget _sub(BuildContext context, String text) => Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: UiText.body(size: 12, height: 1.4, color: context.ui.inkMuted),
  );
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.username});

  final String? username;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = ProfileL10n.of(context);
    final ok = await showUiSheet<bool>(
      context: context,
      builder: (context) {
        final ui = context.ui;
        return Column(
          key: const ValueKey('profile-signout-dialog'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.profile_signOutTitle,
                style: UiText.h2(color: ui.ink),
              ),
            ),
            const SizedBox(height: UiSpace.sm),
            Text(
              l10n.profile_signOutMessage,
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
            const SizedBox(height: UiSpace.xl),
            UiButton(
              key: const ValueKey('profile-signout-confirm'),
              label: l10n.profile_signOut,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: UiSpace.sm),
            UiButton.secondary(
              label: AppLocalizations.of(context).common_cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final errorText = AppLocalizations.of(context).common_errorGeneric;
    try {
      // The router redirects to /auth once the user id becomes null.
      await ref.read(authRepositoryProvider).signOut();
    } on Object {
      if (context.mounted) showUiToast(context, errorText);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = ProfileL10n.of(context);
    OurneyHaptics.warning();
    final name = username;
    await DeleteAccountDialog.show(
      context,
      phrase: name ?? l10n.profile_deleteConfirmWord,
      caseSensitive: name != null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    return Column(
      children: [
        UiRow(
          key: const ValueKey('profile-signout'),
          leading: const Icon(Icons.logout_rounded),
          title: l10n.profile_signOut,
          onPressed: () => _signOut(context, ref),
        ),
        UiRow(
          key: const ValueKey('profile-delete'),
          leading: Icon(Icons.delete_outline_rounded, color: ui.danger),
          title: l10n.profile_deleteAccount,
          divider: false,
          showChevron: false,
          onPressed: () => _delete(context),
        ),
      ],
    );
  }
}
