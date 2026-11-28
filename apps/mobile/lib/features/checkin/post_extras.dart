import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../shared/places/place_picker.dart';
import '../../ui/ui.dart';
import 'l10n/generated/checkin_localizations.dart';

/// Wire values of `extras.mood` (stable across locales).
const List<String> postMoodCodes = ['light', 'normal', 'tired'];

/// Quick picks of the study-time chips (Figma squad Post).
const List<int> postMinuteChoices = [15, 30, 45, 60];

typedef PostExtrasDraft = ({
  String? mood,
  int? minutes,
  bool customMinutes,
  int? hearts,
  String? cook,
  String paceDigits,
  String place,
  String dish,
  String km,
});

/// Holds the per-skin Post inputs of one check-in. The screen owns it, the
/// section below edits it, and [extras] is what is posted.
class PostExtrasController extends ChangeNotifier {
  PostExtrasController({CheckInExtras initial = CheckInExtras.empty})
    : mood = initial.mood,
      minutes = initial.minutes,
      hearts = initial.hearts,
      cook = initial.cook,
      _paceDigits = initial.pace ?? '';

  final TextEditingController place = TextEditingController();
  final TextEditingController dish = TextEditingController();

  /// Flexer distance as typed (`5.3` or `5,3`).
  final TextEditingController km = TextEditingController();

  String? mood;
  int? minutes;
  bool customMinutes = false;
  int? hearts;
  String? cook;
  String _paceDigits;

  String get paceDigits => _paceDigits;

  PostExtrasDraft get draft => (
    mood: mood,
    minutes: minutes,
    customMinutes: customMinutes,
    hearts: hearts,
    cook: cook,
    paceDigits: _paceDigits,
    place: place.text,
    dish: dish.text,
    km: km.text,
  );

  void restoreDraft(PostExtrasDraft draft) {
    mood = draft.mood;
    minutes = draft.minutes;
    customMinutes = draft.customMinutes;
    hearts = draft.hearts;
    cook = draft.cook;
    _paceDigits = draft.paceDigits;
    place.text = draft.place;
    dish.text = draft.dish;
    km.text = draft.km;
  }

  /// `m:ss` once something is typed, otherwise empty.
  String get paceText => _paceDigits;

  void setPaceParts(String minutes, String seconds) {
    _paceDigits = minutes.isEmpty && seconds.isEmpty
        ? ''
        : '$minutes:${seconds.padLeft(2, '0')}';
    notifyListeners();
  }

  bool get paceMinutesInvalid =>
      _paceDigits.isNotEmpty &&
      (int.tryParse(paceText.split(':').first) ?? 0) < 1;

  bool get paceInvalid =>
      _paceDigits.isNotEmpty &&
      (paceMinutesInvalid || CheckInExtras(pace: paceText).validate() != null);

  /// Parsed distance, null when empty or not a number.
  double? get kmValue {
    final t = km.text.trim().replaceAll(',', '.');
    final value = double.tryParse(t);
    return value == null || !value.isFinite ? null : roundKm(value);
  }

  /// Something is typed but it is not a valid distance (0.1..500, one decimal).
  bool get kmInvalid {
    if (km.text.trim().isEmpty) return false;
    final v = kmValue;
    return v == null || CheckInExtras(km: v).validate() != null;
  }

  void pickMood(String? value) {
    mood = mood == value ? null : value;
    notifyListeners();
  }

  void pickMinutes(int? value, {bool custom = false}) {
    minutes = value;
    customMinutes = custom;
    notifyListeners();
  }

  void pickHearts(int value) {
    hearts = hearts == value ? null : value;
    notifyListeners();
  }

  void pickCook(String value) {
    cook = cook == value ? null : value;
    notifyListeners();
  }

  /// Only the inputs of [skin] count: a stale value of another skin is
  /// never posted.
  CheckInExtras extrasFor(
    PersonaSkinId skin, {
    bool isRunning = true,
  }) => switch (skin) {
    PersonaSkinId.quietTransformer => CheckInExtras(mood: mood),
    PersonaSkinId.accountabilitySquad => CheckInExtras(minutes: minutes),
    PersonaSkinId.memoryCollectors => CheckInExtras(place: place.text),
    PersonaSkinId.coupleRituals => CheckInExtras(
      dish: dish.text,
      cook: cook,
      hearts: hearts,
    ),
    PersonaSkinId.aestheticFlexer =>
      isRunning
          ? CheckInExtras(
              pace: _paceDigits.isEmpty ? null : paceText,
              km: kmValue,
            )
          : CheckInExtras(minutes: minutes),
    PersonaSkinId.minimalistHabit => CheckInExtras.empty,
  }.normalized();

