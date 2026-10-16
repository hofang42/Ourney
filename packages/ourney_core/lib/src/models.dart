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

enum JourneyKind { solo, group }

enum JourneyVisibility { private, group, link }

enum JourneyStatus { active, ended, archived }

enum MemberRole { owner, member }

enum TemplateId { weightLoss, englishDaily, workout30, travel, custom }

enum ReportReason { spam, nudity, harassment, selfHarm, other }

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
    this.visibility = JourneyVisibility.private,
  });

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
  final JourneyVisibility visibility;
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

class MemberToday {
  const MemberToday({
    required this.userId,
    required this.displayName,
    required this.role,
    this.avatarPath,
    this.todayCheckIn,
    this.currentStreak = 0,
  });

  final String userId;
  final String displayName;
  final String? avatarPath;
  final MemberRole role;
  final CheckIn? todayCheckIn;
  final int currentStreak;
}
