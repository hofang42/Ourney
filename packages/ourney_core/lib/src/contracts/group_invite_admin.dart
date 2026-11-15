// Inviter-side invitation management (supabase/migrations/0010).
//
//   GroupInviteAdminRepository.sent        -> rpc journey_pending_invitations
//   GroupInviteAdminRepository.revoke      -> rpc revoke_group_invitation
//   GroupInviteAdminRepository.renameCouple -> rpc rename_couple

import 'social.dart';

/// One pending invitation of a group, as listed to its members.
class SentGroupInvitation {
  const SentGroupInvitation({
    required this.id,
    required this.invitee,
    required this.inviter,
    required this.canRevoke,
    required this.createdAt,
    required this.expiresAt,
  });

  factory SentGroupInvitation.fromJson(Map<String, dynamic> json) {
    PersonSummary person(Object? raw) {
      final p = (raw as Map?)?.cast<String, dynamic>() ?? const {};
      return PersonSummary(
        userId: p['user_id'] as String? ?? '',
        username: p['username'] as String? ?? '',
        displayName: p['display_name'] as String? ?? '',
        avatarPath: p['avatar_path'] as String?,
      );
    }

    return SentGroupInvitation(
      id: json['id'] as String,
      invitee: person(json['invitee']),
      inviter: person(json['inviter']),
      canRevoke: json['can_revoke'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String id;
  final PersonSummary invitee;
  final PersonSummary inviter;

  /// The caller is the inviter or the journey owner.
  final bool canRevoke;
  final DateTime createdAt;
  final DateTime expiresAt;
}

abstract interface class GroupInviteAdminRepository {
  /// Pending invitations of [journeyId], newest first. Throws
  /// `GroupException` `forbidden` for non-members.
  Future<List<SentGroupInvitation>> sent(String journeyId);

  /// Withdraws a pending invitation (inviter or owner). `notFound` when it
  /// was already answered.
  Future<void> revoke(String invitationId);

  /// Owner only. Both names are required (1..24 chars).
  Future<void> renameCouple(String journeyId, String self, String partner);
}
