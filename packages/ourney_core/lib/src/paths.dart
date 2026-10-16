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

/// `profiles.avatar_path` = `avatars/{user_id}/{uuid}.jpg` (new uuid per upload).
String avatarPath(String userId, String fileId) => 'avatars/$userId/$fileId.jpg';

/// Edge Function names (`/functions/v1/<name>`).
const String deleteAccountFunction = 'delete-account';
const String publicJourneyFunction = 'public-journey';

final RegExp _publicToken = RegExp(r'^[a-z0-9]{40}$');

/// `journeys.public_token` as issued by `set_public_link` / `create_journey`.
bool isValidPublicToken(String token) => _publicToken.hasMatch(token);

/// JSON endpoint of the read-only public view of a solo `link` journey:
/// `GET {supabaseUrl}/functions/v1/public-journey?token=<token>` (404
/// `{"error":"not_found"}` for unknown/revoked tokens). The human-facing share
/// link is a static page that calls this endpoint.
Uri publicJourneyUri(Uri supabaseUrl, String token) {
  final base =
      supabaseUrl.path.endsWith('/') ? supabaseUrl.path.substring(0, supabaseUrl.path.length - 1) : supabaseUrl.path;
  return supabaseUrl.replace(
    path: '$base/functions/v1/$publicJourneyFunction',
    queryParameters: {'token': token},
  );
}
