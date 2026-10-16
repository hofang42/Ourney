# ADR 0001: iOS minimum version, device family and CI build

- Status: accepted (2026-10-16)
- Owner: iOS Platform Engineer
- Related: `docs/04-implementation-plan-v1.md` §0, §8; `docs/05-platform-plan-ios-android.md` §4

## Context

Ourney is iOS-first, built without a Mac. iOS builds only happen on GitHub Actions macOS runners and
produce an **unsigned** `.ipa` that users sign themselves with a free Apple ID (see `docs/platform/ios.md`).
`docs/05` proposed iOS 16 "to be checked against Flutter and plugins".

## Decision

1. **Deployment target stays `IPHONEOS_DEPLOYMENT_TARGET = 15.0`** (already set by the Flutter template).
2. **iPhone only**: `TARGETED_DEVICE_FAMILY = 1` (Debug/Release/Profile). Portrait only
   (`UISupportedInterfaceOrientations` = Portrait; iPad keys removed).
3. **Default language is Vietnamese** (`developmentRegion = vi`; `vi.lproj` and `en.lproj`
   `InfoPlist.strings` added to the Runner target). `Info.plist` also carries the Vietnamese strings as a
   fallback.
4. **CI build**: `flutter build ios --release --no-codesign` on `macos-latest`, then
   `scripts/ios/package_ipa.sh` zips `Payload/Runner.app` into `Ourney-unsigned.ipa`
   (artifact `Ourney-unsigned-ipa`; attached to the GitHub Release on `v*` tags).
5. Android CI uses JDK 17 (Temurin) and a debug-signed release APK unless `ANDROID_KEYSTORE_BASE64` is set.

## Verification of plugin iOS minimums

Read from the package sources (pub.dev archives of the exact versions in `apps/mobile/pubspec.lock`;
`Package.swift` / `*.podspec`):

| Plugin (iOS implementation, version) | iOS minimum |
|---|---|
| camera -> camera_avfoundation 0.10.3+1 | 13.0 |
| image_picker -> image_picker_ios 0.8.13+12 | **15.0** (highest of all) |
| flutter_image_compress -> flutter_image_compress_common 1.1.1 | 9.0 |
| share_plus 13.3.1 | 13.0 |
| flutter_local_notifications 22.3.2 | 13.0 (Package.swift) |
| flutter_timezone 5.1.1 | 11.0 |
| supabase_flutter 2.18.3 -> app_links 7.2.2 / url_launcher_ios 6.4.2 / shared_preferences_foundation 2.5.7 | 13.0 each |
| drift_flutter 0.3.1 -> sqlite3 3.5.2 (native assets via build hooks; `sqlite3_flutter_libs` is an empty EOL shim) | no iOS minimum declared in the package; not verified beyond "iOS arm64 / simulator supported" (README) |
| path_provider_foundation 2.6.0 | not found in the archive's Package.swift/podspec by my search; unverified |

Result: the highest declared minimum is **15.0** (image_picker_ios), so 15.0 is correct and 16 is not
required. Moving to 16 would be a product decision (drops iPhone 6s/7/SE1), not a plugin requirement.
Re-check when plugins are upgraded (`pubspec.lock` changes).

## AppDelegate (flutter_local_notifications)

Per the plugin README ("General setup"): set
`UNUserNotificationCenter.current().delegate = self` in `didFinishLaunchingWithOptions`. Applied in
`apps/mobile/ios/Runner/AppDelegate.swift`. For the UIScene lifecycle (this project's template), the README
puts the `setPluginRegistrantCallback` call in `didInitializeImplicitFlutterEngine` (needed only for
notification actions in the background isolate; harmless otherwise). Applied there too. The notification
permission prompt itself is requested at runtime by the plugin (Dart `requestPermissions`), no Info.plist key.

## CI facts

- Runner: `macos-latest` = macOS 26 arm64, free and unlimited for public repos; other labels:
  `macos-14`, `macos-15`, `macos-26`, `macos-15-intel`, `macos-26-intel`
  (docs.github.com/en/actions/reference/runners/github-hosted-runners). Pin to `macos-26`/`macos-15` if
  `-latest` moves and breaks the build.
- Actions (latest majors checked via the GitHub API on 2026-10-16): `actions/checkout@v7`,
  `actions/setup-java@v6`, `actions/upload-artifact@v7`, `subosito/flutter-action@v2` (v2.23.0),
  `softprops/action-gh-release@v3`.
- Flutter `3.47.7` stable exists (Dart 3.13.5, released 2026-10-08, from the official
  `releases_linux.json`); matches `sdk: ^3.13.5` in `pubspec.yaml`.
- JDK 17: AGP 9.0 documents JDK 17 as minimum and default (developer.android.com AGP 9.0 release
  notes); the project uses AGP 9.1.0 and Java 17 source/target.

## Consequences / unverified

- No macOS build was run locally (Windows machine). The pbxproj edit (new `InfoPlist.strings` variant
  group, `vi` region, device family) and the `import flutter_local_notifications` in `AppDelegate.swift`
  are validated only by review; the first `ios.yml` run is the real test.
- With a free Apple ID: expires after 7 days, no push, no App Groups, no universal links.
- `ANDROID_KEYSTORE_BASE64` makes the workflow write `android/key.properties`, but
  `android/app/build.gradle.kts` currently signs release with the debug key and must be changed by the
  Android owner to read it.
