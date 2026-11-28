// Wire <-> drift <-> domain mapping. Enum values cross every boundary through
// `wireName` / `fromWire` only (schema.md: never `Enum.name`).
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import 'db/app_database.dart';
import 'remote/remote_api.dart';

DateTime parseInstant(Object? value) =>
    DateTime.parse(value! as String).toUtc();

double? _toDouble(Object? v) => switch (v) {
  null => null,
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};

bool isTombstone(RemoteRow r) => r['deleted_at'] != null;

// --- journeys ---------------------------------------------------------------

JourneysCompanion journeyFromRemote(RemoteRow r) => JourneysCompanion(
  id: Value(r['id'] as String),
  ownerId: Value(r['owner_id'] as String),
  kind: Value(JourneyKind.fromWire(r['kind'] as String).wireName),
  templateId: Value(TemplateId.fromWire(r['template_id'] as String).wireName),
  title: Value(r['title'] as String),
  emoji: Value(r['emoji'] as String),
  metricName: Value(r['metric_name'] as String?),
  metricUnit: Value(r['metric_unit'] as String?),
  hideMetricDefault: Value(r['hide_metric_default'] as bool? ?? false),
  startDate: Value(LocalDate.parse(r['start_date'] as String)),
  durationDays: Value((r['duration_days'] as num?)?.toInt()),
  timezone: Value(r['timezone'] as String),
  visibility: Value(
    JourneyVisibility.fromWire(r['visibility'] as String).wireName,
  ),
  status: Value(JourneyStatus.fromWire(r['status'] as String).wireName),
  inviteCode: Value(r['invite_code'] as String?),
  maxMembers: Value((r['max_members'] as num?)?.toInt() ?? 10),
  publicToken: Value((r['public_slug'] ?? r['public_token']) as String?),
  // Absent before v1.3 (0006): every older journey is lived.
  origin: Value(
    JourneyOrigin.fromWire(r['origin'] as String? ?? 'live').wireName,
  ),
  coupleSelfName: Value(r['couple_self_name'] as String?),
  couplePartnerName: Value(r['couple_partner_name'] as String?),
  layout: Value(r['layout'] as String?),
  cover: Value((r['cover'] as num?)?.toInt()),
  color: Value((r['color'] as num?)?.toInt()),
  reminderTime: Value(r['reminder_time'] as String?),
  dna: Value(_encodeDna(r['dna'])),
  updatedAt: Value(r['updated_at'] as String?),
);

String? _encodeDna(Object? v) => switch (v) {
  null => null,
  final Map<dynamic, dynamic> m => jsonEncode(m),
  final String s => s,
  _ => null,
};

Map<String, Object?>? decodeDna(String? s) {
  if (s == null) return null;
  try {
    final v = jsonDecode(s);
    return v is Map ? v.cast<String, Object?>() : null;
  } on FormatException {
    return null;
  }
}

PersonaSkinId? _layoutOf(String? wire) {
  if (wire == null) return null;
  for (final v in PersonaSkinId.values) {
    if (v.wireName == wire) return v;
  }
  return null;
}

Journey journeyFromRow(JourneyRow r) => Journey(
  id: r.id,
  ownerId: r.ownerId,
  kind: JourneyKind.fromWire(r.kind),
  templateId: TemplateId.fromWire(r.templateId),
  title: r.title,
  emoji: r.emoji,
  startDate: r.startDate,
  durationDays: r.durationDays,
  timezone: r.timezone,
  visibility: JourneyVisibility.fromWire(r.visibility),
  status: JourneyStatus.fromWire(r.status),
  metricName: r.metricName,
  metricUnit: r.metricUnit,
  hideMetricDefault: r.hideMetricDefault,
  inviteCode: r.inviteCode,
  maxMembers: r.maxMembers,
  publicToken: r.publicToken,
  origin: JourneyOrigin.fromWire(r.origin),
  coupleSelfName: r.coupleSelfName,
  couplePartnerName: r.couplePartnerName,
  layout: _layoutOf(r.layout),
  cover: r.cover,
  color: r.color,
  reminderTime: r.reminderTime,
  dna: decodeDna(r.dna),
);

