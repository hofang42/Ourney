import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../data/import_draft.dart';
import '../data/import_job.dart';
import '../data/photo_dates.dart';
import '../l10n/generated/import_localizations.dart';
import 'import_widgets.dart';

/// `.pushed-header`: 48dp back, centered 13dp bold title.
class ImportHeader extends StatelessWidget {
  const ImportHeader({required this.title, required this.onBack, super.key});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 74),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Row(
          children: [
            UiBarIconButton(
              key: const ValueKey('import-back'),
              glyph: const OurneyIcon(name: 'back', size: 21),
              label: l10n.import_back,
              onPressed: onBack,
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: UiText.body(
                    size: 13,
                    weight: FontWeight.w800,
                    height: 1.35,
                    color: ui.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Screen heading (`h1`) with the step counter above it.
class ImportHeading extends StatelessWidget {
  const ImportHeading({required this.title, this.step, super.key});

  final String title;

  /// 1..3, or null on the saving / done screens.
  final int? step;

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.import_stepOf(step!),
                style: UiText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: ui.inkMuted,
                ),
              ),
            ),
          Semantics(
            header: true,
            child: Text(
              title,
              style: UiText.h2(size: 25, color: ui.ink).copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small bold uppercase section label.
class ImportSectionLabel extends StatelessWidget {
  const ImportSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 9),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: UiText.body(
          size: 13,
          weight: FontWeight.w800,
          height: 1.4,
          color: context.ui.ink,
        ),
      ),
    ),
  );
}

/// Two equal columns that wrap (`repeat(2, 1fr)`), rows as tall as content.
class ImportTwoColumn extends StatelessWidget {
  const ImportTwoColumn({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = 9.0;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      },
    );
  }
}

