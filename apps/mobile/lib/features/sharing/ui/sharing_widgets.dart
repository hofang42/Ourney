import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';

/// Unwraps Riverpod's [ProviderException] (a dependency in error state).
Object sharingRootError(Object error) {
  var e = error;
  while (e is ProviderException) {
    e = e.exception;
  }
  return e;
}

OurneyErrorCode? sharingErrorCode(Object error) =>
    switch (sharingRootError(error)) {
      OurneyException(:final error) => error,
      _ => null,
    };

/// User-facing message for a repository error (raw details never shown).
String sharingErrorMessage(BuildContext context, Object error) {
  final l10n = SharingL10n.of(context);
  final app = AppLocalizations.of(context);
  return switch (sharingErrorCode(error)) {
    OurneyErrorCode.forbidden => l10n.sharing_errorNotFriend,
    OurneyErrorCode.rateLimited => l10n.sharing_errorRateLimited,
    OurneyErrorCode.invalid => l10n.sharing_linkLockedTitle,
    OurneyErrorCode.consentRequired => l10n.sharing_askGroupHint,
    OurneyErrorCode.notFound => l10n.sharing_privateNow,
    OurneyErrorCode.offline => app.common_offline,
    _ => app.common_errorGeneric,
  };
}

void showSharingSnack(BuildContext context, String message) =>
    showUiToast(context, message);

/// "1.2k" style numbers.
String compactCount(BuildContext context, int value) =>
    NumberFormat.compact(locale: Localizations.localeOf(context).toString())
        .format(value);

/// "3 Feb 2024" (en) / "3 thg 2, 2024" (vi).
String formatLocalDate(BuildContext context, LocalDate date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(DateTime(date.year, date.month, date.day));

/// "3 Feb – 6 Feb 2024", or a single date when both are the same day.
String formatDateRange(BuildContext context, LocalDate first, LocalDate last) {
  if (first == last) return formatLocalDate(context, first);
  final locale = Localizations.localeOf(context).toString();
  final a = DateTime(first.year, first.month, first.day);
  final b = DateTime(last.year, last.month, last.day);
  final start = first.year == last.year
      ? DateFormat.MMMd(locale).format(a)
      : DateFormat.yMMMd(locale).format(a);
  return '$start – ${DateFormat.yMMMd(locale).format(b)}';
}

/// Body text style of the kit (Vietnamese-safe line height).
TextStyle sharingBody(BuildContext context, {double size = 14, Color? color}) =>
    UiText.body(size: size, color: color ?? context.ui.ink);

/// Small bold label.
TextStyle sharingLabel(
  BuildContext context, {
  double size = 14,
  Color? color,
  FontWeight weight = FontWeight.w700,
}) => UiText.body(
  size: size,
  weight: weight,
  height: 1.35,
  color: color ?? context.ui.ink,
);

/// Pops when possible, else goes to [fallback] (the journeys tab).
void sharingBack(BuildContext context, {String fallback = '/journeys'}) {
  final router = GoRouter.maybeOf(context);
  if (router == null || router.canPop()) {
    Navigator.of(context).maybePop();
  } else {
    router.go(fallback);
  }
}

/// Screen frame: a back header (+ optional trailing) over the kit scaffold.
class SharingPage extends StatelessWidget {
  const SharingPage({
    required this.children,
    this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.bottom,
    this.background,
    this.scaffoldKey,
    super.key,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget? bottom;
  final Color? background;
  final Key? scaffoldKey;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: scaffoldKey,
    child: UiScaffold(
      background: background,
      bottom: bottom,
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: onBack ?? () => sharingBack(context),
            backLabel: MaterialLocalizations.of(context).backButtonTooltip,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
          ...children,
        ],
      ),
    ),
  );
}

/// Local-only mode placeholder (FR-A5).
class SharingNeedsServer extends StatelessWidget {
  const SharingNeedsServer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context);
    return UiEmptyState(
      key: const ValueKey('needs-server'),
      icon: Icons.cloud_off_rounded,
      title: app.needsServer_title,
      body: app.needsServer_message,
    );
  }
}

/// Capsule outlined action ("Copy link", "Reset link", "Add friend").
class SharingPillButton extends StatelessWidget {
  const SharingPillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => UiButton.secondary(
    label: label,
    icon: icon,
    onPressed: onPressed,
    compact: true,
    expand: false,
  );
}

/// Photo (or thumbnail) stored at [path], loaded through the media store.
/// [blurred] keeps it unreadable (`blur_media`, S10).
class StoragePhoto extends ConsumerWidget {
  const StoragePhoto({
    required this.path,
    this.blurred = false,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    super.key,
  });

  final String path;
  final bool blurred;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Blurred photos arrive without a path (FR-B7): placeholder only.
    final file = path.isEmpty
        ? null
        : ref.watch(storageFileProvider(path)).value;
    Widget child = file == null
        ? const PhotoPlaceholder()
        : Image.file(
            File(file),
            fit: fit,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => const PhotoPlaceholder(),
          );
    if (blurred) {
      child = ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: child,
        ),
      );
    }
    return child;
  }
}

class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ColoredBox(
      color: ui.fill,
      child: Center(
        child: Icon(Icons.image_outlined, color: ui.inkMuted, size: 22),
      ),
    );
  }
}

/// Avatar of a [PersonSummary]: their photo when it loads, else initials.
class PersonAvatar extends ConsumerWidget {
  const PersonAvatar({required this.person, this.size = 32, super.key});

  final PersonSummary person;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = person.avatarPath;
    final file = path == null
        ? null
        : ref.watch(storageFileProvider(path)).value;
    return UiAvatar(
      name: person.displayName,
      colorIndex: UiAvatar.indexFor(person.userId),
      size: size,
      ring: false,
      image: file == null ? null : FileImage(File(file)),
    );
  }
}

/// Square check box of the V1.0 design (ink fill when ticked).
class SharingCheckSquare extends StatelessWidget {
  const SharingCheckSquare({required this.checked, super.key});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? ui.ink : Colors.transparent,
        border: Border.all(color: checked ? ui.ink : ui.inkMuted, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: checked ? Icon(Icons.check_rounded, size: 16, color: ui.bg) : null,
    );
  }
}

/// Plain or destructive confirmation as a kit sheet. Resolves to true on
/// confirm.
Future<bool> confirmSharingAction(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  String? title,
  bool destructive = false,
}) async {
  final app = AppLocalizations.of(context);
  final result = await showUiSheet<bool>(
    context: context,
    builder: (context) {
      final ui = context.ui;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title, style: UiText.h2(size: 20, color: ui.ink)),
            const SizedBox(height: UiSpace.sm),
          ],
          Text(message, style: UiText.muted(color: ui.inkMuted)),
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('sharing-confirm'),
            label: confirmLabel,
            accent: destructive ? ui.danger : null,
            onAccent: destructive ? Colors.white : null,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.ghost(
            label: app.common_cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Loading body shared by the sharing screens.
class SharingLoading extends StatelessWidget {
  const SharingLoading({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(UiSpace.xl),
      child: CircularProgressIndicator(
        color: context.ui.brand,
        semanticsLabel: AppLocalizations.of(context).common_loading,
      ),
    ),
  );
}

class SharingErrorView extends StatelessWidget {
  const SharingErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: ui.inkMuted),
            const SizedBox(height: UiSpace.md),
            Text(
              sharingErrorMessage(context, error),
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.ink),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: UiSpace.lg),
              UiButton.secondary(
                key: const ValueKey('sharing-retry'),
                label: app.common_retry,
                icon: Icons.refresh_rounded,
                expand: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
