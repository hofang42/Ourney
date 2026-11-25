import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

SemVer version(String value) => SemVer.tryParse(value)!;

Map<String, Object?> manifestJson({
  String latest = '1.1.0',
  String? recommended,
  String minSupported = '1.0.0',
  bool forceOnMajor = true,
  bool killSwitch = false,
  String platform = 'android',
  String? downloadUrl = 'https://ourney.tech/Ourney.apk',
}) =>
    {
      'platform': platform,
      'latest': latest,
      'latest_build': 2,
      'recommended': recommended ?? latest,
      'min_supported': minSupported,
      'force_on_major': forceOnMajor,
      'kill_switch': killSwitch,
      'download_url': downloadUrl,
      'notes': {
        'vi': ['Cập nhật mới'],
        'en': ['New features'],
      },
      'updated_at': '2026-11-25T00:00:00Z',
      'future_field': ['ignored'],
    };

void main() {
  test('SemVer orders releases numerically', () {
    final expected = ['1.0.0', '1.0.1', '1.1.0', '1.1.9', '1.2.0', '2.0.0'];
    final sorted = expected.reversed.map(version).toList()..sort();
    expect(sorted.map((v) => v.toString()), expected);
    expect(
      version('99999999999999999999.0.0').compareTo(version('2.0.0')),
      greaterThan(0),
    );
  });

  test('SemVer follows prerelease ordering and ignores build metadata', () {
    final expected = [
      '1.0.0-alpha',
      '1.0.0-alpha.1',
      '1.0.0-alpha.beta',
      '1.0.0-beta',
      '1.0.0-beta.2',
      '1.0.0-beta.11',
      '1.0.0-rc.1',
      '1.0.0',
    ];
    final sorted = expected.reversed.map(version).toList()..sort();
    expect(sorted.map((v) => v.toString()), expected);
    expect(version('1.0.0+01'), version('1.0.0+2026.release'));
  });

  test('malformed SemVer returns null', () {
    for (final value in [
      null,
      '',
      'v1.0.0',
      '1.0',
      '01.0.0',
      '1.0.0-',
      '1.0.0-01',
      '1.0.0+',
      '1.0.0-rc..1',
      '1.0.0\n',
      ' 1.0.0'
    ]) {
      expect(SemVer.tryParse(value), isNull, reason: '$value');
    }
  });

  test('manifest round trips known fields and validates download URLs', () {
    final manifest = AppUpdateManifest.tryFromJson(manifestJson())!;
    expect(manifest.notes.forLanguage('vi'), ['Cập nhật mới']);
    expect(manifest.notes.forLanguage('en'), ['New features']);
    final reparsed = AppUpdateManifest.tryFromJson(manifest.toJson())!;
    expect(reparsed.latest, version('1.1.0'));
    expect(reparsed.updatedAt, DateTime.utc(2026, 11, 25));
    expect(reparsed.latestBuild, 2);

    for (final url in [
      'http://ourney.tech/Ourney.apk',
      'https://evil.example/Ourney.apk',
      'https://ourney.tech@evil.example/Ourney.apk',
      'https://ourney.tech:8443/Ourney.apk',
      'https://github.com/other/project/releases/latest',
      'https://github.com/hofang42/ourney-releases/releases/%2F..%2FAPK',
    ]) {
      final parsed =
          AppUpdateManifest.tryFromJson(manifestJson(downloadUrl: url))!;
      expect(parsed.downloadUrl, isNull, reason: url);
      expect(
          AppUpdateManifest.tryFromJson(parsed.toJson())!.downloadUrl, isNull);
    }
    expect(
        isAllowedUpdateUrl(Uri.parse(
          'https://github.com/hofang42/ourney-releases/releases/download/v1.1.0/Ourney.apk',
        )),
        isTrue);
  });

  final now = DateTime.utc(2026, 11, 25);

  UpdateDecision decide(
    Map<String, Object?> json, {
    String installed = '1.0.0',
    String? previous,
    DateTime? firstSeenAt,
    DateTime? checkedAt,
    SemVer? hubDismissedVersion,
    SemVer? skippedVersion,
    UpdateSnooze? snooze,
    bool enabled = true,
  }) =>
      evaluateAppUpdatePolicy(
        installed: version(installed),
        manifest: AppUpdateManifest.tryFromJson(json),
        now: now,
        enabled: enabled,
        isCached: checkedAt != null,
        checkedAt: checkedAt,
        firstSeenAt: firstSeenAt,
        hubDismissedVersion: hubDismissedVersion,
        skippedVersion: skippedVersion,
        snooze: snooze,
        lastSeenInstalledVersion: SemVer.tryParse(previous),
      );

  test('kill switch takes precedence over minimum and major forces', () {
    expect(decide(manifestJson(minSupported: '1.1.0')).urgency,
        UpdateUrgency.forced);
    expect(decide(manifestJson(latest: '2.0.0')).urgency, UpdateUrgency.forced);
    expect(decide(manifestJson(latest: '2.0.0', forceOnMajor: false)).urgency,
        UpdateUrgency.softSheet);
    expect(
        decide(manifestJson(
                latest: '2.0.0', minSupported: '2.0.0', killSwitch: true))
            .urgency,
        UpdateUrgency.none);
    expect(decide(manifestJson(latest: '2.0.0'), enabled: false).urgency,
        UpdateUrgency.none);
    expect(
        decide(manifestJson(), installed: '1.2.0').urgency, UpdateUrgency.none);
  });

  test('malformed notes and URL preserve the minimum and kill switch', () {
    final json = manifestJson(
      minSupported: '1.1.0',
      downloadUrl: 'https://example.com/Ourney.apk',
    )..['notes'] = {
        'vi': ['', '  ', '  Ourney  '],
        'en': [null, '\t\n'],
      };
    final manifest = AppUpdateManifest.tryFromJson(json)!;
    expect(manifest.notes.vi, ['Ourney']);
    expect(manifest.notes.en, isEmpty);
    expect(manifest.downloadUrl, isNull);
    expect(decide(json).urgency, UpdateUrgency.forced);
    json['kill_switch'] = true;
    expect(AppUpdateManifest.tryFromJson(json)?.killSwitch, isTrue);
    expect(decide(json).urgency, UpdateUrgency.none);
  });

  test('patch, minor, and below-latest but recommended tiers', () {
    final patch = manifestJson(latest: '1.0.1');
    expect(decide(patch).urgency, UpdateUrgency.softBanner);
    final dismissed = decide(patch, hubDismissedVersion: version('1.0.1'));
    expect(dismissed.urgency, UpdateUrgency.passive);
    expect(dismissed.showHubBanner, isFalse);
    expect(dismissed.showSettingsBadge, isTrue);
    expect(decide(manifestJson()).urgency, UpdateUrgency.softSheet);
    expect(decide(manifestJson(recommended: '1.0.0')).urgency,
        UpdateUrgency.passive);
    expect(decide(manifestJson(), firstSeenAt: now).urgency,
        UpdateUrgency.softBanner);
    expect(
        decide(manifestJson(), firstSeenAt: now.subtract(updateInstallGrace))
            .urgency,
        UpdateUrgency.softSheet);
  });

  test('iOS without a download URL hides soft prompts and honors the floor',
      () {
    expect(decide(manifestJson(platform: 'ios', downloadUrl: null)).urgency,
        UpdateUrgency.none);
    expect(
        decide(manifestJson(
                platform: 'ios', downloadUrl: null, minSupported: '1.1.0'))
            .urgency,
        UpdateUrgency.forced);
  });

  test('snooze lasts 3 days then 7 days then stops for the current version',
      () {
    final latest = version('1.1.0');
    final first = UpdateSnooze(version: latest, count: 0).next(latest, now);
    final second = first.next(latest, first.until!);
    final third = second.next(latest, second.until!);
    expect(first.until, now.add(const Duration(days: 3)));
    expect(second.until, first.until!.add(const Duration(days: 7)));
    expect(first.suppresses(latest, first.until!), isFalse);
    expect(decide(manifestJson(), snooze: first).urgency,
        UpdateUrgency.softBanner);
    expect(
        decide(manifestJson(), snooze: third).urgency, UpdateUrgency.passive);
    expect(decide(manifestJson(), skippedVersion: latest).urgency,
        UpdateUrgency.passive);
    expect(decide(manifestJson(latest: '1.2.0'), snooze: third).urgency,
        UpdateUrgency.softSheet);
    expect(third.next(version('1.2.0'), now).count, 1);
  });

  test(
      'cached forced rules expire in seven days and cached soft rules stay quiet',
      () {
    final hard = manifestJson(minSupported: '1.1.0');
    expect(
        decide(hard, checkedAt: now.subtract(const Duration(days: 6))).urgency,
        UpdateUrgency.forced);
    expect(decide(hard, checkedAt: now.subtract(updateForcedCacheTtl)).urgency,
        UpdateUrgency.none);
    expect(decide(hard, checkedAt: now.add(const Duration(hours: 1))).urgency,
        UpdateUrgency.none);
    expect(decide(manifestJson(), checkedAt: now).urgency, UpdateUrgency.none);
  });

  test('Whats New needs a previous installed version and matching notes', () {
    expect(decide(manifestJson(), installed: '1.1.0').canShowWhatsNew, isFalse);
    expect(
        decide(manifestJson(), installed: '1.1.0', previous: '1.0.0')
            .canShowWhatsNew,
        isTrue);
    expect(
        decide(manifestJson(), installed: '1.1.0', previous: '1.1.0+2')
            .canShowWhatsNew,
        isFalse);
    expect(
        decide(manifestJson(latest: '1.2.0'),
                installed: '1.1.0', previous: '1.0.0')
            .canShowWhatsNew,
        isFalse);
  });
}
