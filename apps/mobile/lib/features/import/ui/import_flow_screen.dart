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
import '../../auth/l10n/generated/auth_localizations.dart';
import '../../checkin/photo_compressor.dart';
import '../../journeys/data/journeys_providers.dart';
import '../data/import_draft.dart';
import '../data/import_files.dart';
import '../data/import_job.dart';
import '../data/import_job_runner.dart';
import '../data/import_job_store.dart';
import '../data/import_photo_picker.dart';
import '../data/import_providers.dart';
import '../data/import_types.dart';
import '../data/photo_dates.dart';
import '../l10n/generated/import_localizations.dart';
import 'import_date_sheet.dart';
import 'import_parts.dart';
import 'import_widgets.dart';

enum _Stage { photos, timeline, details, job }

/// `/import` (also `/retell`): the one flow that retells a past journey from
/// old photos. Steps: photos, timeline check, details, then a durable saving
/// job (see [ImportJobRunner]) that survives the app being killed.
class ImportFlowScreen extends ConsumerStatefulWidget {
  const ImportFlowScreen({super.key});

  @override
  ConsumerState<ImportFlowScreen> createState() => _ImportFlowScreenState();
}

class _ImportFlowScreenState extends ConsumerState<ImportFlowScreen> {
  final List<DraftPhoto> _photos = [];
  final List<DraftPhoto> _removedPhotos = [];
  final _title = TextEditingController();
  _Stage _stage = _Stage.photos;
  String _typeId = 'trip';
  String _layout = 'memory';
  bool _continues = false;
  bool _titleTouched = false;
  bool _loading = true;
  bool _picking = false;
  bool _selecting = false;
  final Set<String> _bulk = {};
  String? _jobId;
  bool _saving = false;
  bool _cancelling = false;

  /// Set by "Edit details" after a failed create: the next Save reuses this
  /// id, so a create that did reach the server is deduplicated, not doubled.
  String? _reuseJobId;

  /// Kept copies of the originals that "Edit details" put back in the list.
  /// They belong to the job folder, not to the picker.
  final Set<String> _keptPaths = {};
  ImportJobRunner? _runner;
  ImportFiles? _files;
  DraftFiles? _drafts;
  ImportJobStore? _store;

  @override
  void initState() {
    super.initState();
    final runner = ref.read(importJobRunnerProvider);
    runner.active.addListener(_onActive);
    _runner = runner;
    // Read here: a ref cannot be used in dispose.
    _files = ref.read(importFilesProvider);
    _drafts = ref.read(draftFilesProvider);
    _store = ref.read(importJobStoreProvider);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _runner?.active.removeListener(_onActive);
    _title.dispose();
    _tidyOnClose();
    super.dispose();
  }

  /// The flow is closing: drop what nothing holds any more. A job keeps its
  /// own copies, so the picker's temp originals can go; copies left by "Edit
  /// details" go when no job was saved from them.
  void _tidyOnClose() {
    final files = _files;
    final drafts = _drafts;
    if (files == null || drafts == null) return;
    // A Save is storing the job right now: tidying would race it.
    if (_saving) return;
    try {
      if (_jobId == null && _reuseJobId != null) {
        _runner?.release(_reuseJobId!);
        unawaited(files.deleteJob(_reuseJobId!));
      }
      // Every picked path the stored job does not reference goes: photos
      // deselected in step 1, and all of them when the job was dropped (a
      // foreign or row-less job). A path a job row still uses (a file not
      // moved yet, or a moved copy) is never deleted.
      final jobId = _jobId;
      final store = _store;
      final paths = [
        for (final p in [..._photos, ..._removedPhotos])
          if (!_keptPaths.contains(p.path) || jobId == null) p.path,
      ];
      unawaited(() async {
        final used = <String>{};
        if (jobId != null && store != null) {
          final job = await store.get(jobId);
          if (job != null) {
            for (final p in job.photos) {
              used.addAll([?p.sourcePath, ?p.photoFile, ?p.thumbFile]);
            }
          }
        }
        await drafts.discard([
          for (final path in paths)
            if (!used.contains(path)) path,
        ]);
      }());
    } on Object catch (e) {
      debugPrint('import: tidy failed: $e');
    }
  }

  void _onActive() {
    if (!mounted) return;
    setState(() {
      if (!_running) _cancelling = false;
    });
  }

  bool get _running => _jobId != null && (_runner?.isRunning(_jobId!) ?? false);