  @override
  void dispose() {
    place.dispose();
    dish.dispose();
    km.dispose();
    super.dispose();
  }
}

/// The skin-specific inputs under the caption (Figma Post screens).
class PostExtrasSection extends StatelessWidget {
  const PostExtrasSection({
    required this.skin,
    required this.controller,
    required this.selfName,
    required this.partnerName,
    this.ritual,
    this.isRunning = true,
    this.destination,
    this.recentPlaces = const [],
    super.key,
  });

  final PersonaSkinId skin;
  final PostExtrasController controller;

  /// Couple names of the journey (null: the localized You / Partner).
  final String? selfName;
  final String? partnerName;

  /// Couple ritual code (`cook`, `save`, `ldr`, `custom`).
  final String? ritual;

  /// False when a workout journey is non-running (gym, pilates, yoga, etc.).
  final bool isRunning;
  final String? destination;
  final List<String> recentPlaces;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final child = switch (skin) {
          PersonaSkinId.quietTransformer => _MoodPicker(controller),
          PersonaSkinId.accountabilitySquad => _MinutesPicker(controller),
          PersonaSkinId.memoryCollectors => _PlaceField(
            controller.place,
            destination: destination,
            recent: recentPlaces,
          ),
          PersonaSkinId.coupleRituals => _CoupleInputs(
            controller: controller,
            selfName: selfName,
            partnerName: partnerName,
            ritual: ritual,
          ),
          PersonaSkinId.aestheticFlexer =>
            isRunning ? _FlexerInputs(controller) : _MinutesPicker(controller),
          PersonaSkinId.minimalistHabit => null,
        };
        if (child == null) return const SizedBox.shrink();
        final ui = context.ui;
        return Padding(
          padding: const EdgeInsets.only(top: UiSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  CheckinL10n.of(context).checkin_details,
                  key: const ValueKey('checkin-details'),
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    height: 1.4,
                    color: ui.ink,
                  ),
                ),
              ),
              const SizedBox(height: UiSpace.md),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker(this.c);

  final PostExtrasController c;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final labels = {
      'light': l10n.checkin_extraMoodLight,
      'normal': l10n.checkin_extraMoodNormal,
      'tired': l10n.checkin_extraMoodTired,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.checkin_extraMoodLabel,
          style: UiText.fieldLabel(color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.sm),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final code in postMoodCodes)
              UiChip(
                key: ValueKey('checkin-mood-$code'),
                label: labels[code]!,
                selected: c.mood == code,
                glyph: c.mood == code
                    ? const OurneyIcon(name: 'check', size: 16)
                    : null,
                onPressed: () => c.pickMood(code),
              ),
          ],
        ),
      ],
    );
  }
}

class _MinutesPicker extends StatelessWidget {
  const _MinutesPicker(this.c);

