import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/locale_override.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import '../social/social.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';
import 'settings_screen.dart' show profileSettingsPath;
import 'widgets/delete_account_dialog.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/profile_stats_section.dart';

/// Route of the profile setup screen (sub-path of `/profile`).
const String profileSetupPath = '${AppRoutes.profile}/setup';

/// Route of the edit profile screen (sub-path of `/profile`).
const String profileEditPath = '${AppRoutes.profile}/edit';

/// `/profile` (App.tsx `ProfileSheet`): who I am, friends, settings links,
/// sign out and account deletion. In local-only mode (FR-A5) it shows a
/// guest state without account actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
          // A Dock root tab has nowhere to go back to (U9): plain title bar.
          if (context.canPop())
            UiBackHeader(
              onBack: context.pop,
              backLabel: MaterialLocalizations.of(context).backButtonTooltip,
              title: l10n.profile_title,
            )
          else
            UiTopBar(
              key: const ValueKey('profile-top-bar'),
              title: l10n.profile_title,
            ),
          const SizedBox(height: UiSpace.lg),
          if (profile == null)
            const _GuestHeader()
          else
            _ProfileHeader(profile: profile),
          if (!localOnly) ...[
            const SizedBox(height: UiSpace.sm),
            const FriendsProfileTile(),
          ],
          const SizedBox(height: UiSpace.xl),
          const ProfileStatsSection(),
          const SizedBox(height: UiSpace.xl),
          UiListHeading(title: l10n.profile_sectionSettings),
          const _SettingsSection(),
          if (!localOnly) ...[
            const SizedBox(height: UiSpace.xl),
            UiListHeading(title: l10n.profile_sectionAccount),
            _AccountSection(),
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
              OurneyIcon(name: 'phone', flat: true, color: ui.ink, size: 20),
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
              glyph: const OurneyIcon(name: 'user-plus', flat: true),
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
            glyph: const OurneyIcon(name: 'refresh', flat: true),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfileAvatar(
          name: profile.displayName,
          storagePath: profile.avatarPath,
          size: 88,
        ),
        const SizedBox(height: UiSpace.md),
        Text(
          profile.displayName,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: UiText.h1(size: 26, color: ui.ink),
        ),
        const SizedBox(height: UiSpace.xs),
        Text(
          '@${profile.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiText.body(size: 14, color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.lg),
        UiButton.secondary(
          key: const ValueKey('profile-edit'),
          label: l10n.profile_editTitle,
          glyph: const OurneyIcon(name: 'edit', flat: true),
          compact: true,
          expand: false,
          onPressed: () => context.push(profileEditPath),
        ),
      ],
    );
  }
}

/// `.settings-card`: grouped rows in one sticker card.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => UiCard(
    radius: UiRadius.card,
    borderColor: borderColor,
    shadowOffset: UiShadow.small,
    padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
    child: child,
  );
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final haptics = ref.watch(hapticsEnabledProvider);
    final language = ref.watch(localeOverrideProvider);
    return _GroupCard(
      child: Column(
        children: [
          UiRow(
            key: const ValueKey('profile-settings'),
            leading: const OurneyIcon(name: 'settings', flat: true),
            title: l10n.profile_settingsEntry,
            subtitle: _sub(context, l10n.profile_settingsEntrySub),
            onPressed: () => context.push(profileSettingsPath),
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
            leading: const OurneyIcon(name: 'translate', flat: true),
            title: l10n.profile_language,
            // Shows the language actually in use; Settings owns the picker.
            subtitle: _sub(context, switch (language?.languageCode) {
              null => l10n.profile_languageNote,
              'en' => l10n.profile_languageEn,
              _ => l10n.profile_languageVi,
            }),
            onPressed: () => context.push(profileSettingsPath),
          ),
          UiRow(
            key: const ValueKey('profile-safety'),
            leading: const OurneyIcon(name: 'shield', flat: true),
            title: l10n.profile_safety,
            divider: false,
            onPressed: () => context.push(AppRoutes.safety),
          ),
        ],
      ),
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
  const _AccountSection();

  Future<void> _delete(BuildContext context) async {
    OurneyHaptics.warning();
    await DeleteAccountDialog.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    return Column(
      children: [
        _GroupCard(
          borderColor: ui.danger,
          child: UiRow(
            key: const ValueKey('profile-delete'),
            leading: OurneyIcon(name: 'trash', flat: true, color: ui.danger),
            title: l10n.profile_deleteAccount,
            divider: false,
            showChevron: false,
            onPressed: () => _delete(context),
          ),
        ),
      ],
    );
  }
}
