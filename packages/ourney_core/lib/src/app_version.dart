/// Semantic Versioning precedence. Build metadata is retained for display and
/// ignored by comparisons, including equality.
final class SemVer implements Comparable<SemVer> {
  SemVer._(this.major, this.minor, this.patch, this._pre, this.build);

  static final _pattern = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
    r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
    r'(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
  );
  static final _digits = RegExp(r'^[0-9]+$');

  final BigInt major;
  final BigInt minor;
  final BigInt patch;
  final List<String> _pre;
  final String? build;

  static SemVer? tryParse(String? value) {
    if (value == null) return null;
    final match = _pattern.firstMatch(value);
    if (match == null || match.end != value.length) return null;

    final pre = match[4]?.split('.') ?? const <String>[];
    if (pre.any(
      (p) => p.length > 1 && p.startsWith('0') && _digits.hasMatch(p),
    )) {
      return null;
    }
    return SemVer._(
      BigInt.parse(match[1]!),
      BigInt.parse(match[2]!),
      BigInt.parse(match[3]!),
      pre,
      match[5],
    );
  }

  /// Stable per-version key for snoozes, skips and seen releases.
  String get precedence => _pre.isEmpty
      ? '$major.$minor.$patch'
      : '$major.$minor.$patch-${_pre.join('.')}';

  @override
  String toString() => build == null ? precedence : '$precedence+$build';

  @override
  int compareTo(SemVer other) {
    final majorOrder = major.compareTo(other.major);
    if (majorOrder != 0) return majorOrder;
    final minorOrder = minor.compareTo(other.minor);
    if (minorOrder != 0) return minorOrder;
    final patchOrder = patch.compareTo(other.patch);
    if (patchOrder != 0) return patchOrder;

    if (_pre.isEmpty || other._pre.isEmpty) {
      return other._pre.isEmpty ? (_pre.isEmpty ? 0 : -1) : 1;
    }
    for (var i = 0; i < _pre.length && i < other._pre.length; i++) {
      final left = _pre[i];
      final right = other._pre[i];
      if (left == right) continue;
      final leftNumeric = _digits.hasMatch(left);
      final rightNumeric = _digits.hasMatch(right);
      if (leftNumeric != rightNumeric) return leftNumeric ? -1 : 1;
      if (leftNumeric && left.length != right.length) {
        return left.length.compareTo(right.length);
      }
      return left.compareTo(right);
    }
    return _pre.length.compareTo(other._pre.length);
  }

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, Object.hashAll(_pre));
}

enum UpdatePlatform { android, ios }

final _androidDownloadUrl = Uri.parse('https://ourney.tech/Ourney.apk');

bool isAllowedUpdateUrl(Uri uri) {
  if (uri.scheme != 'https' || uri.authority.contains('@') || uri.port != 443) {
    return false;
  }
  if (uri.host == 'github.com') {
    return uri.path.startsWith('/hofang42/ourney-releases/releases/') &&
        !uri.pathSegments.any(
          (part) =>
              part == '.' ||
              part == '..' ||
              part.contains('/') ||
              part.contains('\\'),
        );
  }
  return const {
    'ourney.tech',
    'www.ourney.tech',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
    'play.google.com',
    'apps.apple.com',
    'testflight.apple.com',
  }.contains(uri.host);
}

final class UpdateReleaseNotes {
  UpdateReleaseNotes({required List<String> vi, required List<String> en})
      : vi = List.unmodifiable(vi),
        en = List.unmodifiable(en);

  final List<String> vi;
  final List<String> en;

  bool get isNotEmpty => vi.isNotEmpty || en.isNotEmpty;

  List<String> forLanguage(String languageCode) {
    if (languageCode == 'vi') return vi.isNotEmpty ? vi : en;
    return en.isNotEmpty ? en : vi;
  }

  Map<String, Object> toJson() => {'vi': vi, 'en': en};
}

final class AppUpdateManifest {
  const AppUpdateManifest._({
    required this.platform,
    required this.latest,
    required this.latestBuild,
    required this.recommended,
    required this.minSupported,
    required this.forceOnMajor,
    required this.killSwitch,
    required this.downloadUrl,
    required this.notes,
    required this.updatedAt,
  });

  final UpdatePlatform platform;
  final SemVer latest;
  final int latestBuild;
  final SemVer recommended;
  final SemVer minSupported;
  final bool forceOnMajor;
  final bool killSwitch;
  final Uri? downloadUrl;
  final UpdateReleaseNotes notes;
  final DateTime updatedAt;

