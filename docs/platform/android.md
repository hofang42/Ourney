# Android platform notes (Ourney)

Owner: Android Platform Engineer. Scope: `apps/mobile/android/**`.
Plan reference: `docs/05-platform-plan-ios-android.md` §2 and §5.

## 1. App identity and config

| Item | Value | Source |
|---|---|---|
| applicationId / namespace | `com.hofang42.ourney` | `android/app/build.gradle.kts` |
| App label | `Ourney` | `AndroidManifest.xml` |
| Orientation | portrait (`MainActivity`) | `docs/05` §5.1 "Chỉ dọc" |
| minSdk | 26 (Android 8.0) | see §2 |
| targetSdk / compileSdk | from Flutter SDK (`flutter.targetSdkVersion` / `flutter.compileSdkVersion`) | `android/app/build.gradle.kts` |

## 2. minSdk decision

| Dependency | Requirement found | Source |
|---|---|---|
| camera 0.12.1 | "SDK 24+" | https://pub.dev/packages/camera |
| image_picker 1.2.4 | "SDK 24+" | https://pub.dev/packages/image_picker |
| flutter_local_notifications 22.3.2 | no minSdk stated; needs compileSdk >= 35, AGP >= 8.11.1, core library desugaring | https://pub.dev/packages/flutter_local_notifications |
| supabase_flutter 2.18.3 | no minSdk stated on pub.dev page | https://pub.dev/packages/supabase_flutter |
| drift_flutter 0.3.1 | no minSdk stated on pub.dev page | https://pub.dev/packages/drift_flutter |

Result: no listed package requires more than 24. minSdk is set to **26** as proposed in `docs/05` §5.1 (Android 8.0 required for notification channels, which the reminder feature needs). This is a product choice, not a plugin requirement. Lowering it to 24 is possible if reach matters more; verify notification-channel code paths first.

Unverified: supabase_flutter and drift_flutter transitive native dependencies may set their own minSdk. The build output will show a manifest-merger error if they do. Check the failing error before changing the value.

## 3. Permissions and manifest

