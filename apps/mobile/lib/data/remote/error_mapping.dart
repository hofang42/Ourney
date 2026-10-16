import 'dart:async';
import 'dart:io';

import 'package:ourney_core/ourney_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps anything thrown by supabase_flutter (or dart:io) to an
/// [OurneyException]. Codes always come from [OurneyErrorCode.fromServer] /
/// [OurneyErrorCode.fromWire]; transport failures become `offline`.
OurneyException mapRemoteError(Object error) {
  switch (error) {
    case OurneyException():
      return error;
    case PostgrestException(:final message, :final code):
      return OurneyException(
        OurneyErrorCode.fromServer(message: message, sqlstate: code),
        '$code: $message',
      );
    case FunctionsFetchException():
      return OurneyException(OurneyErrorCode.offline, error.toString());
    case FunctionException(:final status, :final details):
      return OurneyException(_functionCode(status, details), error.toString());
    case StorageException(:final message, :final statusCode, :final error):
      return OurneyException(
        _storageCode(statusCode, message, error),
        '$statusCode: $message',
      );
    case AuthRetryableFetchException():
      return OurneyException(OurneyErrorCode.offline, error.toString());
    case AuthException(:final statusCode, :final message):
      return OurneyException(_authCode(statusCode), '$statusCode: $message');
    case SocketException() ||
        HttpException() ||
        TimeoutException() ||
        HandshakeException():
      return OurneyException(OurneyErrorCode.offline, error.toString());
  }
  // package:http ClientException (not a direct dependency): match by name.
  if (error.runtimeType.toString() == 'ClientException') {
    return OurneyException(OurneyErrorCode.offline, error.toString());
  }
  return OurneyException(OurneyErrorCode.unknown, error.toString());
}

OurneyErrorCode _functionCode(int status, Object? details) {
  if (details is Map && details['error'] is String) {
    final code = OurneyErrorCode.fromWire(details['error'] as String);
    if (code != OurneyErrorCode.unknown) return code;
  }
  return switch (status) {
    401 => OurneyErrorCode.unauthenticated,
    403 => OurneyErrorCode.forbidden,
    404 => OurneyErrorCode.notFound,
    405 => OurneyErrorCode.methodNotAllowed,
    >= 500 => OurneyErrorCode.internal,
    _ => OurneyErrorCode.unknown,
  };
}

OurneyErrorCode _storageCode(String? status, String message, String? error) {
  final byMessage = OurneyErrorCode.fromWire(error ?? message);
  if (byMessage != OurneyErrorCode.unknown) return byMessage;
  return switch (status) {
    '401' => OurneyErrorCode.unauthenticated,
    // Storage reports RLS denials as 400/403 "new row violates row-level
    // security policy".
    '403' => OurneyErrorCode.forbidden,
    '400' when message.contains('row-level security') =>
      OurneyErrorCode.forbidden,
    '404' => OurneyErrorCode.notFound,
    '413' || '415' => OurneyErrorCode.invalid,
    final s? when s.startsWith('5') => OurneyErrorCode.internal,
    _ => OurneyErrorCode.unknown,
  };
}

OurneyErrorCode _authCode(String? status) => switch (status) {
  '401' => OurneyErrorCode.unauthenticated,
  '403' => OurneyErrorCode.invalid, // expired / wrong OTP
  '422' || '400' => OurneyErrorCode.invalid,
  '429' => OurneyErrorCode.rateLimited,
  final s? when s.startsWith('5') => OurneyErrorCode.internal,
  _ => OurneyErrorCode.unknown,
};

/// Runs [body] and rethrows any failure as a mapped [OurneyException].
Future<T> guardRemote<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on Object catch (e) {
    throw mapRemoteError(e);
  }
}
