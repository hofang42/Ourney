import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';

/// Full-screen social page (V1.0 `.sharing-screen`): [UiBackHeader] with
/// back, centered title + subtitle and one trailing action. Shows the
/// needs-server state in local-only mode instead of [body].
class SocialScaffold extends ConsumerWidget {
  const SocialScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.action,
    this.bottom,
    this.header,
    super.key,
  });

  /// Replaces the centered title block (chat: avatar + name + journey).
  final Widget? header;

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget body;

  /// Pinned under the body (chat composer).
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = context.ui;
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final l10n = AppLocalizations.of(context);
    final back = MaterialLocalizations.of(context).backButtonTooltip;
    final Widget bar = header != null && !localOnly
        ? Row(
            children: [
              UiIconButton(
                key: const ValueKey('social-back'),
                icon: Icons.arrow_back_rounded,
                label: back,
                onPressed: () => socialBack(context),
              ),
              Expanded(child: header!),
              action ?? const SizedBox(width: UiSize.tap),
            ],
          )
        : UiBackHeader(
            key: const ValueKey('social-back'),
            backLabel: back,
            onBack: () => socialBack(context),
            title: title,
            subtitle: localOnly ? null : subtitle,
            trailing: localOnly ? null : action,
          );
    return UiScaffold(
      scroll: false,
      padTop: 0,
      padBottom: 0,
      bottom: localOnly ? null : bottom,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ui.divider)),
            ),
            child: bar,
          ),
          Expanded(
            child: localOnly
                ? UiEmptyState(
                    key: const ValueKey('needs-server'),
                    icon: Icons.cloud_off_rounded,
                    title: l10n.needsServer_title,
                    body: l10n.needsServer_message,
                  )
                : body,
          ),
        ],
      ),
    );
  }
}

void socialBack(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.journeys);
    }
    return;
  }
  Navigator.of(context).maybePop();
}

/// `.nav-text-button`: icon + short label in the header (48dp).
class SocialHeaderAction extends StatelessWidget {
  const SocialHeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: ui.ink),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              style: UiText.body(
                size: 14,
                weight: FontWeight.w700,
                height: 1.3,
                color: ui.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eyebrow section label (`TODAY` style).
class SocialSectionLabel extends StatelessWidget {
  const SocialSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: Semantics(header: true, child: UiEyebrow(text.toUpperCase())),
    );
  }
}

/// A display name to show (falls back to the username).
String displayNameOf(PersonSummary p) =>
    p.displayName.trim().isEmpty ? p.username : p.displayName.trim();

/// [UiPersonRow] bound to a [PersonSummary]; subtitle defaults to `@username`.
class PersonRow extends StatelessWidget {
  const PersonRow({
    required this.person,
    this.title,
    this.subtitle,
    this.extraLine,
    this.trailing = const [],
    this.actions = const [],
    this.onTap,
    this.unread = false,
    this.leading,
    super.key,
  });

  final PersonSummary person;
  final String? title;
  final String? subtitle;
  final String? extraLine;
  final List<Widget> trailing;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final bool unread;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => UiPersonRow(
    name: displayNameOf(person),
    title: title ?? displayNameOf(person),
    subtitle: subtitle ?? '@${person.username}',
    extraLine: extraLine,
    trailing: trailing,
    actions: actions,
    onPressed: onTap,
    unread: unread,
    leading: leading,
  );
}

/// Scrolling list body with bottom safe-area padding.
class SocialListBody extends StatelessWidget {
  const SocialListBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: UiSpace.huge + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}

/// User-facing message for a repository error (raw details never shown).
String socialErrorMessage(BuildContext context, Object error) {
  final l10n = SocialL10n.of(context);
  final app = AppLocalizations.of(context);
  return switch (socialErrorCode(error)) {
    OurneyErrorCode.notFound => l10n.social_errorNotFound,
    OurneyErrorCode.blocked => l10n.social_errorBlocked,
    OurneyErrorCode.forbidden => l10n.social_errorForbidden,
    OurneyErrorCode.rateLimited => l10n.social_rateLimited,
    OurneyErrorCode.offline => app.common_offline,
    _ => app.common_errorGeneric,
  };
}

void showSocialSnack(BuildContext context, String message) =>
    showUiToast(context, message, bottomOffset: 24);

/// Runs [action] and shows a toast with the error, if any. Returns true on
/// success.
Future<bool> runSocialAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on Object catch (e) {
    if (context.mounted) {
      showSocialSnack(context, socialErrorMessage(context, e));
    }
    return false;
  }
}

/// Confirmation sheet. Resolves to true on confirm.
Future<bool> confirmSocialAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showUiConfirmSheet(
    context: context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: AppLocalizations.of(context).common_cancel,
    destructive: destructive,
    sheetKey: const ValueKey('social-confirm-dialog'),
    confirmKey: const ValueKey('social-confirm'),
  );
}

/// "20:14" for today, a short date otherwise (local time).
String socialTime(BuildContext context, DateTime at, {DateTime? now}) {
  final m = MaterialLocalizations.of(context);
  final local = at.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  if (sameDay) {
    return m.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  return m.formatShortMonthDay(local);
}

/// Centered spinner with the shared loading label.
class SocialLoading extends StatelessWidget {
  const SocialLoading({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      color: context.ui.ink,
      semanticsLabel: AppLocalizations.of(context).common_loading,
    ),
  );
}
