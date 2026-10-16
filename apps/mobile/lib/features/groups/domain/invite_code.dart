import 'package:ourney_core/ourney_core.dart';

import '../../../app/redirect.dart' show kDeepLinkScheme;

/// Maximum members of a group journey (FR-D2, `journeys.max_members`).
const int maxGroupMembers = 10;

final RegExp _separators = RegExp(r'[\s\-_.]');

/// Cleans what a user typed or pasted before `join_by_code`: accepts a
/// pasted `ourney://join/<code>` link, drops spaces/dashes, then applies
/// [normalizeInviteCode] (trim + upper-case).
String parseInviteInput(String input) {
  var s = input.trim();
  final uri = Uri.tryParse(s);
  if (uri != null && uri.scheme == kDeepLinkScheme && uri.host == 'join') {
    s = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  }
  return normalizeInviteCode(s.replaceAll(_separators, ''));
}

/// True when [code] (already parsed) has the server's shape (8 `[A-Z0-9]`).
bool isValidInviteCode(String code) => validateInviteCode(code) == null;

/// Share link for an invite code: `ourney://join/<code>` (FR-D1).
String inviteLink(String code) =>
    Uri(scheme: kDeepLinkScheme, host: 'join', path: '/$code').toString();
