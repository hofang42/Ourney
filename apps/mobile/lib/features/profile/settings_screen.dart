import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
import 'share_privacy_sync.dart';
import 'widgets/delete_account_dialog.dart';
import 'widgets/sign_out_flow.dart';

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
                    showChevron: false,
                    onPressed: () => confirmSignOut(context, ref),
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
          const _AppIconPicker(),
          UiListHeading(title: l10n.profile_settings_secPrivacy),
          _Card(
            child: Column(
              children: [
                UiSwitchRow(
                  key: const ValueKey('settings-hide-kg'),
                  label: l10n.profile_settings_hideKg,
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
                  value: ref.watch(blurPhotosOnShareProvider),
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

/// `.app-icon-picker`: 8 Ourney V2 icon variants rendered inside a [UiCard]
/// grid with bundled `180x180` previews, localized names (vi/en), current
/// selection badge, 48dp touch targets, and platform channel switching.
/// Gracefully hidden on platforms without launcher icon support.
class _AppIconPicker extends ConsumerWidget {
  const _AppIconPicker();

  static String _labelFor(ProfileL10n l10n, String id) => switch (id) {
    'default' => l10n.profile_settings_iconDefault,
    'yellow' => l10n.profile_settings_iconYellow,
    'green' => l10n.profile_settings_iconGreen,
    'coral' => l10n.profile_settings_iconCoral,
    'violet' => l10n.profile_settings_iconViolet,
    'sky' => l10n.profile_settings_iconSky,
    'dark' => l10n.profile_settings_iconDark,
    'minimal' => l10n.profile_settings_iconMinimal,
    _ => id,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(appIconSwitcherProvider).supported;
    if (!supported) return const SizedBox.shrink();

    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final boldText = MediaQuery.boldTextOf(context);
    final selected = ref.watch(appIconProvider);

    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.md),
      child: UiCard(
        key: const ValueKey('settings-app-icons'),
        radius: UiRadius.card,
        shadowOffset: UiShadow.small,
        padding: const EdgeInsets.all(UiSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profile_settings_appIcon,
              style: UiText.body(
                size: 14,
                weight: FontWeight.w700,
                color: ui.ink,
              ),
            ),
            const SizedBox(height: UiSpace.xs),
            Text(
              l10n.profile_settings_appIconNote,
              key: const ValueKey('settings-app-icon-note'),
              style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
            ),
            const SizedBox(height: UiSpace.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth < 230 ? 2 : 4;
                const spacing = UiSpace.sm;
                final rawWidth =
                    (constraints.maxWidth - spacing * (cols - 1)) / cols;
                final itemWidth = rawWidth < UiSize.tap ? UiSize.tap : rawWidth;
                return Wrap(
                  spacing: spacing,
                  runSpacing: UiSpace.md,
                  children: [
                    for (final (index, variant)
                        in AppIconController.variants.indexed)
                      Builder(
                        builder: (context) {
                          final id = variant.id;
                          final isSelected = id == selected;
                          final label = _labelFor(l10n, id);
                          return Semantics(
                            sortKey: OrdinalSortKey(index.toDouble()),
                            child: UiPressable(
                              key: ValueKey('settings-icon-$id'),
                              selected: isSelected,
                              semanticLabel: l10n.profile_settings_iconSemantic(
                                label,
                              ),
                              excludeChildSemantics: true,
                              minSize: const Size(UiSize.tap, UiSize.tap),
                              borderRadius: BorderRadius.circular(
                                UiRadius.menu,
                              ),
                              onPressed: () {
                                OurneyHaptics.selection();
                                unawaited(
                                  ref.read(appIconProvider.notifier).set(id),
                                );
                              },
                              child: SizedBox(
                                width: itemWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? ui.focus
                                                  : ui.outline,
                                              width: isSelected
                                                  ? 3
                                                  : UiBorder.standard,
                                            ),
                                            boxShadow: isSelected
                                                ? ui.hardShadow(2)
                                                : null,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            child: Image.asset(
                                              variant.previewAsset,
                                              width: 52,
                                              height: 52,
                                              fit: BoxFit.cover,
                                              cacheWidth: 180,
                                              filterQuality:
                                                  FilterQuality.medium,
                                              excludeFromSemantics: true,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          PositionedDirectional(
                                            top: -6,
                                            end: -6,
                                            child: Container(
                                              key: const ValueKey(
                                                'settings-icon-check',
                                              ),
                                              width: 22,
                                              height: 22,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: ui.ink,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: ui.surface,
                                                  width: UiBorder.thin,
                                                ),
                                              ),
                                              child: OurneyIcon(
                                                name: 'check',
                                                size: 12,
                                                flat: true,
                                                color: ui.surface,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: UiText.body(
                                        size: 11,
                                        height: 1.3,
                                        weight: isSelected || boldText
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected ? ui.ink : ui.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
