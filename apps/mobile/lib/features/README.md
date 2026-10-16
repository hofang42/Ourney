# Feature conventions (read before touching `lib/features/`)

The app shell (A3) is done so that Wave B/C agents work **only inside their
own folder**. Nobody edits `lib/app/`, `lib/shared/`, `lib/l10n/`,
`pubspec.yaml` or `analysis_options.yaml` in a feature PR; ask the
Orchestrator instead. The single exception is the body of
`lib/app/data_overrides.dart`, owned by B1.

```
lib/features/<feature>/
├── routes.dart              # REQUIRED: exports List<RouteBase> <feature>Routes
├── l10n/
│   ├── <feature>_vi.arb     # template (Vietnamese is the default language)
│   ├── <feature>_en.arb
│   └── generated/           # output of tool/gen_l10n.dart, committed
└── ...                      # screens, widgets, controllers: any structure
test/features/<feature>/     # your tests
```

Features: `auth`, `onboarding`, `profile` (B2) · `camera`, `checkin` (B3) ·
`journeys` (B4) · `groups` (C1) · `share_card` (C2) · `safety`,
`reminders` (C3). Data/sync lives in `lib/data/` (B1).

## 1. Routes

`lib/app/feature_routes.dart` aggregates every `<feature>Routes` list and
`lib/app/router.dart` builds the `GoRouter`. You only edit your
`routes.dart`; keep the exported variable name.

| Feature | Variable | Top-level prefixes you own | Where it renders |
|---|---|---|---|
| camera | `cameraRoutes` | `/capture` | Capture tab (center). **Initial location** (FR-C1) |
| journeys | `journeysRoutes` | `/journeys`, `/journey` | Journeys tab. `/journey/:id` = `ourney://journey/<id>` |
| groups | `groupsRoutes` | `/groups`, `/join` | Groups tab. `/join/:code` = `ourney://join/<code>` |
| checkin | `checkinRoutes` | `/checkin` | Full screen (root navigator) |
| onboarding | `onboardingRoutes` | `/onboarding` | Full screen |
| auth | `authRoutes` | `/auth` | Full screen |
| profile | `profileRoutes` | `/profile` | Full screen |
| share_card | `shareCardRoutes` | `/share` (`/share/:journeyId`) | Full screen |
| safety | `safetyRoutes` | `/safety` | Full screen, reachable before sign-in |
| reminders | `remindersRoutes` | `/reminders` | Full screen |

Rules (enforced by `test/app/route_registry_test.dart`):

- Every top-level `GoRoute.path` starts with one of your prefixes. Put
  sub-screens under them as child routes or longer paths
  (`/journeys/new`, `/safety/report`, `/profile/edit`).
- No path may be declared twice across features.
- Build links with `AppRoutes` (`lib/app/app_routes.dart`):
  `context.go(AppRoutes.journey(id))`, `context.push(AppRoutes.checkin, extra: photo)`.
  Import `package:ourney/app/app_routes.dart` (not `router.dart`, to avoid an
  import cycle through the registry).
- A tab route that must cover the bottom bar sets
  `parentNavigatorKey: rootNavigatorKey` (`lib/app/navigator_keys.dart`).
- A new top-level prefix or a new `AppRoutes` constant is an Orchestrator
  change to `lib/app/app_routes.dart`.

Redirects are global (`lib/app/redirect.dart`, unit-tested). Do not add your
own top-level redirects:

1. `ourney://<host>/<rest>` is normalised to `/<host>/<rest>`.
2. Not onboarded → `/onboarding?from=<target>` (only `/onboarding` and
   `/safety` are reachable).
3. Backend configured and signed out → `/auth?from=<target>` (`/auth`,
   `/onboarding`, `/safety` reachable). **Local-only mode has no auth gate.**
4. Backend configured, signed in and the EULA not accepted →
   `/safety/eula/accept?from=<target>` (only `/safety` reachable).
   Local-only mode has no EULA gate.
5. Once a gate is satisfied the router leaves `/onboarding` / `/auth` for
   the `?from=` target (or `/capture`) **by itself**: onboarding calls
   `ref.read(onboardingCompleteProvider.notifier).complete()`, auth just
   makes `AuthRepository.watchUserId()` emit the user id. Do not navigate
   manually after that. Profile setup after first sign-in is part of the
   auth flow (B2), e.g. `/auth/profile`.

## 2. Strings (l10n)

`flutter gen-l10n` supports one template ARB per generated class and ignores
CLI flags when an `l10n.yaml` exists. So there is **no l10n.yaml**: every
feature has its **own ARB pair and its own generated class**, and no two
agents ever edit the same ARB file.

| ARB set | Class | Import |
|---|---|---|
| `lib/l10n/app_{vi,en}.arb` (shared: nav, common, streak, needs-server) | `AppLocalizations` | `package:ourney/l10n/generated/app_localizations.dart` |
| `lib/features/<f>/l10n/<f>_{vi,en}.arb` | `<F>L10n` (`JourneysL10n`, `ShareCardL10n`, …) | `package:ourney/features/<f>/l10n/generated/<f>_localizations.dart` |