/// `create_journey` arguments (names from 0004_rpc.sql).
Map<String, dynamic> createJourneyParams(String id, JourneyDraft d) => {
  'p_id': id,
  'p_kind': d.kind.wireName,
  'p_template_id': d.templateId.wireName,
  'p_title': d.title.trim(),
  'p_emoji': d.emoji,
  'p_metric_name': d.metricName,
  'p_metric_unit': d.metricUnit,
  'p_hide_metric_default': d.hideMetricDefault,
  'p_start_date': d.startDate.toString(),
  'p_duration_days': d.durationDays,
  'p_timezone': d.timezone,
  'p_max_members': maxMembersForDraft(d),
  'p_visibility': normalizedVisibility(d.kind, d.visibility).wireName,
  'p_couple_self_name': d.coupleSelfName?.trim(),
  'p_couple_partner_name': d.couplePartnerName?.trim(),
};

/// `update_journey` arguments (names from 0012_journey_edit.sql).
Map<String, dynamic> updateJourneyParams(String id, JourneyUpdate u) => {
  'p_journey': id,
  'p_title': u.title?.trim(),
  'p_layout': u.layout?.wireName,
  'p_cover': u.cover,
  'p_color': u.color,
  'p_reminder_time': u.reminderTime,
  'p_dna': u.dna,
  'p_clear': u.clear.toList(),
};

// --- memberships ------------------------------------------------------------

MembershipsCompanion membershipFromRemote(RemoteRow r) => MembershipsCompanion(
  journeyId: Value(r['journey_id'] as String),
  userId: Value(r['user_id'] as String),
  role: Value(MemberRole.fromWire(r['role'] as String).wireName),
  status: Value(
    isTombstone(r)
        ? MemberStatus.left.wireName
        : MemberStatus.fromWire(r['status'] as String).wireName,
  ),
  joinedAt: Value(parseInstant(r['joined_at'])),
  hideMetric: Value(r['hide_metric'] as bool? ?? false),
  blurMedia: Value(r['blur_media'] as bool? ?? false),
  hideExtras: Value(r['hide_extras'] as bool? ?? false),
  pinned: Value(r['pinned'] as bool? ?? false),
  updatedAt: Value(r['updated_at'] as String?),
);

Membership membershipFromRow(MembershipRow r) => Membership(
  journeyId: r.journeyId,
  userId: r.userId,
  role: MemberRole.fromWire(r.role),
  status: MemberStatus.fromWire(r.status),
  joinedAt: r.joinedAt,
  hideMetric: r.hideMetric,
  blurMedia: r.blurMedia,
  hideExtras: r.hideExtras,
  pinned: r.pinned,
);

// --- check_ins --------------------------------------------------------------

CheckInsCompanion checkInFromRemote(RemoteRow r) => CheckInsCompanion(
  id: Value(r['id'] as String),
  journeyId: Value(r['journey_id'] as String),
  userId: Value(r['user_id'] as String),
  localDate: Value(LocalDate.parse(r['local_date'] as String)),
  capturedAt: Value(parseInstant(r['captured_at'])),
  photoPath: Value(r['photo_path'] as String),
  thumbPath: Value(r['thumb_path'] as String),
  fromLibrary: Value(r['from_library'] as bool? ?? false),
  caption: Value(r['caption'] as String?),
  moderated: Value(r['moderated_at'] != null),
  // Since 0011 `check_ins.extras` is always blank: extras arrive from
  // `check_in_extras` (see [extrasFromRemote]) so applying a pulled row
  // keeps the cached value.
  partnerPhotoPath: Value(r['partner_photo_path'] as String?),
  // Since 0005 the server never returns a metric in `check_ins` (always
  // null): metrics arrive from `check_in_metrics` (see [metricFromRemote]).
  // Left absent so applying a pulled row keeps the cached value.
  uploaded: const Value(true),
  updatedAt: Value(r['updated_at'] as String?),
);

/// Write body for `check_ins` (server recomputes `local_date`).
RemoteRow checkInToRemote(CheckInRow r) => {
  'id': r.id,
  'journey_id': r.journeyId,
  'user_id': r.userId,
  'local_date': r.localDate.toString(),
  'captured_at': r.capturedAt.toUtc().toIso8601String(),
  'photo_path': r.photoPath,
  'thumb_path': r.thumbPath,
  'from_library': r.fromLibrary,
  'caption': r.caption,
};

/// Upsert body for `check_in_metrics` (on `checkin_id`; the server copies
/// journey_id/user_id from the check-in). Sent for every check-in, also with
/// a null value, so a retake without a number clears the old one.
RemoteRow checkInMetricToRemote(CheckInRow r) => {
  'checkin_id': r.id,
  'journey_id': r.journeyId,
  'user_id': r.userId,
  'metric_value': r.metricValue,
};

