import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../../checkin/photo_compressor.dart';
import '../../journeys/data/journeys_providers.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import 'sharing_widgets.dart';

/// Longest retold journey (server: `duration_days` 1..366).
const int retellMaxDays = 366;

class _Pick {
  _Pick(this.path, this.date);

  final String path;
  LocalDate date;

  /// Set once the photo is a check-in of the new journey.
  bool saved = false;
}

/// `/retell` (SCR-28): old photos → a retold journey on the shelf (S1, S12).
/// Each photo gets a date (file date by default, editable); the journey is
/// created with `createImported`, then every photo is submitted as a
/// check-in captured at noon of its day (journey-local).
class RetellScreen extends ConsumerStatefulWidget {
  const RetellScreen({super.key});

  @override
  ConsumerState<RetellScreen> createState() => _RetellScreenState();
}

class _RetellScreenState extends ConsumerState<RetellScreen> {
  final List<_Pick> _picks = [];
  final _title = TextEditingController();
  final _metricName = TextEditingController();
  final _metricUnit = TextEditingController();
  final String _clientId = const Uuid().v4();
  TemplateId _template = TemplateId.travel;
  bool _submitted = false;
  bool _busy = false;
  int _done = 0;
  int _failed = 0;
  Journey? _created;

  @override
  void dispose() {
    _title.dispose();
    _metricName.dispose();
    _metricUnit.dispose();
    super.dispose();
  }

  LocalDate _today() {
    final now = ref.read(journeysClockProvider).now();
    return LocalDate(now.year, now.month, now.day);
  }

  void _sort() => _picks.sort((a, b) => a.date.compareTo(b.date));

  Future<void> _pick() async {
    final photos = await ref.read(retellPhotoPickerProvider).pickPhotos();
    if (!mounted || photos.isEmpty) return;
    setState(() {
      for (final p in photos) {
        final m = p.modified.toLocal();
        _picks.add(_Pick(p.path, LocalDate(m.year, m.month, m.day)));
      }
      _sort();
    });
  }

