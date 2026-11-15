import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/locale_override.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import '../safety/safety_paths.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_screen.dart' show profileEditPath;
import 'settings_providers.dart';
import 'widgets/delete_account_dialog.dart';

/// Route of the settings screen (sub-path of `/profile`).
const String profileSettingsPath = '${AppRoutes.profile}/settings';

/// Figma `SettingsScreen` (`/settings`): account, reminders, appearance
/// (theme, language, app icon), privacy, info, delete account.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
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
          if (!localOnly) ...[
            UiListHeading(title: l10n.profile_settings_secAccount),
            _Card(
              child: Column(
                children: [
                  UiRow(
                    key: const ValueKey('settings-edit-profile'),
                    leading: const OurneyIcon(name: 'profile', flat: true),
                    title: l10n.profile_settings_editProfile,
                    onPressed: () => context.push(profileEditPath),
                  ),
                  UiRow(
                    key: const ValueKey('settings-signout'),
                    leading: const OurneyIcon(name: 'logout', flat: true),
                    title: l10n.profile_settings_signOut,
                    divider: false,
                    onPressed: () =>
                        unawaited(ref.read(authRepositoryProvider).signOut()),
                  ),
                ],
              ),
            ),
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
          UiListHeading(title: l10n.profile_settings_secTheme),
          const _ThemePicker(),
          const SizedBox(height: UiSpace.md),
          const _LanguagePicker(),
          const SizedBox(height: UiSpace.md),
          const _AppIconPicker(),
          UiListHeading(title: l10n.profile_settings_secPrivacy),
          _Card(
            child: Column(
              children: [
                UiSwitchRow(
                  key: const ValueKey('settings-hide-kg'),
                  label: l10n.profile_settings_hideKg,
                  value: ref.watch(hideWeightOnShareProvider),
                  onChanged: (v) => unawaited(
                    ref.read(hideWeightOnShareProvider.notifier).set(v),
                  ),
                ),
                UiSwitchRow(
                  key: const ValueKey('settings-blur-photos'),
                  label: l10n.profile_settings_blurPhotos,
                  value: ref.watch(blurPhotosOnShareProvider),
                  onChanged: (v) => unawaited(
                    ref.read(blurPhotosOnShareProvider.notifier).set(v),
                  ),
                ),
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
          UiListHeading(title: l10n.profile_settings_secInfo),
          _Card(
            child: Column(
              children: [
                UiRow(
                  key: const ValueKey('settings-eula'),
                  leading: const OurneyIcon(name: 'shield', flat: true),
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
                  leading: const OurneyIcon(name: 'chat', flat: true),
                  title: l10n.profile_settings_contact,
                  divider: false,
                  onPressed: () => context.push(SafetyPaths.contact),
                ),
              ],
            ),
          ),
          if (!localOnly) ...[
            const SizedBox(height: UiSpace.lg),
            _Card(
              borderColor: context.ui.danger,
              child: UiRow(
                key: const ValueKey('settings-delete'),
                leading: OurneyIcon(
                  name: 'trash',
                  flat: true,
                  color: context.ui.danger,
                ),
                title: l10n.profile_settings_delete,
                divider: false,
                showChevron: false,
                onPressed: () {
                  OurneyHaptics.warning();
                  unawaited(DeleteAccountDialog.show(context));
                },
              ),
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

class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderColor});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profile_settings_language,
          style: UiText.body(
            size: 14,
            weight: FontWeight.w700,
            color: context.ui.ink,
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        UiSegmented<String>(
          value: code == 'en' ? 'en' : 'vi',
          onChanged: (c) => unawaited(
            ref.read(localeOverrideProvider.notifier).set(Locale(c)),
          ),
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
      ],
    );
  }
}

/// `.app-icon-picker`: 7 tiles. Selection is stored only; no plugin switches
/// the launcher icon yet (see [appIconProvider]).
class _AppIconPicker extends ConsumerWidget {
  const _AppIconPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final selected = ref.watch(appIconProvider);
    final items = <(String, Color, Color, String)>[
      (
        'default',
        const Color(0xFFFF4D6D),
        const Color(0xFF10B981),
        l10n.profile_settings_iconDefault,
      ),
      (
        'quiet',
        const Color(0xFFDFF7EC),
        const Color(0xFF10B981),
        l10n.profile_settings_iconQuiet,
      ),
      (
        'squad',
        const Color(0xFFFFF0C7),
        const Color(0xFFFF9F1C),
        l10n.profile_settings_iconSquad,
      ),
      (
        'memory',
        const Color(0xFFF3E3C3),
        const Color(0xFFC2452B),
        l10n.profile_settings_iconMemory,
      ),
      (
        'couple',
        const Color(0xFFFFE0E9),
        const Color(0xFFE15B72),
        l10n.profile_settings_iconCouple,
      ),
      (
        'flexer',
        const Color(0xFF14161F),
        const Color(0xFF3DE88C),
        l10n.profile_settings_iconFlexer,
      ),
      (
        'minimal',
        const Color(0xFFF4F4F5),
        const Color(0xFFEA580C),
        l10n.profile_settings_iconMinimal,
      ),
    ];
    return Column(
      key: const ValueKey('settings-app-icons'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profile_settings_appIcon,
          style: UiText.body(size: 14, weight: FontWeight.w700, color: ui.ink),
        ),
        const SizedBox(height: UiSpace.sm),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final (id, tile, mark, label) in items)
              UiPressable(
                key: ValueKey('settings-icon-$id'),
                selected: id == selected,
                semanticLabel: l10n.profile_settings_iconSemantic(label),
                excludeChildSemantics: true,
                borderRadius: BorderRadius.circular(UiRadius.menu),
                onPressed: () =>
                    unawaited(ref.read(appIconProvider.notifier).set(id)),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tile,
                          borderRadius: BorderRadius.circular(UiRadius.menu),
                          border: Border.all(
                            color: id == selected ? ui.focus : ui.outline,
                            width: id == selected ? 3 : UiBorder.thin,
                          ),
                        ),
                        child: Text(
                          'O',
                          style: UiText.h1(size: 24, color: mark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: UiText.body(size: 11, color: ui.ink),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: UiSpace.xs),
        Text(
          l10n.profile_settings_appIconNote,
          style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
        ),
      ],
    );
  }
}