  final PostExtrasController c;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final custom = c.customMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.checkin_extraMinutesLabel,
          style: UiText.fieldLabel(color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.sm),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final m in postMinuteChoices)
              UiChip(
                key: ValueKey('checkin-minutes-$m'),
                label: '$m',
                selected: !custom && c.minutes == m,
                onPressed: () => c.pickMinutes(m),
              ),
            UiChip(
              key: const ValueKey('checkin-minutes-other'),
              label: l10n.checkin_extraMinutesOther,
              selected: custom,
              onPressed: () => c.pickMinutes(c.minutes ?? 45, custom: true),
            ),
          ],
        ),
        if (custom)
          Padding(
            padding: const EdgeInsets.only(top: UiSpace.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UiIconButton(
                  key: const ValueKey('checkin-minutes-less'),
                  glyph: const OurneyIcon(name: 'minus', size: 22),
                  label: l10n.checkin_extraMinutesLess,
                  onPressed: () => c.pickMinutes(
                    ((c.minutes ?? 45) - 5).clamp(5, 180),
                    custom: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
                  child: Text(
                    l10n.checkin_extraMinutesValue(c.minutes ?? 45),
                    key: const ValueKey('checkin-minutes-custom'),
                    style: UiText.h2(color: ui.ink, size: 20),
                  ),
                ),
                UiIconButton(
                  key: const ValueKey('checkin-minutes-more'),
                  glyph: const OurneyIcon(name: 'plus', size: 22),
                  label: l10n.checkin_extraMinutesMore,
                  onPressed: () => c.pickMinutes(
                    ((c.minutes ?? 45) + 5).clamp(5, 180),
                    custom: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlaceField extends StatelessWidget {
  const _PlaceField(
    this.controller, {
    required this.destination,
    required this.recent,
  });

  final TextEditingController controller;
  final String? destination;
  final List<String> recent;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    return PlacePicker(
      fieldKey: const ValueKey('checkin-place'),
      label: l10n.checkin_extraPlaceLabel,
      hint: l10n.checkin_extraPlaceHint,
      controller: controller,
      destination: destination,
      recent: recent,
      maxRunes: extrasPlaceMax,
    );
  }
}

class _CoupleInputs extends StatelessWidget {
  const _CoupleInputs({
    required this.controller,
    required this.selfName,
    required this.partnerName,
    this.ritual,
  });

  final PostExtrasController controller;
  final String? selfName;
  final String? partnerName;
  final String? ritual;

  bool get _isCooking => ritual == null || ritual == 'cook';

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final c = controller;
    final self = selfName ?? l10n.checkin_extraYou;
    final partner = partnerName ?? l10n.checkin_extraPartner;
    final cooking = _isCooking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiTextField(
          fieldKey: const ValueKey('checkin-dish'),
          label: cooking
              ? l10n.checkin_extraDishLabel
              : l10n.checkin_extraMomentLabel,
          hint: cooking
              ? l10n.checkin_extraDishHint
              : l10n.checkin_extraMomentHint,
          controller: c.dish,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: const [CodePointLimitFormatter(extrasDishMax)],
        ),
        if (cooking) ...[
          const SizedBox(height: UiSpace.md),
          Text(
            l10n.checkin_extraCookLabel,
            style: UiText.fieldLabel(color: ui.inkMuted),
          ),
          const SizedBox(height: UiSpace.sm),
          Wrap(
            spacing: UiSpace.sm,
            runSpacing: UiSpace.sm,
            children: [
              for (final name in {self, partner})
                UiChip(
                  key: ValueKey('checkin-cook-$name'),
                  label: name,
                  selected: c.cook == name,
                  glyph: c.cook == name
                      ? const OurneyIcon(name: 'check', size: 16)
                      : null,
                  onPressed: () => c.pickCook(name),
                ),
            ],
          ),
        ],
        const SizedBox(height: UiSpace.md),
        Text(
          cooking
              ? l10n.checkin_extraHeartsLabel
              : l10n.checkin_extraHeartsMomentLabel,
          style: UiText.fieldLabel(color: ui.inkMuted),
        ),
        Row(
          children: [
            for (var i = 1; i <= extrasHeartsMax; i++)
              UiIconButton(
                key: ValueKey('checkin-heart-$i'),
                // On: accent sticker; off: quiet line heart.
                glyph: i <= (c.hearts ?? 0)
                    ? OurneyIcon(
                        name: 'heart',
                        size: 26,
                        color: ui.accent,
                        inkColor: ui.ink,
                      )
                    : OurneyIcon(
                        name: 'heart',
                        size: 26,
                        flat: true,
                        color: ui.inkMuted,
                      ),
                label: l10n.checkin_extraHeartsValue(i),
                onPressed: () => c.pickHearts(i),
              ),
          ],
        ),
      ],
    );
  }
}

/// Distance and pace use the same system number keyboard.
class _FlexerInputs extends StatelessWidget {
  const _FlexerInputs(this.c);

  final PostExtrasController c;

  @override
  Widget build(BuildContext context) {
    final l = CheckinL10n.of(context);
    final ui = context.ui;
    final distance = ListenableBuilder(
      listenable: c.km,
      builder: (context, _) => UiTextField(
        fieldKey: const ValueKey('checkin-km'),
        label: l.checkin_distanceLabel,
        hint: l.checkin_extraKmHint,
        trailing: Center(
          widthFactor: 1,
          child: Text('km', style: UiText.muted(color: ui.inkMuted)),
        ),
        controller: c.km,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
          LengthLimitingTextInputFormatter(6),
        ],
        error: c.kmInvalid ? l.checkin_extraKmInvalid : null,
      ),
    );
    final pace = _PaceFields(c);
    final stack =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(10) > 12;
    return stack
        ? Column(
            key: const ValueKey('checkin-run-inputs-stacked'),
            children: [distance, const SizedBox(height: UiSpace.md), pace],
          )
        : Row(
            key: const ValueKey('checkin-run-inputs-row'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: distance),
              const SizedBox(width: UiSpace.md),
              Expanded(flex: 3, child: pace),
            ],
          );
  }
}