  /// Today on the device's wall clock; an empty zone is the device zone (never
  /// UTC, which would be a day off around midnight).
  LocalDate _today() => journeyLocalDate(
    ref.read(deviceTimezoneProvider).value ?? '',
    ref.read(journeysClockProvider).now(),
  );

  Future<String> _timezone() async {
    try {
      return await ref.read(deviceTimezoneProvider.future);
    } on Object {
      // The journey needs a real zone name (today's date never uses this).
      return 'UTC';
    }
  }

  Iterable<DraftPhoto> get _chosen => _photos.where((p) => p.selected);

  bool get _titleValid => validateJourneyTitle(_title.text) == null;

  String _fmt(LocalDate d) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(DateTime(d.year, d.month, d.day));
  }

  // --- start -------------------------------------------------------------

  /// A stored job (a kill, or failures kept on exit) comes back first; then
  /// photos Android held for us; then the picker opens at once.
  Future<void> _bootstrap() async {
    final localOnly = ref.read(appConfigProvider).localOnly;
    try {
      final store = ref.read(importJobStoreProvider);
      final me =
          ref.read(currentUserIdProvider) ?? (localOnly ? 'local' : null);
      for (final job in await store.unfinished()) {
        // Another account's leftover, a finished job, or one whose photos all
        // failed before a journey existed: nothing to show.
        final foreign = job.ownerId != me;
        final dead = job.phase == ImportPhase.preparing && job.pending == 0;
        if (foreign ||
            dead ||
            (job.phase == ImportPhase.done && job.complete)) {
          await _runner!.discard(job.id);
          continue;
        }
        if (!mounted) return;
        setState(() {
          _jobId = job.id;
          _stage = _Stage.job;
          _loading = false;
        });
        // A paused job waits for the person; a failed create shows its
        // reason first (Try again / Edit details), it is not hammered again.
        if (!job.paused &&
            job.createFailure == null &&
            (job.pending > 0 || job.phase == ImportPhase.creating)) {
          unawaited(_run(job.id));
        }
        return;
      }
    } on Object catch (e) {
      debugPrint('import: cannot read stored jobs: $e');
    }
    if (localOnly) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    List<ImportPhoto> lost = const [];
    try {
      lost = await ref.read(importPhotoPickerProvider).recoverLost();
    } on Object catch (e) {
      debugPrint('import: recoverLost failed: $e');
    }
    if (!mounted) return;
    setState(() {
      if (lost.isNotEmpty) _add(lost);
      _loading = false;
    });
    if (_photos.isEmpty) await _pick();
  }

  AddPhotosResult _add(List<ImportPhoto> picked) => addPickedPhotos(
    _photos,
    picked,
    now: ref.read(journeysClockProvider).now(),
    today: _today(),
  );

  // --- step 1 ------------------------------------------------------------

  Future<void> _pick() async {
    if (_picking) return;
    final remaining = importMaxPhotos - _photos.length;
    final l10n = ImportL10n.of(context);
    if (remaining <= 0) {
      showUiToast(context, l10n.import_maxReached(importMaxPhotos));
      return;
    }
    setState(() => _picking = true);
    try {
      final picked = await ref
          .read(importPhotoPickerProvider)
          .pickPhotos(limit: remaining);
      if (!mounted) return;
      late AddPhotosResult result;
      setState(() => result = _add(picked));
      if (result.overLimit > 0) {
        showUiToast(context, l10n.import_pickLimit(importMaxPhotos));
      } else if (result.duplicates > 0) {
        showUiToast(context, l10n.import_duplicatesSkipped(result.duplicates));
      }
    } on Object catch (e) {
      debugPrint('import: picker failed: $e');
      if (mounted) showUiToast(context, l10n.import_pickFailed);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // --- step 2 ------------------------------------------------------------

  Future<LocalDate?> _askDate(LocalDate? initial) async {
    final today = _today();
    return showImportDateSheet(
      context,
      initial: initial ?? today,
      first: const LocalDate(importMinYear, 1, 1),
      last: today,
    );
  }

  Future<void> _editDate(DraftPhoto photo) async {
    final d = await _askDate(photo.date);
    if (d == null || !mounted) return;
    setState(() => photo.setDate(d));
  }

  /// Sets one date on every photo of [targets].
  Future<void> _setDateFor(List<DraftPhoto> targets) async {
    if (targets.isEmpty) return;
    final d = await _askDate(targets.first.date);
    if (d == null || !mounted) return;
    setState(() {
      for (final p in targets) {
        p.setDate(d);
      }
      _bulk.clear();
      _selecting = false;
    });
  }

  void _remove(Iterable<DraftPhoto> gone) {
    final removed = gone.toList();
    if (removed.isEmpty) return;
    final ids = {for (final p in removed) p.id};
    final l10n = ImportL10n.of(context);
    setState(() {
      _photos.removeWhere((p) => ids.contains(p.id));
      _removedPhotos.addAll(removed);
      _bulk.removeAll(ids);
      if (_chosen.isEmpty) {
        _selecting = false;
        _stage = _Stage.photos;
      }
    });
    showUiToast(
      context,
      l10n.import_photoRemoved(removed.length),
      actionLabel: l10n.import_undo,
      onAction: () {
        if (!mounted) return;
        setState(() {
          _removedPhotos.removeWhere((p) => ids.contains(p.id));
          _photos
            ..addAll(removed)
            ..sort((a, b) => a.order.compareTo(b.order));
        });
      },
    );
  }

  // --- save --------------------------------------------------------------

  bool get _canSave => _titleValid && timelineIssue(_chosen) == null;

  Future<void> _save() async {
    setState(() => _titleTouched = true);
    // A second tap while the first is still storing the job would make a
    // second job (and a second journey).
    if (!_canSave || _running || _saving) return;
    setState(() => _saving = true);
    try {
      final owner =
          ref.read(currentUserIdProvider) ??
          (ref.read(appConfigProvider).localOnly ? 'local' : null);
      if (owner == null) throw const OurneyException(OurneyErrorCode.unknown);
      final tz = await _timezone();
      if (!mounted) return;
      final job = buildImportJob(
        id: _reuseJobId ?? const Uuid().v4(),
        ownerId: owner,
        title: _title.text,
        type: importTypes.firstWhere((t) => t.id == _typeId),
        layout: _layout,
        continues: _continues,
        timezone: tz,
        photos: _chosen,
        now: ref.read(journeysClockProvider).now(),
      );
      final stored = await _runner!.enqueue(job);
      if (!mounted) return;
      setState(() {
        _jobId = stored.id;
        _reuseJobId = null;
        _stage = _Stage.job;
      });
      unawaited(_run(stored.id));
    } on Object catch (e, st) {
      logImportError('cannot store the job', e, st);
      if (mounted) showUiToast(context, _errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Runs (or resumes) the job. What it ends with reaches the screen through
  /// the stored job, not through this call: a run started at launch looks the
  /// same.
  Future<void> _run(String id, {bool retry = false}) async {
    final runner = _runner!;
    final res = await (retry ? runner.retryFailed(id) : runner.run(id));
    if (!mounted) return;
    if (res.end == ImportRunEnd.discarded) {
      // The job no longer belongs to this account: nothing is left to show.
      _leave();
    }
  }

  /// A readable message for what the server or the network answered.
  String _errorMessage(Object e) {
    final l10n = ImportL10n.of(context);
    final app = AppLocalizations.of(context);
    return switch (e) {
      OurneyException(error: OurneyErrorCode.offline) => app.common_offline,
      OurneyException(
        error: OurneyErrorCode.invalid || OurneyErrorCode.invalidCapturedAt,
      ) =>
        l10n.import_errorInvalid,
      _ => app.common_errorGeneric,
    };
  }

  /// Pause: the job stops after the photo it is on and waits (the launch
  /// resume leaves it alone) until the person continues.
  Future<void> _pauseJob() async {
    final id = _jobId;
    if (id == null) return;
    setState(() => _cancelling = true);
    _runner!.cancel(id);
  }

  /// A failed create: back to the details with everything the person had, and
  /// the same journey id for the next Save.
  Future<void> _editDetails(ImportJob job) async {
    final reopened = await _runner!.reopen(job.id);
    if (reopened == null || !mounted) return;
    setState(() {
      _photos
        ..clear()
        ..addAll([
          for (final p in reopened.photos)
            DraftPhoto(
              id: p.id,
              path: p.sourcePath ?? '',
              dedupeKey: p.dedupeKey ?? 'job:${p.id}',
              order: p.position,
              date: p.date,
              secondsOfDay: p.secondsOfDay,
              offsetMinutes: p.offsetMinutes,
            ),
        ]);
      _keptPaths
        ..clear()
        ..addAll([for (final p in reopened.photos) ?p.sourcePath]);
      _title.text = reopened.title;
      _titleTouched = true;
      _typeId = importTypes
          .firstWhere(
            (t) => t.template == reopened.templateId,
            orElse: () => importTypes.firstWhere((t) => t.id == 'trip'),
          )
          .id;
      _layout = importLayoutOf(reopened.layout);
      _continues = reopened.continues;
      _reuseJobId = reopened.id;
      _jobId = null;
      _stage = _Stage.details;
    });
  }

  Future<void> _openJourney(ImportJob? job) async {
    final id = _jobId;
    if (id == null) return;
    // Everything saved: nothing is kept for a later retry.
    if (job != null && job.complete) await _runner!.discard(id);
    if (mounted) context.go(AppRoutes.journey(id));
  }

  /// A create that keeps failing: drop the job and its files, after asking.
  Future<void> _abandon(ImportJob job) async {
    final l10n = ImportL10n.of(context);
    final ok = await showUiConfirmSheet(
      context: context,
      title: l10n.import_abandonTitle,
      message: l10n.import_abandonBody,
      confirmLabel: l10n.import_abandonConfirm,
      cancelLabel: l10n.import_discardKeep,
      destructive: true,
      confirmKey: const ValueKey('import-abandon-confirm'),
    );
    if (!ok || !mounted) return;
    await _runner!.discard(job.id);
    if (mounted) _leave();
  }

  Future<void> _leaveRestOut(ImportJob job) async {
    final exists =
        job.phase == ImportPhase.uploading || job.phase == ImportPhase.done;
    await _runner!.discard(job.id);
    if (!mounted) return;
    if (exists) {
      context.go(AppRoutes.journey(job.id));
    } else {
      _leave();
    }
  }

  // --- navigation --------------------------------------------------------

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.journeys);
    }
  }

  Future<void> _onBack() async {
    switch (_stage) {
      case _Stage.photos:
        if (_photos.isEmpty) return _leave();
        final l10n = ImportL10n.of(context);
        final leave = await showUiConfirmSheet(
          context: context,
          title: l10n.import_discardTitle,
          message: l10n.import_discardBody,
          confirmLabel: l10n.import_discardConfirm,
          cancelLabel: l10n.import_discardKeep,
          destructive: true,
          confirmKey: const ValueKey('import-discard-confirm'),
        );
        if (leave && mounted) _leave();
      case _Stage.timeline:
        setState(() {
          _selecting = false;
          _bulk.clear();
          _stage = _Stage.photos;
        });
      case _Stage.details:
        setState(() => _stage = _Stage.timeline);
      case _Stage.job:
        // While it runs, Cancel is the way out; a stored job stays for later.
        if (!_running) _leave();
    }
  }

  // --- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    // Keeps the zone loading and rebuilds once it is known.
    ref.watch(deviceTimezoneProvider);
    if (ref.watch(appConfigProvider).localOnly && _stage != _Stage.job) {
      final app = AppLocalizations.of(context);
      return UiScaffold(
        scroll: false,
        child: Column(
          children: [
            ImportHeader(title: l10n.import_headerTitle, onBack: _leave),
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
    final job = _jobId == null
        ? null
        : ref.watch(importJobProvider(_jobId!)).value;

    final List<Widget> slivers;
    Widget? action;
    if (_loading) {
      slivers = [
        SliverToBoxAdapter(
          child: Column(
            key: const ValueKey('import-loading'),
            children: const [
              UiSkeleton(height: 140, radius: 12),
              SizedBox(height: 12),
              UiSkeleton(height: 140, radius: 12),
            ],
          ),
        ),
      ];
    } else {
      switch (_stage) {
        case _Stage.photos:
          slivers = _photosSlivers(l10n);
          final n = _chosen.length;
          action = UiButton(
            key: const ValueKey('import-next'),
            label: l10n.import_nextTimeline(n),
            onPressed: n == 0
                ? null
                : () => setState(() => _stage = _Stage.timeline),
          );
        case _Stage.timeline:
          slivers = _timelineSlivers(l10n);
          action = _timelineAction(l10n);
        case _Stage.details:
          slivers = _detailsSlivers(l10n);
          action = UiButton(
            key: const ValueKey('import-save'),
            label: l10n.import_save,
            loading: _saving,
            onPressed: _canSave && !_saving ? _save : null,
          );
        case _Stage.job:
          slivers = _jobSlivers(l10n, job);
          action = _jobAction(l10n, job);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBack());
      },
      child: UiScaffold(
        scroll: false,
        gutter: false,
        padTop: 0,
        padBottom: 0,
        bottom: action == null
            ? null
            : Padding(
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
              child: ImportHeader(
                title: l10n.import_headerTitle,
                onBack: _running ? null : _onBack,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      UiSpace.lg,
                      gutter,
                      UiSpace.lg,
                    ),
                    sliver: SliverMainAxisGroup(slivers: slivers),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- step 1: photos ----------------------------------------------------

  List<Widget> _photosSlivers(ImportL10n l10n) {
    final ui = context.ui;
    final chosen = _chosen.length;
    return [
      SliverToBoxAdapter(
        child: ImportHeading(title: l10n.import_photosTitle, step: 1),
      ),
      SliverToBoxAdapter(
        child: Text(
          l10n.import_photosIntro,
          style: UiText.muted(color: ui.inkMuted, size: 13),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (_photos.isEmpty)
        SliverToBoxAdapter(
          child: UiEmptyState(
            key: const ValueKey('import-empty'),
            glyph: const OurneyIcon(name: 'image-plus', flat: true),
            title: l10n.import_libraryEmptyTitle,
            body: l10n.import_libraryEmptyBody,
            actionLabel: l10n.import_openLibrary,
            actionKey: const ValueKey('import-pick'),
            onAction: _pick,
          ),
        )
      else ...[
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.import_selectedCount(chosen, _photos.length),
                key: const ValueKey('import-selected-count'),
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: ui.ink,
                ),
              ),
              Wrap(
                spacing: UiSpace.md,
                children: [
                  UiTextAction(
                    key: const ValueKey('import-select-all'),
                    label: l10n.import_selectAll,
                    onPressed: chosen == _photos.length
                        ? null
                        : () => setState(() {
                            for (final p in _photos) {
                              p.selected = true;
                            }
                          }),
                  ),
                  UiTextAction(
                    key: const ValueKey('import-select-none'),
                    label: l10n.import_selectNone,
                    onPressed: chosen == 0
                        ? null
                        : () => setState(() {
                            for (final p in _photos) {
                              p.selected = false;
                            }
                          }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          delegate: SliverChildBuilderDelegate((context, i) {
            final p = _photos[i];
            final label = p.date == null ? l10n.import_noDate : _fmt(p.date!);
            return ImportPhotoTile(
              key: ValueKey('import-photo-${p.order}'),
              photo: p,
              dateLabel: label,
              semantic: p.selected
                  ? l10n.import_deselectPhoto(label)
                  : l10n.import_selectPhoto(label),
              onPressed: () => setState(() => p.selected = !p.selected),
            );
          }, childCount: _photos.length),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: UiButton.secondary(
              key: const ValueKey('import-pick'),
              label: l10n.import_addMore,
              glyph: const OurneyIcon(name: 'image-plus', size: 20, flat: true),
              loading: _picking,
              onPressed: _photos.length >= importMaxPhotos ? null : _pick,
            ),
          ),
        ),
      ],
    ];
  }

  // --- step 2: timeline --------------------------------------------------

  Widget? _timelineAction(ImportL10n l10n) {
    if (_selecting) {
      final targets = _chosen.where((p) => _bulk.contains(p.id)).toList();
      return Column(
        key: const ValueKey('import-bulk-bar'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiButton(
            key: const ValueKey('import-bulk-date'),
            label: l10n.import_bulkSetDate(targets.length),
            onPressed: targets.isEmpty ? null : () => _setDateFor(targets),
          ),
          UiButton.ghost(
            key: const ValueKey('import-bulk-remove'),
            label: l10n.import_bulkRemove(targets.length),
            onPressed: targets.isEmpty ? null : () => _remove(targets),
          ),
        ],
      );
    }
    return UiButton(
      key: const ValueKey('import-to-details'),
      label: l10n.import_next,
      onPressed: timelineIssue(_chosen) == null
          ? () => setState(() => _stage = _Stage.details)
          : null,
    );
  }

  List<Widget> _timelineSlivers(ImportL10n l10n) {
    final ui = context.ui;
    final chosen = _chosen.toList();
    final rows = buildTimeline(chosen);
    final range = dateRangeOf(chosen);
    final issue = timelineIssue(chosen);
    final undated = chosen.where((p) => p.date == null).toList();
    return [
      SliverToBoxAdapter(
        child: ImportHeading(title: l10n.import_timelineTitle, step: 2),
      ),
      SliverToBoxAdapter(
        child: Text(
          l10n.import_timelineIntro,
          style: UiText.muted(color: ui.inkMuted, size: 13),
        ),
      ),
      if (range != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.import_rangeLine(
                range.first == range.last
                    ? _fmt(range.first)
                    : '${_fmt(range.first)} – ${_fmt(range.last)}',
                l10n.import_days(range.first.daysUntil(range.last) + 1),
              ),
              key: const ValueKey('import-range'),
              style: UiText.body(
                size: 13,
                weight: FontWeight.w700,
                height: 1.4,
                color: ui.ink,
              ),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.centerLeft,
          child: UiTextAction(
            key: const ValueKey('import-select-mode'),
            label: _selecting ? l10n.import_selectDone : l10n.import_selectMode,
            onPressed: () => setState(() {
              _selecting = !_selecting;
              _bulk.clear();
            }),
          ),
        ),
      ),
      if (issue == TimelineIssue.tooLong)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KeyedSubtree(
              key: const ValueKey('import-error'),
              child: UiInlineError(message: l10n.import_errorRange),
            ),
          ),
        ),
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, i) => _timelineRow(l10n, rows[i], undated),
      ),
    ];
  }

  Widget _timelineRow(
    ImportL10n l10n,
    TimelineRow row,
    List<DraftPhoto> undated,
  ) {
    final ui = context.ui;
    switch (row) {
      case UndatedHeaderRow(:final count):
        return Padding(
          key: const ValueKey('import-undated'),
          padding: const EdgeInsets.only(bottom: 10),
          child: DashedBox(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '${l10n.import_undatedTitle} · $count'.toUpperCase(),
                    style: UiText.body(
                      size: 13,
                      weight: FontWeight.w800,
                      height: 1.4,
                      color: ui.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.import_undatedBody,
                  style: UiText.body(size: 12, height: 1.4, color: ui.ink),
                ),
                const SizedBox(height: 6),
                UiButton.secondary(
                  key: const ValueKey('import-undated-all'),
                  label: l10n.import_setDateAllUndated,
                  glyph: const OurneyIcon(
                    name: 'calendar',
                    size: 18,
                    flat: true,
                  ),
                  onPressed: () => _setDateFor(undated),
                ),
              ],
            ),
          ),
        );
      case UndatedPhotoRow(:final photo):
        return ImportTimelineTile(
          key: ValueKey('import-row-${photo.order}'),
          photo: photo,
          dateLabel: l10n.import_noDate,
          undated: true,
          selecting: _selecting,
          selected: _bulk.contains(photo.id),
          onTap: () => _selecting ? _toggleBulk(photo) : _editDate(photo),
          onRemove: () => _remove([photo]),
        );
      case DayHeaderRow(:final day, :final date, :final count):
        return ImportDayHeader(
          key: ValueKey('import-day-$day'),
          day: day,
          dateLabel: _fmt(date),
          count: count,
        );
      case DayPhotoRow(:final photo):
        return ImportTimelineTile(
          key: ValueKey('import-row-${photo.order}'),
          photo: photo,
          dateLabel: _fmt(photo.date!),
          selecting: _selecting,
          selected: _bulk.contains(photo.id),
          onTap: () => _selecting ? _toggleBulk(photo) : _editDate(photo),
          onRemove: () => _remove([photo]),
        );
      case GapRow(:final firstDay, :final days):
        return ImportGapRow(key: ValueKey('import-gap-$firstDay'), days: days);
    }
  }

  void _toggleBulk(DraftPhoto p) => setState(() {
    if (!_bulk.add(p.id)) _bulk.remove(p.id);
  });

  // --- step 3: details ---------------------------------------------------

  List<Widget> _detailsSlivers(ImportL10n l10n) {
    final ui = context.ui;
    final range = dateRangeOf(_chosen);
    final titleError = _titleTouched && !_titleValid
        ? l10n.import_errorTitle
        : null;
    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImportHeading(title: l10n.import_detailsTitle, step: 3),
            if (range != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  l10n.import_summaryLine(
                    _chosen.length,
                    range.first == range.last
                        ? _fmt(range.first)
                        : '${_fmt(range.first)} – ${_fmt(range.last)}',
                  ),
                  style: UiText.muted(color: ui.inkMuted, size: 13),
                ),
              ),
            UiTextArea(
              label: l10n.import_nameLabel,
              fieldKey: const ValueKey('import-title'),
              controller: _title,
              hint: l10n.import_nameHint,
              maxLength: journeyTitleMax,
              onChanged: (_) => setState(() => _titleTouched = true),
            ),
            if (titleError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    titleError,
                    key: const ValueKey('import-title-error'),
                    style: UiText.body(
                      size: 12,
                      weight: FontWeight.w600,
                      height: 1.4,
                      color: ui.danger,
                    ),
                  ),
                ),
              ),
            ImportSectionLabel(l10n.import_typeHeading),
            ImportTwoColumn(
              children: [
                for (final t in importTypes)
                  ImportTypeButton(
                    key: ValueKey('import-type-${t.id}'),
                    id: t.id,
                    label: _typeLabel(l10n, t.id),
                    selected: _typeId == t.id,
                    onPressed: () => setState(() {
                      _typeId = t.id;
                      if (!importLayoutsFor(_typeId).contains(_layout)) {
                        _layout = 'memory';
                      }
                    }),
                  ),
              ],
            ),
            ImportSectionLabel(l10n.import_layoutHeading),
            ImportTwoColumn(
              children: [
                for (final id in importLayoutsFor(_typeId))
                  ImportLayoutButton(
                    key: ValueKey('import-layout-$id'),
                    label: _layoutLabel(l10n, id),
                    selected: _layout == id,
                    onPressed: () => setState(() => _layout = id),
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
            const SizedBox(height: 16),
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
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OurneyIcon(name: 'lock', size: 15, flat: true, color: ui.ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.import_privacyNote,
                      key: const ValueKey('import-privacy-note'),
                      style: UiText.body(size: 12, height: 1.4, color: ui.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  String _typeLabel(ImportL10n l10n, String id) => switch (id) {
    'weight' => l10n.import_type_weight,
    'study' => l10n.import_type_study,
    'trip' => l10n.import_type_trip,
    'workout' => l10n.import_type_workout,
    _ => l10n.import_type_custom,
  };

  String _layoutLabel(ImportL10n l10n, String id) => switch (id) {
    'quiet' => l10n.import_layout_quiet,
    'memory' => l10n.import_layout_memory,
    'flexer' => l10n.import_layout_flexer,
    _ => l10n.import_layout_minimal,
  };

  // --- step 4 / 5: saving and done ---------------------------------------

  /// A thumbnail for a job photo: the picked file of this session, else a
  /// file the stored job still holds. A saved photo's files are deleted, so
  /// it has none (the row shows a plain placeholder, not a broken image).
  String? _thumbOf(ImportJobPhoto p) {
    if (p.state == ImportPhotoState.saved) return null;
    return p.sourcePath ?? p.thumbFile;
  }

  /// A readable line for why creating the journey failed.
  String _createMessage(ImportFailure failure) {
    final l10n = ImportL10n.of(context);
    final app = AppLocalizations.of(context);
    return switch (failure) {
      ImportFailure.offline => app.common_offline,
      ImportFailure.invalid ||
      ImportFailure.badDate => l10n.import_errorInvalid,
      _ => app.common_errorGeneric,
    };
  }

  List<Widget> _jobSlivers(ImportL10n l10n, ImportJob? job) {
    final ui = context.ui;
    if (job == null) {
      return [
        const SliverToBoxAdapter(
          child: UiSkeleton(
            key: ValueKey('import-job-loading'),
            height: 90,
            radius: 12,
          ),
        ),
      ];
    }
    final running = _running;
    final total = job.photos.length;
    final unsaved = total - job.saved;
    final signedOut =
        !ref.watch(appConfigProvider).localOnly &&
        !running &&
        unsaved > 0 &&
        ref.watch(currentUserIdProvider) == null;
    final createFailure = running || signedOut ? null : job.createFailure;
    final paused = !running && !signedOut && job.paused && unsaved > 0;
    final String title;
    final String status;
    if (running) {
      title = l10n.import_savingTitle;
      status = switch (job.phase) {
        ImportPhase.preparing => l10n.import_preparing(
          job.photos.where((p) => p.prepared).length,
          total,
        ),
        ImportPhase.creating => l10n.import_creating,
        _ => l10n.import_saving(job.saved, total),
      };
    } else if (signedOut) {
      title = l10n.import_signedOutTitle;
      status = l10n.import_signedOutBody;
    } else if (createFailure != null) {
      title = l10n.import_savingTitle;
      status = _createMessage(createFailure);
    } else if (paused) {
      title = l10n.import_pausedTitle;
      status = l10n.import_pausedBody;
    } else {
      title = unsaved == 0 ? l10n.import_doneTitle : l10n.import_partialTitle;
      status = unsaved == 0
          ? l10n.import_savedSummary(job.saved)
          : '${l10n.import_savedSummary(job.saved)} · '
                '${l10n.import_notSaved(unsaved)}';
    }
    return [
      SliverToBoxAdapter(child: ImportHeading(title: title)),
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                key: const ValueKey('import-status'),
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color:
                      createFailure != null ||
                          (!running && !paused && unsaved > 0)
                      ? ui.danger
                      : ui.ink,
                ),
              ),
            ),
            if (paused && unsaved > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.import_notSaved(unsaved),
                  style: UiText.body(size: 13, height: 1.4, color: ui.inkMuted),
                ),
              ),
            const SizedBox(height: UiSpace.sm),
            UiProgressBar(
              key: const ValueKey('import-progress'),
              value: total == 0 ? 0 : job.saved / total,
              semanticLabel: status,
            ),
            if (running)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.import_pauseHint,
                  key: const ValueKey('import-pause-hint'),
                  style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
                ),
              ),
            const SizedBox(height: UiSpace.lg),
          ],
        ),
      ),
      SliverList.builder(
        itemCount: total,
        itemBuilder: (context, i) {
          final p = job.photos[i];
          return ImportJobPhotoRow(
            key: ValueKey('import-job-photo-${p.id}'),
            photo: p,
            dateLabel: _fmt(p.date),
            thumbPath: _thumbOf(p),
          );
        },
      ),
    ];
  }

  Widget? _jobAction(ImportL10n l10n, ImportJob? job) {
    if (job == null) return null;
    if (_running) {
      return UiButton.secondary(
        key: const ValueKey('import-pause'),
        label: _cancelling ? l10n.import_cancelling : l10n.import_pause,
        onPressed: _cancelling ? null : _pauseJob,
      );
    }
    final unsaved = job.photos.length - job.saved;
    final exists =
        job.phase == ImportPhase.uploading || job.phase == ImportPhase.done;
    // Signed out (an expired session): saving waits for the same person; the
    // job and its photos are kept. Offer a way back to sign in.
    if (!ref.watch(appConfigProvider).localOnly &&
        unsaved > 0 &&
        ref.watch(currentUserIdProvider) == null) {
      return UiButton(
        key: const ValueKey('import-sign-in'),
        label: AuthL10n.of(context).auth_signIn,
        onPressed: () => context.go(
          '${AppRoutes.auth}?${AppRoutes.fromParam}='
          '${Uri.encodeQueryComponent(AppRoutes.importJourney)}',
        ),
      );
    }
    if (job.createFailure != null) {
      // Only a refused create (nothing reached the server) can be edited. After
      // an offline or unknown failure the journey may already exist, and its
      // name, dates and skin can not change through a second create: the only
      // honest options are to try again or to leave and finish later.
      final refused = job.createFailure == ImportFailure.invalid;
      return Column(
        key: const ValueKey('import-create-failed'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!refused)
            Padding(
              padding: const EdgeInsets.only(bottom: UiSpace.sm),
              child: Text(
                l10n.import_createMaybeLanded,
                key: const ValueKey('import-maybe-landed'),
                style: UiText.body(
                  size: 12,
                  height: 1.4,
                  color: context.ui.inkMuted,
                ),
              ),
            ),
          UiButton(
            key: const ValueKey('import-retry'),
            label: l10n.import_tryAgain,
            onPressed: () => _run(job.id),
          ),
          if (refused)
            UiButton.ghost(
              key: const ValueKey('import-edit-details'),
              label: l10n.import_editDetails,
              onPressed: () => _editDetails(job),
            ),
          // A create that keeps failing must not be a dead end.
          UiButton.ghost(
            key: const ValueKey('import-abandon'),
            label: l10n.import_abandon,
            onPressed: () => _abandon(job),
          ),
        ],
      );
    }
    if (unsaved == 0) {
      return UiButton(
        key: const ValueKey('import-open'),
        label: l10n.import_openJourney,
        onPressed: () => _openJourney(job),
      );
    }
    final paused = job.paused;
    return Column(
      key: ValueKey(paused ? 'import-paused' : 'import-failed'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiButton(
          key: ValueKey(paused ? 'import-resume' : 'import-retry-failed'),
          label: paused ? l10n.import_resume : l10n.import_retryFailed,
          onPressed: () => _run(job.id, retry: !paused),
        ),
        if (exists && job.saved > 0)
          UiButton.secondary(
            key: const ValueKey('import-open'),
            label: l10n.import_openJourney,
            onPressed: () => _openJourney(job),
          ),
        UiButton.ghost(
          key: const ValueKey('import-leave-rest'),
          label: l10n.import_leaveRest,
          onPressed: () => _leaveRestOut(job),
        ),
      ],
    );
  }
}
