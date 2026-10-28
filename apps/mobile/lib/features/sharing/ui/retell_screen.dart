import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/ourney_primary_button.dart';
import '../../../shared/template_icons.dart';
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
    final c = OurneyColors.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final appBar = AppBar(
      centerTitle: true,
      title: SharingNavTitle(title: l10n.sharing_retellTitle),
    );
    if (localOnly) {
      return Scaffold(
        appBar: appBar,
        body: const SafeArea(child: NeedsServerView()),
      );
    }
    final error = _submitted ? _error(l10n) : null;
    final dates = [for (final p in _picks) p.date];
    final dupes = {
      for (final d in dates)
        if (dates.where((x) => x == d).length > 1) d,
    };

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 7),
      child: Semantics(
        header: true,
        child: Text(s, style: sharingLabel(context, size: 13)),
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
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _picks.isEmpty ? null : _done / _picks.length,
            color: c.primary,
            backgroundColor: c.surfaceSunken,
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
            style: sharingLabel(context, size: 13, color: c.danger),
          ),
          const SizedBox(height: 8),
          OurneyPrimaryButton(
            key: const ValueKey('retell-retry'),
            label: l10n.sharing_retry,
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            onPressed: _save,
          ),
          TextButton(
            key: const ValueKey('retell-open'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: c.ink,
            ),
            onPressed: () => context.go(AppRoutes.journey(_created!.id)),
            child: Text(l10n.sharing_openJourney),
          ),
        ],
      );
    } else {
      bottom = OurneyPrimaryButton(
        key: const ValueKey('retell-save'),
        label: l10n.sharing_saveToShelf,
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        onPressed: _save,
      );
    }

    return Scaffold(
      key: const ValueKey('retell'),
      appBar: appBar,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: bottom,
      ),
      body: SafeArea(
        top: false,
        child: AbsorbPointer(
          absorbing: _busy,
          child: SharingColumn(
            builder: (context, gutter) => ListView(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
              children: [
                Text(
                  l10n.sharing_retellIntro,
                  style: sharingBody(context, color: c.inkMuted),
                ),
                label(l10n.sharing_journeyName),
                TextField(
                  key: const ValueKey('retell-title'),
                  controller: _title,
                  maxLength: journeyTitleMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.sharing_journeyName,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                label(l10n.sharing_style),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in allTemplates)
                      _StyleChip(
                        template: t,
                        selected: t.id == _template,
                        onTap: () => setState(() => _template = t.id),
                      ),
                  ],
                ),
                label(l10n.sharing_metricOptional),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        key: const ValueKey('retell-metric-name'),
                        controller: _metricName,
                        decoration: InputDecoration(
                          labelText: l10n.sharing_metricName,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        key: const ValueKey('retell-metric-unit'),
                        controller: _metricUnit,
                        decoration: InputDecoration(
                          labelText: l10n.sharing_metricUnit,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _picks.isEmpty
                            ? l10n.sharing_pickPhotos
                            : l10n.sharing_photosCount(_picks.length),
                        style: headingStyle(size: 17),
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
                    style: sharingBody(context, size: 13, color: c.inkMuted),
                  ),
                  Text(
                    l10n.sharing_photosHint,
                    style: sharingBody(context, size: 12, color: c.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.72,
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
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.sharing_sameDay,
                        style: sharingBody(context, size: 12, color: c.warning),
                      ),
                    ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      error,
                      key: const ValueKey('retell-error'),
                      style: sharingLabel(context, size: 13, color: c.danger),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final JourneyTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final style = OurneyPersonaTheme.forSkin(
      template.personaSkinId,
      Theme.of(context).brightness,
    );
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.surfaceRaised : c.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? c.ink : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('retell-style-${template.id.wireName}'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: style.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(templateIcon(template.id), size: 16, color: c.ink),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      vi ? template.titleVi : template.titleEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sharingLabel(context, size: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    final c = OurneyColors.of(context);
    final date = formatLocalDate(context, pick.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
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
                  child: Icon(Icons.check_circle_rounded, color: c.success),
                ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  key: ValueKey('retell-remove-$index'),
                  tooltip: l10n.sharing_removePhoto,
                  onPressed: onRemove,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: c.bg.withValues(alpha: 0.8),
                    foregroundColor: c.ink,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: l10n.sharing_changeDate(date),
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('retell-date-$index'),
            onTap: onDate,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Icon(
                    duplicate
                        ? Icons.warning_amber_rounded
                        : Icons.event_rounded,
                    size: 14,
                    color: duplicate ? c.warning : c.inkMuted,
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
