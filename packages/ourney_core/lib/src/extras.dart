// Per-skin Post inputs persisted as `check_ins.extras` (jsonb, migration 0007).
// Mirrors `public.check_in_extras_valid` so bad values never reach the server.

import 'dart:convert';

const int extrasMoodMax = 24;
const int extrasPlaceMax = 60;
const int extrasDishMax = 60;
const int extrasCookMax = 24;
const int extrasMinutesMax = 1440;
const int extrasHeartsMax = 5;
const int partnerNameMax = 24;

final RegExp _paceFormat = RegExp(r'^[0-9]{1,2}:[0-5][0-9]$');

int _len(String s) => s.runes.length;

/// Optional per-skin inputs of one check-in. Every field is optional; null
/// means "nothing entered".
class CheckInExtras {
  const CheckInExtras({
    this.mood,
    this.minutes,
    this.place,
    this.dish,
    this.cook,
    this.hearts,
    this.pace,
  });

  static const CheckInExtras empty = CheckInExtras();

  /// Lenient: unknown keys and wrongly typed values are ignored. Accepts a
  /// decoded map or a JSON string (the local database stores text).
  factory CheckInExtras.fromJson(Object? json) {
    if (json is String) {
      if (json.isEmpty) return empty;
      try {
        return CheckInExtras.fromJson(jsonDecode(json));
      } on FormatException {
        return empty;
      }
    }
    if (json is! Map) return empty;
    String? s(String k) => json[k] is String ? json[k] as String : null;
    int? i(String k) => json[k] is num ? (json[k] as num).toInt() : null;
    return CheckInExtras(
      mood: s('mood'),
      minutes: i('minutes'),
      place: s('place'),
      dish: s('dish'),
      cook: s('cook'),
      hearts: i('hearts'),
      pace: s('pace'),
    );
  }

  /// Quiet transformer: how the day felt.
  final String? mood;

  /// Accountability squad: minutes studied (1..1440).
  final int? minutes;

  /// Memory collectors: where the photo was taken.
  final String? place;

  /// Couple rituals: today's dish, who cooked and a 1..5 heart rating.
  final String? dish;
  final String? cook;
  final int? hearts;

  /// Aesthetic flexer: pace as `m:ss` per km (distance is the metric value).
  final String? pace;

  bool get isEmpty =>
      mood == null &&
      minutes == null &&
      place == null &&
      dish == null &&
      cook == null &&
      hearts == null &&
      pace == null;

  /// Null when valid, otherwise the offending key.
  String? validate() {
    bool bad(String? v, int max) => v != null && (_len(v) < 1 || _len(v) > max);
    if (bad(mood, extrasMoodMax)) return 'mood';
    if (bad(place, extrasPlaceMax)) return 'place';
    if (bad(dish, extrasDishMax)) return 'dish';
    if (bad(cook, extrasCookMax)) return 'cook';
    if (minutes != null && (minutes! < 1 || minutes! > extrasMinutesMax)) {
      return 'minutes';
    }
    if (hearts != null && (hearts! < 1 || hearts! > extrasHeartsMax)) {
      return 'hearts';
    }
    if (pace != null && !_paceFormat.hasMatch(pace!)) return 'pace';
    return null;
  }

  /// Trims strings and drops blank ones.
  CheckInExtras normalized() {
    String? t(String? v) {
      final s = v?.trim();
      return s == null || s.isEmpty ? null : s;
    }

    return CheckInExtras(
      mood: t(mood),
      minutes: minutes,
      place: t(place),
      dish: t(dish),
      cook: t(cook),
      hearts: hearts,
      pace: t(pace),
    );
  }

  Map<String, Object?> toJson() => {
        if (mood != null) 'mood': mood,
        if (minutes != null) 'minutes': minutes,
        if (place != null) 'place': place,
        if (dish != null) 'dish': dish,
        if (cook != null) 'cook': cook,
        if (hearts != null) 'hearts': hearts,
        if (pace != null) 'pace': pace,
      };

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is CheckInExtras && other.toJsonString() == toJsonString();

  @override
  int get hashCode => toJsonString().hashCode;
}

enum CoupleNamesError { missing, tooLong }

/// Couple names come as a pair (`journeys.couple_*_name`, 1..24 each).
CoupleNamesError? validateCoupleNames(String? self, String? partner) {
  final a = self?.trim() ?? '';
  final b = partner?.trim() ?? '';
  if (a.isEmpty && b.isEmpty) return null;
  if (a.isEmpty || b.isEmpty) return CoupleNamesError.missing;
  if (_len(a) > partnerNameMax || _len(b) > partnerNameMax) {
    return CoupleNamesError.tooLong;
  }
  return null;
}
