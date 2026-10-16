// Input validation returning typed errors (null = valid) so the UI can map
// them to localized messages. Lengths count Unicode code points.

enum UsernameError { tooShort, tooLong, invalidChars }

enum DisplayNameError { empty, tooLong }

enum JourneyTitleError { empty, tooLong }

enum CaptionError { tooLong }

enum InviteCodeError { wrongLength, invalidChars }

enum MetricValueError { notFinite, outOfRange }

enum DurationError { outOfRange }

const int usernameMin = 3;
const int usernameMax = 20;
const int displayNameMax = 40;
const int journeyTitleMax = 60;
const int captionMax = 140;
const int inviteCodeLength = 8;
const int durationMin = 7;
const int durationMax = 365;
const double metricValueMax = 100000;

int _len(String s) => s.runes.length;

final RegExp _usernameChars = RegExp(r'^[a-z0-9_.]+$');
final RegExp _inviteChars = RegExp(r'^[A-Z0-9]+$');

UsernameError? validateUsername(String value) {
  final n = _len(value);
  if (n < usernameMin) return UsernameError.tooShort;
  if (n > usernameMax) return UsernameError.tooLong;
  if (!_usernameChars.hasMatch(value)) return UsernameError.invalidChars;
  return null;
}

DisplayNameError? validateDisplayName(String value) {
  final n = _len(value.trim());
  if (n == 0) return DisplayNameError.empty;
  if (n > displayNameMax) return DisplayNameError.tooLong;
  return null;
}

JourneyTitleError? validateJourneyTitle(String value) {
  final n = _len(value.trim());
  if (n == 0) return JourneyTitleError.empty;
  if (n > journeyTitleMax) return JourneyTitleError.tooLong;
  return null;
}

CaptionError? validateCaption(String? value) {
  if (value != null && _len(value) > captionMax) return CaptionError.tooLong;
  return null;
}

/// Trims and upper-cases user input (paste from clipboard, manual typing).
String normalizeInviteCode(String raw) => raw.trim().toUpperCase();

InviteCodeError? validateInviteCode(String value) {
  if (value.length != inviteCodeLength) return InviteCodeError.wrongLength;
  if (!_inviteChars.hasMatch(value)) return InviteCodeError.invalidChars;
  return null;
}

/// Sanity range for a metric reading (weight, minutes, pages...).
MetricValueError? validateMetricValue(double? value) {
  if (value == null) return null;
  if (!value.isFinite) return MetricValueError.notFinite;
  if (value < 0 || value > metricValueMax) return MetricValueError.outOfRange;
  return null;
}

/// `null` means open-ended and is valid.
DurationError? validateDurationDays(int? days) {
  if (days == null) return null;
  if (days < durationMin || days > durationMax) return DurationError.outOfRange;
  return null;
}
