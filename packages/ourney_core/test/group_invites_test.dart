import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  test('GroupPreview.fromJson parses the RPC payload', () {
    final p = GroupPreview.fromJson({
      'state': 'full',
      'title': 'Hoi IELTS',
      'emoji': 'x',
      'template_id': 'english_daily',
      'owner': {'display_name': 'Ha', 'avatar_path': null},
      'member_count': 10,
      'max_members': 10,
      'duration_days': 30,
      'day_number': 21,
      'members': [
        {'display_name': 'Ha'},
      ],
    });
    expect(p.state, GroupPreviewState.full);
    expect(p.canJoin, isFalse);
    expect(p.ownerName, 'Ha');
    expect(p.dayNumber, 21);
    expect(p.members.single.displayName, 'Ha');
  });

  test('unknown preview state never offers a join', () {
    expect(GroupPreviewState.fromWire('???'), GroupPreviewState.ended);
    expect(GroupPreviewState.fromWire(null).name, 'ended');
    expect(GroupPreviewState.fromWire('open'), GroupPreviewState.open);
  });

  test('GroupInvitation.fromJson parses inviter and dates', () {
    final i = GroupInvitation.fromJson({
      'id': 'i1',
      'journey_id': 'j1',
      'title': 'T',
      'emoji': 'e',
      'template_id': 'custom',
      'inviter': {'user_id': 'u', 'username': 'ha', 'display_name': 'Ha'},
      'member_count': 5,
      'max_members': 10,
      'created_at': '2026-11-01T10:00:00Z',
      'expires_at': '2026-11-08T10:00:00Z',
    });
    expect(i.inviter.displayName, 'Ha');
    expect(i.expiresAt.isAfter(i.createdAt), isTrue);
  });
}