- Keys are `<feature>_<camelCase>`: `journeys_createTitle`,
  `share_card_saveButton`. vi is the template; en must define the same keys
  (checked by `test/app/l10n_test.dart`). Add `@key` descriptions and
  placeholder types in the vi file (ICU plurals: see `streak_days` in
  `lib/l10n/app_vi.arb`).
- Regenerate after editing, from `apps/mobile/`:
  `dart run tool/gen_l10n.dart <feature>` (or no argument for all) and
  commit the `generated/` output.
- Use it: `final l10n = JourneysL10n.of(context);` then `l10n.journeys_title`.
- All delegates are already registered in `lib/app/localization.dart`
  (`ourneyLocalizationsDelegates`, `ourneySupportedLocales` = vi, en).
- No hard-coded user-facing strings; no emoji in system UI (reactions and
  stickers only).

## 3. Providers (`lib/app/providers.dart`)

| Provider | Type | Notes |
|---|---|---|
| `appConfigProvider` | `AppConfig` | `.localOnly` / `.hasBackend` (FR-A5) |
| `sharedPreferencesProvider` | `SharedPreferencesWithCache` | Keys `<feature>.<name>`, e.g. `camera.lastJourneyId` |
| `supabaseClientProvider` | `SupabaseClient?` | null in local-only. **lib/data only** |
| `authRepositoryProvider` | `AuthRepository` | placeholder → B1 |
| `profileRepositoryProvider` | `ProfileRepository` | placeholder → B1 |
| `journeyRepositoryProvider` | `JourneyRepository` | placeholder → B1 |
| `checkInRepositoryProvider` | `CheckInRepository` | placeholder → B1 |
| `groupRepositoryProvider` | `GroupRepository` | placeholder → B1; never used in local-only |
| `safetyRepositoryProvider` | `SafetyRepository` | placeholder → B1 |
| `mediaStoreProvider` | `MediaStore` | placeholder → B1 |
| `currentUserIdProvider` | `String?` | null when signed out / local-only |
| `authStatusProvider` | `AuthStatus` | `localOnly`, `signedIn`, `signedOut` |
| `onboardingCompleteProvider` | `bool` | `.notifier.complete()` / `.reset()` |
| `hapticsEnabledProvider` | `bool` | `.notifier.set(enabled:)`; mirrors `OurneyHaptics.enabled` |

Interfaces come from `package:ourney_core/ourney_core.dart` (contract, do not
change). Placeholder repositories throw `UnimplementedError` until B1 returns
real implementations from `createDataOverrides()` in
`lib/app/data_overrides.dart`. Until then, and always in tests, override them:

```dart
ProviderScope(overrides: [
  appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
  journeyRepositoryProvider.overrideWithValue(FakeJourneyRepository()),
], child: ...)
```

Your own providers live in your folder. Riverpod codegen is set up
(`@riverpod`, `part 'x.g.dart';`): run `dart run build_runner build` and
commit the `.g.dart` files.

**Local-only mode** (no `SUPABASE_URL`/`SUPABASE_ANON_KEY`): solo journeys
work fully; any group/invite/reaction screen must show `NeedsServerView`
(`lib/shared/needs_server_view.dart`) when
`ref.watch(appConfigProvider).localOnly`.

## 4. UI building blocks

- Tokens: `OurneyColors.of(context)`, `OurneySpacing`, `OurneyRadii`,
  `OurneySizes`, `OurneyDurations` (`lib/app/theme/tokens.dart`); text styles
  from `Theme.of(context).textTheme`, big numbers `bigNumberStyle()`
  (`lib/app/theme/app_theme.dart`). Camera surfaces use
  `OurneyColors.cameraBg` and dark colors regardless of theme.
- Motion: `OurneyMotion.duration/movement/allowsDecoration(context)` — under
  Reduce Motion use a 0.2s fade and no confetti/looping. Haptics only via
  `OurneyHaptics.*` (respects the user toggle).
- Widgets (`lib/shared/`): `ChunkyButton`, `OurneyCard`, `OurneyChip`,
  `Avatar`, `EmptyState`, `NeedsServerView`, `StreakFlame`, `StampAnimation`.
- Text scale is clamped to 2x app-wide; layouts must not overflow at 2x
  (wrap long content in scroll views, use `maxLines` + ellipsis for chips).
  Icon-only buttons need a `Semantics`/`tooltip` label; state never relies on
  color alone.

## 5. Checks before a PR

From `apps/mobile/`: `dart run tool/gen_l10n.dart`, `dart run build_runner build`
(if you use codegen), `dart format .`, `flutter analyze`, **`dart analyze`**
(only `dart analyze` runs the riverpod_lint plugin), `flutter test`.
Test helpers: `test/app/test_helpers.dart` (`testApp`, `pumpOurneyApp`,
`testPrefs`, `FakeAuthRepository`).
