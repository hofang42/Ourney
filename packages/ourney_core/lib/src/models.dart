// Contract (A0): plain immutable domain models mirroring docs/contracts/schema.md.

/// A calendar date without time or timezone (journey-local).
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  /// Parses `YYYY-MM-DD`.
  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) throw FormatException('Invalid date', iso);
    return LocalDate(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

// Wire enums. Postgres enum labels are snake_case; NEVER serialize with
// `Enum.name` (e.g. `TemplateId.weightLoss.name == 'weightLoss'` but the
// server expects `weight_loss`). Use `wireName` / `fromWire`.

T _fromWire<T extends Enum>(List<T> values, String wire, String Function(T) nameOf) {
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
  static JourneyKind fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `journey_visibility`. Allowed combinations (server CHECKs):
/// solo → `private` | `link`; group → `group` only. See [defaultVisibilityFor].
enum JourneyVisibility {
  private('private'),
  group('group'),
  link('link');

  const JourneyVisibility(this.wireName);
  final String wireName;
  static JourneyVisibility fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
}

/// Visibility a new journey of [kind] gets when none is chosen: `group` for
/// group journeys (the only value the server stores for them), else `private`.
JourneyVisibility defaultVisibilityFor(JourneyKind kind) =>
    kind == JourneyKind.group ? JourneyVisibility.group : JourneyVisibility.private;

/// SQL `journey_status`.
enum JourneyStatus {
  active('active'),
  ended('ended'),
  archived('archived');

  const JourneyStatus(this.wireName);
  final String wireName;
  static JourneyStatus fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `member_role`.
enum MemberRole {
  owner('owner'),
  member('member');

  const MemberRole(this.wireName);
  final String wireName;
  static MemberRole fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
}

/// SQL `member_status`. `left` rows are kept so a rejoin restores progress.
enum MemberStatus {
  active('active'),
  left('left');

  const MemberStatus(this.wireName);
  final String wireName;
  static MemberStatus fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
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
  static TemplateId fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
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
  static ReportReason fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
}

/// `reports.status` (text + CHECK on the server, readable by the reporter).
enum ReportStatus {
  open('open'),
  actioned('actioned'),
  dismissed('dismissed');

  const ReportStatus(this.wireName);
  final String wireName;
  static ReportStatus fromWire(String wire) => _fromWire(values, wire, (v) => v.wireName);
}

/// The only emojis `reactions.emoji` accepts (server CHECK).
const List<String> reactionEmojis = ['🔥', '💪', '👏', '❤️', '😂'];

class Profile {
  const Profile({required this.id, required this.username, required this.displayName, this.avatarPath});

  final String id;
  final String username;
  final String displayName;
  final String? avatarPath;
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

  LocalDate? get endDate => durationDays == null ? null : startDate.addDays(durationDays! - 1);
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
  }) : visibility = visibility ?? (kind == JourneyKind.group ? JourneyVisibility.group : JourneyVisibility.private);

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

  bool get isActive => status == MemberStatus.active;
}

/// A `reactions` row: one emoji per (checkInId, userId); see [reactionEmojis].
class Reaction {
  const Reaction({required this.checkInId, required this.userId, required this.emoji, required this.createdAt});

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
    this.localPhotoFile,
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

  /// Set while the photo still lives only on this device.
  final String? localPhotoFile;
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
  });

  final String journeyId;
  final DateTime capturedAt;

  /// Already compressed JPEG (1080px, q70) and thumbnail on local disk.
  final String photoFile;
  final String thumbFile;
  final bool fromLibrary;
  final String? caption;
  final double? metricValue;
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
    this.currentStreak = 0,
  });

  final String userId;
  final String? username;
  final String displayName;
  final String? avatarPath;
  final MemberRole role;
  final CheckIn? todayCheckIn;

  /// Server-computed (`journey_streak`, counts from the member's join date).
  final int currentStreak;

  bool get checkedIn => todayCheckIn != null;
}
