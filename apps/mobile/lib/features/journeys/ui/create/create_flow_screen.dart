import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/providers.dart';
import '../../../../ui/ui.dart';
import '../../../onboarding/onboarding_providers.dart';
import '../../../reminders/data/reminder_scheduler.dart';
import '../../../reminders/data/reminder_settings.dart';
import '../../../reminders/domain/reminder_plan.dart';
import '../../data/create_progress.dart';
import '../../data/journeys_providers.dart';
import '../../domain/journey_form.dart';
import '../../domain/journey_time.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_errors.dart';
import '../widgets/departure_ticket.dart';
import 'create_deck.dart';
import 'create_widgets.dart';
import 'dna_pages.dart';
import 'dna_questions.dart';
import 'dna_text.dart';

/// Who the journey is with (V2 create step 3).
enum CreateWho { solo, group, couple }

/// One journey type of step 1 (V2 `createTypes`).
class CreateTypeOption {
  const CreateTypeOption({
    required this.keyName,
    required this.templateId,
    required this.skinId,
    required this.badge,
    this.isCouple = false,
  });

  final String keyName;
  final TemplateId templateId;
  final PersonaSkinId skinId;

  /// `UiTypeBadge` id.
  final String badge;
  final bool isCouple;

  bool get isCustom => templateId == TemplateId.custom && !isCouple;

  /// The six V2 types, in the Figma order's data-model terms.
  static List<CreateTypeOption> all() => [
    for (final t in allTemplates.where((t) => t.id != TemplateId.custom))
      CreateTypeOption(
        keyName: t.id.wireName,
        templateId: t.id,
        skinId: t.personaSkinId,
        badge: switch (t.id) {
          TemplateId.weightLoss => 'weight',
          TemplateId.englishDaily => 'study',
          TemplateId.workout30 => 'workout',
          TemplateId.travel => 'trip',
          TemplateId.custom => 'custom',
        },
      ),
    const CreateTypeOption(
      keyName: 'couple',
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.coupleRituals,
      badge: 'couple',
      isCouple: true,
    ),
    CreateTypeOption(
      keyName: TemplateId.custom.wireName,
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.minimalistHabit,
      badge: 'custom',
    ),
  ];
}

/// **Create journey**, V2 five-step flow (`/journeys/new`):
/// 1 type, 2 name + goal (+ icon, tracked number), 3 who (+ couple names),
/// 4 rhythm (duration, start date, visibility), 5 review on the departure
/// ticket and **Bắt đầu hành trình**.
///
/// All state lives in one [JourneyForm] plus the few flow fields below, so
/// going back keeps every answer. The journey is created through
/// `JourneyRepository.create` exactly like the quick setup.
class CreateFlowScreen extends ConsumerStatefulWidget {
  const CreateFlowScreen({super.key});

  @override
  ConsumerState<CreateFlowScreen> createState() => _CreateFlowScreenState();
}

class _CreateFlowScreenState extends ConsumerState<CreateFlowScreen> {
  static const _steps = 5;

  final _options = CreateTypeOption.all();
  final _title = TextEditingController();
  final _duration = TextEditingController();
  final _metricName = TextEditingController();
  final _metricUnit = TextEditingController();
  final _nameLeft = TextEditingController();
  final _nameRight = TextEditingController();
  final _trophy = TextEditingController();
  final _place = TextEditingController();
  final _habit = TextEditingController();
  final _reason = TextEditingController();

  int _step = 0;

  /// Focused card of the step-1 type deck.
  int _deckFocus = 0;

  /// Step-2 "DNA" question page; equal to the question count = the form.
  int _dnaPage = 0;
  final Map<String, Object> _dna = {};
  bool _hideWeight = true;
  CreateTypeOption? _option;
  JourneyForm? _form;
  CreateWho _who = CreateWho.solo;
  LocalDate? _start;
  int _variant = 0;
  bool _busy = false;

  /// Steps whose Next was pressed: only then show their errors.
  final Set<int> _attempted = {};

