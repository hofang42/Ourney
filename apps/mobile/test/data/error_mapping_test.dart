import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/remote/error_mapping.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

OurneyErrorCode codeOf(Object e) => mapRemoteError(e).error;

void main() {
  group('PostgrestException', () {
    test('raised message wins (0004_rpc.sql codes)', () {
      for (final c in [
        'limit',
        'not_found',
        'full',
        'blocked',
        'ended',
        'not_alone',
        'rate_limited',
        'consent_required',
      ]) {
        expect(
          codeOf(PostgrestException(message: c, code: 'P0001')),
          OurneyErrorCode.fromWire(c),
        );
      }
      expect(
        codeOf(const PostgrestException(message: 'forbidden', code: '42501')),
        OurneyErrorCode.forbidden,
      );
    });

    test('SQLSTATE decides otherwise', () {
      expect(
        codeOf(
          const PostgrestException(
            message: 'new row violates row-level security policy',
            code: '42501',
          ),
        ),
        OurneyErrorCode.forbidden,
      );
      expect(
        codeOf(
          const PostgrestException(
            message: 'invalid_captured_at',
            code: '22008',
          ),
        ),
        OurneyErrorCode.invalidCapturedAt,
      );
      expect(
        codeOf(
          const PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          ),
        ),
        OurneyErrorCode.invalid,
      );
      expect(
        codeOf(const PostgrestException(message: 'boom', code: 'XX000')),
        OurneyErrorCode.unknown,
      );
    });

    test('keeps the raw message as detail', () {
      final e = mapRemoteError(
        const PostgrestException(message: 'limit', code: 'P0001'),
      );
      expect(e.detail, contains('limit'));
      expect(e.code, 'limit');
    });
  });

  group('Edge Functions', () {
    test('error body code wins', () {
      expect(
        codeOf(
          const FunctionsHttpException(
            status: 500,
            details: {'error': 'storage_cleanup_failed'},
          ),
        ),
        OurneyErrorCode.storageCleanupFailed,
      );
      expect(
        codeOf(
          const FunctionsHttpException(
            status: 401,
            details: {'error': 'unauthenticated'},
          ),
        ),
        OurneyErrorCode.unauthenticated,
      );
    });

    test('410 already_deleted is distinct from a 401', () {
      expect(
        codeOf(
          const FunctionsHttpException(
            status: 410,
            details: {'error': 'already_deleted'},
          ),
        ),
        OurneyErrorCode.alreadyDeleted,
      );
      expect(
        codeOf(const FunctionsHttpException(status: 410)),
        OurneyErrorCode.alreadyDeleted,
      );
      expect(
        codeOf(const FunctionsHttpException(status: 401)),
        OurneyErrorCode.unauthenticated,
      );
    });

    test('falls back to the HTTP status', () {
      expect(
        codeOf(const FunctionsHttpException(status: 404)),
        OurneyErrorCode.notFound,
      );
      expect(
        codeOf(const FunctionsHttpException(status: 405)),
        OurneyErrorCode.methodNotAllowed,
      );
      expect(
        codeOf(const FunctionsHttpException(status: 503)),
        OurneyErrorCode.internal,
      );
    });

    test('transport failure is offline', () {
      expect(
        codeOf(const FunctionsFetchException(details: 'x')),
        OurneyErrorCode.offline,
      );
    });
  });

  group('Storage', () {
    test('maps status codes', () {
      expect(
        codeOf(
          const StorageException(
            'Object not found',
            statusCode: '404',
            error: 'not_found',
          ),
        ),
        OurneyErrorCode.notFound,
      );
      expect(
        codeOf(
          const StorageException(
            'new row violates row-level security policy',
            statusCode: '400',
          ),
        ),
        OurneyErrorCode.forbidden,
      );
      expect(
        codeOf(const StorageException('x', statusCode: '403')),
        OurneyErrorCode.forbidden,
      );
      expect(
        codeOf(const StorageException('too big', statusCode: '413')),
        OurneyErrorCode.invalid,
      );
      expect(
        codeOf(const StorageException('x', statusCode: '502')),
        OurneyErrorCode.internal,
      );
    });
  });

  group('Auth', () {
    test('wrong OTP is invalid, 429 rate limited, network offline', () {
      expect(
        codeOf(const AuthException('Token has expired', statusCode: '403')),
        OurneyErrorCode.invalid,
      );
      expect(
        codeOf(const AuthException('slow down', statusCode: '429')),
        OurneyErrorCode.rateLimited,
      );
      expect(
        codeOf(AuthRetryableFetchException(message: 'x')),
        OurneyErrorCode.offline,
      );
    });

    test('Auth error_code wins over the HTTP status', () {
      AuthException ex(String code, [String status = '400']) =>
          AuthException('x', statusCode: status, code: code);
      expect(
        codeOf(ex('phone_provider_disabled')),
        OurneyErrorCode.unavailable,
      );
      expect(codeOf(ex('sms_provider_disabled')), OurneyErrorCode.unavailable);
      expect(
        codeOf(ex('email_provider_disabled')),
        OurneyErrorCode.unavailable,
      );
      expect(codeOf(ex('signup_disabled', '422')), OurneyErrorCode.unavailable);
      expect(codeOf(ex('otp_disabled', '422')), OurneyErrorCode.unavailable);
      expect(codeOf(ex('sms_send_failed')), OurneyErrorCode.internal);
      expect(
        codeOf(ex('email_address_not_authorized')),
        OurneyErrorCode.forbidden,
      );
      expect(codeOf(ex('captcha_failed')), OurneyErrorCode.forbidden);
      expect(codeOf(ex('user_banned', '403')), OurneyErrorCode.forbidden);
      expect(
        codeOf(ex('reauthentication_needed', '400')),
        OurneyErrorCode.invalid,
      );
      expect(
        codeOf(ex('reauthentication_not_valid', '400')),
        OurneyErrorCode.invalid,
      );
      expect(codeOf(ex('otp_expired', '500')), OurneyErrorCode.invalid);
      expect(codeOf(ex('validation_failed', '500')), OurneyErrorCode.invalid);
      expect(
        codeOf(ex('email_address_invalid', '500')),
        OurneyErrorCode.invalid,
      );
      expect(codeOf(ex('phone_invalid', '500')), OurneyErrorCode.invalid);
      expect(codeOf(ex('same_password', '422')), OurneyErrorCode.invalid);
      expect(codeOf(ex('weak_password', '422')), OurneyErrorCode.invalid);
      expect(
        mapRemoteError(ex('same_password', '422')).detail,
        contains('same_password'),
      );
      expect(
        codeOf(ex('over_sms_send_rate_limit')),
        OurneyErrorCode.rateLimited,
      );
      expect(
        codeOf(ex('over_email_send_rate_limit')),
        OurneyErrorCode.rateLimited,
      );
      expect(
        codeOf(ex('over_request_rate_limit', '400')),
        OurneyErrorCode.rateLimited,
      );
      // No code: the status decides.
      expect(
        codeOf(const AuthException('bad', statusCode: '400')),
        OurneyErrorCode.invalid,
      );
    });
  });

  test('network errors are offline, OurneyException passes through', () {
    expect(codeOf(const SocketException('no route')), OurneyErrorCode.offline);
    expect(codeOf(TimeoutException('t')), OurneyErrorCode.offline);
    expect(codeOf(const HttpException('reset')), OurneyErrorCode.offline);
    const own = OurneyException(OurneyErrorCode.ended);
    expect(identical(mapRemoteError(own), own), isTrue);
    expect(codeOf(StateError('?')), OurneyErrorCode.unknown);
  });

  test('guardRemote rethrows mapped exceptions', () async {
    await expectLater(
      guardRemote<void>(
        () async =>
            throw const PostgrestException(message: 'full', code: 'P0001'),
      ),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.full,
        ),
      ),
    );
  });

  test('PGRST202 / PGRST203 mean the server is outdated', () {
    for (final code in ['PGRST202', 'PGRST203']) {
      final e = mapRemoteError(
        PostgrestException(message: 'Could not find the function', code: code),
      );
      expect(e.error, OurneyErrorCode.serverOutdated);
      expect(e.detail, contains(code));
    }
  });

  test(
    'FormatException from row mapping becomes unknown with detail',
    () async {
      final e = mapRemoteError(const FormatException('bad enum "x"'));
      expect(e.error, OurneyErrorCode.unknown);
      expect(e.detail, startsWith('bad data:'));
      expect(e.detail, contains('bad enum'));
      await expectLater(
        guardRemote<void>(() async => throw const FormatException('row')),
        throwsA(isA<OurneyException>()),
      );
    },
  );
}
