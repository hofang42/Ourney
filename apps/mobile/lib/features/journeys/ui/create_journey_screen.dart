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
import '../../../shared/chunky_button.dart';
import '../../../shared/ourney_chip.dart';
import '../../../shared/persona_pill.dart';
import '../../../shared/template_icons.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_form.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_errors.dart';

/// Step 2 of the create flow (`/journeys/new/:template`): title, emoji,
/// solo/group, duration, optional metric, visibility, time zone (FR-B2),
/// seeded from the template (FR-B7 defaults for weight loss).
class CreateJourneyScreen extends ConsumerStatefulWidget {
  const CreateJourneyScreen({
    required this.templateId,
    this.isCouplePreset = false,
    super.key,
  });

  final TemplateId templateId;
  final bool isCouplePreset;

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

  /// One id per form: retrying after a lost response (offline, timeout)
  /// returns the same journey instead of creating a duplicate.
  final String _clientId = const Uuid().v4();

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
      data: buildAppTheme(brightness, skin).copyWith(
        scaffoldBackgroundColor: pTheme.background,
      ),
      duration: OurneyMotion.duration(context, OurneyDurations.personaTheme),
      curve: Curves.easeOutCubic,
      child: Scaffold(
        key: const ValueKey('journeys-create'),
        backgroundColor: pTheme.background,
        appBar: AppBar(
          backgroundColor: pTheme.background,
          foregroundColor: pTheme.ink,
          title: Text(l10n.journeys_createTitle),
        ),
        body: SafeArea(
          child: form == null
              ? Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: app.common_loading,
                  ),
                )
              : _buildForm(context, form, skin),
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
    final designAsset = designAssetForPersona(skin);
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
      padding: const EdgeInsets.only(
        top: OurneySpacing.xl,
        bottom: OurneySpacing.sm,
      ),
      child: Semantics(header: true, child: Text(s, style: text.titleMedium)),
    );

    Widget note(IconData icon, String s) => Padding(
      padding: const EdgeInsets.only(top: OurneySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.inkMuted),
          const SizedBox(width: OurneySpacing.xs),
          Expanded(child: Text(s, style: text.bodySmall)),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OurneySpacing.screenMargin,
        OurneySpacing.sm,
        OurneySpacing.screenMargin,
        OurneySpacing.xxl,
      ),
      children: [
        Container(
          key: const ValueKey('journey-create-design-preview'),
          padding: const EdgeInsets.all(OurneySpacing.md),
          decoration: BoxDecoration(
            color: pTheme.surface,
            borderRadius: BorderRadius.circular(pTheme.cardRadius),
            border: Border.all(
              color: pTheme.border,
              width: pTheme.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PersonaPill(
                  icon: Icons.palette_rounded,
                  emphasized: true,
                  label: l10n.journeys_personaPreviewLabel,
                ),
              ),
              const SizedBox(height: OurneySpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    designAsset,
                    key: ValueKey('create-asset-$designAsset'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: pTheme.surfaceElevated,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: pTheme.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        const SizedBox(height: OurneySpacing.xxl),
        ChunkyButton(
          key: const ValueKey('journey-create'),
          label: l10n.journeys_createButton,
          onPressed: _busy ? null : _submit,
        ),
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