  /// One id per flow: a retry after a lost response returns the same journey.
  final String _clientId = const Uuid().v4();

  @override
  void dispose() {
    for (final c in [
      _title,
      _duration,
      _metricName,
      _metricUnit,
      _nameLeft,
      _nameRight,
      _trophy,
      _place,
      _habit,
      _reason,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _localOnly => ref.read(appConfigProvider).localOnly;

  /// Quiz-derived defaults (type, who, reminder); applied once, overridable.
  JourneySuggestion? _suggestion;
  bool _suggestionApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_suggestionApplied) return;
    _suggestionApplied = true;
    final s = ref.read(journeySuggestionProvider);
    if (s == null) return;
    _suggestion = s;
    final key = s.coupleRitual ? 'couple' : s.templateId.wireName;
    for (final o in _options) {
      if (o.keyName != key) continue;
      _apply(o);
      if (!o.isCouple && !_localOnly && s.kind == JourneyKind.group) {
        _who = CreateWho.group;
        _applyWho(_form!);
      }
      return;
    }
  }

  void _select(CreateTypeOption option) {
    _apply(option);
    setState(() => _step = 1);
  }

  void _apply(CreateTypeOption option) {
    final l10n = JourneysL10n.of(context);
    if (_option?.keyName != option.keyName) {
      final tz = ref.read(deviceTimezoneProvider).value ?? 'UTC';
      final form = JourneyForm.fromTemplate(
        templateFor(option.templateId),
        languageCode: Localizations.localeOf(context).languageCode,
        timezone: tz,
      );
      if (option.isCouple) {
        form.emoji = '💞';
        form.title = l10n.journeys_templateCoupleTitle;
      }
      _option = option;
      _deckFocus = _options
          .indexWhere((o) => o.keyName == option.keyName)
          .clamp(0, _options.length - 1);
      _form = form;
      _who = option.isCouple ? CreateWho.couple : CreateWho.solo;
      _applyWho(form);
      _title.text = form.title;
      _duration.text = form.durationDays?.toString() ?? '';
      _metricName.text = form.metricName;
      _metricUnit.text = form.metricUnit;
      _start = null;
      _dnaPage = 0;
      _dna.clear();
      _trophy.clear();
      _place.clear();
      _habit.clear();
      _reason.clear();
      _attempted.clear();
    }
  }

  void _applyWho(JourneyForm form) {
    form.kind = switch (_who) {
      CreateWho.solo => JourneyKind.solo,
      CreateWho.group => JourneyKind.group,
      // Couples are a two-person group journey where a server exists.
      CreateWho.couple => _localOnly ? JourneyKind.solo : JourneyKind.group,
    };
    if (_who != CreateWho.solo) form.soloVisibility = JourneyVisibility.private;
  }

  String get _skinId {
    final form = _form;
    final option = _option;
    if (form == null || option == null) return 'minimal';
    if (_who == CreateWho.couple) return 'couple';
    return uiSkinIdFor(
      personaSkinForTemplate(
        form.template.id,
        kind: form.kind,
        emoji: form.emoji,
      ),
    );
  }

  LocalDate _today(JourneyForm form) => journeyLocalDate(
    ref.read(deviceTimezoneProvider).value ?? form.timezone,
    ref.read(journeysClockProvider).now(),
  );

  void _update(void Function(JourneyForm f) change) =>
      setState(() => change(_form!));

  // Validation per step (null = fine).
  bool _step1Valid(JourneyForm f) {
    final e = f.validate();
    return e.title == null && e.metricName != true;
  }

  bool _step2Valid() =>
      _who != CreateWho.couple ||
      (_nameLeft.text.trim().isNotEmpty && _nameRight.text.trim().isNotEmpty);

  bool _step3Valid(JourneyForm f) => f.validate().duration == null;

  bool _valid(int step) {
    final f = _form;
    if (f == null) return step == 0;
    return switch (step) {
      1 => _step1Valid(f),
      2 => _step2Valid(),
      3 => _step3Valid(f),
      _ => true,
    };
  }

  List<DnaQuestion> get _questions {
    final o = _option;
    if (o == null) return const [];
    return o.isCouple ? dnaCoupleQuestions : dnaQuestionsFor(o.templateId);
  }

  bool get _inDna => _step == 1 && _dnaPage < _questions.length;

  void _next() {
    if (_step == 0) {
      if (_option != null) setState(() => _step = 1);
      return;
    }
    if (_inDna) {
      if (!dnaAnswered(_questions[_dnaPage], _dna)) return;
      _advanceDna();
      return;
    }
    if (!_valid(_step)) {
      setState(() => _attempted.add(_step));
      return;
    }
    setState(() => _step = (_step + 1).clamp(0, _steps - 1));
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else if (_step == 1 && _questions.isNotEmpty && _dnaPage > 0) {
      setState(() => _dnaPage -= 1);
    } else {
      setState(() => _step -= 1);
    }
  }

  /// The title is exactly what the user typed; a couple's names are stored
  /// in their own fields (`journeys.couple_*_name`), not folded into it.
  String _finalTitle(JourneyForm form) => form.title.trim();

  String? get _selfName =>
      _who == CreateWho.couple ? _nameLeft.text.trim() : null;

  String? get _partnerName =>
      _who == CreateWho.couple ? _nameRight.text.trim() : null;

  String? _reminderHHmm() {
    final rt = ReminderTime.tryParse(_suggestion?.reminder);
    if (rt == null) return null;
    return '${rt.hour.toString().padLeft(2, '0')}:'
        '${rt.minute.toString().padLeft(2, '0')}';
  }

  /// DNA answers the server stores (`journeys.dna`); weight and the ghost
  /// photo request stay on the device.
  Map<String, Object?>? _storableDna() {
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final raw = <String, Object?>{
      for (final e in _dna.entries)
        if (e.value is DnaDates)
          e.key: {
            'start': iso((e.value as DnaDates).start),
            if ((e.value as DnaDates).end case final end?) 'end': iso(end),
          }
        else
          e.key: e.value,
    };
    if (raw['minutes'] is int) raw['minutes'] = '${raw['minutes']}';
    return sanitizeJourneyDna(raw);
  }

  Future<void> _submit() async {
    final form = _form;
    if (form == null || _busy) return;
    for (var s = 1; s <= 3; s++) {
      if (!_valid(s)) {
        setState(() {
          _attempted.add(s);
          _step = s;
        });
        return;
      }
    }
    final tz = ref.read(deviceTimezoneProvider).value;
    if (tz != null) form.timezone = tz;
    final repo = ref.read(journeyRepositoryProvider);
    final today = _today(form);
    final start = _start != null && !_start!.isBefore(today) ? _start! : today;
    final reminders = ref.read(reminderSchedulerProvider);
    final title = _finalTitle(form);
    setState(() => _busy = true);
    try {
      final journey = await repo.create(
        JourneyDraft(
          kind: form.kind,
          templateId: form.template.id,
          title: title,
          emoji: form.emoji,
          startDate: start,
          timezone: form.timezone,
          durationDays: form.durationDays,
          metricName: form.trackMetric ? form.metricName.trim() : null,
          metricUnit: form.trackMetric && form.metricUnit.trim().isNotEmpty
              ? form.metricUnit.trim()
              : null,
          hideMetricDefault: form.trackMetric && form.hideMetric,
          visibility: form.visibility,
          id: _clientId,
          coupleSelfName: _selfName,
          couplePartnerName: _partnerName,
          reminderTime: _reminderHHmm(),
          dna: _storableDna(),
        ),
      );
      final rt = ReminderTime.tryParse(_suggestion?.reminder);
      if (rt != null) {
        await ref
            .read(reminderSettingsProvider.notifier)
            .save(journey.id, ReminderSetting(enabled: true, time: rt));
      }
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
      unawaited(ref.read(createProgressProvider.notifier).clear());
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
    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);
    // Keeps the timezone provider alive and rebuilds when it resolves.
    ref.watch(deviceTimezoneProvider);

    final Widget bottom = switch (_step) {
      0 => Padding(
        padding: EdgeInsets.fromLTRB(gutter, UiSpace.sm, gutter, 20),
        // Same type as already chosen (back from step 2, quiz suggestion):
        // "Next" keeps the form; another card is chosen with this button.
        child: _option?.keyName == _options[_deckFocus].keyName
            ? UiButton(
                key: const ValueKey('create-next'),
                label: l10n.journeys_createNext,
                onPressed: _next,
              )
            : UiButton(
                key: const ValueKey('create-choose'),
                label: l10n.journeys_createDeckChoose,
                onPressed: () => _select(_options[_deckFocus]),
              ),
      ),
      _ => Padding(
        padding: EdgeInsets.fromLTRB(gutter, UiSpace.sm, gutter, 20),
        child: UiButton(
          key: ValueKey(_step == _steps - 1 ? 'journey-create' : 'create-next'),
          label: _step == _steps - 1
              ? l10n.journeys_createButton
              : _inDna && _questions[_dnaPage].kind == DnaKind.ghost
              ? l10n.journeys_dna_ghost_now
              : l10n.journeys_createNext,
          loading: _busy,
          onPressed: _step == _steps - 1 ? _submit : _next,
        ),
      ),
    };

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: UiSkinScope(
        skinId: _skinId,
        variant: _variant,
        child: Builder(
          builder: (context) => Stack(
            children: [
              UiScaffold(
                key: const ValueKey('journeys-create-flow'),
                padTop: 0,
                bottom: bottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: UiSpace.md),
                    KeyedSubtree(
                      key: ValueKey('create-step-body-$_step'),
                      child: switch (_step) {
                        0 => _typeStep(context),
                        1 =>
                          _inDna
                              ? _dnaStep(context, _questions[_dnaPage])
                              : _detailStep(context, _form!),
                        2 => _whoStep(context, _form!),
                        3 => _rhythmStep(context, _form!),
                        _ => _reviewStep(context, _form!),
                      },
                    ),
                  ],
                ),
              ),
              if (_busy) const Positioned.fill(child: DnaForge()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final stepLabel = l10n.journeys_createStepOf(_step + 1, _steps);
    return Row(
      children: [
        UiIconButton(
          key: const ValueKey('create-back'),
          glyph: OurneyIcon(name: 'back', size: 22, color: ui.ink),
          iconSize: 22,
          color: ui.ink,
          label: l10n.journeys_back,
          onPressed: _back,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                stepLabel,
                key: const ValueKey('create-step-label'),
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: ui.ink,
                ),
              ),
              const SizedBox(height: 4),
              CreateStepSegments(
                count: _steps,
                current: _step,
                label: stepLabel,
              ),
            ],
          ),
        ),
        UiIconButton(
          key: const ValueKey('create-close'),
          glyph: OurneyIcon(name: 'close', size: 22, color: ui.ink),
          iconSize: 22,
          color: ui.ink,
          label: l10n.journeys_createExit,
          onPressed: () {
            // Leave a "continue creating" card on the Hub (steps 2..5).
            unawaited(
              ref.read(createProgressProvider.notifier).save(_step + 1),
            );
            context.pop();
          },
        ),
      ],
    );
  }

  Widget _heading(BuildContext context, String text, [String? sub]) {
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: UiText.h1(color: ui.ink)),
        ),
        if (sub != null) ...[
          const SizedBox(height: UiSpace.xs),
          Text(sub, style: UiText.muted(color: ui.inkMuted)),
        ],
        const SizedBox(height: UiSpace.lg),
      ],
    );
  }

  Widget _label(BuildContext context, String s) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 7),
    child: Semantics(
      header: true,
      child: Text(s, style: UiText.fieldLabel(color: context.ui.inkMuted)),
    ),
  );

  Widget _note(BuildContext context, String icon, String s) {
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OurneyIcon(name: icon, size: 16, color: ui.inkMuted),
          const SizedBox(width: UiSpace.xs),
          Expanded(
            child: Text(
              s,
              style: UiText.body(size: 12, height: 1.45, color: ui.inkMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step 1: type ----------------------------------------------------

  Widget _typeStep(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final en = Localizations.localeOf(context).languageCode == 'en';
    return KeyedSubtree(
      key: const ValueKey('journeys-template-picker'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
            context,
            l10n.journeys_pickTemplateTitle,
            l10n.journeys_createPickSubtitle,
          ),
          UiButton.ghost(
            key: const ValueKey('create-import-link'),
            label: l10n.journeys_dna_import_link,
            onPressed: () => context.push(AppRoutes.importJourney),
          ),
          CreateTypeDeck(
            items: [
              for (final o in _options)
                () {
                  final tpl = templateFor(o.templateId);
                  final title = o.isCouple
                      ? l10n.journeys_templateCoupleTitle
                      : (en ? tpl.titleEn : tpl.titleVi);
                  final tagline = switch (o.templateId) {
                    _ when o.isCouple => l10n.journeys_tagCouple,
                    TemplateId.weightLoss => l10n.journeys_tagWeightLoss,
                    TemplateId.englishDaily => l10n.journeys_tagEnglish,
                    TemplateId.travel => l10n.journeys_tagTravel,
                    TemplateId.workout30 => l10n.journeys_tagWorkout,
                    TemplateId.custom => l10n.journeys_tagCustom,
                  };
                  final mode = switch (o.templateId) {
                    _ when o.isCouple => l10n.journeys_modeCoupleOnly,
                    TemplateId.weightLoss => l10n.journeys_modeSoloOnly,
                    _ => l10n.journeys_modeSoloGroup,
                  };
                  final days = o.isCustom
                      ? null
                      : l10n.journeys_templateDays(tpl.defaultDurationDays);
                  return CreateDeckItem(
                    keyName: o.keyName,
                    title: title,
                    tagline: tagline,
                    meta: [mode, ?days].join(' · '),
                    badge: o.badge,
                  );
                }(),
            ],
            initial: _deckFocus,
            onFocus: (i) => setState(() => _deckFocus = i),
            onChoose: (i) {
              _deckFocus = i;
              _select(_options[i]);
            },
          ),
        ],
      ),
    );
  }

  // ---- Step 2: DNA questions (V2 `CreateStepTwo`) -------------------------

  void _setDna(String key, Object value) => setState(() => _dna[key] = value);

  void _advanceDna() {
    final q = _questions[_dnaPage];
    if (q.kind == DnaKind.weight) {
      _dna.putIfAbsent('weight', () => dnaWeightDefault);
    }
    if (q.kind == DnaKind.ghost) _dna['ghostRequested'] = true;
    setState(() => _dnaPage += 1);
  }

  void _applyDates(DnaDates d) {
    _setDna('dates', d);
    final today = _today(_form!);
    _start = LocalDate(d.start.year, d.start.month, d.start.day);
    if (_start!.isBefore(today)) _start = today;
    final end = d.end;
    if (end == null) return;
    final n =
        DateUtils.dateOnly(end).difference(DateUtils.dateOnly(d.start)).inDays +
        1;
    if (validateDurationDays(n) == null) {
      _update((f) => f.durationDays = n);
      _duration.text = '$n';
    }
  }

  Widget _dnaStep(BuildContext context, DnaQuestion q) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final Widget body = switch (q.kind) {
      DnaKind.choice => DnaChoiceList(
        question: q,
        value: _dna[q.key] as String?,
        onChanged: (v) => _setDna(q.key, v),
      ),
      DnaKind.weight => DnaWeightPicker(
        weight: (_dna['weight'] as int?) ?? dnaWeightDefault,
        hide: _hideWeight,
        onWeight: (v) => _setDna('weight', v),
        onHide: (v) => setState(() => _hideWeight = v),
        onSkip: _advanceDna,
      ),
      DnaKind.ghost => DnaGhostPage(onLater: _advanceDna),
      DnaKind.trophy => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: OurneyIcon(name: 'trophy', size: 76, color: ui.ink),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('dna-trophy'),
            label: l10n.journeys_dna_trophy_label,
            hint: l10n.journeys_dna_trophy_hint,
            controller: _trophy,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaTrophyMax)],
            helper: '${_trophy.text.length}/$dnaTrophyMax',
            onChanged: (v) => _setDna('trophy', v),
          ),
        ],
      ),
      DnaKind.place => DnaPlacePicker(
        controller: _place,
        place: (_dna['place'] as String?) ?? '',
        onChanged: (v) => _setDna('place', v),
      ),
      DnaKind.dates => DnaDateRange(
        today: DateTime.now(),
        value: _dna['dates'] as DnaDates?,
        locale: locale,
        onChanged: _applyDates,
      ),
      DnaKind.names => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiTextField(
            fieldKey: const ValueKey('dna-name-left'),
            label: l10n.journeys_dna_name_left,
            hint: l10n.journeys_dna_name_left,
            controller: _nameLeft,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaNameMax)],
            onChanged: (v) => _setDna('nameLeft', v),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('dna-name-right'),
            label: l10n.journeys_dna_name_right,
            hint: l10n.journeys_dna_name_right,
            controller: _nameRight,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaNameMax)],
            onChanged: (v) => _setDna('nameRight', v),
          ),
        ],
      ),
      DnaKind.habit => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiTextField(
            fieldKey: const ValueKey('dna-habit'),
            label: l10n.journeys_dna_habit_label,
            hint: l10n.journeys_dna_habit_hint,
            controller: _habit,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaHabitMax)],
            helper: '${_habit.text.length}/$dnaHabitMax',
            onChanged: (v) => _setDna('habit', v),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('dna-reason'),
            label: l10n.journeys_dna_reason_label,
            hint: l10n.journeys_dna_reason_hint,
            controller: _reason,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaReasonMax)],
            helper: '${_reason.text.length}/$dnaReasonMax',
            onChanged: (v) => _setDna('reason', v),
          ),
        ],
      ),
    };
    final total = _questions.length;
    return Column(
      key: ValueKey('dna-page-${q.key}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.xs),
            child: Text(
              l10n.journeys_dna_step_of_q(_dnaPage + 1, total),
              key: const ValueKey('dna-question-count'),
              style: UiText.fieldLabel(color: ui.inkMuted),
            ),
          ),
        _heading(context, dnaText(l10n, q.titleId)),
        body,
      ],
    );
  }

  // ---- Step 2: name + goal ----------------------------------------------

  Widget _detailStep(BuildContext context, JourneyForm form) {
    final l10n = JourneysL10n.of(context);
    final errors = form.validate();
    final show = _attempted.contains(1);
    final titleError = switch (show ? errors.title : null) {
      JourneyTitleError.empty => l10n.journeys_errorTitleEmpty,
      JourneyTitleError.tooLong => l10n.journeys_errorTitleTooLong(
        journeyTitleMax,
      ),
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.journeys_createDetailTitle),
        UiTextField(
          fieldKey: const ValueKey('journey-title'),
          label: l10n.journeys_fieldTitle,
          hint: l10n.journeys_fieldTitle,
          controller: _title,
          error: titleError,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) => _update((f) => f.title = v),
        ),
        _label(context, l10n.journeys_fieldEmoji),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
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
        _label(context, l10n.journeys_fieldMetric),
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
      ],
    );
  }

  // ---- Step 3: who ------------------------------------------------------

  Widget _whoStep(BuildContext context, JourneyForm form) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final localOnly = _localOnly;
    final show = _attempted.contains(2);
    void pick(CreateWho who) => setState(() {
      _who = who;
      _applyWho(form);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.journeys_createWhoTitle),
        CreateChoiceCard(
          key: const ValueKey('journey-kind-solo'),
          title: l10n.journeys_kindSolo,
          body: l10n.journeys_kindSoloBody,
          glyph: OurneyIcon(name: 'profile', size: 30, color: ui.ink),
          selected: _who == CreateWho.solo,
          onPressed: () => pick(CreateWho.solo),
        ),
        const SizedBox(height: UiSpace.sm),
        CreateChoiceCard(
          key: const ValueKey('journey-kind-group'),
          title: l10n.journeys_kindGroup,
          body: l10n.journeys_kindGroupBody,
          glyph: OurneyIcon(name: 'squad', size: 30, color: ui.ink),
          selected: _who == CreateWho.group,
          onPressed: localOnly ? null : () => pick(CreateWho.group),
        ),
        if (localOnly)
          _note(context, 'cloud-off', l10n.journeys_groupNeedsServer),
        const SizedBox(height: UiSpace.sm),
        CreateChoiceCard(
          key: const ValueKey('journey-kind-couple'),
          title: l10n.journeys_kindCouple,
          body: l10n.journeys_kindCoupleBody,
          glyph: OurneyIcon(name: 'heart', size: 30, color: ui.ink),
          selected: _who == CreateWho.couple,
          onPressed: () => pick(CreateWho.couple),
        ),
        if (_who == CreateWho.couple) ...[
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('journey-couple-left'),
            label: l10n.journeys_coupleNameYou,
            controller: _nameLeft,
            error: show && _nameLeft.text.trim().isEmpty
                ? l10n.journeys_errorCoupleNames
                : null,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(18)],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('journey-couple-right'),
            label: l10n.journeys_coupleNameOther,
            controller: _nameRight,
            error: show && _nameRight.text.trim().isEmpty
                ? l10n.journeys_errorCoupleNames
                : null,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(18)],
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  // ---- Step 4: rhythm ---------------------------------------------------

  Widget _rhythmStep(BuildContext context, JourneyForm form) {
    final l10n = JourneysL10n.of(context);
    final localOnly = _localOnly;
    final errors = form.validate();
    final durationError = _attempted.contains(3) && errors.duration != null
        ? l10n.journeys_errorDuration(durationMin, durationMax)
        : null;
    final today = _today(form);
    final start = _start != null && !_start!.isBefore(today) ? _start! : today;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.journeys_createRhythmTitle),
        Text(
          l10n.journeys_fieldDuration,
          style: UiText.fieldLabel(color: context.ui.inkMuted),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final d in journeyDurationChoices)
              CreateDurationChip(
                key: ValueKey('journey-duration-$d'),
                label: l10n.journeys_templateDays(d),
                selected: form.durationDays == d,
                onPressed: () => _update((f) {
                  f.durationDays = d;
                  _duration.text = '$d';
                }),
              ),
            if (form.allowOpenEnded)
              CreateDurationChip(
                key: const ValueKey('journey-duration-open'),
                label: l10n.journeys_openEnded,
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
            f.durationDays = n ?? (f.allowOpenEnded ? null : 0);
          }),
        ),
        _label(context, l10n.journeys_fieldStartDate),
        CreateCalendar(
          today: today,
          start: start,
          days: form.durationDays != null && form.durationDays! > 0
              ? form.durationDays
              : null,
          locale: locale,
          prevLabel: l10n.journeys_calendarPrev,
          nextLabel: l10n.journeys_calendarNext,
          onPick: (d) => setState(() => _start = d),
        ),
        _label(context, l10n.journeys_fieldVisibility),
        if (_who == CreateWho.solo) ...[
          Wrap(
            spacing: UiSpace.sm,
            runSpacing: UiSpace.sm,
            children: [
              UiChip(
                key: const ValueKey('journey-visibility-private'),
                label: l10n.journeys_visibilityPrivate,
                glyph: const OurneyIcon(name: 'lock', size: 16),
                selected: form.soloVisibility == JourneyVisibility.private,
                onPressed: () => _update(
                  (f) => f.soloVisibility = JourneyVisibility.private,
                ),
              ),
              UiChip(
                key: const ValueKey('journey-visibility-link'),
                label: l10n.journeys_visibilityLink,
                glyph: const OurneyIcon(name: 'share', size: 16),
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
            _note(context, 'cloud-off', l10n.journeys_linkNeedsServer),
        ] else
          _note(
            context,
            'lock',
            _who == CreateWho.group
                ? l10n.journeys_visibilityGroup
                : l10n.journeys_kindCouple,
          ),
      ],
    );
  }

  // ---- Step 5: review ---------------------------------------------------

  Widget _reviewStep(BuildContext context, JourneyForm form) {
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).toString();
    final days = form.durationDays;
    final hasDays = days != null && days > 0;
    final skinId = _skinId;
    final metric = form.trackMetric ? form.metricName.trim() : '';
    final goalLine = metric.isNotEmpty
        ? (form.metricUnit.trim().isEmpty
              ? metric
              : '$metric (${form.metricUnit.trim()})')
        : switch (form.template.id) {
            _ when _option!.isCouple || _who == CreateWho.couple =>
              l10n.journeys_tagCouple,
            TemplateId.weightLoss => l10n.journeys_tagWeightLoss,
            TemplateId.englishDaily => l10n.journeys_tagEnglish,
            TemplateId.travel => l10n.journeys_tagTravel,
            TemplateId.workout30 => l10n.journeys_tagWorkout,
            _ => l10n.journeys_tagCustom,
          };
    final today = _today(form);
    final start = _start != null && !_start!.isBefore(today) ? _start! : today;
    final fmt = DateFormat.MMMd(locale);
    String d(LocalDate x) => fmt.format(DateTime(x.year, x.month, x.day));
    final datesLabel = hasDays
        ? l10n.journeys_ticketDates(d(start), d(start.addDays(days - 1)))
        : l10n.journeys_ticketDatesOpen(d(start));
    final milestones = !hasDays || days < 3
        ? const <String>[]
        : {
            for (final n in [7, days ~/ 2, days])
              if (n >= 1 && n <= days) l10n.journeys_ticketMilestone('$n'),
          }.toList();
    final title = _finalTitle(form);
    final couple = _who == CreateWho.couple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.journeys_createReviewTitle),
        KeyedSubtree(
          key: const ValueKey('journey-create-design-preview'),
          child: Semantics(
            container: true,
            label: l10n.journeys_ticketPreview,
            child: AnimatedSwitcher(
              duration: UiMotion.of(context, UiMotion.theme),
              child: DepartureTicket(
                key: ValueKey('ticket-$skinId'),
                skinId: skinId,
                variant: _variant,
                title: title,
                goalLine: goalLine,
                durationLabel: hasDays
                    ? l10n.journeys_templateDays(days)
                    : l10n.journeys_ticketOpenEnded,
                datesLabel: datesLabel,
                milestones: milestones,
                leftName: couple && _nameLeft.text.trim().isNotEmpty
                    ? _nameLeft.text.trim()
                    : l10n.journeys_ticketYou,
                rightName: couple && _nameRight.text.trim().isNotEmpty
                    ? _nameRight.text.trim()
                    : l10n.journeys_ticketPartner,
                privateLabel: l10n.journeys_ticketPrivate,
                memoryLabel: l10n.journeys_ticketMemory,
                tagline: switch (skinId) {
                  'quiet' => l10n.journeys_ticketTagQuiet,
                  'squad' => l10n.journeys_ticketTagSquad,
                  'memory' => l10n.journeys_ticketTagMemory,
                  'couple' => l10n.journeys_ticketTagCouple,
                  'flexer' => l10n.journeys_ticketTagFlexer,
                  _ => '',
                },
                changeVariantLabel: l10n.journeys_ticketChangeColor,
                onChangeVariant: () =>
                    setState(() => _variant = (_variant + 1) % 3),
              ),
            ),
          ),
        ),
        const SizedBox(height: UiSpace.md),
        UiButton.secondary(
          key: const ValueKey('create-review-edit'),
          label: l10n.journeys_createReviewEdit,
          onPressed: () => setState(() => _step = 3),
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
          color: selected ? createSelectedFill(ui) : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(
            color: selected ? ui.outline : ui.border,
            width: selected ? 3 : 1,
          ),
        ),
        child: uiJourneyGlyph(emoji, template, size: 26, color: ui.ink),
      ),
    );
  }
}
