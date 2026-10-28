import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/avatar.dart';
import '../../../shared/layout.dart';
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

void showSharingSnack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

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

/// Body text with the Vietnamese-safe line height.
TextStyle sharingBody(BuildContext context, {double size = 14, Color? color}) =>
    TextStyle(
      fontFamily: kBodyFont,
      fontSize: size,
      height: 1.4,
      color: color ?? OurneyColors.of(context).ink,
    );

/// Small bold label ("Friends", switch titles).
TextStyle sharingLabel(
  BuildContext context, {
  double size = 14,
  Color? color,
  FontWeight weight = FontWeight.w700,
}) => TextStyle(
  fontFamily: kBodyFont,
  fontSize: size,
  fontWeight: weight,
  height: 1.35,
  color: color ?? OurneyColors.of(context).ink,
);

/// Horizontal padding of the available width (16/20/24, CLAUDE.md §3) in a
/// centered column no wider than 480/520dp.
class SharingColumn extends StatelessWidget {
  const SharingColumn({required this.builder, super.key});

  final Widget Function(BuildContext context, double gutter) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: OurneyLayout.contentMaxWidth(width),
          child: builder(context, OurneyLayout.horizontalPadding(width)),
        ),
      );
    },
  );
}

/// AppBar title with an optional subtitle (V1.0 "sharing-nav").
class SharingNavTitle extends StatelessWidget {
  const SharingNavTitle({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: displayStyle(size: 16, weight: 700, height: 1.3, color: c.ink),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sharingBody(context, size: 11, color: c.inkMuted),
          ),
      ],
    );
  }
}

/// Title + hint + switch, 54dp minimum, hairline below (V1.0 "switch-row").
class SharingSwitchRow extends StatelessWidget {
  const SharingSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final String title;
  final String? hint;
  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: sharingLabel(context, size: 14)),
                  if (hint != null)
                    Text(
                      hint!,
                      style: sharingBody(context, size: 12, color: c.inkMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: OurneySpacing.sm),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: c.primary,
              activeThumbColor: OurneyColors.light.surface,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section rule + heading used by the share sheet blocks.
class SharingSectionHeader extends StatelessWidget {
  const SharingSectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: headingStyle(size: 17)),
          ),
        ),
        if (trailing != null)
          Flexible(
            flex: 2,
            child: Wrap(alignment: WrapAlignment.end, children: trailing!),
          ),
      ],
    ),
  );
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
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const StadiumBorder(),
        side: BorderSide(color: c.border),
        backgroundColor: c.surface,
        foregroundColor: c.ink,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sharingLabel(context, size: 13),
            ),
          ),
        ],
      ),
    );
  }
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
    final c = OurneyColors.of(context);
    return ColoredBox(
      color: c.surfaceSunken,
      child: Center(
        child: Icon(Icons.image_outlined, color: c.inkMuted, size: 22),
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
    return Avatar(
      name: person.displayName,
      size: size,
      image: file == null ? null : FileImage(File(file)),
    );
  }
}

/// Destructive or plain confirmation. Resolves to true on confirm.
Future<bool> confirmSharingAction(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  String? title,
  bool destructive = false,
}) async {
  final app = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title == null ? null : Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(app.common_cancel),
        ),
        TextButton(
          key: const ValueKey('sharing-confirm'),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: OurneyColors.of(context).danger,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Loading / error body shared by the sharing screens.
class SharingLoading extends StatelessWidget {
  const SharingLoading({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(OurneySpacing.xl),
      child: CircularProgressIndicator(
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
    final c = OurneyColors.of(context);
    final app = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(OurneySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: c.inkMuted),
            const SizedBox(height: OurneySpacing.md),
            Text(
              sharingErrorMessage(context, error),
              textAlign: TextAlign.center,
              style: sharingBody(context),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: OurneySpacing.lg),
              SharingPillButton(
                key: const ValueKey('sharing-retry'),
                label: app.common_retry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
