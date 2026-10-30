import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../sharing/l10n/generated/sharing_localizations.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_form.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_errors.dart';
import 'journey_style.dart';

/// Step 2 of the create flow (`/journeys/new/:template`), V1.0
/// `QuickSetup`: the whole screen takes the chosen style (paper, ink,
/// accent); name, solo/group and duration up front; icon, metric, privacy,
/// link and time zone under **More options** (FR-B2), seeded from the
/// template (FR-B7 defaults for weight loss open those options so they are
/// seen).
class CreateJourneyScreen extends ConsumerStatefulWidget {
  const CreateJourneyScreen({
    required this.templateId,
    this.isCouplePreset = false,
    this.frame,
    this.openMoreOptions = false,
    super.key,
  });

  final TemplateId templateId;
  final bool isCouplePreset;

  /// "Do this journey" (S15, SCR-87): prefill from another journey's frame.
  final JourneyFrame? frame;

  /// Open **More options** at once ("Change something").
  final bool openMoreOptions;

  /// True when `:template` is the `couple` preset (`TemplateId.custom` + heart).
  static bool isCoupleWire(String? wire) =>
      wire == 'couple' || wire == 'couple_rituals';

  /// Parses the route parameter; unknown values fall back to Custom.
  static TemplateId parseTemplate(String? wire) {
    if (wire == null || isCoupleWire(wire)) return TemplateId.custom;
    try {
      return TemplateId.fromWire(wire);
    } on FormatException {
      return TemplateId.custom;
    }
  }

  @override
  ConsumerState<CreateJourneyScreen> createState() =>
      _CreateJourneyScreenState();
}

class _CreateJourneyScreenState extends ConsumerState<CreateJourneyScreen> {
  JourneyForm? _form;
  final _title = TextEditingController();
  final _duration = TextEditingController();
  final _metricName = TextEditingController();
  final _metricUnit = TextEditingController();
  bool _submitted = false;
  bool _busy = false;

  /// Null until the form exists: then opened when the template preset
  /// touches privacy (weight loss hides kg and blurs shares).
  bool? _moreOpen;

  /// One id per form: retrying after a lost response (offline, timeout)
  /// returns the same journey instead of creating a duplicate.
  final String _clientId = const Uuid().v4();

