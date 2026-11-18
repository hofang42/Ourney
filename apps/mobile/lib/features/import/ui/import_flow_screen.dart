import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/time_zones.dart';
import '../../../ui/ui.dart';
import '../../checkin/photo_compressor.dart';
import '../../journeys/data/journeys_providers.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../profile/share_privacy_sync.dart';
import '../../sharing/data/sharing_providers.dart';
import '../l10n/generated/import_localizations.dart';
import 'import_widgets.dart';

/// Longest imported journey (server: `duration_days` 1..366).
const int importMaxDays = 366;

/// Files whose modified time is before this year carry no real date.
const int _minRealYear = 1990;

enum _Stage { setup, library, review }

class _Photo {
  _Photo(this.path, this.date);

  final String path;
  LocalDate? date;
  bool selected = true;
  bool saved = false;
}

/// Figma wire label of the six types; maps onto the five data templates
/// (couple and custom both save as `custom`).
class _Type {
  const _Type(this.id, this.template);
  final String id;
  final TemplateId template;
}

const List<_Type> _types = [
  _Type('weight', TemplateId.weightLoss),
  _Type('study', TemplateId.englishDaily),
  _Type('trip', TemplateId.travel),
  _Type('couple', TemplateId.custom),
  _Type('workout', TemplateId.workout30),
  _Type('custom', TemplateId.custom),
];

/// `/import` (Figma `ImportJourneyFlow`): setup, library, review. Saves with
/// the same data layer as retell (`createImported` + one check-in per photo).
class ImportFlowScreen extends ConsumerStatefulWidget {
  const ImportFlowScreen({super.key});

  @override
  ConsumerState<ImportFlowScreen> createState() => _ImportFlowScreenState();
}

class _ImportFlowScreenState extends ConsumerState<ImportFlowScreen> {
  final List<_Photo> _photos = [];
  final _place = TextEditingController();
  final String _clientId = const Uuid().v4();
  _Stage _stage = _Stage.setup;
  String _type = 'trip';
  String _skin = 'memory';
  LocalDate? _start;
  LocalDate? _end;
  bool _datesTouched = false;
  bool _continues = false;
  bool _picking = false;
  bool _submitted = false;
  bool _busy = false;
  int _done = 0;
  int _failed = 0;
  String? _saveError;
  Journey? _created;

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  /// Today on the device's wall clock (bug C-B12: not the UTC date).
  LocalDate _today() => journeyLocalDate(
    ref.read(deviceTimezoneProvider).value ?? 'UTC',
    ref.read(journeysClockProvider).now(),
  );

  /// The device zone, waiting for the platform answer (bug C-B12).
  Future<String> _timezone() async {
    try {
      return await ref.read(deviceTimezoneProvider.future);
    } on Object {
      return 'UTC';
    }
  }

  List<String> get _layouts => [
    'memory',
    'minimal',
    if (_type == 'weight') 'quiet',
    if (_type == 'workout') 'flexer',
  ];

  /// The picker's short id as the persona skin the server stores (C-B11).
  PersonaSkinId _skinId(String id) => switch (id) {
    'quiet' => PersonaSkinId.quietTransformer,
    'flexer' => PersonaSkinId.aestheticFlexer,
    'minimal' => PersonaSkinId.minimalistHabit,
    _ => PersonaSkinId.memoryCollectors,
  };

