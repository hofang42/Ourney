// Contract (A0): plain immutable domain models mirroring docs/contracts/schema.md.

import 'dart:convert' show jsonEncode, utf8;

import 'contracts/social.dart' show JourneyOrigin;
import 'extras.dart' show CheckInExtras;

/// A calendar date without time or timezone (journey-local).
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  /// Parses `YYYY-MM-DD`.
  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) throw FormatException('Invalid date', iso);
    return LocalDate(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  LocalDate addDays(int days) {
    final d = _utc.add(Duration(days: days));
    return LocalDate(d.year, d.month, d.day);
  }

  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

// Wire enums. Postgres enum labels are snake_case; NEVER serialize with
// `Enum.name` (e.g. `TemplateId.weightLoss.name == 'weightLoss'` but the
// server expects `weight_loss`). Use `wireName` / `fromWire`.

T _fromWire<T extends Enum>(
    List<T> values, String wire, String Function(T) nameOf) {
  for (final v in values) {
    if (nameOf(v) == wire) return v;
  }
  throw FormatException('Unknown ${T.toString()} wire value', wire);
}

/// SQL `journey_kind`.
enum JourneyKind {
  solo('solo'),
  group('group');

  const JourneyKind(this.wireName);
  final String wireName;
  static JourneyKind fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `journey_visibility`. Allowed combinations (server CHECKs):
/// solo → `private` | `link`; group → `group` only. See [defaultVisibilityFor].
enum JourneyVisibility {
  private('private'),
  group('group'),
  link('link');

  const JourneyVisibility(this.wireName);
  final String wireName;
  static JourneyVisibility fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// Visibility a new journey of [kind] gets when none is chosen: `group` for
/// group journeys (the only value the server stores for them), else `private`.
JourneyVisibility defaultVisibilityFor(JourneyKind kind) =>
    kind == JourneyKind.group
        ? JourneyVisibility.group
        : JourneyVisibility.private;

/// SQL `journey_status`.
enum JourneyStatus {
  active('active'),
  ended('ended'),
  archived('archived');

  const JourneyStatus(this.wireName);
  final String wireName;
  static JourneyStatus fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `member_role`.
enum MemberRole {
  owner('owner'),
  member('member');

  const MemberRole(this.wireName);
  final String wireName;
  static MemberRole fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `member_status`. `left` rows are kept so a rejoin restores progress.
enum MemberStatus {
  active('active'),
  left('left');

  const MemberStatus(this.wireName);
  final String wireName;
  static MemberStatus fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `template_id`.
enum TemplateId {
  weightLoss('weight_loss'),
  englishDaily('english_daily'),
  workout30('workout_30'),
  travel('travel'),
  custom('custom');

  const TemplateId(this.wireName);
  final String wireName;
  static TemplateId fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// The 6 distinct UI persona skins that adapt timeline, camera HUD, and share card.
enum PersonaSkinId {
  quietTransformer('quiet_transformer'),
  accountabilitySquad('accountability_squad'),
  memoryCollectors('memory_collectors'),
  coupleRituals('couple_rituals'),
  aestheticFlexer('aesthetic_flexer'),
  minimalistHabit('minimalist_habit');

  const PersonaSkinId(this.wireName);
  final String wireName;
  static PersonaSkinId fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `report_reason`.
enum ReportReason {
  spam('spam'),
  nudity('nudity'),
  harassment('harassment'),
  selfHarm('self_harm'),
  other('other');

  const ReportReason(this.wireName);
  final String wireName;
  static ReportReason fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// `reports.status` (text + CHECK on the server, readable by the reporter).
enum ReportStatus {
  open('open'),
  actioned('actioned'),
  dismissed('dismissed');

  const ReportStatus(this.wireName);
  final String wireName;
  static ReportStatus fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// The only emojis `reactions.emoji` accepts (server CHECK).
const List<String> reactionEmojis = ['🔥', '💪', '👏', '❤️', '😂'];

class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarPath,
    this.termsVersion = 0,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarPath;

  /// Version of the terms the user accepted (`profiles.terms_version`).
  final int termsVersion;
}

class Journey {
  const Journey({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.templateId,
    required this.title,
    required this.emoji,
    required this.startDate,
    required this.timezone,
    required this.visibility,
    required this.status,
    this.durationDays,
    this.metricName,
    this.metricUnit,
    this.hideMetricDefault = false,
    this.inviteCode,
    this.maxMembers = 10,
    this.publicToken,
    this.origin = JourneyOrigin.live,
    this.coupleSelfName,
    this.couplePartnerName,
    this.layout,
    this.cover,
    this.color,
    this.reminderTime,
    this.dna,
  });

  final String id;
  final String ownerId;
  final JourneyKind kind;
  final TemplateId templateId;
  final String title;
  final String emoji;
  final LocalDate startDate;
  final int? durationDays;
  final String timezone;
  final JourneyVisibility visibility;
  final JourneyStatus status;
  final String? metricName;
  final String? metricUnit;
  final bool hideMetricDefault;
  final String? inviteCode;
  final int maxMembers;

  /// `journeys.public_token`: 40 chars `[a-z0-9]`, non-null iff
  /// `visibility == link` (solo only). Build the share URL with
  /// `publicJourneyUri`. Rotated/revoked by `JourneyRepository.setPublicLink`.
  final String? publicToken;

  /// `journeys.origin` (v1.3): lived in the app, or retold from old photos.
  final JourneyOrigin origin;

  /// `journeys.couple_self_name` / `couple_partner_name` (0007): both or none.
  final String? coupleSelfName;
  final String? couplePartnerName;

  /// `journeys.layout` (0012): owner's skin override; null = derived from the template.
  final PersonaSkinId? layout;

  /// `journeys.cover` / `color` (0012): sticker and colour-variant index 0..2.
  final int? cover;
  final int? color;

  /// `journeys.reminder_time` (0012): `HH:MM`.
  final String? reminderTime;

  /// `journeys.dna` (0012): validated create-flow answers (see [journeyDnaKeys]).
  final Map<String, Object?>? dna;

  LocalDate? get endDate =>
      durationDays == null ? null : startDate.addDays(durationDays! - 1);

  /// True when this journey is still `active` on the server but its fixed
  /// window is over on [today] (the day after [endDate] or later): nothing
  /// accepts a check-in any more and nothing has moved it to `ended` yet.
  bool isPastEndOn(LocalDate today) {
    final end = endDate;
    return status == JourneyStatus.active && end != null && today.isAfter(end);
  }

  /// This journey as it really is on [today]: an expired `active` journey is
  /// reported as `ended` (it is on the server too once its owner opens it).
  Journey settledOn(LocalDate today) =>
      isPastEndOn(today) ? copyWith(status: JourneyStatus.ended) : this;

  /// Copy with the edit-screen fields and status replaced (null = keep).
  Journey copyWith({
    String? title,
    JourneyStatus? status,
    PersonaSkinId? layout,
    int? cover,
    int? color,
    String? reminderTime,
    Map<String, Object?>? dna,
    bool clearLayout = false,
  }) => Journey(
    id: id,
    ownerId: ownerId,
    kind: kind,
    templateId: templateId,
    title: title ?? this.title,
    emoji: emoji,
    startDate: startDate,
    timezone: timezone,
    visibility: visibility,
    status: status ?? this.status,
    durationDays: durationDays,
    metricName: metricName,
    metricUnit: metricUnit,
    hideMetricDefault: hideMetricDefault,
    inviteCode: inviteCode,
    maxMembers: maxMembers,
    publicToken: publicToken,
    origin: origin,
    coupleSelfName: coupleSelfName,
    couplePartnerName: couplePartnerName,
    layout: clearLayout ? null : (layout ?? this.layout),
    cover: cover ?? this.cover,
    color: color ?? this.color,
    reminderTime: reminderTime ?? this.reminderTime,
    dna: dna ?? this.dna,
  );
}

class JourneyDraft {
  const JourneyDraft({
    required this.kind,
    required this.templateId,
    required this.title,
    required this.emoji,
    required this.startDate,
    required this.timezone,
    this.durationDays,
    this.metricName,
    this.metricUnit,
    this.hideMetricDefault = false,
    JourneyVisibility? visibility,
    this.id,
    this.coupleSelfName,
    this.couplePartnerName,
    this.layout,
    this.cover,
    this.color,
    this.reminderTime,
    this.dna,
  }) : visibility = visibility ??
            (kind == JourneyKind.group
                ? JourneyVisibility.group
                : JourneyVisibility.private);

  final JourneyKind kind;
  final TemplateId templateId;
  final String title;
  final String emoji;
  final LocalDate startDate;
  final int? durationDays;
  final String timezone;
  final String? metricName;
  final String? metricUnit;
  final bool hideMetricDefault;

  /// Defaults to [defaultVisibilityFor] `kind`. Check with
  /// `validateJourneyVisibility` before calling `create_journey`.
  final JourneyVisibility visibility;

  /// Client-generated UUID (`create_journey` is idempotent on `p_id`).
  /// Generate it once per create form so a retry after a lost response
  /// cannot create a second journey. Null: the repository generates one.
  final String? id;

  /// Couple names (both or none, 1..24 chars; see `validateCoupleNames`).
  final String? coupleSelfName;
  final String? couplePartnerName;

  /// Optional 0012 fields persisted right after creation.
  final PersonaSkinId? layout;
  final int? cover;
  final int? color;
  final String? reminderTime;
  final Map<String, Object?>? dna;
}

/// Keys `journeys.dna` accepts (server `journey_dna_valid`). Weight and the
/// ghost-photo request are deliberately absent: they never leave the device.
const Set<String> journeyDnaKeys = {
  'goal', 'minutes', 'sport', 'measure', 'hud', 'film', 'ritual', 'side',
  'trophy', 'place', 'habit', 'reason', 'dates',
};

/// Keeps only the storable DNA answers (drops unknown keys and empties),
/// mirroring server `public.journey_dna_valid(x jsonb)` (0012).
Map<String, Object?>? sanitizeJourneyDna(Map<String, Object?> answers) {
  final out = <String, Object?>{};
  for (final e in answers.entries) {
    final key = e.key;
    final val = e.value;
    if (!journeyDnaKeys.contains(key) || val == null) continue;
    if (key == 'dates') {
      final dates = _sanitizeDnaDates(val);
      if (dates != null) out[key] = dates;
    } else if (_dnaTextMax.containsKey(key)) {
      if (val is! String) continue;
      final trimmed = val.trim();
      if (trimmed.isEmpty) continue;
      out[key] = _clipDna(key, trimmed);
    } else {
      if (val is! String) continue;
      final trimmed = val.trim();
      if (!_dnaChoicePattern.hasMatch(trimmed)) continue;
      out[key] = trimmed;
    }
  }
  if (out.isEmpty) return null;
  if (_jsonbTextOctetLength(out) > 960) return null;
  return out;
}

/// Upper bound of Postgres `octet_length(x::jsonb::text)`: Postgres formats
/// `jsonb::text` with a space after every `:` and `,`.
int _jsonbTextOctetLength(Map<String, Object?> map) {
  var extraSpaces = map.length + (map.length > 1 ? map.length - 1 : 0);
  final dates = map['dates'];
  if (dates is Map) {
    extraSpaces += dates.length + (dates.length > 1 ? dates.length - 1 : 0);
  }
  return utf8.encode(jsonEncode(map)).length + extraSpaces;
}

final RegExp _dnaChoicePattern = RegExp(r'^[a-z0-9_]{1,24}$');
final RegExp _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

LocalDate? _tryParseIsoDate(Object? raw) {
  if (raw is! String || !_isoDatePattern.hasMatch(raw)) return null;
  try {
    final parsed = LocalDate.parse(raw);
    return parsed.toString() == raw ? parsed : null;
  } on Object {
    return null;
  }
}

Map<String, String>? _sanitizeDnaDates(Object? raw) {
  if (raw is! Map) return null;
  for (final k in raw.keys) {
    if (k != 'start' && k != 'end') return null;
  }
  final start = _tryParseIsoDate(raw['start']);
  if (start == null) return null;
  final endRaw = raw['end'];
  if (endRaw == null) return {'start': start.toString()};
  final end = _tryParseIsoDate(endRaw);
  if (end == null || end.isBefore(start)) return null;
  return {'start': start.toString(), 'end': end.toString()};
}

/// Maximum number of Unicode code points in a trip destination.
const int dnaPlaceMax = 60;

const Map<String, int> _dnaTextMax = {
  'trophy': 24,
  'place': dnaPlaceMax,
  'habit': 40,
  'reason': 80,
};

/// Clips to [_dnaTextMax] code points (Postgres `char_length`), never inside
/// a UTF-16 surrogate pair: a lone surrogate is invalid JSON for `jsonb`.
String _clipDna(String key, String v) {
  final max = _dnaTextMax[key];
  if (max == null) return v;
  final runes = v.runes;
  return runes.length > max ? String.fromCharCodes(runes.take(max)) : v;
}

/// Partial edit sent to `update_journey` (null = unchanged; [clear] resets
/// the named fields: layout, cover, color, reminder_time, dna).
class JourneyUpdate {
  const JourneyUpdate({
    this.title,
    this.layout,
    this.cover,
    this.color,
    this.reminderTime,
    this.dna,
    this.clear = const {},
  });

  final String? title;
  final PersonaSkinId? layout;
  final int? cover;
  final int? color;
  final String? reminderTime;
  final Map<String, Object?>? dna;
  final Set<String> clear;

  bool get isEmpty =>
      title == null &&
      layout == null &&
      cover == null &&
      color == null &&
      reminderTime == null &&
      dna == null &&
      clear.isEmpty;
}

/// A `memberships` row. Every journey (solo too) has one for its owner.
class Membership {
  const Membership({
    required this.journeyId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.hideMetric = false,
    this.blurMedia = false,
    this.hideExtras = false,
    this.pinned = false,
  });

  final String journeyId;
  final String userId;
  final MemberRole role;
  final MemberStatus status;

  /// Personal progress counts from the journey-local date of this instant;
  /// see `effectiveStreakStart` / `computeMemberStreak`. Kept on rejoin.
  final DateTime joinedAt;

  /// Hide my metric values from others / on the public link (FR-B7).
  final bool hideMetric;

  /// Blur my photos when shared outside (share card, public link) (FR-B7).
  final bool blurMedia;

  /// Hide my mood / minutes / place / dish / cook / hearts / pace / km from
  /// other members (0011). I always see my own.
  final bool hideExtras;

  /// Per-user pin: this journey is listed first for me (0011).
  final bool pinned;

  bool get isActive => status == MemberStatus.active;
}

/// A `reactions` row: one emoji per (checkInId, userId); see [reactionEmojis].
class Reaction {
  const Reaction(
      {required this.checkInId,
      required this.userId,
      required this.emoji,
      required this.createdAt});

  final String checkInId;
  final String userId;
  final String emoji;
  final DateTime createdAt;
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.journeyId,
    required this.userId,
    required this.localDate,
    required this.capturedAt,
    required this.photoPath,
    required this.thumbPath,
    this.fromLibrary = false,
    this.caption,
    this.metricValue,
    this.extras = CheckInExtras.empty,
    this.partnerPhotoPath,
    this.localPhotoFile,
    this.localPartnerPhotoFile,
    this.uploaded = false,
  });

  final String id;
  final String journeyId;
  final String userId;
  final LocalDate localDate;
  final DateTime capturedAt;
  final String photoPath;
  final String thumbPath;
  final bool fromLibrary;
  final String? caption;
  final double? metricValue;

  /// Per-skin Post inputs (`check_ins.extras`).
  final CheckInExtras extras;

  /// Legacy photo attached by this check-in's author.
  final String? partnerPhotoPath;

  /// Set while the photo still lives only on this device.
  final String? localPhotoFile;
  final String? localPartnerPhotoFile;
  final bool uploaded;
}

class CheckInDraft {
  const CheckInDraft({
    required this.journeyId,
    required this.capturedAt,
    required this.photoFile,
    required this.thumbFile,
    this.fromLibrary = false,
    this.caption,
    this.metricValue,
    this.extras = CheckInExtras.empty,
    this.id,
  });

  /// Optional client-chosen check-in id (a uuid). A retry of a submit with the
  /// same id returns the row it already created instead of adding another
  /// (the import job gives each photo a stable id).
  final String? id;
  final String journeyId;
  final DateTime capturedAt;

  /// Already compressed JPEG (1080px, q70) and thumbnail on local disk.
  final String photoFile;
  final String thumbFile;
  final bool fromLibrary;
  final String? caption;
  final double? metricValue;
  final CheckInExtras extras;
}

/// One row of RPC `group_today(journey)` (active, non-blocked members ordered
/// by joined_at). The RPC returns `checkin_id`, `thumb_path`, `captured_at`
/// for today's check-in; `photoPath` follows from `checkInPhotoPath`.
class MemberToday {
  const MemberToday({
    required this.userId,
    required this.displayName,
    required this.role,
    this.username,
    this.avatarPath,
    this.todayCheckIn,
    this.checkedInHidden = false,
    this.currentStreak = 0,
  });

  final String userId;
  final String? username;
  final String displayName;
  final String? avatarPath;
  final MemberRole role;
  final CheckIn? todayCheckIn;

  /// Checked in today, but the photo is hidden from the caller (they
  /// reported it, rule L7): [todayCheckIn] is null yet the day counts.
  final bool checkedInHidden;

  /// Server-computed (`journey_streak`, counts from the member's join date).
  final int currentStreak;

  bool get checkedIn => todayCheckIn != null || checkedInHidden;
}
