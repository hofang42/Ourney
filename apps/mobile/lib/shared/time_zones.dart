import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The single place that loads the IANA time zone database for the whole
/// app (journeys, check-in, groups, reminders, lib/data).
///
/// Uses `latest_all` (every zone and backward-compatible link). `latest`
/// lacks links that devices still report, e.g. `Asia/Saigon` (Vietnamese
/// Android builds), `Asia/Calcutta` or `US/Pacific`, which used to fall back
/// to UTC silently. Pure Dart, no platform channel; loaded lazily on first
/// use so app start stays fast.
void ensureTimeZonesLoaded() {
  // Own flag: a package that initialised the smaller `latest` set first
  // must not stop us from loading the full one.
  if (_loaded) return;
  tzdata.initializeTimeZones();
  _loaded = true;
}

bool _loaded = false;

/// Legacy / backward-compatible names mapped to the canonical IANA name the
/// app stores (journeys.timezone) and the server compares with.
const Map<String, String> legacyTimeZoneAliases = {
  // Asia
  'Asia/Saigon': 'Asia/Ho_Chi_Minh',
  'Asia/Calcutta': 'Asia/Kolkata',
  'Asia/Katmandu': 'Asia/Kathmandu',
  'Asia/Rangoon': 'Asia/Yangon',
  'Asia/Dacca': 'Asia/Dhaka',
  'Asia/Thimbu': 'Asia/Thimphu',
  'Asia/Ujung_Pandang': 'Asia/Makassar',
  'Asia/Ulan_Bator': 'Asia/Ulaanbaatar',
  'Asia/Chongqing': 'Asia/Shanghai',
  'Asia/Chungking': 'Asia/Shanghai',
  'Asia/Harbin': 'Asia/Shanghai',
  'Asia/Macao': 'Asia/Macau',
  'Asia/Tel_Aviv': 'Asia/Jerusalem',
  'Asia/Istanbul': 'Europe/Istanbul',
  'Asia/Ashkhabad': 'Asia/Ashgabat',
  'Hongkong': 'Asia/Hong_Kong',
  'Japan': 'Asia/Tokyo',
  'Singapore': 'Asia/Singapore',
  'ROK': 'Asia/Seoul',
  'ROC': 'Asia/Taipei',
  'PRC': 'Asia/Shanghai',
  'Israel': 'Asia/Jerusalem',
  'Iran': 'Asia/Tehran',
  // United States / Canada
  'US/Pacific': 'America/Los_Angeles',
  'US/Mountain': 'America/Denver',
  'US/Arizona': 'America/Phoenix',
  'US/Central': 'America/Chicago',
  'US/Eastern': 'America/New_York',
  'US/East-Indiana': 'America/Indiana/Indianapolis',
  'US/Indiana-Starke': 'America/Indiana/Knox',
  'US/Michigan': 'America/Detroit',
  'US/Alaska': 'America/Anchorage',
  'US/Aleutian': 'America/Adak',
  'US/Hawaii': 'Pacific/Honolulu',
  'US/Samoa': 'Pacific/Pago_Pago',
  'America/Indianapolis': 'America/Indiana/Indianapolis',
  'America/Fort_Wayne': 'America/Indiana/Indianapolis',
  'America/Louisville': 'America/Kentucky/Louisville',
  'America/Buenos_Aires': 'America/Argentina/Buenos_Aires',
  'America/Godthab': 'America/Nuuk',
  'Canada/Pacific': 'America/Vancouver',
  'Canada/Mountain': 'America/Edmonton',
  'Canada/Central': 'America/Winnipeg',
  'Canada/Eastern': 'America/Toronto',
  'Canada/Atlantic': 'America/Halifax',
  'Canada/Newfoundland': 'America/St_Johns',
  // Europe / Africa / Pacific
  'Europe/Kiev': 'Europe/Kyiv',
  'GB': 'Europe/London',
  'Turkey': 'Europe/Istanbul',
  'Egypt': 'Africa/Cairo',
  'Africa/Asmera': 'Africa/Asmara',
  'Atlantic/Faeroe': 'Atlantic/Faroe',
  'Australia/ACT': 'Australia/Sydney',
  'Australia/NSW': 'Australia/Sydney',
  'Australia/Canberra': 'Australia/Sydney',
  'Australia/Victoria': 'Australia/Melbourne',
  'Australia/Queensland': 'Australia/Brisbane',
  'Australia/West': 'Australia/Perth',
  'Australia/South': 'Australia/Adelaide',
  'Australia/North': 'Australia/Darwin',
  'Australia/Tasmania': 'Australia/Hobart',
  'NZ': 'Pacific/Auckland',
  'Pacific/Samoa': 'Pacific/Pago_Pago',
  'Pacific/Truk': 'Pacific/Chuuk',
  'Pacific/Yap': 'Pacific/Chuuk',
  'Pacific/Ponape': 'Pacific/Pohnpei',
  'Pacific/Enderbury': 'Pacific/Kanton',
  // UTC spellings
  'Etc/UTC': 'UTC',
  'Etc/UCT': 'UTC',
  'UCT': 'UTC',
  'Etc/Universal': 'UTC',
  'Universal': 'UTC',
  'Etc/Zulu': 'UTC',
  'Zulu': 'UTC',
  'Etc/GMT': 'UTC',
  'GMT': 'UTC',
  'Etc/Greenwich': 'UTC',
  'Greenwich': 'UTC',
};

