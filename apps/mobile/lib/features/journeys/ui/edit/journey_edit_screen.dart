import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../personas/persona_contract.dart';
import '../../../../ui/ui.dart';
import '../../../groups/data/groups_providers.dart';
import '../../../reminders/data/reminder_scheduler.dart';
import '../../../reminders/data/reminder_settings.dart';
import '../../../reminders/domain/reminder_plan.dart';
import '../../../reminders/ui/reminder_permission_prompt.dart';
import '../../data/journeys_providers.dart';
import '../../domain/journey_layouts.dart';
import '../../journeys_paths.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_actions.dart';
import '../journey_errors.dart';
import 'layout_preview.dart';
import 'skin_names.dart';
import 'time_wheel.dart';

/// `/journey/:id/edit`, Figma `JourneyEditScreen` ("cập nhật hành trình."):
/// name, cover, layout ("Giao diện"), colour, per-skin fields, reminder time
/// wheel, visibility and the end button. Owner only; everyone else sees the
/// current layout read-only.
class JourneyEditScreen extends ConsumerWidget {
  const JourneyEditScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final journeyAsync = ref.watch(journeyByIdProvider(journeyId));
    final journey = journeyAsync.value;
    if (journey == null) {
      void back() {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.journeys);
        }
      }

      return UiScaffold(
        key: const ValueKey('journey-edit-empty'),
        padTop: 0,
        child: Column(
          children: [
            UiBackHeader(
              onBack: back,
              backLabel: l10n.journeys_back,
            ),
            if (journeyAsync.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(
                    key: const ValueKey('journey-edit-loading'),
                    semanticsLabel: app.common_loading,
                  ),
                ),
              )
            else
              UiEmptyState(
                key: ValueKey(
                  journeyAsync.hasError
                      ? 'journey-edit-error'
                      : 'journey-edit-not-found',
                ),
                glyph: OurneyIcon(
                  name: journeyAsync.hasError ? 'error' : 'search',
                  size: 40,
                ),
                title: journeyAsync.hasError
                    ? journeyErrorMessage(context, journeyAsync.error!)
                    : l10n.journeys_errorNotFound,
                actionLabel: journeyAsync.hasError
                    ? app.common_retry
                    : l10n.journeys_title,
                onAction: journeyAsync.hasError
                    ? () => ref.invalidate(journeyByIdProvider(journeyId))
                    : () => context.go(AppRoutes.journeys),
              ),
          ],
        ),
      );
    }
    final membership = ref.watch(myMembershipProvider(journeyId)).value;
    final perms = JourneyPermissions(
      journey: journey,
      membership: membership,
      currentUserId: ref.watch(currentUserIdProvider),
    );
    return _EditBody(journey: journey, perms: perms);
  }
}

void _leave(BuildContext context, String id) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(JourneysPaths.home(id));
  }
}

class _EditBody extends ConsumerStatefulWidget {
  const _EditBody({required this.journey, required this.perms});

  final Journey journey;
  final JourneyPermissions perms;