- `CAMERA`, `INTERNET`, `POST_NOTIFICATIONS` declared in the app manifest.
- `POST_PROMOTED_NOTIFICATIONS` declared for Android 16 (API 36) Live Updates (`Notification.ProgressStyle` check-in window status-bar chip and lock-screen live progress). This is a normal install-time permission (`canPostPromotedNotifications()` checked at runtime; degrades to standard silent ongoing chronometer notification on API 26–35 or when toggled off by the user).
- `RECEIVE_BOOT_COMPLETED` plus the two `ScheduledNotification*` receivers are declared because check-in reminders are scheduled. Source: flutter_local_notifications README, "To schedule notifications" section (https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/README.md).
- No storage permissions. image_picker 1.2.4 uses the Android Photo Picker on Android 13+ and "No configuration required" (https://pub.dev/packages/image_picker). Do not add `READ_MEDIA_*` or `READ_EXTERNAL_STORAGE`.
- No `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`. Reminders and widget midnight/window rollovers (`CheckInWindowReceiver`) use inexact scheduling (`AlarmManager.setAndAllowWhileIdle`, `docs/05` §5.2).
- Not added (not needed by current features): `USE_FULL_SCREEN_INTENT`, `ACCESS_NOTIFICATION_POLICY`.
- Deep links: custom scheme `ourney` with hosts `join`, `j`, `journey`, `friend`, `f`, `p`, `capture`, `journeys`, and `groups`, `VIEW` action, `DEFAULT` and `BROWSABLE` categories. Source: https://developer.android.com/training/app-links/deep-linking (custom-scheme example). Custom schemes are not App Links; no `autoVerify` and no `assetlinks.json` needed for custom schemes. All widget and Live Update `PendingIntent`s target `MainActivity` explicitly (`FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE`).

## 4. Home-Screen Widgets (Jetpack Glance 1.2) & Android 16 Live Updates

- **Jetpack Glance (`androidx.glance:glance-appwidget:1.2.0`):**
  - Enabled with the Kotlin 2.4.0 Compose compiler plugin (`org.jetbrains.kotlin.plugin.compose`) and `buildFeatures { compose = true }`.
  - Three widget receivers registered in `AndroidManifest.xml`:
    1. `.widgets.OurneyTodayWidgetReceiver` (`TodayGlanceWidget` — responsive `2x2`, `4x2`, `4x4` with in-place `CycleTodayJourneyAction` when 2+ journeys are pending).
    2. `.widgets.OurneyStreakWidgetReceiver` (`StreakGlanceWidget` — `2x2` Soft Neo-Brutalist streak counter + 7-day chain).
    3. `.widgets.OurneySquadWidgetReceiver` (`SquadGlanceWidget` — `4x2`, `4x4` Squad & Couple Rituals status card).
  - **Data Contract (`MethodChannel("ourney/widgets")`):**
    - `OurneyWidgetBridge` reads/writes `<filesDir>/ourney_widgets/snapshot_v1.json` atomically (`snapshot_v1.json.tmp` -> rename), caches content-addressed thumbnails under `<filesDir>/ourney_widgets/thumbs/`, and stores interactive cycle/dismiss state in `<filesDir>/ourney_widgets/state.json`.
    - `WidgetSnapshotStore` evaluates post-midnight rollover natively in Kotlin so widgets never show stale "checked in today" statuses on the next morning even if the app hasn't been opened.
- **Check-In Window Live Updates (`CheckInLiveUpdateManager`):**
  - Uses notification ID `42000` on silent channel `checkin_window_live` (disjoint from `ReminderScheduler`'s `41000..41063` on `checkin_reminders`).
  - On **Android 16 (`API 36`)**: Builds `Notification.ProgressStyle` with per-journey segments, `setOngoing(true)`, `setRequestPromotedOngoing(true)`, and `setShortCriticalText(...)` (`<= 7` chars) for status-bar chip promotion.
  - On **Android 8.0–15 (`API 26–35`)**: Falls back to a silent ongoing countdown chronometer notification (`setUsesChronometer(true)`, `setChronometerCountDown(true)`).
  - Uses `VISIBILITY_PRIVATE` with a redacted `publicVersion` when `redactLockScreenTitles` is enabled.
- **R8 / ProGuard (`android/app/proguard-rules.pro`):**
  - Retains no-arg constructors for all `GlanceAppWidgetReceiver`, `GlanceAppWidget`, `ActionCallback`, and `CheckInWindowReceiver` classes.

## 5. flutter_local_notifications Gradle setup

Applied exactly as the README requires:
- `compileOptions { isCoreLibraryDesugaringEnabled = true }`
- `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`
- `multiDexEnabled = true`
- Java 17 (already set)
- compileSdk must be >= 35: provided by the Flutter SDK; check with `flutter.compileSdkVersion` in the build log.

Source: https://pub.dev/packages/flutter_local_notifications (Android setup section).

## 5. Build and install

Prerequisites: Flutter 3.47.7, Android SDK with platform matching `compileSdk`, JDK 17.

```bash
cd apps/mobile
flutter pub get
flutter build apk --release
# Output: apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

Install on a device with USB debugging enabled:

```bash
adb devices                       # confirm device is listed as "device"
adb install -r apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

Local builds were NOT run in this environment: the Android SDK is not installed locally. CI builds the APK (`.github/workflows/android.yml`, planned).

## 6. Release signing

- Keystore is never committed. It is stored only as a GitHub secret.
- Secret name: `ANDROID_KEYSTORE_BASE64` (base64 of the `.jks` file).
- Companion secrets expected by the signing config (to be added with the CI workflow): `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- Current state: `release` buildType still uses the debug signing config (template default). Wiring the real release signing config is a follow-up that depends on the CI workflow. Do not commit `key.properties` or any `.jks` file.

Restore a keystore locally from the secret for a signed build (example):

```bash
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/app/upload-keystore.jks
```

`*.jks` and `key.properties` are already ignored by `android/.gitignore`.

## 7. Verification status

- `flutter pub get` and `flutter analyze`: see the commit message / report.
- APK build: not verified locally (no Android SDK). Pending CI.
- Device test on Android 13+ for POST_NOTIFICATIONS prompt: pending (matrix TBD in `docs/05` §5.3).