  /// Accepts unknown fields so newer servers can extend the wire format.
  /// A malformed policy is treated as a failed check by the caller.
  static AppUpdateManifest? tryFromJson(Object? json) {
    if (json
        case {
          'platform': String platformName,
          'latest': String latestRaw,
          'latest_build': int build,
          'recommended': String recommendedRaw,
          'min_supported': String minRaw,
          'force_on_major': bool forceOnMajor,
          'kill_switch': bool killSwitch,
          'download_url': final rawUrl,
          'notes': {'vi': List<Object?> vi, 'en': List<Object?> en},
          'updated_at': String updatedAtRaw,
        }) {
      final platform = switch (platformName) {
        'android' => UpdatePlatform.android,
        'ios' => UpdatePlatform.ios,
        _ => null,
      };
      final latest = SemVer.tryParse(latestRaw);
      final recommended = SemVer.tryParse(recommendedRaw);
      final minSupported = SemVer.tryParse(minRaw);
      final updatedAt = DateTime.tryParse(updatedAtRaw);
      final url = rawUrl is String ? Uri.tryParse(rawUrl) : null;
      if (!killSwitch &&
          rawUrl != null &&
          (url == null || !isAllowedUpdateUrl(url))) {
        return null;
      }
      if (platform == null ||
          latest == null ||
          recommended == null ||
          minSupported == null ||
          updatedAt == null ||
          build < 1 ||
          latest.compareTo(recommended) < 0 ||
          recommended.compareTo(minSupported) < 0 ||
          vi.any((line) => line is! String || line.trim().isEmpty) ||
          en.any((line) => line is! String || line.trim().isEmpty)) {
        return null;
      }
      return AppUpdateManifest._(
        platform: platform,
        latest: latest,
        latestBuild: build,
        recommended: recommended,
        minSupported: minSupported,
        forceOnMajor: forceOnMajor,
        killSwitch: killSwitch,
        downloadUrl: rawUrl == null && platform == UpdatePlatform.android
            ? _androidDownloadUrl
            : url != null && isAllowedUpdateUrl(url)
                ? url
                : null,
        notes: UpdateReleaseNotes(vi: vi.cast<String>(), en: en.cast<String>()),
        updatedAt: updatedAt,
      );
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'platform': platform.name,
        'latest': latest.toString(),
        'latest_build': latestBuild,
        'recommended': recommended.toString(),
        'min_supported': minSupported.toString(),
        'force_on_major': forceOnMajor,
        'kill_switch': killSwitch,
        'download_url': downloadUrl?.toString(),
        'notes': notes.toJson(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

enum UpdateUrgency { none, passive, softBanner, softSheet, forced }

const updateInstallGrace = Duration(days: 1);
const updateForcedCacheTtl = Duration(days: 7);

/// A per-release snooze. The third dismissal ends automatic sheet reminders.
final class UpdateSnooze {
  const UpdateSnooze({required this.version, required this.count, this.until});

  final SemVer version;
  final int count;
  final DateTime? until;

  UpdateSnooze next(SemVer latest, DateTime now) {
    final nextCount = version != latest
        ? 1
        : count >= 3
            ? 3
            : count + 1;
    final until = switch (nextCount) {
      1 => now.add(const Duration(days: 3)),
      2 => now.add(const Duration(days: 7)),
      _ => null,
    };
    return UpdateSnooze(version: latest, count: nextCount, until: until);
  }

  bool suppresses(SemVer latest, DateTime now) =>
      version == latest && (count >= 3 || until?.isAfter(now) == true);
}

final class UpdateDecision {
  const UpdateDecision({
    this.urgency = UpdateUrgency.none,
    this.showHubBanner = false,
    this.canShowWhatsNew = false,
  });

  final UpdateUrgency urgency;
  final bool showHubBanner;
  final bool canShowWhatsNew;

  bool get showSettingsBadge =>
      urgency != UpdateUrgency.none && urgency != UpdateUrgency.forced;
}

/// A cached policy can only show a forced gate and matching installed notes.
/// Its age is measured from the last successful fetch, using the device clock.
UpdateDecision evaluateAppUpdatePolicy({
  required SemVer? installed,
  required AppUpdateManifest? manifest,
  required DateTime now,
  bool enabled = true,
  bool isCached = false,
  DateTime? checkedAt,
  DateTime? firstSeenAt,
  UpdateSnooze? snooze,
  SemVer? skippedVersion,
  SemVer? hubDismissedVersion,
  SemVer? lastSeenInstalledVersion,
}) {
  if (!enabled ||
      installed == null ||
      manifest == null ||
      manifest.killSwitch) {
    return const UpdateDecision();
  }

  final forced = installed.compareTo(manifest.minSupported) < 0 ||
      (manifest.forceOnMajor && installed.major < manifest.latest.major);
  final age = checkedAt == null ? null : now.difference(checkedAt);
  if (forced &&
      (!isCached ||
          (age != null && !age.isNegative && age < updateForcedCacheTtl))) {
    return const UpdateDecision(urgency: UpdateUrgency.forced);
  }

  final whatsNew = installed == manifest.latest &&
      manifest.notes.isNotEmpty &&
      lastSeenInstalledVersion != null &&
      installed.compareTo(lastSeenInstalledVersion) > 0;
  if (isCached ||
      installed.compareTo(manifest.latest) >= 0 ||
      manifest.downloadUrl == null) {
    return UpdateDecision(canShowWhatsNew: whatsNew);
  }
  if (installed.compareTo(manifest.recommended) >= 0 ||
      skippedVersion == manifest.latest) {
    return const UpdateDecision(urgency: UpdateUrgency.passive);
  }

  final showHubBanner = hubDismissedVersion != manifest.latest;
  final featureUpdate = installed.major != manifest.latest.major ||
      installed.minor != manifest.latest.minor;
  final installAge = firstSeenAt == null ? null : now.difference(firstSeenAt);
  final inInstallGrace = installAge != null &&
      !installAge.isNegative &&
      installAge < updateInstallGrace;
  if (featureUpdate &&
      !inInstallGrace &&
      snooze?.suppresses(manifest.latest, now) != true) {
    return UpdateDecision(
      urgency: UpdateUrgency.softSheet,
      showHubBanner: showHubBanner,
    );
  }
  if (snooze != null &&
      snooze.version == manifest.latest &&
      snooze.count >= 3) {
    return const UpdateDecision(urgency: UpdateUrgency.passive);
  }
  return UpdateDecision(
    urgency: showHubBanner ? UpdateUrgency.softBanner : UpdateUrgency.passive,
    showHubBanner: showHubBanner,
  );
}
