import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../ui/ui.dart';
import 'l10n/generated/checkin_localizations.dart';

/// Wire values of `extras.mood` (stable across locales).
const List<String> postMoodCodes = ['light', 'normal', 'tired'];

/// Quick picks of the study-time chips (Figma squad Post).
const List<int> postMinuteChoices = [15, 30, 45, 60];

/// Pace as typed on the keypad: digits only, `504` reads `5:04`.
String paceFromDigits(String digits) {
  if (digits.isEmpty) return '';
  final padded = digits.padLeft(3, '0');
  final minutes = int.parse(padded.substring(0, padded.length - 2));
  return '$minutes:${padded.substring(padded.length - 2)}';
}

/// Holds the per-skin Post inputs of one check-in. The screen owns it, the
/// section below edits it, and [extras] is what is posted.
class PostExtrasController extends ChangeNotifier {
  PostExtrasController({CheckInExtras initial = CheckInExtras.empty})
    : mood = initial.mood,
      minutes = initial.minutes,
      hearts = initial.hearts,
      cook = initial.cook,
      _paceDigits = (initial.pace ?? '').replaceAll(':', '');

  final TextEditingController place = TextEditingController();
  final TextEditingController dish = TextEditingController();

  /// Flexer distance as typed (`5.3` or `5,3`).
  final TextEditingController km = TextEditingController();

  String? mood;
  int? minutes;
  bool customMinutes = false;
  int? hearts;
  String? cook;
  String? partnerPhotoPath;
  String _paceDigits;

  String get paceDigits => _paceDigits;

  /// `m:ss` once something is typed, otherwise empty.
  String get paceText => paceFromDigits(_paceDigits);

  bool get paceInvalid =>
      _paceDigits.isNotEmpty &&
      CheckInExtras(pace: paceText).validate() != null;

  /// Parsed distance, null when empty or not a number.
  double? get kmValue {
    final t = km.text.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
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

  void setPartnerPhoto(String? path) {
    partnerPhotoPath = path;
    notifyListeners();
  }

  void typeDigit(String digit) {
    if (_paceDigits.length >= 4) return;
    _paceDigits = '$_paceDigits$digit';
    notifyListeners();
  }

  void backspace() {
    if (_paceDigits.isEmpty) return;
    _paceDigits = _paceDigits.substring(0, _paceDigits.length - 1);
    notifyListeners();
  }

  /// Only the inputs of [skin] count: a stale value of another skin is
  /// never posted.
  CheckInExtras extrasFor(PersonaSkinId skin) => switch (skin) {
    PersonaSkinId.quietTransformer => CheckInExtras(mood: mood),
    PersonaSkinId.accountabilitySquad => CheckInExtras(minutes: minutes),
    PersonaSkinId.memoryCollectors => CheckInExtras(place: place.text),
    PersonaSkinId.coupleRituals => CheckInExtras(
      dish: dish.text,
      cook: cook,
      hearts: hearts,
    ),
    PersonaSkinId.aestheticFlexer => CheckInExtras(
      pace: _paceDigits.isEmpty ? null : paceText,
      km: kmValue,
    ),
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
    required this.onPickPartnerPhoto,
    super.key,
  });

  final PersonaSkinId skin;
  final PostExtrasController controller;

  /// Couple names of the journey (null: the localized You / Partner).
  final String? selfName;
  final String? partnerName;
  final VoidCallback onPickPartnerPhoto;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final child = switch (skin) {
          PersonaSkinId.quietTransformer => _MoodPicker(controller),
          PersonaSkinId.accountabilitySquad => _MinutesPicker(controller),
          PersonaSkinId.memoryCollectors => _PlaceField(controller),
          PersonaSkinId.coupleRituals => _CoupleInputs(
            controller: controller,
            selfName: selfName,
            partnerName: partnerName,
            onPickPartnerPhoto: onPickPartnerPhoto,
          ),
          PersonaSkinId.aestheticFlexer => _FlexerInputs(controller),
          PersonaSkinId.minimalistHabit => null,
        };
        if (child == null) return const SizedBox.shrink();
        final ui = context.ui;
        return Padding(
          padding: const EdgeInsets.only(top: UiSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CheckinL10n.of(context).checkin_details,
                key: const ValueKey('checkin-details'),
                style: UiText.fieldLabel(color: ui.inkMuted),
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
                  glyph: Text('−', style: UiText.h2(color: ui.ink, size: 24)),
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
  const _PlaceField(this.c);

  final PostExtrasController c;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    return UiTextField(
      fieldKey: const ValueKey('checkin-place'),
      label: l10n.checkin_extraPlaceLabel,
      hint: l10n.checkin_extraPlaceHint,
      controller: c.place,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [_RuneLimit(extrasPlaceMax)],
    );
  }
}

class _CoupleInputs extends StatelessWidget {
  const _CoupleInputs({
    required this.controller,
    required this.selfName,
    required this.partnerName,
    required this.onPickPartnerPhoto,
  });

