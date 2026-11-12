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
}