  Future<void> _editDate(_Pick pick) async {
    final today = _today();
    final last = DateTime(today.year, today.month, today.day);
    final current = DateTime(pick.date.year, pick.date.month, pick.date.day);
    final chosen = await showDatePicker(
      context: context,
      initialDate: current.isAfter(last) ? last : current,
      firstDate: DateTime(2000),
      lastDate: last,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      pick.date = LocalDate(chosen.year, chosen.month, chosen.day);
      _sort();
    });
  }

  String? _error(SharingL10n l10n) {
    if (_picks.isEmpty) return l10n.sharing_errorNoPhotos;
    if (validateJourneyTitle(_title.text) != null) {
      return l10n.sharing_errorTitleEmpty;
    }
    if (_picks.last.date.isAfter(_today())) return l10n.sharing_errorFuture;
    if (_picks.first.date.daysUntil(_picks.last.date) + 1 > retellMaxDays) {
      return l10n.sharing_errorRange;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = SharingL10n.of(context);
    setState(() => _submitted = true);
    if (_error(l10n) != null || _busy) return;
    final timezone = ref.read(deviceTimezoneProvider).value ?? 'UTC';
    setState(() {
      _busy = true;
      _failed = 0;
    });
    try {
      final metric = _metricName.text.trim();
      final unit = _metricUnit.text.trim();
      final journey = _created ??= await ref
          .read(sharingRepositoryProvider)
          .createImported(
            ImportedJourneyDraft(
              id: _clientId,
              title: _title.text.trim(),
              emoji: templateFor(_template).emoji,
              templateId: _template,
              firstDate: _picks.first.date,
              lastDate: _picks.last.date,
              timezone: timezone,
              metricName: metric.isEmpty ? null : metric,
              metricUnit: metric.isEmpty || unit.isEmpty ? null : unit,
            ),
          );
      final compressor = ref.read(photoCompressorProvider);
      final checkIns = ref.read(checkInRepositoryProvider);
      final drafts = ref.read(draftFilesProvider);
      for (final pick in List.of(_picks)) {
        if (pick.saved) continue;
        try {
          final files = await compressor.compress(pick.path);
          await checkIns.submit(
            CheckInDraft(
              journeyId: journey.id,
              capturedAt: noonInZone(pick.date, journey.timezone),
              photoFile: files.photoFile,
              thumbFile: files.thumbFile,
              fromLibrary: true,
            ),
          );
          await drafts.discard([files.photoFile, files.thumbFile]);
          pick.saved = true;
          if (mounted) setState(() => _done++);
        } on Object {
          if (mounted) setState(() => _failed++);
        }
      }
      if (!mounted) return;
      if (_failed == 0) {
        context.go(AppRoutes.journey(journey.id));
      } else {
        setState(() => _busy = false);
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSharingSnack(context, sharingErrorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final localOnly = ref.watch(appConfigProvider).localOnly;
    if (localOnly) {
      return SharingPage(
        title: l10n.sharing_retellTitle,
        children: const [SharingNeedsServer()],
      );
    }
    final error = _submitted ? _error(l10n) : null;
    final dates = [for (final p in _picks) p.date];
    final dupes = {
      for (final d in dates)
        if (dates.where((x) => x == d).length > 1) d,
    };
    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);
    final vi = Localizations.localeOf(context).languageCode == 'vi';

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: UiSpace.xl, bottom: 7),
      child: Semantics(
        header: true,
        child: Text(s, style: UiText.fieldLabel(color: ui.inkMuted)),
      ),
    );

    final Widget bottom;
    if (_busy) {
      bottom = Column(
        key: const ValueKey('retell-progress'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sharing_saving(_done, _picks.length),
            style: sharingLabel(context, size: 13),
          ),
          const SizedBox(height: UiSpace.sm),
          UiProgressBar(
            value: _picks.isEmpty ? 0 : _done / _picks.length,
            semanticLabel: l10n.sharing_saving(_done, _picks.length),
          ),
        ],
      );
    } else if (_failed > 0 && _created != null) {
      bottom = Column(
        key: const ValueKey('retell-failed'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sharing_retellFailed(_failed),
            style: sharingLabel(context, size: 13, color: ui.danger),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton(
            key: const ValueKey('retell-retry'),
            label: l10n.sharing_retry,
            onPressed: _save,
          ),
          UiButton.ghost(
            key: const ValueKey('retell-open'),
            label: l10n.sharing_openJourney,
            onPressed: () => context.go(AppRoutes.journey(_created!.id)),
          ),
        ],
      );
    } else {
      bottom = UiButton(
        key: const ValueKey('retell-save'),
        label: l10n.sharing_saveToShelf,
        onPressed: _save,
      );
    }

    // Leaving mid-import would orphan a half-filled journey.
    return PopScope(
      canPop: !_busy,
      child: SharingPage(
        scaffoldKey: const ValueKey('retell'),
        title: l10n.sharing_retellTitle,
        bottom: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            UiSpace.sm,
            gutter,
            UiSpace.lg + MediaQuery.paddingOf(context).bottom,
          ),
          child: bottom,
        ),
        children: [
          AbsorbPointer(
            absorbing: _busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: UiSpace.sm),
                Text(
                  l10n.sharing_retellIntro,
                  style: UiText.muted(color: ui.inkMuted, size: 14),
                ),
                const SizedBox(height: UiSpace.lg),
                UiTextArea(
                  label: l10n.sharing_journeyName,
                  fieldKey: const ValueKey('retell-title'),
                  controller: _title,
                  hint: l10n.sharing_journeyName,
                  maxLength: journeyTitleMax,
                  onChanged: (_) => setState(() {}),
                ),
                label(l10n.sharing_style),
                Wrap(
                  spacing: UiSpace.sm,
                  runSpacing: UiSpace.sm,
                  children: [
                    for (final t in allTemplates)
                      UiChip(
                        key: ValueKey('retell-style-${t.id.wireName}'),
                        label: vi ? t.titleVi : t.titleEn,
                        icon: uiTemplateIcon(t.id),
                        selected: t.id == _template,
                        onPressed: () => setState(() => _template = t.id),
                      ),
                  ],
                ),
                label(l10n.sharing_metricOptional),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: UiTextField(
                        label: l10n.sharing_metricName,
                        fieldKey: const ValueKey('retell-metric-name'),
                        controller: _metricName,
                      ),
                    ),
                    const SizedBox(width: UiSpace.sm),
                    Expanded(
                      flex: 2,
                      child: UiTextField(
                        label: l10n.sharing_metricUnit,
                        fieldKey: const ValueKey('retell-metric-unit'),
                        controller: _metricUnit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UiSpace.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _picks.isEmpty
                            ? l10n.sharing_pickPhotos
                            : l10n.sharing_photosCount(_picks.length),
                        style: UiText.h2(size: 18, color: ui.ink),
                      ),
                    ),
                    Flexible(
                      child: SharingPillButton(
                        key: const ValueKey('retell-pick'),
                        icon: Icons.add_photo_alternate_outlined,
                        label: _picks.isEmpty
                            ? l10n.sharing_pickPhotos
                            : l10n.sharing_addPhotos,
                        onPressed: _pick,
                      ),
                    ),
                  ],
                ),
                if (_picks.isNotEmpty) ...[
                  Text(
                    l10n.sharing_rangeLine(
                      formatDateRange(
                        context,
                        _picks.first.date,
                        _picks.last.date,
                      ),
                      l10n.sharing_days(
                        _picks.first.date.daysUntil(_picks.last.date) + 1,
                      ),
                    ),
                    key: const ValueKey('retell-range'),
                    style: UiText.body(size: 13, color: ui.inkMuted),
                  ),
                  Text(
                    l10n.sharing_photosHint,
                    style: UiText.body(size: 12, color: ui.inkMuted),
                  ),
                  const SizedBox(height: UiSpace.sm),
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.66,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < _picks.length; i++)
                        _PickCell(
                          index: i,
                          pick: _picks[i],
                          duplicate: dupes.contains(_picks[i].date),
                          onDate: () => _editDate(_picks[i]),
                          onRemove: () => setState(() => _picks.removeAt(i)),
                        ),
                    ],
                  ),
                  if (dupes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: UiSpace.sm),
                      child: Text(
                        l10n.sharing_sameDay,
                        style: UiText.body(size: 12, color: ui.warn),
                      ),
                    ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: KeyedSubtree(
                      key: const ValueKey('retell-error'),
                      child: UiInlineError(message: error),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickCell extends StatelessWidget {
  const _PickCell({
    required this.index,
    required this.pick,
    required this.duplicate,
    required this.onDate,
    required this.onRemove,
  });

  final int index;
  final _Pick pick;
  final bool duplicate;
  final VoidCallback onDate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final date = formatLocalDate(context, pick.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UiRadius.thumb),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(pick.path),
                  fit: BoxFit.cover,
                  cacheWidth: 240,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stack) =>
                      const PhotoPlaceholder(),
                ),
                if (pick.saved)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: ui.success,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: UiIconButton(
                    key: ValueKey('retell-remove-$index'),
                    icon: Icons.close_rounded,
                    label: l10n.sharing_removePhoto,
                    background: ui.bg.withValues(alpha: 0.8),
                    iconSize: 18,
                    onPressed: onRemove,
                  ),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: l10n.sharing_changeDate(date),
          excludeSemantics: true,
          child: UiPressable(
            key: ValueKey('retell-date-$index'),
            onPressed: onDate,
            borderRadius: BorderRadius.circular(UiRadius.otp),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: UiSize.tap),
              child: Row(
                children: [
                  Icon(
                    duplicate
                        ? Icons.warning_amber_rounded
                        : Icons.event_rounded,
                    size: 14,
                    color: duplicate ? ui.warn : ui.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      date,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: sharingLabel(context, size: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