  @override
  ConsumerState<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends ConsumerState<_EditBody> {
  late final _name = TextEditingController(text: widget.journey.title);
  late final _trophy = TextEditingController(
    text: (widget.journey.dna?['trophy'] as String?) ?? '',
  );
  late final _self = TextEditingController(
    text: widget.journey.coupleSelfName ?? '',
  );
  late final _partner = TextEditingController(
    text: widget.journey.couplePartnerName ?? '',
  );
  late PersonaSkinId _layout = personaSkinOf(widget.journey);
  late int _color = widget.journey.color ?? 0;
  late bool _link = widget.journey.visibility == JourneyVisibility.link;

  /// The reminder setting when the screen opened. `reminderSettingsProvider`
  /// wins over `j.reminderTime` when the user already adjusted the reminder in
  /// `/reminders` so opening Edit never clobbers their toggle/time (UX-18).
  late final ReminderSetting _initialReminder = _readInitialReminder();
  late bool _reminderEnabled = _initialReminder.enabled;
  late ReminderTime _time = _initialReminder.time;
  bool _busy = false;

  /// Saved or ended: leaving needs no "discard changes?" question.
  bool _saved = false;

  Journey get j => widget.journey;
  bool get _owner => widget.perms.isOwner && widget.perms.isActive;

  ReminderSetting _readInitialReminder() {
    final map = ref.read(reminderSettingsProvider);
    final existing = map[j.id];
    if (existing != null) return existing;
    final saved = ReminderTime.tryParse(j.reminderTime);
    if (saved != null) return ReminderSetting(enabled: true, time: saved);
    return ReminderSetting.off;
  }

  @override
  void dispose() {
    _name.dispose();
    _trophy.dispose();
    _self.dispose();
    _partner.dispose();
    super.dispose();
  }

  String _hhmm(ReminderTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  bool get _nameOk => validateJourneyTitle(_name.text) == null;

  bool get _isCoupleCapable =>
      j.coupleSelfName != null ||
      skinOfCurrent == PersonaSkinId.coupleRituals ||
      (j.kind == JourneyKind.group && j.maxMembers == 2);

  bool get _coupleChanged =>
      _isCoupleCapable &&
      (_self.text.trim() != (j.coupleSelfName ?? '') ||
          _partner.text.trim() != (j.couplePartnerName ?? ''));

  /// A journey that has couple names keeps both: `validateCoupleNames` lets
  /// an empty pair through (it means "no names"), which is not an option once
  /// names exist or when the user begins typing names (U19, UX-04).
  bool get _coupleOk {
    if (!_isCoupleCapable) return true;
    if (j.coupleSelfName == null && !_coupleChanged) return true;
    return _self.text.trim().isNotEmpty &&
        _partner.text.trim().isNotEmpty &&
        validateCoupleNames(_self.text, _partner.text) == null;
  }

  bool get _reminderChanged =>
      _reminderEnabled != _initialReminder.enabled ||
      _hhmm(_time) != _hhmm(_initialReminder.time);

  bool get _changed =>
      _name.text.trim() != j.title ||
      _layout != personaSkinOf(j) ||
      _color != (j.color ?? 0) ||
      _reminderChanged ||
      _trophy.text.trim() != ((j.dna?['trophy'] as String?) ?? '') ||
      _link != (j.visibility == JourneyVisibility.link) ||
      _coupleChanged;

  Future<void> _save() async {
    if (!_owner || !_changed || !_nameOk || !_coupleOk || _busy) return;
    setState(() => _busy = true);
    final repo = ref.read(journeyRepositoryProvider);
    try {
      final dna = <String, Object?>{...?j.dna};
      final trophy = _trophy.text.trim();
      // An emptied trophy field removes the goal (bug B-B13).
      if (trophy.isNotEmpty) {
        dna['trophy'] = trophy;
      } else {
        dna.remove('trophy');
      }
      final sanitized = sanitizeJourneyDna(dna);
      final isDefaultLayout = _layout == defaultSkinOf(j);
      final clear = <String>{
        if (j.dna != null && sanitized == null) 'dna',
        if (isDefaultLayout && j.layout != null) 'layout',
        if (!_reminderEnabled && j.reminderTime != null) 'reminder_time',
      };
      await repo.update(
        j.id,
        JourneyUpdate(
          title: _name.text.trim(),
          layout: isDefaultLayout ? null : _layout,
          color: _color,
          reminderTime: _reminderEnabled ? _hhmm(_time) : null,
          dna: sanitized,
          // A null field is "unchanged": clear it when nothing is left.
          clear: clear,
        ),
      );
      if (_coupleChanged) {
        await ref
            .read(groupInviteAdminRepositoryProvider)
            .renameCouple(j.id, _self.text, _partner.text);
      }
      if (_link != (j.visibility == JourneyVisibility.link)) {
        await repo.setPublicLink(j.id, enabled: _link);
      }
      final reminders = ref.read(reminderSettingsProvider.notifier);
      final current = reminders.of(j.id);
      final next = ReminderSetting(enabled: _reminderEnabled, time: _time);
      final reminderChanged =
          next.enabled != current.enabled || next.time != current.time;
      if (reminderChanged) {
        await reminders.save(j.id, next);
        unawaited(ref.read(reminderSchedulerProvider).reschedule());
      }
      if (!mounted) return;
      if (reminderChanged && next.enabled) {
        await offerReminderPermission(context, ref, time: _time);
        if (!mounted) return;
      }
      _saved = true;
      _leave(context, j.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showJourneySnack(context, journeyErrorMessage(context, e));
    }
  }

  PersonaSkinId get skinOfCurrent => _layout;

  /// Unsaved edits that leaving would lose (U19).
  bool get _dirty => _owner && !_saved && _changed;

  /// Back (header or system): asks before dropping unsaved edits (U19).
  Future<void> _back() async {
    if (_busy) return;
    if (_dirty) {
      final l10n = JourneysL10n.of(context);
      final discard = await showUiConfirmSheet(
        context: context,
        title: l10n.journeys_edit_discardTitle,
        message: l10n.journeys_edit_discardBody,
        confirmLabel: l10n.journeys_edit_discardConfirm,
        cancelLabel: l10n.journeys_edit_discardKeep,
        destructive: true,
        confirmKey: const ValueKey('edit-discard-confirm'),
      );
      if (!discard || !mounted) return;
      setState(() => _saved = true);
    }
    if (mounted) _leave(context, j.id);
  }

  String? _nameError(JourneysL10n l10n) =>
      switch (validateJourneyTitle(_name.text)) {
        null => null,
        JourneyTitleError.empty => l10n.journeys_errorTitleEmpty,
        JourneyTitleError.tooLong => l10n.journeys_errorTitleTooLong(
          journeyTitleMax,
        ),
      };

  String? _coupleError(JourneysL10n l10n, TextEditingController field) {
    if (!_isCoupleCapable) return null;
    if (j.coupleSelfName == null && !_coupleChanged) return null;
    if (field.text.trim().isEmpty) return l10n.journeys_errorCoupleNames;
    final e = validateCoupleNames(_self.text, _partner.text);
    if (e != CoupleNamesError.tooLong) return null;
    return field.text.trim().runes.length > partnerNameMax
        ? l10n.journeys_errorTitleTooLong(partnerNameMax)
        : null;
  }

  Future<void> _pickLayout(PersonaSkinId skin) async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _LayoutFullPreview(journey: j, skin: skin),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      if (_layout != skin) {
        _layout = skin;
        _color = 0;
      }
    });
  }

