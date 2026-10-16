import '../../../app/redirect.dart' show kDeepLinkScheme;

/// Length of `journeys.invite_code` (docs/contracts/schema.md: 8 chars
/// `[A-Z0-9]`).
const int inviteCodeLength = 8;

/// Maximum members of a group journey (FR-D2, `journeys.max_members`).
const int maxGroupMembers = 10;

final RegExp _validCode = RegExp(r'^[A-Z0-9]{8}$');
final RegExp _separators = RegExp(r'[\s\-_.]');

/// Normalises what a user typed or pasted: trims, drops spaces/dashes,
/// upper-cases and accepts a pasted `ourney://join/<code>` link.
String normalizeInviteCode(String input) {
  var s = input.trim();
  final uri = Uri.tryParse(s);
  if (uri != null && uri.scheme == kDeepLinkScheme && uri.host == 'join') {
    s = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  }
  return s.replaceAll(_separators, '').toUpperCase();
}

/// True when [code] (already normalised) has the server's shape.
bool isValidInviteCode(String code) => _validCode.hasMatch(code);

/// Share link for an invite code: `ourney://join/<code>` (FR-D1).
String inviteLink(String code) =>
    Uri(scheme: kDeepLinkScheme, host: 'join', path: '/$code').toString();
