import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  const j = '11111111-1111-4111-8111-111111111111';
  const u = '22222222-2222-4222-8222-222222222222';
  const c = '33333333-3333-4333-8333-333333333333';

  test('check-in paths match the SQL CHECKs', () {
    expect(checkInPhotoPath(j, u, c), 'checkins/$j/$u/$c.jpg');
    expect(checkInThumbPath(j, u, c), 'checkins/$j/$u/${c}_t.jpg');
  });

  test('avatar path matches the SQL CHECK', () {
    expect(RegExp('^avatars/$u/[0-9a-f-]{36}\\.jpg\$').hasMatch(avatarPath(u, c)), isTrue);
  });

  test('public token format', () {
    expect(isValidPublicToken('a' * 40), isTrue);
    expect(isValidPublicToken('0123456789abcdefghij0123456789abcdefghij'), isTrue);
    expect(isValidPublicToken('A' * 40), isFalse);
    expect(isValidPublicToken('a' * 39), isFalse);
  });

  test('publicJourneyUri', () {
    final t = 'a' * 40;
    expect(publicJourneyUri(Uri.parse('https://x.supabase.co'), t).toString(),
        'https://x.supabase.co/functions/v1/public-journey?token=$t');
    expect(publicJourneyUri(Uri.parse('https://x.supabase.co/'), t).toString(),
        'https://x.supabase.co/functions/v1/public-journey?token=$t');
  });
}