  /// "Based on {name}'s journey" (S36); removing it also drops the link to
  /// the source journey (no `markFollowed`).
  late bool _basedOn = widget.frame != null;

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _metricName.dispose();
    _metricUnit.dispose();
    super.dispose();
  }

  JourneyForm _initForm(String timezone) {
    final form = JourneyForm.fromTemplate(
      templateFor(widget.templateId),
      languageCode: Localizations.localeOf(context).languageCode,
      timezone: timezone,
    );
    if (widget.isCouplePreset) {
      form.emoji = '💞';
      form.title = JourneysL10n.of(context).journeys_templateCoupleTitle;
      if (!ref.read(appConfigProvider).localOnly) {
        form.kind = JourneyKind.group;
      }
    }
    final frame = widget.frame;
    if (frame != null) {
      form.title = frame.title;
      form.emoji = frame.emoji;
      if (frame.durationDays != null || form.allowOpenEnded) {
        form.durationDays = frame.durationDays?.clamp(durationMin, durationMax);
      }
      form.trackMetric = frame.metricName != null;
      form.metricName = frame.metricName ?? '';
      form.metricUnit = frame.metricUnit ?? '';
      // S35: a group/couple source makes a journey of the same kind.
      if (frame.kind == JourneyKind.group &&
          !ref.read(appConfigProvider).localOnly) {
        form.kind = JourneyKind.group;
      }
    }
    _title.text = form.title;
    _duration.text = form.durationDays?.toString() ?? '';
    _metricName.text = form.metricName;
    _metricUnit.text = form.metricUnit;
    return form;
  }

  void _update(void Function(JourneyForm f) change) =>
      setState(() => change(_form!));

  Future<void> _submit() async {
    final form = _form!;
    setState(() => _submitted = true);
    if (!form.validate().isValid || _busy) return;
    final repo = ref.read(journeyRepositoryProvider);
    final now = ref.read(journeysClockProvider).now();
    final reminders = ref.read(reminderSchedulerProvider);
    setState(() => _busy = true);
    try {
      final journey = await repo.create(
        form.toDraft(
          startDate: journeyLocalDate(form.timezone, now),
          id: _clientId,
        ),
      );
      // The new journey may get the 21:00 streak alert (FR-G2).
      unawaited(reminders.reschedule());
      final hide = form.trackMetric && form.hideMetric;
      if (hide || form.blurOnShare) {
        try {
          await repo.updateMyMembership(
            journey.id,
            hideMetric: hide ? true : null,
            blurMedia: form.blurOnShare ? true : null,
          );
        } on Object catch (e) {
          if (mounted) {
            showJourneySnack(context, journeyErrorMessage(context, e));
          }
        }
      }
      final frame = widget.frame;
      if (frame != null && _basedOn) {
        try {
          await ref
              .read(sharingRepositoryProvider)
              .markFollowed(journey.id, frame.sourceJourneyId);
        } on Object {
          // Counting "started" is best effort; the journey exists.
        }
      }
      if (!mounted) return;
      unawaited(ref.read(activeJourneyIdProvider.notifier).select(journey.id));
      context.go(AppRoutes.journey(journey.id));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (rootError(e) case OurneyException(error: OurneyErrorCode.limit)) {
        await showJourneyLimitDialog(context);
      } else {
        showJourneySnack(context, journeyErrorMessage(context, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final timezone = ref.watch(deviceTimezoneProvider);
    final tz = timezone.value ?? (timezone.hasError ? 'UTC' : null);
    if (tz != null) _form ??= _initForm(tz);
    final form = _form;
    if (form != null) {
      _moreOpen ??=
          widget.openMoreOptions || form.trackMetric || form.blurOnShare;
    }

    final skin = form == null
        ? personaSkinForTemplate(
            widget.templateId,
            emoji: widget.isCouplePreset ? '💞' : null,
          )
        : personaSkinForTemplate(
            form.template.id,
            kind: form.kind,
            emoji: form.emoji,
          );
    final pal = JourneyPalette.of(context, journeyStyleFor(skin));
    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);

    return UiScaffold(
      key: const ValueKey('journeys-create'),
      background: pal.paper,
      padTop: 0,
      bottom: form == null
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(gutter, UiSpace.sm, gutter, 20),
              child: UiButton(
                key: const ValueKey('journey-create'),
                label: l10n.journeys_createButton,
                accent: pal.accent,
                onAccent: pal.onAccent,
                loading: _busy,
                onPressed: _submit,
              ),
            ),
      child: form == null
          ? Column(
              children: [
                UiBackHeader(
                  onBack: () => context.pop(),
                  backLabel: l10n.journeys_back,
                ),
                const SizedBox(height: 120),
                Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: app.common_loading,
                  ),
                ),
              ],
            )
          : _buildForm(context, form, pal),
    );
  }

  Widget _buildForm(
    BuildContext context,
    JourneyForm form,
    JourneyPalette pal,
  ) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final errors = form.validate();
    final show = _submitted;

    String? titleError() => switch (show ? errors.title : null) {
      JourneyTitleError.empty => l10n.journeys_errorTitleEmpty,
      JourneyTitleError.tooLong => l10n.journeys_errorTitleTooLong(
        journeyTitleMax,
      ),
      null => null,
    };

    final durationError = show && errors.duration != null
        ? l10n.journeys_errorDuration(durationMin, durationMax)
        : null;

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 7),
      child: Semantics(
        header: true,
        child: Text(s, style: UiText.fieldLabel(color: pal.inkAt(0.78))),
      ),
    );

    Widget note(IconData icon, String s) => Padding(
      padding: const EdgeInsets.only(top: UiSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: pal.inkAt(0.72)),
          const SizedBox(width: UiSpace.xs),
          Expanded(
            child: Text(
              s,
              style: UiText.body(
                size: 12,
                height: 1.45,
                color: pal.inkAt(0.72),
              ),
            ),
          ),
        ],
      ),
    );

    final more = _moreOpen ?? false;
    final metricMissing = show && errors.metricName == true;
    if (metricMissing && !more) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _moreOpen = true);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiBackHeader(
          onBack: () => context.pop(),
          backLabel: l10n.journeys_back,
        ),
        const SizedBox(height: UiSpace.sm),
        ExcludeSemantics(
          child: UiEyebrow(
            pal.name,
            key: const ValueKey('journey-create-style'),
            color: pal.ink,
          ),
        ),
        const SizedBox(height: UiSpace.xl),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            key: const ValueKey('journey-create-design-preview'),
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pal.accent,
              border: Border.all(color: pal.ink),
            ),
            child: Icon(
              uiJourneyIcon(form.emoji, form.template.id),
              size: 28,
              color: pal.onAccent,
            ),
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.journeys_createTitle,
            style: UiText.h1(color: pal.ink),
          ),
        ),
        if (widget.frame != null && _basedOn) ...[
          const SizedBox(height: UiSpace.md),
          Container(
            key: const ValueKey('journey-based-on'),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border.all(color: pal.inkAt(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    SharingL10n.of(context)
                        .sharing_basedOn(widget.frame!.ownerName),
                    style: UiText.body(
                      size: 12,
                      weight: FontWeight.w700,
                      height: 1.4,
                      color: pal.ink,
                    ),
                  ),
                ),
                UiIconButton(
                  key: const ValueKey('journey-based-on-remove'),
                  icon: Icons.close_rounded,
                  iconSize: 18,
                  color: pal.ink,
                  label: SharingL10n.of(context).sharing_removeBasedOn,
                  onPressed: () => setState(() => _basedOn = false),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: UiSpace.lg),
        UiTextField(
          fieldKey: const ValueKey('journey-title'),
          label: l10n.journeys_fieldTitle,
          hint: l10n.journeys_fieldTitle,
          controller: _title,
          error: titleError(),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) => _update((f) => f.title = v),
        ),
        label(l10n.journeys_fieldKind),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            UiChip(
              key: const ValueKey('journey-kind-solo'),
              label: l10n.journeys_kindSolo,
              icon: Icons.person_rounded,
              selected: form.kind == JourneyKind.solo,
              onPressed: () => _update((f) => f.kind = JourneyKind.solo),
            ),
            UiChip(
              key: const ValueKey('journey-kind-group'),
              label: l10n.journeys_kindGroup,
              icon: Icons.groups_rounded,
              selected: form.kind == JourneyKind.group,
              onPressed: localOnly
                  ? null
                  : () => _update((f) => f.kind = JourneyKind.group),
            ),
          ],
        ),
        if (localOnly)
          note(Icons.cloud_off_rounded, l10n.journeys_groupNeedsServer),
        label(l10n.journeys_fieldDuration),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final d in journeyDurationChoices)
              UiChip(
                key: ValueKey('journey-duration-$d'),
                label: l10n.journeys_templateDays(d),
                selected: form.durationDays == d,
                onPressed: () => _update((f) {
                  f.durationDays = d;
                  _duration.text = '$d';
                }),
              ),
            if (form.allowOpenEnded)
              UiChip(
                key: const ValueKey('journey-duration-open'),
                label: l10n.journeys_openEnded,
                icon: Icons.all_inclusive_rounded,
                selected: form.durationDays == null,
                onPressed: () => _update((f) {
                  f.durationDays = null;
                  _duration.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: UiSpace.md),
        UiTextField(
          fieldKey: const ValueKey('journey-duration'),
          label: l10n.journeys_durationCustom,
          controller: _duration,
          error: durationError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _update((f) {
            final n = int.tryParse(v);
            // Empty input is open-ended only where the template allows it.
            f.durationDays = n ?? (f.allowOpenEnded ? null : 0);
          }),
        ),
        const SizedBox(height: UiSpace.lg),
        note(Icons.lock_outline_rounded, l10n.journeys_styleLocked),
        const SizedBox(height: UiSpace.sm),
        _MoreOptionsToggle(
          key: const ValueKey('journey-more-options'),
          label: l10n.journeys_moreOptions,
          open: more,
          color: pal.ink,
          rule: pal.inkAt(0.22),
          onPressed: () => setState(() => _moreOpen = !more),
        ),
        if (more) ...[
          label(l10n.journeys_fieldEmoji),
          Wrap(
            spacing: UiSpace.sm,
            runSpacing: UiSpace.sm,
            children: [
              for (final e in {form.template.emoji, ...journeyEmojiChoices})
                _EmojiChoice(
                  emoji: e,
                  template: form.template.id,
                  selected: form.emoji == e,
                  accent: pal.accent,
                  onTap: () => _update((f) => f.emoji = e),
                ),
            ],
          ),
          label(l10n.journeys_fieldMetric),
          UiSwitchRow(
            key: const ValueKey('journey-metric'),
            label: l10n.journeys_fieldMetric,
            subtitle: l10n.journeys_fieldMetricHint,
            value: form.trackMetric,
            onChanged: (v) => _update((f) => f.trackMetric = v),
          ),
          if (form.trackMetric) ...[
            const SizedBox(height: UiSpace.md),
            UiTextField(
              fieldKey: const ValueKey('journey-metric-name'),
              label: l10n.journeys_metricName,
              controller: _metricName,
              error: show && errors.metricName == true
                  ? l10n.journeys_errorMetricName
                  : null,
              onChanged: (v) => _update((f) => f.metricName = v),
            ),
            const SizedBox(height: UiSpace.md),
            UiTextField(
              fieldKey: const ValueKey('journey-metric-unit'),
              label: l10n.journeys_metricUnit,
              controller: _metricUnit,
              onChanged: (v) => _update((f) => f.metricUnit = v),
            ),
            UiSwitchRow(
              key: const ValueKey('journey-hide-metric'),
              label: l10n.journeys_hideMetric,
              value: form.hideMetric,
              onChanged: (v) => _update((f) => f.hideMetric = v),
            ),
          ],
          UiSwitchRow(
            key: const ValueKey('journey-blur'),
            label: l10n.journeys_blurOnShare,
            value: form.blurOnShare,
            onChanged: (v) => _update((f) => f.blurOnShare = v),
          ),
          label(l10n.journeys_fieldVisibility),
          if (form.kind == JourneyKind.group)
            note(Icons.lock_rounded, l10n.journeys_visibilityGroup)
          else ...[
            Wrap(
              spacing: UiSpace.sm,
              runSpacing: UiSpace.sm,
              children: [
                UiChip(
                  key: const ValueKey('journey-visibility-private'),
                  label: l10n.journeys_visibilityPrivate,
                  icon: Icons.lock_rounded,
                  selected: form.soloVisibility == JourneyVisibility.private,
                  onPressed: () => _update(
                    (f) => f.soloVisibility = JourneyVisibility.private,
                  ),
                ),
                UiChip(
                  key: const ValueKey('journey-visibility-link'),
                  label: l10n.journeys_visibilityLink,
                  icon: Icons.link_rounded,
                  selected: form.soloVisibility == JourneyVisibility.link,
                  onPressed: localOnly
                      ? null
                      : () => _update(
                          (f) => f.soloVisibility = JourneyVisibility.link,
                        ),
                ),
              ],
            ),
            if (localOnly)
              note(Icons.cloud_off_rounded, l10n.journeys_linkNeedsServer),
          ],
          label(l10n.journeys_fieldTimezone),
          Row(
            children: [
              Icon(Icons.public_rounded, color: ui.inkMuted),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Text(
                  form.timezone,
                  key: const ValueKey('journey-timezone'),
                  style: UiText.body(size: 15, color: pal.ink),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// `.more-options`: full-width row between two hairlines with a chevron.
class _MoreOptionsToggle extends StatelessWidget {
  const _MoreOptionsToggle({
    required this.label,
    required this.open,
    required this.color,
    required this.rule,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool open;
  final Color color;
  final Color rule;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      expanded: open,
      child: UiPressable(
        onPressed: onPressed,
        semanticLabel: label,
        excludeChildSemantics: true,
        borderRadius: BorderRadius.zero,
        minSize: const Size(UiSize.tap, 52),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: rule)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: UiText.button(color: color)),
              ),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: UiMotion.of(context, UiMotion.press),
                child: Icon(Icons.expand_more_rounded, size: 22, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.template,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final TemplateId template;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      key: ValueKey('journey-emoji-$emoji'),
      onPressed: onTap,
      selected: selected,
      semanticLabel: JourneysL10n.of(context).journeys_emojiSemantics(emoji),
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(
            color: selected ? ui.ink : ui.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(uiJourneyIcon(emoji, template), size: 26, color: ui.ink),
      ),
    );
  }
}
