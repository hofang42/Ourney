import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/avatar.dart';
import '../../shared/chunky_button.dart';
import '../../shared/ourney_card.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';
import 'widgets/delete_account_dialog.dart';
import 'widgets/inline_error.dart';
import 'widgets/profile_avatar.dart';

/// Route of the profile setup screen (sub-path of `/profile`).
const String profileSetupPath = '${AppRoutes.profile}/setup';

/// Route of the edit profile screen (sub-path of `/profile`).
const String profileEditPath = '${AppRoutes.profile}/edit';

/// `/profile`: who I am, settings links, sign out and account deletion.
/// In local-only mode (FR-A5) it shows a guest state without account actions.
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

    return Scaffold(
      key: const ValueKey('profile-screen'),
      appBar: AppBar(
        leading: BackButton(onPressed: () => _close(context)),
        title: Text(l10n.profile_title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          children: [
            if (profile == null)
              const _GuestHeader()
            else
              _ProfileHeader(profile: profile),
            const SizedBox(height: OurneySpacing.xl),
            _SectionTitle(l10n.profile_sectionSettings),
            const _SettingsSection(),
            if (!localOnly) ...[
              const SizedBox(height: OurneySpacing.xl),
              _SectionTitle(l10n.profile_sectionAccount),
              _AccountSection(username: profile?.value?.username),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: OurneySpacing.xs,
      bottom: OurneySpacing.sm,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: OurneyColors.of(context).inkMuted),
      ),
    ),
  );
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    return OurneyCard(
      key: const ValueKey('profile-guest'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(name: l10n.profile_guestName, size: 64),
              const SizedBox(width: OurneySpacing.lg),
              Expanded(
                child: Text(l10n.profile_guestName, style: text.displaySmall),
              ),
            ],
          ),
          const SizedBox(height: OurneySpacing.lg),
          Row(
            children: [
              Icon(Icons.phone_iphone_rounded, color: c.accent),
              const SizedBox(width: OurneySpacing.sm),
              Expanded(
                child: Text(l10n.profile_guestTitle, style: text.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: OurneySpacing.xs),
          Text(
            l10n.profile_guestMessage,
            style: text.bodyMedium?.copyWith(color: c.inkMuted),
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
      AsyncData() => OurneyCard(
        key: const ValueKey('profile-incomplete'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profile_completeTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: OurneySpacing.xs),
            Text(l10n.profile_completeMessage),
            const SizedBox(height: OurneySpacing.lg),
            ChunkyButton(
              key: const ValueKey('profile-complete'),
              label: l10n.profile_completeTitle,
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => context.push(profileSetupPath),
            ),
          ],
        ),
      ),
      AsyncError() => Column(
        key: const ValueKey('profile-load-error'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineError(message: l10n.profile_loadError),
          const SizedBox(height: OurneySpacing.md),
          ChunkyButton(
            key: const ValueKey('profile-retry'),
            label: AppLocalizations.of(context).common_retry,
            variant: ChunkyVariant.neutral,
            icon: Icons.refresh_rounded,
            onPressed: () => ref.invalidate(myProfileProvider),
          ),
        ],
      ),
      _ => Semantics(
        label: AppLocalizations.of(context).common_loading,
        child: const SizedBox(
          key: ValueKey('profile-loading'),
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final text = Theme.of(context).textTheme;
    // White text on the gradient: bold >= 18pt only (design system).
    const onGradient = Colors.white;
    return OurneyCard(
      key: const ValueKey('profile-card'),
      gradient: OurneyColors.heroGradient,
      padding: const EdgeInsets.all(OurneySpacing.xl),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: onGradient, width: 3),
            ),
            child: ProfileAvatar(
              name: profile.displayName,
              storagePath: profile.avatarPath,
              size: 96,
            ),
          ),
          const SizedBox(height: OurneySpacing.md),
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: text.displaySmall?.copyWith(color: onGradient),
          ),
          const SizedBox(height: OurneySpacing.xs),
          Text(
            '@${profile.username}',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(color: onGradient),
          ),
          const SizedBox(height: OurneySpacing.lg),
          ChunkyButton(
            key: const ValueKey('profile-edit'),
            label: l10n.profile_editTitle,
            icon: Icons.edit_rounded,
            variant: ChunkyVariant.neutral,
            expand: false,
            onPressed: () => context.push(profileEditPath),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final haptics = ref.watch(hapticsEnabledProvider);
    return OurneyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _Tile(
            key: const ValueKey('profile-reminders'),
            icon: Icons.notifications_active_rounded,
            title: l10n.profile_reminders,
            subtitle: l10n.profile_remindersSubtitle,
            onTap: () => context.push(AppRoutes.reminders),
          ),
          const Divider(height: 1),
          SwitchListTile(
            key: const ValueKey('profile-haptics'),
            secondary: const Icon(Icons.vibration_rounded),
            title: Text(l10n.profile_haptics),
            value: haptics,
            onChanged: (v) {
              unawaited(
                ref.read(hapticsEnabledProvider.notifier).set(enabled: v),
              );
              if (v) OurneyHaptics.selection();
            },
          ),
          const Divider(height: 1),
          _Tile(
            key: const ValueKey('profile-language'),
            icon: Icons.translate_rounded,
            title: l10n.profile_language,
            subtitle: l10n.profile_languageNote,
          ),
          const Divider(height: 1),
          _Tile(
            key: const ValueKey('profile-safety'),
            icon: Icons.shield_outlined,
            title: l10n.profile_safety,
            onTap: () => context.push(AppRoutes.safety),
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.username});

  final String? username;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = ProfileL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('profile-signout-dialog'),
        title: Text(l10n.profile_signOutTitle),
        content: Text(l10n.profile_signOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).common_cancel),
          ),
          FilledButton(
            key: const ValueKey('profile-signout-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profile_signOut),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorText = AppLocalizations.of(context).common_errorGeneric;
    try {
      // The router redirects to /auth once the user id becomes null.
      await ref.read(authRepositoryProvider).signOut();
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
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
    final c = OurneyColors.of(context);
    return OurneyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _Tile(
            key: const ValueKey('profile-signout'),
            icon: Icons.logout_rounded,
            title: l10n.profile_signOut,
            onTap: () => _signOut(context, ref),
          ),
          const Divider(height: 1),
          _Tile(
            key: const ValueKey('profile-delete'),
            icon: Icons.delete_forever_rounded,
            title: l10n.profile_deleteAccount,
            color: c.danger,
            onTap: () => _delete(context),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: OurneySizes.minTap + OurneySpacing.md,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: color == null
            ? null
            : Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