class _PaceFields extends StatefulWidget {
  const _PaceFields(this.c);

  final PostExtrasController c;
  @override
  State<_PaceFields> createState() => _PaceFieldsState();
}

class _PaceFieldsState extends State<_PaceFields> {
  final _minutes = TextEditingController();
  final _seconds = TextEditingController();
  final _secondsFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    if (widget.c.paceText.isNotEmpty) {
      final parts = widget.c.paceText.split(':');
      _minutes.text = parts.first;
      _seconds.text = parts.last;
    }
    _secondsFocus.addListener(_onFocus);
  }

  void _onFocus() {
    if (!_secondsFocus.hasFocus && _seconds.text.isNotEmpty) {
      _seconds.text = _seconds.text.padLeft(2, '0');
      _sync();
    }
  }

  void _sync() => widget.c.setPaceParts(_minutes.text, _seconds.text);

  void _onMinutesChanged(String text) {
    if (text.contains(':')) {
      final parts = text.split(':');
      final minutes = parts.first;
      _minutes.text = minutes.substring(0, math.min(2, minutes.length));
      final seconds = parts[1];
      final parsedSeconds = int.tryParse(seconds);
      if (parsedSeconds != null && parsedSeconds <= 59) {
        _seconds.text = seconds.substring(0, math.min(2, seconds.length));
      }
      _secondsFocus.requestFocus();
    } else if (text.length >= 2 || (int.tryParse(text) ?? 0) >= 2) {
      if (text.length > 2) _minutes.text = text.substring(0, 2);
      _secondsFocus.requestFocus();
    }
    _sync();
  }

  @override
  void dispose() {
    _secondsFocus.removeListener(_onFocus);
    _minutes.dispose();
    _seconds.dispose();
    _secondsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = CheckinL10n.of(context);
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.checkin_paceLabel,
          style: UiText.body(
            size: 14,
            weight: FontWeight.w700,
            height: 1.4,
            color: ui.ink,
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Row(
          children: [
            Expanded(
              child: UiTextField(
                fieldKey: const ValueKey('checkin-pace-minutes'),
                label: l.checkin_paceMinutes,
                hint: l.checkin_paceMinutes,
                showLabel: false,
                controller: _minutes,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9:]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                onSubmitted: (_) => _secondsFocus.requestFocus(),
                onChanged: _onMinutesChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UiSpace.xs),
              child: ExcludeSemantics(
                child: Text(':', style: UiText.body(color: ui.ink)),
              ),
            ),
            Expanded(
              child: UiTextField(
                fieldKey: const ValueKey('checkin-pace-seconds'),
                label: l.checkin_paceSeconds,
                hint: l.checkin_paceSeconds,
                showLabel: false,
                controller: _seconds,
                focusNode: _secondsFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                  TextInputFormatter.withFunction(
                    (old, next) =>
                        next.text.isEmpty || (int.tryParse(next.text) ?? 60) <= 59
                        ? next
                        : old,
                  ),
                ],
                onChanged: (_) => _sync(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: UiSpace.xs),
              child: Text(
                '/km',
                style: UiText.muted(size: 11, color: ui.inkMuted),
              ),
            ),
          ],
        ),
        if (widget.c.paceInvalid)
          Semantics(
            liveRegion: true,
            child: Text(
              widget.c.paceMinutesInvalid
                  ? l.checkin_paceMinutesInvalid
                  : l.checkin_paceInvalid,
              key: const ValueKey('checkin-pace-error'),
              style: UiText.muted(color: ui.danger),
            ),
          ),
      ],
    );
  }
}