/// [name] trimmed, with a legacy alias replaced by its canonical name.
/// Does not check that the zone exists (see [resolveTimeZone]).
String canonicalTimeZoneName(String name) {
  final trimmed = name.trim();
  return legacyTimeZoneAliases[trimmed] ?? trimmed;
}

/// True when [name] (after alias mapping) is in the IANA database.
bool isKnownTimeZone(String name) {
  ensureTimeZonesLoaded();
  return tz.timeZoneDatabase.locations.containsKey(canonicalTimeZoneName(name));
}

final Map<String, tz.Location> _guesses = {};

/// The location for [name]: alias -> canonical name, then the database.
///
/// An unknown name never falls back to UTC silently: the best canonical
/// guess is used and logged once per name. Guesses, in order: a
/// case-insensitive match, a zone with the same city (last segment), then a
/// zone with the device's current UTC offset ([deviceOffset] for tests).
tz.Location resolveTimeZone(String name, {Duration? deviceOffset}) {
  ensureTimeZonesLoaded();
  final canonical = canonicalTimeZoneName(name);
  final db = tz.timeZoneDatabase.locations;
  final exact = db[canonical];
  if (exact != null) return exact;
  final cached = _guesses[canonical];
  if (cached != null) return cached;

  final guess = _guess(
    canonical,
    deviceOffset ?? DateTime.now().timeZoneOffset,
  );
  debugPrint(
    'time_zones: unknown time zone "$name", using "${guess.name}" instead',
  );
  return _guesses[canonical] = guess;
}

tz.Location _guess(String name, Duration deviceOffset) {
  final db = tz.timeZoneDatabase.locations;
  final lower = name.toLowerCase();
  for (final entry in db.entries) {
    if (entry.key.toLowerCase() == lower) {
      return db[canonicalTimeZoneName(entry.key)] ?? entry.value;
    }
  }
  final city = lower.split('/').last.replaceAll(' ', '_');
  if (city.isNotEmpty && name.contains('/')) {
    for (final entry in db.entries) {
      if (entry.key.toLowerCase().split('/').last == city) {
        return db[canonicalTimeZoneName(entry.key)] ?? entry.value;
      }
    }
  }
  return guessTimeZoneForOffset(deviceOffset);
}

/// A canonical zone whose current offset is [offset]: `UTC` for zero, a
/// fixed `Etc/GMT±N` zone for whole hours (note the POSIX sign inversion),
/// otherwise the first regional zone currently at that offset.
tz.Location guessTimeZoneForOffset(Duration offset, {DateTime? at}) {
  ensureTimeZonesLoaded();
  final db = tz.timeZoneDatabase.locations;
  if (offset == Duration.zero) return db['UTC']!;
  if (offset.inMinutes % 60 == 0) {
    final hours = offset.inHours;
    final etc = db['Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}'];
    if (etc != null) return etc;
  }
  final ms = (at ?? DateTime.now()).millisecondsSinceEpoch;
  for (final entry in db.entries) {
    if (!entry.key.contains('/') || entry.key.startsWith('Etc/')) continue;
    if (legacyTimeZoneAliases.containsKey(entry.key)) continue;
    if (Duration(milliseconds: entry.value.timeZone(ms).offset) == offset) {
      return entry.value;
    }
  }
  return db['UTC']!;
}

/// UTC offset of zone [name] at [instant] (see [resolveTimeZone]).
Duration timeZoneOffsetAt(String name, DateTime instant) {
  return Duration(
    milliseconds:
        resolveTimeZone(name).timeZone(instant.millisecondsSinceEpoch).offset,
  );
}

@visibleForTesting
void resetTimeZoneGuesses() => _guesses.clear();