  final PostExtrasController controller;
  final String? selfName;
  final String? partnerName;
  final VoidCallback onPickPartnerPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final c = controller;
    final self = selfName ?? l10n.checkin_extraYou;
    final partner = partnerName ?? l10n.checkin_extraPartner;
    final photo = c.partnerPhotoPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiTextField(
          fieldKey: const ValueKey('checkin-dish'),
          label: l10n.checkin_extraDishLabel,
          hint: l10n.checkin_extraDishHint,
          controller: c.dish,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [_RuneLimit(extrasDishMax)],
        ),
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
        const SizedBox(height: UiSpace.md),
        Text(
          l10n.checkin_extraHeartsLabel,
          style: UiText.fieldLabel(color: ui.inkMuted),
        ),
        Row(
          children: [
            for (var i = 1; i <= extrasHeartsMax; i++)
              UiIconButton(
                key: ValueKey('checkin-heart-$i'),
                glyph: OurneyIcon(
                  name: 'heart',
                  size: 26,
                  color: i <= (c.hearts ?? 0) ? ui.accent : ui.fill,
                ),
                label: l10n.checkin_extraHeartsValue(i),
                onPressed: () => c.pickHearts(i),
              ),
          ],
        ),
        const SizedBox(height: UiSpace.sm),
        if (photo == null)
          UiButton.secondary(
            key: const ValueKey('checkin-partner-photo-add'),
            label: l10n.checkin_extraPartnerPhoto,
            glyph: const OurneyIcon(name: 'image-plus', size: 20),
            onPressed: onPickPartnerPhoto,
          )
        else
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.otp),
                child: Semantics(
                  image: true,
                  label: l10n.checkin_extraPartnerPhotoSemantics,
                  child: Image.file(
                    File(photo),
                    key: const ValueKey('checkin-partner-photo'),
                    width: 72,
                    height: 96,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    errorBuilder: (_, _, _) => SizedBox(
                      width: 72,
                      height: 96,
                      child: Center(
                        child: OurneyIcon(
                          name: 'image',
                          flat: true,
                          color: ui.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiTextAction(
                      label: l10n.checkin_extraPartnerPhotoChange,
                      onPressed: onPickPartnerPhoto,
                      alignment: AlignmentDirectional.centerStart,
                      size: 14,
                    ),
                    UiTextAction(
                      key: const ValueKey('checkin-partner-photo-remove'),
                      label: l10n.checkin_extraPartnerPhotoRemove,
                      onPressed: () => c.setPartnerPhoto(null),
                      alignment: AlignmentDirectional.centerStart,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Flexer inputs: distance field above the pace keypad.
class _FlexerInputs extends StatelessWidget {
  const _FlexerInputs(this.c);

  final PostExtrasController c;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    return ListenableBuilder(
      listenable: c.km,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiTextField(
            fieldKey: const ValueKey('checkin-km'),
            label: l10n.checkin_extraKmLabel,
            hint: l10n.checkin_extraKmHint,
            controller: c.km,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(5),
            ],
            error: c.kmInvalid ? l10n.checkin_extraKmInvalid : null,
          ),
          const SizedBox(height: UiSpace.md),
          _PaceKeypad(c),
        ],
      ),
    );
  }
}

/// Pace keypad (Figma flexer Post): digits fill `m:ss` from the right.
class _PaceKeypad extends StatelessWidget {
  const _PaceKeypad(this.c);

  final PostExtrasController c;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final invalid = c.paceInvalid;
    final text = c.paceText.isEmpty ? '0:00' : c.paceText;

    Widget key(String digit) => UiChip(
      key: ValueKey('checkin-pace-key-$digit'),
      label: digit,
      onPressed: () => c.typeDigit(digit),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.checkin_extraPaceLabel,
          style: UiText.fieldLabel(color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.xs),
        Semantics(
          liveRegion: true,
          child: Text(
            text,
            key: const ValueKey('checkin-pace-value'),
            style: UiText.h2(color: invalid ? ui.danger : ui.ink, size: 32),
          ),
        ),
        if (invalid)
          Text(
            l10n.checkin_extraPaceInvalid,
            key: const ValueKey('checkin-pace-error'),
            style: UiText.body(size: 12, height: 1.4, color: ui.danger),
          ),
        const SizedBox(height: UiSpace.sm),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final k in _keys) key(k),
            key('0'),
            UiIconButton(
              key: const ValueKey('checkin-pace-backspace'),
              glyph: const OurneyIcon(name: 'back', size: 22),
              label: l10n.checkin_extraBackspace,
              onPressed: c.backspace,
            ),
          ],
        ),
      ],
    );
  }
}

/// Limits input to [max] Unicode code points (matches the SQL CHECK).
class _RuneLimit extends TextInputFormatter {
  const _RuneLimit(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final runes = newValue.text.runes;
    if (runes.length <= max) return newValue;
    final text = String.fromCharCodes(runes.take(max));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