  Future<void> _confirmEnd() async {
    final l10n = JourneysL10n.of(context);
    final ok = await showUiSheet<bool>(
      context: context,
      builder: (ctx) => _ConfirmEnd(l10n: l10n),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(journeyRepositoryProvider).end(j.id);
      // Drop the pending reminders of the ended journey (bug B-B8).
      unawaited(ref.read(reminderSchedulerProvider).reschedule());
      if (!mounted) return;
      _saved = true;
      context.go(JourneysPaths.wrapped(j.id));
    } on Object catch (e) {
      if (mounted) showJourneySnack(context, journeyErrorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final skin = skinOfCurrent;
    final skinId = uiSkinIdFor(skin);
    final canSave = _owner && _changed && _nameOk && _coupleOk && !_busy;

    return UiSkinScope(
      skinId: skinId,
      variant: _color,
      child: Builder(
        builder: (context) {
          final ui = context.ui;
          final uiSkin = uiSkinById(skinId);
          final layouts = availableLayoutsFor(j, current: skin);
          final groupReadOnly =
              j.kind == JourneyKind.group && !widget.perms.isOwner;
          return PopScope(
            canPop: !_dirty && !_busy,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) unawaited(_back());
            },
            child: UiScaffold(
              key: const ValueKey('journey-edit'),
              padTop: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UiBackHeader(
                    onBack: _back,
                    backLabel: l10n.journeys_back,
                    title: l10n.journeys_edit_title,
                    trailing: _owner
                        ? UiTextAction(
                            key: const ValueKey('edit-save'),
                            label: l10n.journeys_edit_save,
                            onPressed: canSave ? _save : null,
                          )
                        : null,
                  ),
                  const SizedBox(height: UiSpace.lg),
                  if (!widget.perms.isOwner)
                    Padding(
                      padding: const EdgeInsets.only(bottom: UiSpace.lg),
                      child: Text(
                        l10n.journeys_edit_ownerOnly,
                        style: UiText.muted(color: ui.inkMuted),
                      ),
                    ),
                  if (skin == PersonaSkinId.quietTransformer)
                    Padding(
                      padding: const EdgeInsets.only(bottom: UiSpace.lg),
                      child: Row(
                        children: [
                          const OurneyIcon(name: 'lock', size: 16),
                          const SizedBox(width: 6),
                          Text(
                            l10n.journeys_edit_quietLock,
                            style: UiText.eyebrow(color: ui.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  _Section(
                    child: UiTextField(
                      fieldKey: const ValueKey('edit-name'),
                      label: l10n.journeys_edit_name,
                      controller: _name,
                      enabled: _owner,
                      // Says why Save is off (U19).
                      error: _owner ? _nameError(l10n) : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  _Section(
                    title: l10n.journeys_edit_layout,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (groupReadOnly) ...[
                          LayoutPreview(skinId: skinId, journey: j),
                          const SizedBox(height: UiSpace.sm),
                          Text(
                            l10n.journeys_edit_layoutOwnerOnly,
                            style: UiText.muted(color: ui.inkMuted),
                          ),
                        ] else
                          LayoutBuilder(
                            builder: (context, c) {
                              final cols = c.maxWidth < 300 ? 1 : 2;
                              final w =
                                  (c.maxWidth - (cols - 1) * UiSpace.md) / cols;
                              return Wrap(
                                spacing: UiSpace.md,
                                runSpacing: UiSpace.md,
                                children: [
                                  for (final s in layouts)
                                    SizedBox(
                                      width: w,
                                      child: _LayoutTile(
                                        journey: j,
                                        skin: s,
                                        selected: s == skin,
                                        enabled: _owner,
                                        onTap: () => _pickLayout(s),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        const SizedBox(height: UiSpace.sm),
                        Text(
                          l10n.journeys_edit_layoutNote,
                          style: UiText.muted(color: ui.inkMuted, size: 13),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: l10n.journeys_edit_color,
                    child: Wrap(
                      spacing: UiSpace.sm,
                      runSpacing: UiSpace.sm,
                      children: [
                        for (var i = 0; i < uiSkin.variants.length; i++)
                          UiChip(
                            key: ValueKey('edit-color-$i'),
                            label: skinColorName(l10n, uiSkin.id, i),
                            selected: _color == i,
                            glyph: _color == i
                                ? const OurneyIcon(
                                    name: 'check',
                                    size: 15,
                                    flat: true,
                                  )
                                : null,
                            onPressed: _owner
                                ? () => setState(() => _color = i)
                                : null,
                          ),
                      ],
                    ),
                  ),
                  if (skin == PersonaSkinId.accountabilitySquad)
                    _Section(
                      child: UiTextField(
                        fieldKey: const ValueKey('edit-trophy'),
                        label: l10n.journeys_edit_trophy,
                        controller: _trophy,
                        enabled: _owner,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  if (skin == PersonaSkinId.memoryCollectors &&
                      j.dna?['film'] != null)
                    _Section(
                      title: l10n.journeys_edit_film,
                      child: Text(
                        l10n.journeys_edit_filmReadonly(
                          int.tryParse('${j.dna?['film']}') ?? 0,
                        ),
                        style: UiText.body(color: ui.inkMuted),
                      ),
                    ),
                  if (_isCoupleCapable)
                    _Section(
                      title: l10n.journeys_edit_couple,
                      child: Column(
                        children: [
                          UiTextField(
                            fieldKey: const ValueKey('edit-self'),
                            label: l10n.journeys_coupleNameYou,
                            controller: _self,
                            enabled: _owner,
                            error: _coupleError(l10n, _self),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: UiSpace.sm),
                          UiTextField(
                            fieldKey: const ValueKey('edit-partner'),
                            label: l10n.journeys_coupleNameOther,
                            controller: _partner,
                            enabled: _owner,
                            error: _coupleError(l10n, _partner),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  _Section(
                    title: l10n.journeys_edit_reminder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        UiSwitchRow(
                          key: const ValueKey('edit-reminder-toggle'),
                          label: l10n.journeys_edit_reminder,
                          value: _reminderEnabled,
                          onChanged: _owner
                              ? (v) => setState(() => _reminderEnabled = v)
                              : null,
                        ),
                        const SizedBox(height: UiSpace.sm),
                        IgnorePointer(
                          ignoring: !_owner,
                          child: Opacity(
                            opacity: _reminderEnabled ? 1.0 : 0.55,
                            child: UiTimeWheel(
                              hour: _time.hour,
                              minute: _time.minute,
                              hourLabel: l10n.journeys_edit_reminderHour,
                              minuteLabel: l10n.journeys_edit_reminderMinute,
                              onChanged: (h, m) => setState(() {
                                _time = ReminderTime(h, m);
                                _reminderEnabled = true;
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: l10n.journeys_edit_visibility,
                    child: j.kind == JourneyKind.group
                        ? Row(
                            children: [
                              const OurneyIcon(name: 'lock', size: 18),
                              const SizedBox(width: UiSpace.sm),
                              Expanded(
                                child: Text(
                                  '${l10n.journeys_edit_membersOnly}\n'
                                  '${l10n.journeys_edit_membersOnlyHint}',
                                  style: UiText.body(color: ui.ink)
                                      .copyWith(height: 1.4),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: UiSpace.sm,
                                runSpacing: UiSpace.sm,
                                children: [
                                  UiChip(
                                    key: const ValueKey('edit-vis-private'),
                                    label: l10n.journeys_edit_visPrivate,
                                    selected: !_link,
                                    onPressed: _owner
                                        ? () => setState(() => _link = false)
                                        : null,
                                  ),
                                  UiChip(
                                    key: const ValueKey('edit-vis-link'),
                                    label: l10n.journeys_edit_visLink,
                                    selected: _link,
                                    onPressed: _owner
                                        ? () => setState(() => _link = true)
                                        : null,
                                  ),
                                ],
                              ),
                              if (skin == PersonaSkinId.quietTransformer &&
                                  _link)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: UiSpace.sm,
                                  ),
                                  child: Text(
                                    l10n.journeys_edit_visQuietNote,
                                    style: UiText.muted(
                                      color: ui.inkMuted,
                                      size: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  if (widget.perms.canEnd) ...[
                    const SizedBox(height: UiSpace.md),
                    UiButton.secondary(
                      key: const ValueKey('edit-end'),
                      label: l10n.journeys_endJourney,
                      glyph: const OurneyIcon(
                        name: 'flag',
                        size: 18,
                        flat: true,
                      ),
                      onPressed: _confirmEnd,
                    ),
                  ],
                  if (_owner) ...[
                    const SizedBox(height: UiSpace.md),
                    UiButton(
                      key: const ValueKey('edit-save-bottom'),
                      label: app.common_save,
                      loading: _busy,
                      onPressed: canSave ? _save : null,
                    ),
                  ],
                  const SizedBox(height: UiSpace.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title});

  /// Null when the child (a labelled field) already shows the heading (U21).
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Semantics(
              header: true,
              child: Text(title!, style: UiText.h2(color: ui.ink, size: 18)),
            ),
            const SizedBox(height: UiSpace.sm),
          ],
          child,
        ],
      ),
    );
  }
}

class _LayoutTile extends StatelessWidget {
  const _LayoutTile({
    required this.journey,
    required this.skin,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Journey journey;
  final PersonaSkinId skin;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final id = uiSkinIdFor(skin);
    final name = skinShortName(l10n, id);
    return UiPressable(
      key: ValueKey('edit-layout-$id'),
      onPressed: enabled ? onTap : null,
      selected: selected,
      semanticLabel: l10n.journeys_edit_layoutPreviewLabel(name),
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.menu),
      child: Container(
        padding: const EdgeInsets.all(UiSpace.sm),
        decoration: BoxDecoration(
          color: selected ? ui.fillSelected : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.menu),
          border: Border.all(
            color: selected ? ui.outline : ui.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutPreview(skinId: id, journey: journey),
            const SizedBox(height: UiSpace.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(color: ui.ink)
                  .copyWith(fontWeight: FontWeight.w700, height: 1.4),
            ),
            if (selected)
              Text(
                l10n.journeys_edit_layoutInUse,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.muted(
                  color: ui.inkMuted,
                  size: 12,
                ).copyWith(height: 1.4),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen preview of a layout with "Dùng giao diện này" / "Thôi".
class _LayoutFullPreview extends StatelessWidget {
  const _LayoutFullPreview({required this.journey, required this.skin});

  final Journey journey;
  final PersonaSkinId skin;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final id = uiSkinIdFor(skin);
    return UiSkinScope(
      skinId: id,
      child: Builder(
        builder: (context) => UiScaffold(
          key: const ValueKey('layout-full-preview'),
          padTop: 0,
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(
              UiSpace.lg,
              UiSpace.sm,
              UiSpace.lg,
              UiSpace.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiButton(
                  key: const ValueKey('layout-use'),
                  label: l10n.journeys_edit_useLayout,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: UiSpace.sm),
                UiButton.ghost(
                  key: const ValueKey('layout-cancel'),
                  label: l10n.journeys_edit_cancel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiBackHeader(
                onBack: () => Navigator.of(context).pop(false),
                backLabel: l10n.journeys_back,
                title: journey.title,
              ),
              const SizedBox(height: UiSpace.xl),
              LayoutPreview(skinId: id, journey: journey, large: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmEnd extends StatelessWidget {
  const _ConfirmEnd({required this.l10n});

  final JourneysL10n l10n;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.journeys_edit_endTitle,
            style: UiText.h2(color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Text(
          l10n.journeys_edit_endBody,
          style: UiText.body(color: ui.inkMuted).copyWith(height: 1.45),
        ),
        const SizedBox(height: UiSpace.lg),
        UiButton(
          key: const ValueKey('edit-end-confirm'),
          label: l10n.journeys_edit_endConfirm,
          glyph: const OurneyIcon(name: 'flag', size: 18, flat: true),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton.ghost(
          label: l10n.journeys_edit_cancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