/// Upsert body for `check_in_extras` (on `checkin_id`; the server copies
/// journey_id/user_id from the check-in). Always sent, also when empty, so a
/// retake without extras clears the old ones.
RemoteRow checkInExtrasToRemote(CheckInRow r) => {
  'checkin_id': r.id,
  'journey_id': r.journeyId,
  'user_id': r.userId,
  'extras': CheckInExtras.fromJson(r.extras).toJson(),
};

/// `check_in_extras` row → (check-in id, extras JSON text). RLS only returns
/// rows the caller may see (own, or the author does not hide their extras).
({String checkInId, String extras}) extrasFromRemote(RemoteRow r) => (
  checkInId: r['checkin_id'] as String,
  extras: CheckInExtras.fromJson(r['extras']).toJsonString(),
);

/// `check_in_metrics` row → (check-in id, value). RLS only returns rows the
/// caller may see (own, or the author does not hide metrics).
({String checkInId, double? value}) metricFromRemote(RemoteRow r) =>
    (checkInId: r['checkin_id'] as String, value: _toDouble(r['metric_value']));

CheckIn checkInFromRow(
  CheckInRow r, {
  String? localPhotoFile,
  String? localPartnerPhotoFile,
}) => CheckIn(
  id: r.id,
  journeyId: r.journeyId,
  userId: r.userId,
  localDate: r.localDate,
  capturedAt: r.capturedAt,
  photoPath: r.photoPath,
  thumbPath: r.thumbPath,
  fromLibrary: r.fromLibrary,
  caption: r.caption,
  metricValue: r.metricValue,
  extras: CheckInExtras.fromJson(r.extras),
  partnerPhotoPath: r.partnerPhotoPath,
  localPhotoFile: r.uploaded ? null : localPhotoFile,
  localPartnerPhotoFile: r.uploaded ? null : localPartnerPhotoFile,
  uploaded: r.uploaded,
  moderated: r.moderated,
);

// --- reactions / profiles ---------------------------------------------------

ReactionsCompanion reactionFromRemote(RemoteRow r) => ReactionsCompanion(
  checkInId: Value(r['checkin_id'] as String),
  userId: Value(r['user_id'] as String),
  emoji: Value(r['emoji'] as String),
  createdAt: Value(parseInstant(r['created_at'])),
  updatedAt: Value(r['updated_at'] as String?),
);

Reaction reactionFromRow(ReactionRow r) => Reaction(
  checkInId: r.checkInId,
  userId: r.userId,
  emoji: r.emoji,
  createdAt: r.createdAt,
);

ProfilesCompanion profileFromRemote(RemoteRow r) => ProfilesCompanion(
  id: Value(r['id'] as String),
  username: Value(r['username'] as String),
  displayName: Value(r['display_name'] as String),
  avatarPath: Value(r['avatar_path'] as String?),
  termsVersion: Value((r['terms_version'] as num?)?.toInt() ?? 0),
  updatedAt: Value(r['updated_at'] as String?),
);

Profile profileFromRow(ProfileRow r) => Profile(
  id: r.id,
  username: r.username,
  displayName: r.displayName,
  avatarPath: r.avatarPath,
  termsVersion: r.termsVersion,
);

/// One `group_today` row → [MemberToday] ([today] = journey-local today).
MemberToday memberTodayFromRemote(
  RemoteRow r, {
  required String journeyId,
  required LocalDate today,
}) {
  final userId = r['user_id'] as String;
  final checkInId = r['checkin_id'] as String?;
  final checkedIn = r['checked_in'] as bool? ?? false;
  // L7: a check-in the caller reported comes back with checked_in = true but
  // no id/thumb/time; the member still checked in today.
  return MemberToday(
    userId: userId,
    username: r['username'] as String?,
    displayName: r['display_name'] as String? ?? '',
    avatarPath: r['avatar_path'] as String?,
    role: MemberRole.fromWire(r['role'] as String),
    currentStreak: (r['current_streak'] as num?)?.toInt() ?? 0,
    checkedInHidden: checkedIn && checkInId == null,
    todayCheckIn: checkedIn && checkInId != null
        ? CheckIn(
            id: checkInId,
            journeyId: journeyId,
            userId: userId,
            localDate: today,
            capturedAt: parseInstant(r['captured_at']),
            photoPath: checkInPhotoPath(journeyId, userId, checkInId),
            thumbPath:
                r['thumb_path'] as String? ??
                checkInThumbPath(journeyId, userId, checkInId),
            uploaded: true,
          )
        : null,
  );
}
