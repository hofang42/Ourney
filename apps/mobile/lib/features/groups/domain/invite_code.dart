import 'package:ourney_core/ourney_core.dart';

import '../../../app/redirect.dart' show kDeepLinkWebHost;

/// Maximum members of a group journey (FR-D2, `journeys.max_members`).
const int maxGroupMembers = 10;

final RegExp _separators = RegExp(r'[\s\-_.]');
final RegExp _embeddedInviteUrl = RegExp(
  r'(?:(?:https?://|(?<![A-Za-z0-9.\-/]))ourney\.tech/(?:j|join)|ourney://(?:join|j))/([A-Za-z0-9\-_.]+)',
  caseSensitive: false,
);

/// Cleans what a user typed or pasted before `join_by_code`: accepts a
/// pasted `https://ourney.tech/j/<code>`, `ourney.tech/j/<code>`, or
/// `ourney://join/<code>` link (or a message containing one), drops
/// spaces/dashes, then applies [normalizeInviteCode] (trim + upper-case).
String parseInviteInput(String input) {
  var s = input.trim();
  final match = _embeddedInviteUrl.firstMatch(s);
  if (match != null) {
    s = match.group(1)!;
  } else if (s.contains('://') || s.contains('/')) {
    return '';
  }
  return normalizeInviteCode(s.replaceAll(_separators, ''));
}

/// True when [code] (already parsed) has the server's shape (8 `[A-Z0-9]`).
bool isValidInviteCode(String code) => validateInviteCode(code) == null;

/// Share link for an invite code: `https://ourney.tech/j/<code>` (FR-D1).
String inviteLink(String code) =>
    'https://$kDeepLinkWebHost/j/${Uri.encodeComponent(normalizeInviteCode(code))}';
