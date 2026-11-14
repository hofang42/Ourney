// Join-by-code preview and group invitations (supabase/migrations/0008).
//
//   GroupInviteRepository.previewByCode -> rpc preview_group_by_code
//   GroupInviteRepository.pending       -> rpc my_group_invitations
//   GroupInviteRepository.send          -> rpc send_group_invitation
//   GroupInviteRepository.accept        -> rpc accept_group_invitation
//   GroupInviteRepository.decline       -> rpc decline_group_invitation
//
// Confirming a previewed code reuses `GroupRepository.joinByCode`.

import 'social.dart';

/// What the caller may do with a previewed code.
enum GroupPreviewState {
  /// Can be joined.
  open('open'),

  /// The journey ended: the code no longer works.
  ended('ended'),

  /// The group already has `max_members` people.
  full('full'),

  /// The caller is already an active member.
  member('member');

  const GroupPreviewState(this.wireName);
  final String wireName;

  /// Unknown or missing values degrade to [ended]: a client that does not
  /// understand the state never offers a join.
  static GroupPreviewState fromWire(String? wire) {
    for (final s in values) {
      if (s.wireName == wire) return s;
    }
    return ended;
  }
}

/// A member shown on the preview ticket (name and avatar only).
class GroupPreviewMember {
  const GroupPreviewMember({required this.displayName, this.avatarPath});

  factory GroupPreviewMember.fromJson(Map<String, dynamic> json) =>
      GroupPreviewMember(
        displayName: json['display_name'] as String? ?? '',
        avatarPath: json['avatar_path'] as String?,
      );

  final String displayName;
  final String? avatarPath;
}

/// `preview_group_by_code`: everything shown before confirming a join.
class GroupPreview {
  const GroupPreview({
    required this.state,
    required this.title,
    required this.emoji,
    required this.templateId,
    required this.ownerName,
    required this.memberCount,
    required this.maxMembers,
    required this.dayNumber,
    this.ownerAvatarPath,
    this.durationDays,
    this.members = const [],
  });

  factory GroupPreview.fromJson(Map<String, dynamic> json) {
    final owner = (json['owner'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GroupPreview(
      state: GroupPreviewState.fromWire(json['state'] as String?),
      title: json['title'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      templateId: json['template_id'] as String? ?? 'custom',
      ownerName: owner['display_name'] as String? ?? '',
      ownerAvatarPath: owner['avatar_path'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 10,
      durationDays: (json['duration_days'] as num?)?.toInt(),
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      members: [
        for (final m in (json['members'] as List?) ?? const [])
          GroupPreviewMember.fromJson((m as Map).cast<String, dynamic>()),
      ],
    );
  }

  final GroupPreviewState state;
  final String title;
  final String emoji;
  final String templateId;
  final String ownerName;
  final String? ownerAvatarPath;
  final int memberCount;
  final int maxMembers;

  /// Null for open-ended journeys.
  final int? durationDays;

  /// 1-based day of the journey today.
  final int dayNumber;
  final List<GroupPreviewMember> members;

  bool get canJoin => state == GroupPreviewState.open;
}

/// One pending invitation of the caller (`my_group_invitations`).
class GroupInvitation {
  const GroupInvitation({
    required this.id,
    required this.journeyId,
    required this.title,
    required this.emoji,
    required this.templateId,
    required this.inviter,
    required this.memberCount,
    required this.maxMembers,
    required this.createdAt,
    required this.expiresAt,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    final p = (json['inviter'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GroupInvitation(
      id: json['id'] as String,
      journeyId: json['journey_id'] as String,
      title: json['title'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      templateId: json['template_id'] as String? ?? 'custom',
      inviter: PersonSummary(
        userId: p['user_id'] as String? ?? '',
        username: p['username'] as String? ?? '',
        displayName: p['display_name'] as String? ?? '',
        avatarPath: p['avatar_path'] as String?,
      ),
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 10,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String id;
  final String journeyId;
  final String title;
  final String emoji;
  final String templateId;
  final PersonSummary inviter;
  final int memberCount;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime expiresAt;
}

abstract interface class GroupInviteRepository {
  /// Looks a code up WITHOUT joining. Throws [GroupException] `notFound`
  /// (unknown, malformed, blocked or removed: indistinguishable),
  /// `rateLimited` or `offline`.
  Future<GroupPreview> previewByCode(String code);

  /// The caller's pending, unexpired invitations, newest first.
  Future<List<GroupInvitation>> pending();

  /// Invites [userId] or `@handle` to [journeyId] (any active member).
  /// Throws `forbidden`, `notFound`, `ended`, `full`, `invalid` (already a
  /// member / already invited), `rateLimited`.
  Future<void> send(String journeyId, {String? userId, String? handle});

  /// Accepts and joins; returns the journey id. Throws what `joinByCode`
  /// throws (`full`, `blocked`, `limit`, `ended`, `rateLimited`) plus
  /// `notFound` (expired or already answered).
  Future<String> accept(String invitationId);

  Future<void> decline(String invitationId);
}
