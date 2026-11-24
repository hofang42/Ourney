import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import '../social/social.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';
import 'settings_screen.dart' show profileSettingsPath;
import 'widgets/profile_avatar.dart';
import 'widgets/profile_stats_section.dart';

/// Route of the profile setup screen (sub-path of `/profile`).
const String profileSetupPath = '${AppRoutes.profile}/setup';

/// Route of the edit profile screen (sub-path of `/profile`).
const String profileEditPath = '${AppRoutes.profile}/edit';

/// `/profile` (App.tsx `ProfileSheet`): who I am, friends, stats and badges.
/// Everything configurable lives in Settings, one gear away (top right). In
/// local-only mode (FR-A5) it shows a guest state.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final profile = localOnly ? null : ref.watch(myProfileProvider);
    final gear = UiBarIconButton(
      key: const ValueKey('profile-settings'),
      glyph: const OurneyIcon(name: 'settings', size: 21),
      label: l10n.profile_settingsEntry,
      onPressed: () => context.push(profileSettingsPath),
    );

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
              trailing: gear,
            )
          else
            UiTopBar(
              key: const ValueKey('profile-top-bar'),
              title: l10n.profile_title,
              actions: [gear],
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
          child: Center(child: UiSpinner()),
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
