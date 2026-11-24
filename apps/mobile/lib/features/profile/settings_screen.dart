import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_routes.dart';
import '../../app/locale_override.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import '../auth/phone_format.dart';
import '../safety/safety_paths.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_screen.dart' show profileEditPath;
import 'settings_providers.dart';
import 'share_privacy_sync.dart';
import 'widgets/delete_account_dialog.dart';
import 'widgets/sign_out_flow.dart';

/// Route of the settings screen (sub-path of `/profile`).
const String profileSettingsPath = '${AppRoutes.profile}/settings';

/// Figma `SettingsScreen` (`/settings`), reached by the gear on Profile.
/// Named groups, each one flat card: account, reminders, appearance and
/// language, privacy and safety, about. Sign out and delete account sit alone
/// at the bottom (delete is a quiet danger action).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final signedIn = !localOnly && ref.watch(currentUserIdProvider) != null;
    return UiScaffold(
      key: const ValueKey('settings-screen'),
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.profile),
            backLabel: l10n.profile_settings_back,
            title: l10n.profile_settings_title,
          ),
          if (signedIn) ...[
            UiListHeading(title: l10n.profile_settings_secAccount),
            _Card(
              child: Column(
                children: [
                  const _SignedInRow(),
                  UiRow(
                    key: const ValueKey('settings-edit-profile'),
                    leading: const OurneyIcon(name: 'profile', flat: true),
                    title: l10n.profile_settings_editProfile,
                    divider: false,
                    onPressed: () => context.push(profileEditPath),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UiSpace.lg),
          ],
          UiListHeading(title: l10n.profile_settings_secReminders),
          _Card(
            child: UiRow(
              key: const ValueKey('settings-reminders'),
              leading: const OurneyIcon(name: 'bell', flat: true),
              title: l10n.profile_settings_remindersRow,
              subtitle: _sub(context, l10n.profile_settings_remindersSub),
              divider: false,
              onPressed: () => context.push(AppRoutes.reminders),
            ),
          ),
          const SizedBox(height: UiSpace.lg),
          UiListHeading(title: l10n.profile_settings_secAppearance),
          _Card(
            child: Column(
              children: [
                _PickerRow(
                  eyebrow: l10n.profile_settings_themeEyebrow,
                  child: const _ThemePicker(),
                ),
                _PickerRow(
                  eyebrow: l10n.profile_settings_languageEyebrow,
                  child: const _LanguagePicker(),
                ),
                UiSwitchRow(
                  key: const ValueKey('settings-haptics'),
                  label: l10n.profile_settings_haptics,
                  value: ref.watch(hapticsEnabledProvider),
                  divider: false,
                  onChanged: (v) {
                    unawaited(
                      ref.read(hapticsEnabledProvider.notifier).set(enabled: v),
                    );
                    if (v) OurneyHaptics.selection();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.lg),
          UiListHeading(title: l10n.profile_settings_secPrivacy),
          _Card(
            child: Column(
              children: [
                UiSwitchRow(
                  key: const ValueKey('settings-hide-kg'),
                  label: l10n.profile_settings_hideKg,
                  subtitle: l10n.profile_settings_shareNote,
                  value: ref.watch(hideWeightOnShareProvider),
                  onChanged: (v) {
                    final container = ProviderScope.containerOf(context);
                    unawaited(() async {
                      await container
                          .read(hideWeightOnShareProvider.notifier)
                          .set(v);
                      if (v) {
                        await pushSharePrivacyToMemberships(
                          container,
                          hideWeight: true,
                        );
                      }
                    }());
                  },
                ),
                UiSwitchRow(
                  key: const ValueKey('settings-blur-photos'),
                  label: l10n.profile_settings_blurPhotos,
                  subtitle: l10n.profile_settings_shareNote,
                  value: ref.watch(blurPhotosOnShareProvider),
                  divider: signedIn,
                  onChanged: (v) {
                    final container = ProviderScope.containerOf(context);
                    unawaited(() async {
                      await container
                          .read(blurPhotosOnShareProvider.notifier)
                          .set(v);
                      if (v) {
                        await pushSharePrivacyToMemberships(
                          container,
                          blur: true,
                        );
                      }
                    }());
                  },
                ),
                if (signedIn)
                  UiRow(
                    key: const ValueKey('settings-blocked'),
                    leading: const OurneyIcon(name: 'user-minus', flat: true),
                    title: l10n.profile_settings_blocked,
                    subtitle: _sub(context, l10n.profile_settings_blockedSub),
                    divider: false,
                    onPressed: () => context.push(SafetyPaths.blocked),
                  ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.lg),
          UiListHeading(title: l10n.profile_settings_secInfo),
          _Card(
            child: Column(
              children: [
                UiRow(
                  key: const ValueKey('settings-eula'),
                  leading: const OurneyIcon(name: 'gavel', flat: true),
                  title: l10n.profile_settings_eula,
                  onPressed: () => context.push(SafetyPaths.eula),
                ),
                UiRow(
                  key: const ValueKey('settings-privacy-policy'),
                  leading: const OurneyIcon(name: 'lock', flat: true),
                  title: l10n.profile_settings_privacyPolicy,
                  onPressed: () => context.push(SafetyPaths.privacy),
                ),
                UiRow(
                  key: const ValueKey('settings-contact'),
                  leading: const OurneyIcon(name: 'mail', flat: true),
                  title: l10n.profile_settings_contact,
                  onPressed: () => context.push(SafetyPaths.contact),
                ),
                const _VersionRow(),
              ],
            ),
          ),
          if (signedIn) ...[
            const SizedBox(height: UiSpace.xl),
            UiButton.secondary(
              key: const ValueKey('settings-signout'),
              label: l10n.profile_settings_signOut,
              glyph: const OurneyIcon(name: 'logout', flat: true),
              onPressed: () => confirmSignOut(context, ref),
            ),
            const SizedBox(height: UiSpace.md),
            UiTextAction(
              key: const ValueKey('settings-delete'),
              label: l10n.profile_settings_delete,
              color: context.ui.danger,
              onPressed: () {
                OurneyHaptics.warning();
                unawaited(DeleteAccountDialog.show(context));
              },
            ),
          ],
          const SizedBox(height: UiSpace.xl),
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

/// One flat group card: no hard shadow, hairline dividers between rows.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => UiCard(
    radius: UiRadius.card,
    shadowOffset: 0,
    padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
    child: child,
  );
}

/// A segmented control inside a card, under a small eyebrow label.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.eyebrow, required this.child});

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: context.ui.ink.withValues(alpha: 0.12)),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiEyebrow(eyebrow),
        const SizedBox(height: UiSpace.sm),
        child,
      ],
    ),
  );
}

/// Read-only "Signed in with" row: the account's email or phone number.
class _SignedInRow extends ConsumerWidget {
  const _SignedInRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    // Rebuild when the account changes.
    ref.watch(currentUserIdProvider);
    final String? id;
    try {
      id = ref.watch(authRepositoryProvider).signInIdentifier;
    } on Object {
      return const SizedBox.shrink();
    }
    if (id == null) return const SizedBox.shrink();
    final isEmail = id.contains('@');
    final displayId = isEmail
        ? id
        : formatPhoneForDisplay(toE164Vietnam(id) ?? id);
    return MergeSemantics(
      child: UiRow(
        key: const ValueKey('settings-account-id'),
        leading: OurneyIcon(
          name: isEmail ? 'mail' : 'phone',
          flat: true,
        ),
        title: l10n.profile_settings_signedInWith,
        subtitle: Text(
          displayId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiText.body(
            size: 13,
            height: 1.4,
            color: context.ui.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// App version and build, read once from the platform (empty when the
/// platform channel is not available, e.g. in tests).
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';
  } on Object {
    return '';
  }
});

class _VersionRow extends ConsumerWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final version = ref.watch(appVersionProvider).asData?.value ?? '';
    return MergeSemantics(
      child: UiRow(
        key: const ValueKey('settings-version'),
        leading: const OurneyIcon(name: 'info', flat: true),
        title: l10n.profile_settings_version,
        divider: false,
        trailing: version.isEmpty
            ? null
            : Text(
                version,
                style: UiText.body(
                  size: 14,
                  height: 1.4,
                  color: context.ui.inkMuted,
                ),
              ),
      ),
    );
  }
}

/// `.theme-segmented`: Sáng / Tối / Theo máy.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    return Semantics(
      container: true,
      label: l10n.profile_settings_themeLabel,
      child: UiSegmented<ThemeMode>(
        value: ref.watch(themeModeProvider),
        onChanged: (m) =>
            unawaited(ref.read(themeModeProvider.notifier).set(m)),
        segments: [
          UiSegment(
            key: const ValueKey('settings-theme-light'),
            value: ThemeMode.light,
            label: l10n.profile_settings_themeLight,
          ),
          UiSegment(
            key: const ValueKey('settings-theme-dark'),
            value: ThemeMode.dark,
            label: l10n.profile_settings_themeDark,
          ),
          UiSegment(
            key: const ValueKey('settings-theme-system'),
            value: ThemeMode.system,
            label: l10n.profile_settings_themeSystem,
          ),
        ],
      ),
    );
  }
}

/// Việt / English; writes [localeOverrideProvider].
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final override = ref.watch(localeOverrideProvider);
    final code =
        override?.languageCode ?? Localizations.localeOf(context).languageCode;
    return Semantics(
      container: true,
      label: l10n.profile_settings_languageEyebrow,
      child: UiSegmented<String>(
        value: code == 'en' ? 'en' : 'vi',
        onChanged: (c) =>
            unawaited(ref.read(localeOverrideProvider.notifier).set(Locale(c))),
        segments: [
          UiSegment(
            key: const ValueKey('settings-lang-vi'),
            value: 'vi',
            label: l10n.profile_settings_langVi,
          ),
          UiSegment(
            key: const ValueKey('settings-lang-en'),
            value: 'en',
            label: l10n.profile_settings_langEn,
          ),
        ],
      ),
    );
  }
}
