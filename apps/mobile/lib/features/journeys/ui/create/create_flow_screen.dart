import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/providers.dart';
import '../../../../ui/ui.dart';
import '../../../onboarding/onboarding_providers.dart';
import '../../../profile/share_privacy_sync.dart';
import '../../../reminders/data/reminder_scheduler.dart';
import '../../../reminders/data/reminder_settings.dart';
import '../../../reminders/domain/reminder_plan.dart';
import '../../../reminders/ui/reminder_permission_prompt.dart';
import '../../data/create_progress.dart';
import '../../data/journeys_providers.dart';
import '../../domain/journey_form.dart';
import '../../domain/journey_time.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_errors.dart';
import 'create_flow_header.dart';
import 'create_type_option.dart';
import 'dna_pages.dart';
import 'dna_questions.dart';
import 'steps/detail_step.dart';
import 'steps/dna_step.dart';
import 'steps/review_step.dart';
import 'steps/rhythm_step.dart';
import 'steps/type_step.dart';
import 'steps/who_step.dart';

/// **Create journey**, V2 five-step flow (`/journeys/new`):
/// 1 type, 2 name + goal (+ icon, tracked number), 3 who (+ couple names),
/// 4 rhythm (duration, start date, visibility), 5 review on the departure
/// ticket and **Bắt đầu hành trình**.
///
/// All state lives in one [JourneyForm] plus the few flow fields below, so
/// going back keeps every answer. The journey is created through
/// `JourneyRepository.create` exactly like the quick setup.
///
/// A fresh visit (`/journeys/new`) always starts empty; only the Hub's
/// "Continue creating" card (`?resume=1`, [resume]) restores the saved draft.
class CreateFlowScreen extends ConsumerStatefulWidget {
  const CreateFlowScreen({
    this.resume = false,
    this.initialWho,
    super.key,
  });

  /// Reopen the saved draft (U8) instead of starting over.
  final bool resume;

  /// Preselected value for step 3 ("Who is coming along?", e.g. `?who=group`
  /// when launched from a friend's sheet, DE-20).
  final CreateWho? initialWho;

  static CreateWho? parseWho(String? raw) => switch (raw) {
    'solo' => CreateWho.solo,
    'group' => CreateWho.group,
    'couple' => CreateWho.couple,
    _ => null,
  };

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
  int _direction = 1;

  /// Focused card of the step-1 type deck.
  int _deckFocus = 0;

  /// Step-2 "DNA" question page; equal to the question count = the form.
  int _dnaPage = 0;
  final Map<String, Object> _dna = {};
  CreateTypeOption? _option;
  JourneyForm? _form;
  CreateWho _who = CreateWho.solo;
  LocalDate? _start;
  int _variant = 0;
  bool _busy = false;

  /// Steps whose Next was pressed: only then show their errors.
  final Set<int> _attempted = {};

  /// One id per flow: a retry after a lost response returns the same journey.
  /// Saved in the draft so a resumed submit reuses it too (U8).
  String _clientId = const Uuid().v4();

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

  /// The quiz's reminder time ("HH:mm"); kept in the draft so a resumed flow
  /// still turns it on (U8).
  String? _reminder;