  Iterable<_Photo> get _chosen => _photos.where((p) => p.selected);
  List<_Photo> get _dated =>
      _chosen.where((p) => p.date != null).toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));
  List<_Photo> get _undated => _chosen.where((p) => p.date == null).toList();

  void _syncDates() {
    if (_datesTouched) return;
    final d = _dated;
    if (d.isEmpty) return;
    _start = d.first.date;
    _end = d.last.date;
  }

  int _dayOf(LocalDate date) => (_start!.daysUntil(date) + 1).clamp(1, 100000);

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ref.read(retellPhotoPickerProvider).pickPhotos();
      if (!mounted) return;
      setState(() {
        for (final p in picked) {
          final m = p.modified.toLocal();
          _photos.add(
            _Photo(
              p.path,
              m.year < _minRealYear ? null : LocalDate(m.year, m.month, m.day),
            ),
          );
        }
        _syncDates();
      });
    } on Object {
      if (mounted) {
        final l10n = ImportL10n.of(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.import_pickFailed)));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<LocalDate?> _askDate(LocalDate initial) async {
    final today = _today();
    final last = DateTime(today.year, today.month, today.day);
    final cur = DateTime(initial.year, initial.month, initial.day);
    final c = await showDatePicker(
      context: context,
      initialDate: cur.isAfter(last) ? last : cur,
      firstDate: DateTime(2000),
      lastDate: last,
    );
    return c == null ? null : LocalDate(c.year, c.month, c.day);
  }

  String? _error(ImportL10n l10n) {
    if (_place.text.trim().isEmpty ||
        validateJourneyTitle(_place.text) != null) {
      return l10n.import_errorTitle;
    }
    if (_undated.isNotEmpty) return l10n.import_errorUndated;
    final dated = _dated;
    if (dated.isEmpty || _start == null || _end == null) {
      return l10n.import_errorNoPhotos;
    }
    if (_end!.isAfter(_today())) return l10n.import_errorFuture;
    if (dated.first.date!.isBefore(_start!) ||
        dated.last.date!.isAfter(_end!)) {
      return l10n.import_errorOutside;
    }
    if (_start!.daysUntil(_end!) + 1 > importMaxDays) {
      return l10n.import_errorRange;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = ImportL10n.of(context);
    setState(() {
      _submitted = true;
      _saveError = null;
    });
    if (_error(l10n) != null || _busy) return;
    setState(() {
      _busy = true;
      _failed = 0;
    });
    final timezone = await _timezone();
    if (!mounted) return;
    try {
      final type = _types.firstWhere((t) => t.id == _type);
      final fresh = _created == null;
      final journey = _created ??= await ref
          .read(sharingRepositoryProvider)
          .createImported(
            ImportedJourneyDraft(
              id: _clientId,
              title: _place.text.trim(),
              // The couple heart is what marks a custom journey as a
              // couple one (bug C-B11).
              emoji: type.id == 'couple'
                  ? '💞'
                  : templateFor(type.template).emoji,
              templateId: type.template,
              firstDate: _start!,
              lastDate: _end!,
              timezone: timezone,
              layout: _skinId(_skin),
              continues: _continues,
            ),
          );
      if (fresh) unawaited(pushSharePrivacyToJourney(ref, journey.id));
      final compressor = ref.read(photoCompressorProvider);
      final checkIns = ref.read(checkInRepositoryProvider);
      final drafts = ref.read(draftFilesProvider);
      for (final photo in _dated) {
        if (photo.saved) continue;
        try {
          final files = await compressor.compress(photo.path);
          await checkIns.submit(
            CheckInDraft(
              journeyId: journey.id,
              capturedAt: noonInZone(
                photo.date!,
                journey.timezone,
                now: ref.read(journeysClockProvider).now(),
              ),
              photoFile: files.photoFile,
              thumbFile: files.thumbFile,
              fromLibrary: true,
            ),
          );
          await drafts.discard([files.photoFile, files.thumbFile]);
          photo.saved = true;
          if (mounted) setState(() => _done++);
        } on Object {
          if (mounted) setState(() => _failed++);
        }
      }
      if (!mounted) return;
      // A journey that is still going gets its reminders planned (C-B11).
      if (journey.status == JourneyStatus.active) {
        unawaited(ref.read(reminderSchedulerProvider).reschedule());
      }
      if (_failed == 0) {
        context.go(AppRoutes.journey(journey.id));
      } else {
        setState(() => _busy = false);
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _saveError = l10n.import_errorGeneric;
      });
    }
  }

  void _back() {
    switch (_stage) {
      case _Stage.setup:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.journeys);
        }
      case _Stage.library:
        setState(() => _stage = _Stage.setup);
      case _Stage.review:
        setState(() => _stage = _Stage.library);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    // Keeps the zone loading and rebuilds once it is known (bug C-B12).
    ref.watch(deviceTimezoneProvider);
    if (ref.watch(appConfigProvider).localOnly) {
      final app = AppLocalizations.of(context);
      return UiScaffold(
        scroll: false,
        child: Column(
          children: [
            _Header(title: l10n.import_headerTitle, onBack: _back),
            Expanded(
              child: UiEmptyState(
                key: const ValueKey('needs-server'),
                glyph: const OurneyIcon(name: 'cloud-off', flat: true),
                title: app.needsServer_title,
                body: app.needsServer_message,
              ),
            ),
          ],
        ),
      );
    }
    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);

    final Widget body;
    Widget? action;
    switch (_stage) {
      case _Stage.setup:
        body = _setup(l10n, ui);
        action = UiButton(
          key: const ValueKey('import-next'),
          label: l10n.import_pickOld,
          onPressed: () => setState(() => _stage = _Stage.library),
        );
      case _Stage.library:
        body = _library(l10n, ui);
        final n = _chosen.length;
        action = UiButton(
          key: const ValueKey('import-review'),
          label: l10n.import_reviewButton(n),
          onPressed: n == 0
              ? null
              : () => setState(() {
                  _syncDates();
                  _stage = _Stage.review;
                }),
        );
      case _Stage.review:
        body = _review(l10n, ui);
        action = _saveBar(l10n, ui);
    }

    return PopScope(
      canPop: !_busy,
      child: UiScaffold(
        scroll: false,
        gutter: false,
        padTop: 0,
        padBottom: 0,
        bottom: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            UiSpace.sm,
            gutter,
            UiSpace.lg,
          ),
          child: action,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter - 4),
              child: _Header(
                title: l10n.import_headerTitle,
                onBack: _busy ? null : _back,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  UiSpace.lg,
                  gutter,
                  UiSpace.lg,
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _h1(String s, OurneyUi ui) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Semantics(
      header: true,
      child: Text(s, style: UiText.h2(size: 25, color: ui.ink)),
    ),
  );

  Widget _h2(String s, OurneyUi ui) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 9),
    child: Semantics(
      header: true,
      child: Text(
        s.toUpperCase(),
        style: UiText.body(
          size: 13,
          weight: FontWeight.w800,
          height: 1.4,
          color: ui.ink,
        ),
      ),
    ),
  );

  String _typeLabel(ImportL10n l10n, String id) => switch (id) {
    'weight' => l10n.import_type_weight,
    'study' => l10n.import_type_study,
    'trip' => l10n.import_type_trip,
    'couple' => l10n.import_type_couple,
    'workout' => l10n.import_type_workout,
    _ => l10n.import_type_custom,
  };

  String _layoutLabel(ImportL10n l10n, String id) => switch (id) {
    'quiet' => l10n.import_layout_quiet,
    'memory' => l10n.import_layout_memory,
    'flexer' => l10n.import_layout_flexer,
    _ => l10n.import_layout_minimal,
  };

  // --- screen 1: type + layout -------------------------------------------

  Widget _setup(ImportL10n l10n, OurneyUi ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _h1(l10n.import_setupTitle, ui),
        _TwoColumn(
          children: [
            for (final t in _types)
              _TypeButton(
                key: ValueKey('import-type-${t.id}'),
                id: t.id,
                label: _typeLabel(l10n, t.id),
                selected: _type == t.id,
                onPressed: () => setState(() {
                  _type = t.id;
                  if (!_layouts.contains(_skin)) _skin = 'memory';
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        UiTextField(
          label: l10n.import_placeLabel,
          fieldKey: const ValueKey('import-place'),
          controller: _place,
          hint: l10n.import_placeHint,
          onChanged: (_) => setState(() {}),
        ),
        _h2(l10n.import_layoutHeading, ui),
        _TwoColumn(
          children: [
            for (final id in _layouts)
              _LayoutButton(
                key: ValueKey('import-layout-$id'),
                label: _layoutLabel(l10n, id),
                selected: _skin == id,
                onPressed: () => setState(() => _skin = id),
                preview: ImportLayoutPreview(
                  skin: id,
                  previewLabel: l10n.import_previewLabel,
                  hudLabel: l10n.import_previewHud,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.import_layoutNote,
          style: UiText.body(size: 11, height: 1.4, color: ui.inkMuted),
        ),
      ],
    );
  }

  // --- screen 2: library -------------------------------------------------

  Widget _library(ImportL10n l10n, OurneyUi ui) {
    final locale = Localizations.localeOf(context).toString();
    String label(_Photo p) => p.date == null
        ? l10n.import_noDate
        : DateFormat.yMMMd(locale)
              .format(DateTime(p.date!.year, p.date!.month, p.date!.day));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _h1(l10n.import_libraryTitle, ui),
        Text(
          l10n.import_libraryIntro,
          style: UiText.muted(color: ui.inkMuted, size: 13),
        ),
        const SizedBox(height: 14),
        if (_picking && _photos.isEmpty)
          _TwoColumn(
            children: [
              for (var i = 0; i < 4; i++)
                const UiSkeleton(height: 140, radius: 12),
            ],
          )
        else if (_photos.isEmpty)
          UiEmptyState(
            key: const ValueKey('import-empty'),
            glyph: const OurneyIcon(name: 'image-plus', flat: true),
            title: l10n.import_libraryEmptyTitle,
            body: l10n.import_libraryEmptyBody,
            actionLabel: l10n.import_openLibrary,
            actionKey: const ValueKey('import-pick'),
            onAction: _pick,
          )
        else ...[
          _TwoColumn(
            children: [
              for (var i = 0; i < _photos.length; i++)
                _PhotoTile(
                  key: ValueKey('import-photo-$i'),
                  photo: _photos[i],
                  index: i,
                  dateLabel: label(_photos[i]),
                  semantic: _photos[i].selected
                      ? l10n.import_deselectPhoto(label(_photos[i]))
                      : l10n.import_selectPhoto(label(_photos[i])),
                  onPressed: () => setState(() {
                    _photos[i].selected = !_photos[i].selected;
                    _syncDates();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          UiButton.secondary(
            key: const ValueKey('import-pick'),
            label: l10n.import_addMore,
            glyph: const OurneyIcon(name: 'image-plus', size: 20, flat: true),
            loading: _picking,
            onPressed: _pick,
          ),
        ],
      ],
    );
  }

  // --- screen 3: review ---------------------------------------------------

  Widget _review(ImportL10n l10n, OurneyUi ui) {
    final locale = Localizations.localeOf(context).toString();
    String fmt(LocalDate d) =>
        DateFormat.yMMMd(locale).format(DateTime(d.year, d.month, d.day));
    final dated = _dated;
    final undated = _undated;
    final error = _submitted ? _error(l10n) : null;
    final rows = <Widget>[];
    if (_start != null && _end != null && !_end!.isBefore(_start!)) {
      final days = (_start!.daysUntil(_end!) + 1).clamp(1, importMaxDays);
      for (var day = 1; day <= days; day++) {
        final photos = [
          for (final p in dated)
            if (_dayOf(p.date!) == day) p,
        ];
        if (photos.isEmpty) {
          rows.add(
            _TimelineRow(
              key: ValueKey('import-day-$day'),
              empty: true,
              title: l10n.import_dayLabel(day),
              subtitle: l10n.import_noPhotos,
              thumb: null,
            ),
          );
          continue;
        }
        for (var i = 0; i < photos.length; i++) {
          rows.add(
            _TimelineRow(
              key: ValueKey('import-day-$day-$i'),
              empty: false,
              title: l10n.import_dayLabel(day),
              subtitle: l10n.import_fromLibrary(fmt(photos[i].date!)),
              extra: i > 0 ? l10n.import_extraInDay : null,
              thumb: ImportThumb(
                path: photos[i].path,
                index: _photos.indexOf(photos[i]),
                height: 76,
              ),
            ),
          );
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _h1(l10n.import_reviewTitle, ui),
        for (final r in rows) ...[r, const SizedBox(height: 10)],
        if (undated.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DashedBox(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.import_undatedTitle.toUpperCase(),
                    style: UiText.body(
                      size: 13,
                      weight: FontWeight.w800,
                      height: 1.4,
                      color: ui.ink,
                    ),
                  ),
                  for (final p in undated)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 68,
                            child: ImportThumb(
                              path: p.path,
                              index: 4,
                              height: 62,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateField(
                              key: ValueKey(
                                'import-assign-${_photos.indexOf(p)}',
                              ),
                              label: l10n.import_assignDate,
                              value: null,
                              hint: l10n.import_noDate,
                              onPressed: () async {
                                final d = await _askDate(_today());
                                if (d == null || !mounted) return;
                                setState(() {
                                  p.date = d;
                                  _syncDates();
                                });
                              },
                            ),
                          ),
                          UiTextAction(
                            label: l10n.import_drop,
                            color: ui.danger,
                            onPressed: () => setState(() {
                              p.selected = false;
                              _syncDates();
                            }),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DateField(
                key: const ValueKey('import-start'),
                label: l10n.import_startLabel,
                value: _start == null ? null : fmt(_start!),
                onPressed: () async {
                  final d = await _askDate(_start ?? _today());
                  if (d == null || !mounted) return;
                  setState(() {
                    _start = d;
                    _datesTouched = true;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateField(
                key: const ValueKey('import-end'),
                label: l10n.import_endLabel,
                value: _end == null ? null : fmt(_end!),
                onPressed: () async {
                  final d = await _askDate(_end ?? _today());
                  if (d == null || !mounted) return;
                  setState(() {
                    _end = d;
                    _datesTouched = true;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        UiCard(
          padding: const EdgeInsets.all(11),
          radius: UiRadius.input,
          shadowOffset: 0,
          child: UiSwitchRow(
            key: const ValueKey('import-continue'),
            label: l10n.import_continueTitle,
            subtitle: l10n.import_continueBody,
            value: _continues,
            divider: false,
            onChanged: (v) => setState(() => _continues = v),
          ),
        ),
        if (_type == 'weight')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OurneyIcon(name: 'lock', size: 15, flat: true, color: ui.ink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.import_privateNote,
                    style: UiText.body(size: 12, height: 1.4, color: ui.ink),
                  ),
                ),
              ],
            ),
          ),
        if (error != null || _saveError != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: KeyedSubtree(
              key: const ValueKey('import-error'),
              child: UiInlineError(message: (error ?? _saveError)!),
            ),
          ),
      ],
    );
  }

  Widget _saveBar(ImportL10n l10n, OurneyUi ui) {
    if (_busy) {
      final total = _dated.length;
      return Column(
        key: const ValueKey('import-progress'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.import_saving(_done, total),
            style: UiText.body(
              size: 13,
              weight: FontWeight.w700,
              color: ui.ink,
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          UiProgressBar(
            value: total == 0 ? 0 : _done / total,
            semanticLabel: l10n.import_saving(_done, total),
          ),
        ],
      );
    }
    if (_failed > 0 && _created != null) {
      return Column(
        key: const ValueKey('import-failed'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.import_failed(_failed),
            style: UiText.body(
              size: 13,
              weight: FontWeight.w700,
              color: ui.danger,
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton(
            key: const ValueKey('import-retry'),
            label: l10n.import_retry,
            onPressed: _save,
          ),
          UiButton.ghost(
            key: const ValueKey('import-open'),
            label: l10n.import_openJourney,
            onPressed: () => context.go(AppRoutes.journey(_created!.id)),
          ),
        ],
      );
    }
    return UiButton(
      key: const ValueKey('import-save'),
      label: l10n.import_save,
      onPressed: (_dated.isEmpty || _undated.isNotEmpty) ? null : _save,
    );
  }
}

/// `.pushed-header`: 44dp back, centered 13dp bold title.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

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

/// Two equal columns that wrap (`repeat(2, 1fr)`), rows as tall as content.
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.children});

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

class _TypeButton extends StatelessWidget {
  const _TypeButton({
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
    final fg = selected ? importInkOnLight : ui.ink;
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
          color: selected ? importSelectedYellow : ui.surface,
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

class _LayoutButton extends StatelessWidget {
  const _LayoutButton({
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

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.index,
    required this.dateLabel,
    required this.semantic,
    required this.onPressed,
    super.key,
  });

  final _Photo photo;
  final int index;
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
            color: on ? const Color(0xFFFF8A3D) : ui.ink.withValues(alpha: 0.2),
            width: UiBorder.standard,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImportThumb(path: photo.path, index: index),
                if (on)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: importCheckGreen,
                      ),
                      child: const OurneyIcon(
                        name: 'check',
                        size: 15,
                        flat: true,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
              child: Text(
                dateLabel,
                maxLines: 2,
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.empty,
    required this.title,
    required this.subtitle,
    required this.thumb,
    this.extra,
    super.key,
  });

  final bool empty;
  final String title;
  final String subtitle;
  final String? extra;
  final Widget? thumb;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final content = Row(
      children: [
        SizedBox(
          width: 86,
          child:
              thumb ??
              DashedBox(
                radius: 8,
                child: const SizedBox(height: 48, width: double.infinity),
              ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w800,
                  height: 1.35,
                  color: ui.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: UiText.body(size: 11, height: 1.4, color: ui.ink),
              ),
              if (extra != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A3D).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(UiRadius.capsule),
                  ),
                  child: Text(
                    extra!,
                    style: UiText.body(size: 11, height: 1.3, color: ui.ink),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return DashedBox(
      opacity: empty ? 0.64 : 1,
      padding: const EdgeInsets.all(9),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: empty ? 48 : 76),
        child: Align(alignment: Alignment.centerLeft, child: content),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPressed,
    this.hint,
    super.key,
  });

  final String label;
  final String? value;
  final String? hint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: UiText.body(
            size: 12,
            weight: FontWeight.w700,
            height: 1.4,
            color: ui.ink,
          ),
        ),
        const SizedBox(height: 5),
        UiPressable(
          onPressed: onPressed,
          semanticLabel: '$label, ${value ?? hint ?? ''}',
          excludeChildSemantics: true,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: ui.surface,
              borderRadius: BorderRadius.circular(8),
              border: ui.stickerBorder(),
            ),
            child: Row(
              children: [
                OurneyIcon(
                  name: 'calendar',
                  size: 16,
                  flat: true,
                  color: ui.ink,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value ?? hint ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 13,
                      height: 1.3,
                      color: value == null ? ui.inkMuted : ui.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
