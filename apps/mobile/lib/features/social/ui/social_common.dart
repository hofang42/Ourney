import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/avatar.dart';
import '../../../shared/layout.dart';
import '../../../shared/needs_server_view.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';

/// Full-screen social page (V1.0 `.sharing-screen`): sticky hairline header
/// with back, centered title + subtitle and one trailing action. Shows
/// [NeedsServerView] in local-only mode instead of [body].
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
    final c = OurneyColors.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SocialHeader(
              title: title,
              subtitle: localOnly ? null : subtitle,
              action: localOnly ? null : action,
              leading: localOnly ? null : header,
            ),
            Expanded(
              child: localOnly
                  ? const SafeArea(top: false, child: NeedsServerView())
                  : body,
            ),
            if (!localOnly && bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

/// `.sharing-nav`: 48dp back button, centered Bricolage title, trailing
/// action, hairline under it.
class SocialHeader extends StatelessWidget {
  const SocialHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.leading,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  /// Replaces the centered title block (chat header).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('social-back'),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(Icons.arrow_back_rounded, color: c.ink, size: 22),
            constraints: const BoxConstraints(
              minWidth: OurneySizes.minTap,
              minHeight: OurneySizes.minTap,
            ),
            onPressed: () => _back(context),
          ),
          Expanded(
            child:
                leading ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: displayStyle(
                          size: 18,
                          weight: 700,
                          height: 1.3,
                          tracking: -0.02,
                          color: c.ink,
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 12,
                          height: 1.35,
                          color: c.inkMuted,
                        ),
                      ),
                  ],
                ),
          ),
          if (action != null)
            action!
          else
            const SizedBox(width: OurneySizes.minTap),
        ],
      ),
    );
  }

  static void _back(BuildContext context) {
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
}

/// `.nav-text-button`: icon + short label in the header.
class SocialHeaderTextButton extends StatelessWidget {
  const SocialHeaderTextButton({
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
    final c = OurneyColors.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(OurneySizes.minTap, OurneySizes.minTap),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: kBodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

/// Capsule action inside a row (`.person-row > button`): brand fill with
/// ink text, or the quiet sunken variant. 48dp tall.
class SocialPill extends StatelessWidget {
  const SocialPill({
    required this.label,
    required this.onPressed,
    this.quiet = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool quiet;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final bg = quiet ? c.surfaceSunken : c.primary;
    final fg = quiet ? c.ink : c.onPrimary;
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: c.surfaceSunken,
        disabledForegroundColor: c.inkMuted,
        minimumSize: const Size(OurneySizes.minTap, OurneySizes.minTap),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: StadiumBorder(
          side: quiet ? BorderSide(color: c.divider) : BorderSide.none,
        ),
        textStyle: const TextStyle(
          fontFamily: kBodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    if (semanticLabel == null) return button;
    return Semantics(label: semanticLabel, button: true, child: button);
  }
}

/// Muted state label in place of a button ("Requested", "Friends").
class SocialStateLabel extends StatelessWidget {
  const SocialStateLabel(this.text, {this.icon, super.key});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: OurneySizes.minTap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: c.inkMuted),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: c.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eyebrow section label (`TODAY` style).
class SocialSectionLabel extends StatelessWidget {
  const SocialSectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text.toUpperCase(),
                style: eyebrowStyle(size: 11, color: c.inkMuted),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// `.person-row`: avatar, name + @username (+ sub-line), [trailing]
/// widgets, hairline under it. [actions] (Accept / Decline pairs) sit
/// inline on wide rows and wrap under the text on narrow ones (320dp,
/// large text). [unread] adds a red dot and bold text.
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

  /// Defaults to the display name.
  final String? title;

  /// Defaults to `@username`.
  final String? subtitle;
  final String? extraLine;
  final List<Widget> trailing;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final bool unread;

  /// Replaces the avatar.
  final Widget? leading;

  /// Narrowest row (at 1x text) that keeps [actions] inline.
  static const double inlineActionsMinWidth = 340;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final inline =
            actions.isEmpty ||
            constraints.maxWidth >= inlineActionsMinWidth * scale;
        final texts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? displayNameOf(person),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                height: 1.35,
                fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
            Text(
              subtitle ?? '@${person.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: c.inkMuted,
              ),
            ),
            if (extraLine != null)
              Text(
                extraLine!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: c.inkMuted,
                ),
              ),
            if (!inline) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: actions),
            ],
          ],
        );
        final row = Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider)),
          ),
          child: Row(
            children: [
              if (unread) ...[
                Container(
                  key: const ValueKey('unread-dot'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              leading ??
                  ExcludeSemantics(
                    child: Avatar(name: displayNameOf(person), size: 40),
                  ),
              const SizedBox(width: 10),
              Expanded(child: texts),
              if (inline)
                for (final a in actions) ...[const SizedBox(width: 6), a],
              for (final t in trailing) ...[const SizedBox(width: 6), t],
            ],
          ),
        );
        if (onTap == null) return row;
        return InkWell(onTap: onTap, child: row);
      },
    );
  }
}

/// A display name to show (falls back to the username).
String displayNameOf(PersonSummary p) =>
    p.displayName.trim().isEmpty ? p.username : p.displayName.trim();

/// Responsive list body: 16/20/24dp side padding, 520dp column on tablets.
class SocialListBody extends StatelessWidget {
  const SocialListBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pad = OurneyLayout.horizontalPadding(width);
        final max = OurneyLayout.contentMaxWidth(width);
        final side = ((width - max) / 2).clamp(0.0, double.infinity) + pad;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            side,
            0,
            side,
            OurneySpacing.xxl + MediaQuery.paddingOf(context).bottom,
          ),
          children: children,
        );
      },
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

void showSocialSnack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs [action] and shows a snack bar with the error, if any. Returns true
/// on success.
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

/// Confirmation dialog. Resolves to true on confirm.
Future<bool> confirmSocialAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final app = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = OurneyColors.of(context);
      return AlertDialog(
        key: const ValueKey('social-confirm-dialog'),
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(app.common_cancel),
          ),
          TextButton(
            key: const ValueKey('social-confirm'),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: c.danger)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
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
      semanticsLabel: AppLocalizations.of(context).common_loading,
    ),
  );
}