  /// Quiz-derived defaults (type, who, reminder); applied once, overridable.
  bool _suggestionApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_suggestionApplied) return;
    _suggestionApplied = true;
    // "Continue creating" (U8): reopen where the flow was left.
    final draft = widget.resume
        ? ref.read(createProgressProvider.notifier).readDraft()
        : null;
    if (draft != null && _restore(draft)) return;
    final s = ref.read(journeySuggestionProvider);
    if (s == null) return;
    _reminder = s.reminder;
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
    setState(() {
      _direction = 1;
      _step = 1;
    });
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
      final defaultWho =
          !_localOnly && widget.initialWho != null
          ? widget.initialWho!
          : CreateWho.solo;
      _who = option.isCouple ? CreateWho.couple : defaultWho;
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

  /// Couple chosen at step 1 (the couple card) or at step 3 (who).
  bool get _isCouple => _who == CreateWho.couple;

  String get _skinId {
    if (_step == 0 && _options.isNotEmpty) {
      final focusedOption = _options[_deckFocus.clamp(0, _options.length - 1)];
      if (focusedOption.isCouple) return 'couple';
      return uiSkinIdFor(personaSkinForTemplate(focusedOption.templateId));
    }
    final form = _form;
    final option = _option;
    if (form == null || option == null) return 'minimal';
    if (_isCouple) return 'couple';
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

  /// [_today] as a calendar `DateTime` (local midnight) for the date pages.
  DateTime _todayDate(JourneyForm form) {
    final t = _today(form);
    return DateTime(t.year, t.month, t.day);
  }

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
      if (_option != null) {
        setState(() {
          _direction = 1;
          _step = 1;
        });
      }
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
    setState(() {
      _direction = 1;
      _step = (_step + 1).clamp(0, _steps - 1);
    });
  }

  void _back() {
    if (_busy) return;
    if (_step == 0) {
      _leaveFlow();
    } else if (_step == 1 && _questions.isNotEmpty && _dnaPage > 0) {
      setState(() {
        _direction = -1;
        _dnaPage -= 1;
      });
    } else {
      setState(() {
        _direction = -1;
        _step -= 1;
      });
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
    final rt = ReminderTime.tryParse(_reminder);
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
          _direction = s < _step ? -1 : 1;
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
    // Read before any await: the screen may be gone when the work finishes.
    final progress = ref.read(createProgressProvider.notifier);
    final activeJourney = ref.read(activeJourneyIdProvider.notifier);
    final title = _finalTitle(form);
    var extrasRejected = false;
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
          // What the review ticket showed (bugs B-B10, B-B12): the colour
          // variant, and the couple skin whatever template or emoji.
          color: _variant,
          layout: _isCouple ? PersonaSkinId.coupleRituals : null,
        ),
        onExtrasRejected: () => extrasRejected = true,
      );
      // The journey exists: the saved draft must not resurrect it (U8).
      unawaited(progress.clear());
      if (mounted && extrasRejected) {
        showJourneySnack(
          context,
          JourneysL10n.of(context).journeys_createSettingsNotSaved,
        );
      }
      final rt = ReminderTime.tryParse(_reminder);
      if (rt != null) {
        await ref
            .read(reminderSettingsProvider.notifier)
            .save(journey.id, ReminderSetting(enabled: true, time: rt));
      }
      unawaited(reminders.reschedule());
      final privacy = newMembershipPrivacy(
        ref,
        journey,
        hideMetric: form.trackMetric && form.hideMetric,
        blurMedia: form.blurOnShare,
      );
      if (privacy.hideMetric || privacy.blurMedia) {
        try {
          await repo.updateMyMembership(
            journey.id,
            hideMetric: privacy.hideMetric ? true : null,
            blurMedia: privacy.blurMedia ? true : null,
          );
        } on Object catch (e) {
          if (mounted) {
            showJourneySnack(context, journeyErrorMessage(context, e));
          }
        }
      }
      if (!mounted) return;
      // The quiz turned a reminder on: offer the OS permission now, or the
      // scheduler has nothing it may post (bug #7).
      if (rt != null) await offerReminderPermission(context, ref, time: rt);
      if (!mounted) return;
      unawaited(activeJourney.select(journey.id));
      context.go(AppRoutes.journey(journey.id));
    } on Object catch (e) {
      final root = rootError(e);
      if (kDebugMode) {
        debugPrint(
          'createJourney failed: code=${root is OurneyException ? root.code : 'n/a'} '
          'detail=${root is OurneyException ? root.detail : null} original=$e',
        );
      }
      if (!mounted) return;
      setState(() => _busy = false);
      showJourneySnack(context, journeyErrorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);
    // Keeps the timezone provider alive and rebuilds when it resolves.
    ref.watch(deviceTimezoneProvider);

    // At large text scales the pinned CTA is clamped to 1.35x and compact so
    // it never swallows the scrolling content above it.
    final big = MediaQuery.textScalerOf(context).scale(16) / 16 > 1.35;
    Widget cta(Widget button) => Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        big ? UiSpace.xs : UiSpace.sm,
        gutter,
        big ? 10 : 20,
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.35,
        child: button,
      ),
    );

    final Widget bottom = switch (_step) {
      0 => cta(
        // Same type as already chosen (back from step 2, quiz suggestion):
        // "Next" keeps the form; another card is chosen with this button.
        _option?.keyName == _options[_deckFocus].keyName
            ? UiButton(
                key: const ValueKey('create-next'),
                label: l10n.journeys_createNext,
                compact: big,
                onPressed: _next,
              )
            : UiButton(
                key: const ValueKey('create-choose'),
                label: l10n.journeys_createDeckChoose,
                compact: big,
                onPressed: () => _select(_options[_deckFocus]),
              ),
      ),
      _ => cta(
        UiButton(
          compact: big,
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
        if (!didPop) {
          _back();
        } else if (!_leaving && widget.resume) {
          // System back from step 1 of a resumed flow: nothing to resume
          // any more (U8). A fresh visit keeps the older draft. The route
          // may be going away during a build: update after it.
          final progress = ref.read(createProgressProvider.notifier);
          unawaited(Future(progress.clear));
        }
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
                    CreateFlowHeader(
                      step: _step,
                      steps: _steps,
                      onBack: _back,
                      // Leave a "continue creating" card on the Hub (steps
                      // 2..5) that really reopens this step (U8).
                      onClose: _leaveFlow,
                    ),
                    const SizedBox(height: UiSpace.md),
                    UiDirectionalSwitcher(
                      step: 'create-step-$_step-${_step == 1 ? _dnaPage : 0}',
                      direction: _direction,
                      duration: UiMotion.medium,
                      slideOffset: 18.0,
                      child: KeyedSubtree(
                        key: ValueKey(
                          'create-step-$_step-${_step == 1 ? _dnaPage : 0}',
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('create-step-body-$_step'),
                          child: switch (_step) {
                            0 => CreateTypeStep(
                              options: _options,
                              deckFocus: _deckFocus,
                              onFocus: (i) => setState(() => _deckFocus = i),
                              onChoose: (i) {
                                _deckFocus = i;
                                _select(_options[i]);
                              },
                            ),
                            1 =>
                              _inDna
                                  ? CreateDnaStep(
                                      question: _questions[_dnaPage],
                                      dnaPage: _dnaPage,
                                      totalQuestions: _questions.length,
                                      dna: _dna,
                                      hideWeight: _form!.hideMetric,
                                      trophyController: _trophy,
                                      placeController: _place,
                                      nameLeftController: _nameLeft,
                                      nameRightController: _nameRight,
                                      habitController: _habit,
                                      reasonController: _reason,
                                      onSetDna: _setDna,
                                      // The toggle is the journey's hide-number
                                      // default (bug B-B12).
                                      onHideWeightChanged: (v) =>
                                          _update((f) => f.hideMetric = v),
                                      onAdvanceDna: _advanceDna,
                                      onApplyDates: _applyDates,
                                      today: _todayDate(_form!),
                                    )
                                  : CreateDetailStep(
                                      form: _form!,
                                      titleController: _title,
                                      metricNameController: _metricName,
                                      metricUnitController: _metricUnit,
                                      showErrors: _attempted.contains(1),
                                      onUpdate: _update,
                                    ),
                            2 => CreateWhoStep(
                              who: _who,
                              localOnly: _localOnly,
                              showErrors: _attempted.contains(2),
                              nameLeftController: _nameLeft,
                              nameRightController: _nameRight,
                              onPick: (who) => setState(() {
                                _who = who;
                                _applyWho(_form!);
                              }),
                              onNamesChanged: () => setState(() {}),
                            ),
                            3 => CreateRhythmStep(
                              form: _form!,
                              who: _who,
                              localOnly: _localOnly,
                              showErrors: _attempted.contains(3),
                              today: _today(_form!),
                              start: _start,
                              durationController: _duration,
                              onUpdate: _update,
                              onPickStart: (d) => setState(() => _start = d),
                            ),
                            _ => CreateReviewStep(
                              form: _form!,
                              who: _who,
                              optionIsCouple: _option!.isCouple,
                              skinId: _skinId,
                              title: _finalTitle(_form!),
                              variant: _variant,
                              today: _today(_form!),
                              start: _start,
                              nameLeftController: _nameLeft,
                              nameRightController: _nameRight,
                              onChangeVariant: () {
                                unawaited(UiHaptics.selection());
                                setState(() => _variant = (_variant + 1) % 3);
                              },
                              onEdit: () => setState(() {
                                _direction = -1;
                                _step = 3;
                              }),
                            ),
                          },
                        ),
                      ),
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

  // ---- Saved progress ("continue creating", U8) ----------------------------

  static String _iso(DateTime d) =>
      LocalDate(d.year, d.month, d.day).toString();

  /// Everything needed to reopen the flow on this step.
  Map<String, Object?> _snapshot() {
    final form = _form!;
    return {
      'v': 1,
      'clientId': _clientId,
      'reminder': _reminder,
      'option': _option!.keyName,
      'step': _step,
      'dnaPage': _dnaPage,
      'dna': {
        for (final e in _dna.entries)
          e.key: e.value is DnaDates
              ? {
                  'start': _iso((e.value as DnaDates).start),
                  if ((e.value as DnaDates).end case final end?)
                    'end': _iso(end),
                }
              : e.value,
      },
      'title': form.title,
      'emoji': form.emoji,
      'durationDays': form.durationDays,
      'trackMetric': form.trackMetric,
      'metricName': form.metricName,
      'metricUnit': form.metricUnit,
      'hideMetric': form.hideMetric,
      'blurOnShare': form.blurOnShare,
      'soloVisibility': form.soloVisibility.wireName,
      'who': _who.name,
      'nameLeft': _nameLeft.text,
      'nameRight': _nameRight.text,
      'trophy': _trophy.text,
      'place': _place.text,
      'habit': _habit.text,
      'reason': _reason.text,
      'start': _start?.toString(),
      'variant': _variant,
    };
  }

  /// Restores a [_snapshot]; false (nothing changed) when it is unusable.
  bool _restore(Map<String, Object?> d) {
    try {
      final option = _options.firstWhere((o) => o.keyName == d['option']);
      _apply(option);
      final form = _form!;
      if (d['clientId'] case final String id when id.isNotEmpty) {
        _clientId = id;
      }
      _reminder = d['reminder'] as String?;
      form
        ..title = d['title']! as String
        ..emoji = d['emoji']! as String
        ..durationDays = d['durationDays'] as int?
        ..trackMetric = d['trackMetric']! as bool
        ..metricName = d['metricName']! as String
        ..metricUnit = d['metricUnit']! as String
        ..hideMetric = d['hideMetric']! as bool
        ..blurOnShare = d['blurOnShare']! as bool
        ..soloVisibility = JourneyVisibility.fromWire(
          d['soloVisibility']! as String,
        );
      final who = CreateWho.values.byName(d['who']! as String);
      _who = _localOnly && who == CreateWho.group ? CreateWho.solo : who;
      _applyWho(form);
      _title.text = form.title;
      _duration.text = form.durationDays?.toString() ?? '';
      _metricName.text = form.metricName;
      _metricUnit.text = form.metricUnit;
      _nameLeft.text = d['nameLeft'] as String? ?? '';
      _nameRight.text = d['nameRight'] as String? ?? '';
      _trophy.text = d['trophy'] as String? ?? '';
      _place.text = d['place'] as String? ?? '';
      _habit.text = d['habit'] as String? ?? '';
      _reason.text = d['reason'] as String? ?? '';
      _dna.clear();
      for (final e in (d['dna']! as Map<String, Object?>).entries) {
        final v = e.value;
        if (v is Map<String, Object?>) {
          LocalDate? date(Object? x) => x is String ? LocalDate.parse(x) : null;
          final start = date(v['start'])!;
          final end = date(v['end']);
          _dna[e.key] = DnaDates(
            DateTime(start.year, start.month, start.day),
            end == null ? null : DateTime(end.year, end.month, end.day),
          );
        } else if (v != null) {
          _dna[e.key] = v;
        }
      }
      final start = d['start'];
      _start = start is String ? LocalDate.parse(start) : null;
      _variant = ((d['variant'] as int?) ?? 0).clamp(0, 2);
      _dnaPage = ((d['dnaPage'] as int?) ?? 0).clamp(0, _questions.length);
      _step = ((d['step'] as int?) ?? 1).clamp(1, _steps - 1);
      return true;
    } on Object {
      // Older or broken draft: start over (and forget it).
      _option = null;
      _form = null;
      _who = CreateWho.solo;
      _dna.clear();
      _step = 0;
      unawaited(ref.read(createProgressProvider.notifier).clear());
      return false;
    }
  }

  /// Set while [_leaveFlow] pops the route.
  bool _leaving = false;

  /// Leaving the flow: keep a resumable draft from step 2 on. Before that, a
  /// fresh visit leaves the saved draft be; only a resumed flow clears it so
  /// the Hub card does not linger (U8).
  void _leaveFlow() {
    if (_busy) return; // The journey is being created: stay for the result.
    _leaving = true;
    final progress = ref.read(createProgressProvider.notifier);
    if (_step == 0 || _form == null || _option == null) {
      // A fresh visit that never got past step 1 leaves the saved draft be.
      if (widget.resume) unawaited(progress.clear());
    } else {
      unawaited(progress.save(_step + 1, draft: _snapshot()));
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.journeys);
    }
  }

  // ---- Step 2: DNA questions (V2 `CreateStepTwo`) -------------------------

  void _setDna(String key, Object value) => setState(() => _dna[key] = value);

  void _advanceDna() {
    final q = _questions[_dnaPage];
    if (q.kind == DnaKind.weight) {
      _dna.putIfAbsent('weight', () => dnaWeightDefault);
    }
    if (q.kind == DnaKind.ghost) _dna['ghostRequested'] = true;
    setState(() {
      _direction = 1;
      _dnaPage += 1;
    });
  }

  void _applyDates(DnaDates d) {
    _setDna('dates', d);
    final today = _today(_form!);
    _start = LocalDate(d.start.year, d.start.month, d.start.day);
    if (_start!.isBefore(today)) _start = today;
    final end = d.end;
    if (end == null) {
      // "No return date yet": an open-ended trip (bug B-B11).
      _update((f) => f.durationDays = null);
      _duration.text = '';
      return;
    }
    final n = dnaTripDays(d.start, end);
    _update((f) => f.durationDays = n);
    _duration.text = '$n';
  }
}
