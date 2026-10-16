import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

// Every code raised by supabase/migrations/*.sql (`raise exception '<code>'`)
// and returned by supabase/functions/*/index.ts (`{ error: "<code>" }`).
const sqlRaised = [
  'unauthenticated',
  'forbidden',
  'invalid',
  'not_found',
  'full',
  'blocked',
  'limit',
  'ended',
  'not_alone',
  'rate_limited',
  'immutable_column',
  'invalid_captured_at',
];
const edgeFunctionErrors = [
  'method_not_allowed',
  'unauthenticated',
  'storage_listing_failed',
  'storage_cleanup_incomplete',
  'storage_cleanup_failed',
  'delete_failed',
  'not_found',
  'internal',
];

void main() {
  test('every server code is representable', () {
    for (final w in [...sqlRaised, ...edgeFunctionErrors]) {
      final c = OurneyErrorCode.fromWire(w);
      expect(c, isNot(OurneyErrorCode.unknown), reason: w);
      expect(c.wireName, w);
    }
  });

  test('wire names are unique', () {
    final names = OurneyErrorCode.values.map((c) => c.wireName).toList();
    expect(names.toSet().length, names.length);
  });

  test('unknown strings map to unknown', () {
    expect(OurneyErrorCode.fromWire('something_new'), OurneyErrorCode.unknown);
  });

  group('fromServer', () {
    test('message wins over sqlstate', () {
      expect(OurneyErrorCode.fromServer(message: 'forbidden', sqlstate: '42501'), OurneyErrorCode.forbidden);
      expect(OurneyErrorCode.fromServer(message: 'not_alone', sqlstate: 'P0001'), OurneyErrorCode.notAlone);
      expect(
          OurneyErrorCode.fromServer(message: 'immutable_column', sqlstate: '23514'), OurneyErrorCode.immutableColumn);
    });
    test('sqlstate fallback', () {
      expect(OurneyErrorCode.fromServer(message: 'new row violates row-level security policy', sqlstate: '42501'),
          OurneyErrorCode.forbidden);
      expect(OurneyErrorCode.fromServer(sqlstate: '28000'), OurneyErrorCode.unauthenticated);
      expect(OurneyErrorCode.fromServer(sqlstate: '22008'), OurneyErrorCode.invalidCapturedAt);
      expect(OurneyErrorCode.fromServer(message: 'time zone "X" not recognized', sqlstate: '22023'),
          OurneyErrorCode.invalid);
      expect(OurneyErrorCode.fromServer(sqlstate: '23514'), OurneyErrorCode.invalid);
      expect(OurneyErrorCode.fromServer(sqlstate: 'XX000'), OurneyErrorCode.unknown);
      expect(OurneyErrorCode.fromServer(), OurneyErrorCode.unknown);
    });
  });

  group('exceptions', () {
    test('GroupException from wire string keeps code', () {
      final e = GroupException('full');
      expect(e.code, 'full');
      expect(e.error, OurneyErrorCode.full);
      expect(e, isA<OurneyException>());
    });
    test('GroupException.of', () {
      expect(const GroupException.of(OurneyErrorCode.offline).code, 'offline');
    });
    test('JourneyLimitException is limit', () {
      const e = JourneyLimitException();
      expect(e.error, OurneyErrorCode.limit);
      expect(e, isA<OurneyException>());
    });
  });
}
