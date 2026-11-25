// Storage paths and server endpoints fixed by docs/contracts/schema.md.
// The server CHECKs these exact shapes, so never build them by hand.

/// Private storage bucket for all media.
const String mediaBucket = 'media';

/// `check_ins.photo_path` = `checkins/{journey_id}/{user_id}/{id}.jpg`.
String checkInPhotoPath(String journeyId, String userId, String checkInId) =>
    'checkins/$journeyId/$userId/$checkInId.jpg';

/// `check_ins.thumb_path` = `checkins/{journey_id}/{user_id}/{id}_t.jpg`.
String checkInThumbPath(String journeyId, String userId, String checkInId) =>
    'checkins/$journeyId/$userId/${checkInId}_t.jpg';

/// `check_ins.partner_photo_path` = `checkins/{journey_id}/{user_id}/{id}_p.jpg`
/// (couple journeys; lives in the author's folder like the photo).
String checkInPartnerPhotoPath(
  String journeyId,
  String userId,
  String checkInId,
) =>
    'checkins/$journeyId/$userId/${checkInId}_p.jpg';

/// `profiles.avatar_path` = `avatars/{user_id}/{uuid}.jpg` (new uuid per upload).
String avatarPath(String userId, String fileId) =>
    'avatars/$userId/$fileId.jpg';

/// Edge Function names (`/functions/v1/<name>`).
const String deleteAccountFunction = 'delete-account';
const String publicJourneyFunction = 'public-journey';

final RegExp _legacyPublicToken = RegExp(r'^[a-z0-9]{32,64}$');
final RegExp _readablePublicSlug = RegExp(
  r'^[a-z0-9]+(?:-[a-z0-9]+)*-[a-z2-7]{16}$',
);

/// A public journey's legacy token or readable slug.
bool isValidPublicToken(String token) =>
    _legacyPublicToken.hasMatch(token) ||
    (token.length <= 40 && _readablePublicSlug.hasMatch(token));

final RegExp _neutralPublicSlug = RegExp(r'^journey-[a-z2-7]{16}$');

/// A readable address whose prefix may contain the owner's title.
bool isTitledPublicSlug(String? token) =>
    token != null &&
    token.length <= 40 &&
    _readablePublicSlug.hasMatch(token) &&
    !_neutralPublicSlug.hasMatch(token);

/// Canonical public web host for Ourney share links.
const String ourneyWebHost = 'ourney.tech';

/// Human-facing share link for a public journey (`https://ourney.tech/p/<token>`).
/// Opens the `/p/:token` route in the app (via Universal/App Links) or the
/// web page on `ourney.tech` which fetches [publicJourneyUri].
String publicJourneyLink(String token) =>
    'https://$ourneyWebHost/p/${Uri.encodeComponent(token)}';

/// [Uri] form of [publicJourneyLink].
Uri publicJourneyShareUri(String token) => Uri.parse(publicJourneyLink(token));

/// JSON endpoint of the read-only public view of a solo `link` journey
/// (used by the `ourney.tech/p/<token>` web page):
/// `GET {supabaseUrl}/functions/v1/public-journey?token=<token>` (404
/// `{"error":"not_found"}` for unknown/revoked tokens).
Uri publicJourneyUri(Uri supabaseUrl, String token) {
  final base = supabaseUrl.path.endsWith('/')
      ? supabaseUrl.path.substring(0, supabaseUrl.path.length - 1)
      : supabaseUrl.path;
  return supabaseUrl.replace(
    path: '$base/functions/v1/$publicJourneyFunction',
    queryParameters: {'token': token},
  );
}