class ImportTypeButton extends StatelessWidget {
  const ImportTypeButton({
    required this.id,
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final fg = selected ? ui.onBrand : ui.ink;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      shadowOffset: UiShadow.small,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected ? ui.brand : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: ui.stickerBorder(selected ? 3 : UiBorder.standard),
        ),
        child: Row(
          children: [
            UiTypeBadge(type: id, size: 36),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportLayoutButton extends StatelessWidget {
  const ImportLayoutButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.preview,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: selected
              ? Border.all(color: ui.accent, width: 3)
              : ui.stickerBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            preview,
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 12,
                weight: FontWeight.w800,
                height: 1.4,
                color: ui.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tile of the photo grid (step 1): the thumbnail, a check badge when
/// selected, the date below.
class ImportPhotoTile extends StatelessWidget {
  const ImportPhotoTile({
    required this.photo,
    required this.dateLabel,
    required this.semantic,
    required this.onPressed,
    super.key,
  });

  final DraftPhoto photo;
  final String dateLabel;
  final String semantic;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final on = photo.selected;
    return UiPressable(
      onPressed: onPressed,
      selected: on,
      semanticLabel: semantic,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(
            color: on ? ui.accent : ui.border,
            width: UiBorder.standard,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImportThumb(path: photo.path, height: double.infinity),
                  if (on)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ui.success,
                        ),
                        child: OurneyIcon(
                          name: 'check',
                          size: 15,
                          flat: true,
                          color: ui.bg,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
              child: Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(size: 11, height: 1.4, color: ui.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A photo of the timeline (step 2): thumbnail, its date and where the date
/// came from; tap changes the date (or toggles it in select mode).
class ImportTimelineTile extends StatelessWidget {
  const ImportTimelineTile({
    required this.photo,
    required this.dateLabel,
    required this.onTap,
    required this.onRemove,
    this.onEditDate,
    this.selecting = false,
    this.selected = false,
    this.undated = false,
    super.key,
  });

  final DraftPhoto photo;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onEditDate;
  final bool selecting;
  final bool selected;
  final bool undated;

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    final source = switch (photo.source) {
      PhotoDateSource.exif => l10n.import_sourceExif,
      PhotoDateSource.file => l10n.import_sourceFile,
      PhotoDateSource.manual => l10n.import_sourceManual,
      null => null,
    };
    final hasCaption = photo.caption?.trim().isNotEmpty ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: UiPressable(
              onPressed: onTap,
              selected: selecting && selected,
              semanticLabel: selecting
                  ? (selected
                        ? l10n.import_deselectPhoto(dateLabel)
                        : l10n.import_selectPhoto(dateLabel))
                  : undated
                  ? l10n.import_editDate(dateLabel)
                  : hasCaption
                  ? l10n.import_captionEdit(photo.caption!, dateLabel)
                  : l10n.import_captionOpen(dateLabel),
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(UiRadius.input),
              child: Container(
                constraints: const BoxConstraints(minHeight: UiSize.tap),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ui.surface,
                  borderRadius: BorderRadius.circular(UiRadius.input),
                  border: Border.all(
                    color: selecting && selected ? ui.accent : ui.border,
                    width: selecting && selected ? 3 : UiBorder.standard,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: ImportThumb(path: photo.path, height: 56),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!undated &&
                              !selecting &&
                              (photo.caption?.trim().isNotEmpty ?? false))
                            Text(
                              photo.caption!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.body(
                                size: 13,
                                height: 1.35,
                                color: ui.ink,
                              ),
                            ),
                          Text(
                            dateLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.body(
                              size: 13,
                              weight: FontWeight.w700,
                              height: 1.35,
                              color: undated ? ui.warn : ui.ink,
                            ),
                          ),
                          if (source != null)
                            Text(
                              source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.body(
                                size: 11,
                                height: 1.4,
                                color: ui.inkMuted,
                              ),
                            ),
                          if (!undated &&
                              !selecting &&
                              (photo.caption?.trim().isEmpty ?? true))
                            Row(
                              children: [
                                OurneyIcon(
                                  name: 'pencil',
                                  size: 14,
                                  flat: true,
                                  color: ui.inkMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    l10n.import_captionAddHint,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.body(
                                      size: 11,
                                      height: 1.35,
                                      color: ui.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (selecting)
                      OurneyIcon(
                        name: selected ? 'check-circle' : 'plus',
                        size: 20,
                        flat: true,
                        color: selected ? ui.success : ui.inkMuted,
                      )
                    else if (undated)
                      OurneyIcon(
                        name: 'warning',
                        size: 18,
                        flat: true,
                        color: undated ? ui.warn : ui.inkMuted,
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          if (!selecting && !undated)
            UiIconButton(
              key: ValueKey('import-calendar-${photo.order}'),
              glyph: const OurneyIcon(name: 'calendar', flat: true),
              label: l10n.import_captionEditDate,
              iconSize: 20,
              onPressed: onEditDate,
            ),
          if (!selecting)
            UiIconButton(
              key: ValueKey('import-remove-${photo.order}'),
              glyph: const OurneyIcon(name: 'trash', flat: true),
              label: l10n.import_removePhoto,
              iconSize: 20,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// A day heading of the timeline ("Day 3 · 5 Feb 2024 · 2 photos").
class ImportDayHeader extends StatelessWidget {
  const ImportDayHeader({
    required this.day,
    required this.dateLabel,
    required this.count,
    super.key,
  });

  final int day;
  final String dateLabel;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          '${l10n.import_dayLabel(day)} · $dateLabel · '
          '${l10n.import_dayCount(count)}',
          style: UiText.body(
            size: 13,
            weight: FontWeight.w800,
            height: 1.4,
            color: ui.ink,
          ),
        ),
      ),
    );
  }
}

/// A collapsed run of days with no photos.
class ImportGapRow extends StatelessWidget {
  const ImportGapRow({required this.days, super.key});

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: DashedBox(
        radius: 10,
        opacity: 0.64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            l10n.import_gapRow(days),
            textAlign: TextAlign.center,
            style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
          ),
        ),
      ),
    );
  }
}

/// One photo of the saving / done screen with its state.
class ImportJobPhotoRow extends StatelessWidget {
  const ImportJobPhotoRow({
    required this.photo,
    required this.dateLabel,
    required this.thumbPath,
    super.key,
  });

  final ImportJobPhoto photo;
  final String dateLabel;
  final String? thumbPath;

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    final (label, color, icon) = switch (photo.state) {
      ImportPhotoState.saved => (l10n.import_photoSaved, ui.success, 'check'),
      ImportPhotoState.failed => (
        l10n.import_photoFailed,
        ui.danger,
        'warning',
      ),
      ImportPhotoState.pending => (
        l10n.import_photoPending,
        ui.inkMuted,
        'clock',
      ),
    };
    final reason = photo.state == ImportPhotoState.failed
        ? switch (photo.failure) {
            ImportFailure.unreadable => l10n.import_reason_unreadable,
            ImportFailure.offline => l10n.import_reason_offline,
            ImportFailure.badDate => l10n.import_reason_badDate,
            _ => l10n.import_reason_unknown,
          }
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(color: ui.border, width: UiBorder.standard),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: ImportThumb(path: thumbPath, height: 48),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 13,
                      weight: FontWeight.w700,
                      height: 1.35,
                      color: ui.ink,
                    ),
                  ),
                  if (reason != null)
                    Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 11,
                        height: 1.4,
                        color: ui.danger,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            OurneyIcon(name: icon, size: 16, flat: true, color: color),
            const SizedBox(width: 4),
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 84),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 11,
                    weight: FontWeight.w700,
                    height: 1.3,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
