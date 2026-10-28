import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/motion.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/color_utils.dart';
import '../../../shared/ourney_chip.dart';
import '../../../shared/ourney_primary_button.dart';
import '../../../shared/template_icons.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../sharing/l10n/generated/sharing_localizations.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_form.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_errors.dart';

/// Step 2 of the create flow (`/journeys/new/:template`), V1.0 "Quick
/// setup": the whole screen takes the chosen style (paper, ink, accent);
/// name, solo/group and duration up front; icon, metric, privacy, link and
/// time zone under **More options** (FR-B2), seeded from the template
/// (FR-B7 defaults for weight loss open those options so they are seen).
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

  /// True when `:template` is the `couple` preset (`TemplateId.custom` + `💞`).
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
    final brightness = Theme.of(context).brightness;
    final pTheme = OurneyPersonaTheme.forSkin(skin, brightness);

    return AnimatedTheme(
      data: buildAppTheme(
        brightness,
        skin,
      ).copyWith(scaffoldBackgroundColor: pTheme.background),
      duration: OurneyMotion.duration(context, OurneyDurations.personaTheme),
      curve: Curves.easeOutCubic,
      child: Builder(
        builder: (innerContext) => Scaffold(
          key: const ValueKey('journeys-create'),
          backgroundColor: pTheme.background,
          appBar: AppBar(
            backgroundColor: pTheme.background,
            foregroundColor: pTheme.ink,
          ),
          body: SafeArea(
            top: false,
            child: form == null
                ? Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: app.common_loading,
                    ),
                  )
                : _buildForm(innerContext, form, skin),
          ),
          bottomNavigationBar: form == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    OurneySpacing.screenMargin,
                    OurneySpacing.sm,
                    OurneySpacing.screenMargin,
                    OurneySpacing.lg,
                  ),
                  child: OurneyPrimaryButton(
                    key: const ValueKey('journey-create'),
                    label: l10n.journeys_createButton,
                    backgroundColor: pTheme.primaryAccent,
                    onPressed: _busy ? null : _submit,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    JourneyForm form,
    PersonaSkinId skin,
  ) {
    final l10n = JourneysL10n.of(context);
    final pTheme = OurneyPersonaTheme.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
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
        child: Text(
          s,
          style: text.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: pTheme.ink.withValues(alpha: 0.78),
          ),
        ),
      ),
    );

    Widget note(IconData icon, String s) => Padding(
      padding: const EdgeInsets.only(top: OurneySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: pTheme.inkMuted),
          const SizedBox(width: OurneySpacing.xs),
          Expanded(
            child: Text(
              s,
              style: text.bodySmall?.copyWith(color: pTheme.inkMuted),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OurneySpacing.screenMargin,
        0,
        OurneySpacing.screenMargin,
        OurneySpacing.xxl,
      ),
      children: [
        ExcludeSemantics(
          child: Text(
            personaStyleName(skin).toUpperCase(),
            key: const ValueKey('journey-create-style'),
            style: eyebrowStyle(color: pTheme.ink),
          ),
        ),
        const SizedBox(height: OurneySpacing.xl),
        Container(
          key: const ValueKey('journey-create-design-preview'),
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pTheme.primaryAccent,
            border: Border.all(color: pTheme.ink),
          ),
          child: Icon(
            journeyIcon(form.emoji, form.template.id),
            size: 28,
            color: readableOn(pTheme.primaryAccent),
          ),
        ),
        const SizedBox(height: OurneySpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.journeys_createTitle,
            style: text.headlineLarge?.copyWith(color: pTheme.ink),
          ),
        ),
        if (widget.frame != null && _basedOn) ...[
          const SizedBox(height: OurneySpacing.md),
          Container(
            key: const ValueKey('journey-based-on'),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border.all(color: pTheme.ink.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    SharingL10n.of(context)
                        .sharing_basedOn(widget.frame!.ownerName),
                    style: text.labelMedium?.copyWith(
                      color: pTheme.ink,
                      height: 1.35,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('journey-based-on-remove'),
                  tooltip: SharingL10n.of(context).sharing_removeBasedOn,
                  color: pTheme.ink,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _basedOn = false),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: OurneySpacing.sm),
        label(l10n.journeys_fieldTitle),
        TextField(
          key: const ValueKey('journey-title'),
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.journeys_fieldTitle,
            errorText: titleError(),
            errorMaxLines: 3,
          ),
          onChanged: (v) => _update((f) => f.title = v),
        ),
        label(l10n.journeys_fieldKind),
        Wrap(
          spacing: OurneySpacing.sm,
          runSpacing: OurneySpacing.sm,
          children: [
            OurneyChip(
              key: const ValueKey('journey-kind-solo'),
              label: l10n.journeys_kindSolo,
              icon: Icons.person_rounded,
              selected: form.kind == JourneyKind.solo,
              onTap: () => _update((f) => f.kind = JourneyKind.solo),
            ),
            OurneyChip(
              key: const ValueKey('journey-kind-group'),
              label: l10n.journeys_kindGroup,
              icon: Icons.groups_rounded,
              selected: form.kind == JourneyKind.group,
              onTap: localOnly
                  ? null
                  : () => _update((f) => f.kind = JourneyKind.group),
            ),
          ],
        ),
        if (localOnly)
          note(Icons.cloud_off_rounded, l10n.journeys_groupNeedsServer),
        label(l10n.journeys_fieldDuration),
        Wrap(
          spacing: OurneySpacing.sm,
          runSpacing: OurneySpacing.sm,
          children: [
            for (final d in journeyDurationChoices)
              OurneyChip(
                key: ValueKey('journey-duration-$d'),
                label: l10n.journeys_templateDays(d),
                selected: form.durationDays == d,
                onTap: () => _update((f) {
                  f.durationDays = d;
                  _duration.text = '$d';
                }),
              ),
            if (form.allowOpenEnded)
              OurneyChip(
                key: const ValueKey('journey-duration-open'),
                label: l10n.journeys_openEnded,
                icon: Icons.all_inclusive_rounded,
                selected: form.durationDays == null,
                onTap: () => _update((f) {
                  f.durationDays = null;
                  _duration.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: OurneySpacing.md),
        TextField(
          key: const ValueKey('journey-duration'),
          controller: _duration,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.journeys_durationCustom,
            errorText: durationError,
            errorMaxLines: 3,
          ),
          onChanged: (v) => _update((f) {
            final n = int.tryParse(v);
            // Empty input is open-ended only where the template allows it.
            f.durationDays = n ?? (f.allowOpenEnded ? null : 0);
          }),
        ),
        const SizedBox(height: OurneySpacing.lg),
        note(Icons.lock_outline_rounded, l10n.journeys_styleLocked),
        const SizedBox(height: OurneySpacing.sm),
        Semantics(
          button: true,
          expanded: more,
          child: InkWell(
            key: const ValueKey('journey-more-options'),
            onTap: () => setState(() => _moreOpen = !more),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Text(
                    l10n.journeys_moreOptions,
                    style: text.labelLarge?.copyWith(color: pTheme.ink),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: more ? 0.5 : 0,
                    duration: OurneyMotion.duration(
                      context,
                      OurneyDurations.tap,
                    ),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: pTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (more) ...[
          label(l10n.journeys_fieldEmoji),
          Wrap(
            spacing: OurneySpacing.sm,
            runSpacing: OurneySpacing.sm,
            children: [
              for (final e in {form.template.emoji, ...journeyEmojiChoices})
                _EmojiChoice(
                  emoji: e,
                  template: form.template.id,
                  selected: form.emoji == e,
                  onTap: () => _update((f) => f.emoji = e),
                ),
            ],
          ),
          label(l10n.journeys_fieldMetric),
          SwitchListTile(
            key: const ValueKey('journey-metric'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.journeys_fieldMetric),
            subtitle: Text(l10n.journeys_fieldMetricHint),
            value: form.trackMetric,
            onChanged: (v) => _update((f) => f.trackMetric = v),
          ),
          if (form.trackMetric) ...[
            TextField(
              key: const ValueKey('journey-metric-name'),
              controller: _metricName,
              decoration: InputDecoration(
                labelText: l10n.journeys_metricName,
                errorText: show && errors.metricName == true
                    ? l10n.journeys_errorMetricName
                    : null,
              ),
              onChanged: (v) => _update((f) => f.metricName = v),
            ),
            const SizedBox(height: OurneySpacing.md),
            TextField(
              key: const ValueKey('journey-metric-unit'),
              controller: _metricUnit,
              decoration: InputDecoration(labelText: l10n.journeys_metricUnit),
              onChanged: (v) => _update((f) => f.metricUnit = v),
            ),
            SwitchListTile(
              key: const ValueKey('journey-hide-metric'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.visibility_off_rounded),
              title: Text(l10n.journeys_hideMetric),
              value: form.hideMetric,
              onChanged: (v) => _update((f) => f.hideMetric = v),
            ),
          ],
          SwitchListTile(
            key: const ValueKey('journey-blur'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.blur_on_rounded),
            title: Text(l10n.journeys_blurOnShare),
            value: form.blurOnShare,
            onChanged: (v) => _update((f) => f.blurOnShare = v),
          ),
          label(l10n.journeys_fieldVisibility),
          if (form.kind == JourneyKind.group)
            note(Icons.lock_rounded, l10n.journeys_visibilityGroup)
          else ...[
            Wrap(
              spacing: OurneySpacing.sm,
              runSpacing: OurneySpacing.sm,
              children: [
                OurneyChip(
                  key: const ValueKey('journey-visibility-private'),
                  label: l10n.journeys_visibilityPrivate,
                  icon: Icons.lock_rounded,
                  selected: form.soloVisibility == JourneyVisibility.private,
                  onTap: () => _update(
                    (f) => f.soloVisibility = JourneyVisibility.private,
                  ),
                ),
                OurneyChip(
                  key: const ValueKey('journey-visibility-link'),
                  label: l10n.journeys_visibilityLink,
                  icon: Icons.link_rounded,
                  selected: form.soloVisibility == JourneyVisibility.link,
                  onTap: localOnly
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
              Icon(Icons.public_rounded, color: c.inkMuted),
              const SizedBox(width: OurneySpacing.sm),
              Expanded(
                child: Text(
                  form.timezone,
                  key: const ValueKey('journey-timezone'),
                  style: text.bodyLarge,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final TemplateId template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final radius = BorderRadius.circular(OurneyRadii.chip);
    return Semantics(
      button: true,
      selected: selected,
      label: JourneysL10n.of(context).journeys_emojiSemantics(emoji),
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primary.withValues(alpha: 0.16) : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? c.primaryDeep : c.border,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('journey-emoji-$emoji'),
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(journeyIcon(emoji, template), size: 28, color: c.ink),
                if (selected)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: c.primaryDeep,
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
