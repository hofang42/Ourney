# Dart / Flutter / Supabase logic checklist for Ourney

Written for Ourney (not part of the upstream Sentry skill). Each item says what to look for, a grep that finds candidates, and a past Ourney bug of that class from `docs/bug.md` (2026-11-18 scan). A grep hit is a lead, not a finding: read the code path and prove it (Phase 4).

Paths: app `apps/mobile/lib/`, core `packages/ourney_core/lib/src/`, server `supabase/migrations/`, `supabase/functions/`.

## 1. Null, empty, single, many

- `.first`, `.last`, `.single`, `.reduce` on a list that can be empty; `getSingle()` / `getSingleOrNull()` on a drift query that can return 2+ rows since multi-photo per day (`0014`, drift schema v6). Fix shape: `orderBy` + `limit(1)`, or `firstOrNull`.
  `rg -n "\.(single|first|last|reduce)\b|getSingle(OrNull)?\(" apps/mobile/lib packages/ourney_core/lib`
  Past: A-B1 (`watchToday` throws `Too many elements`), B-B5, B-B6 (only one photo per day kept).
- `!` on values from JSON, route params, providers in loading state, or rows of deleted users.
  `rg -n "[a-zA-Z_\)\]]!(\.|\)|;|,)" apps/mobile/lib --glob '!*.g.dart'`
  Past: A-B10 (`consentFromJson` throws when the requester deleted the account).
- `as String` / `as int` casts on JSON, `int.parse` / `double.parse` on user input (use `tryParse`; Vietnamese users type `62,5`).
- Empty string treated as "not set" in one place and as a value in another (clearing a field must clear the stored value). Past: B-B13.

## 2. Off-by-one and boundaries

- Day N of M: is day 1 the start date? Is `endDate` inclusive? Does a journey of length 1 work? Past: B-B7 (journey past `endDate` still active), A-B14 (`atRisk` the day after a finished journey).
- Streak math in `streak.dart`: today not yet checked in vs yesterday missed; first day; gap of exactly one day.
- `substring`, `characters`, length limits: Dart strings are UTF-16, so cutting by `length` splits emoji and Vietnamese composed characters. In the app use `String.characters` (Flutter re-exports `package:characters`); `ourney_core` has no such dependency, so cut on rune boundaries there (adding a dependency is a separate PR, `docs/SRS.md` §6.1). Past: A-B11.
  `rg -n "substring\(|\.length\s*[<>]=?" apps/mobile/lib packages/ourney_core/lib`
- Grid and list index math (7-column calendar, 2x2 Polaroid wall, page dots): last page, partial week, zero items.

## 3. Dates and time zones

- A journey day is `LocalDate` in the **journey's** IANA zone (`JourneyClock`, server `local_date(captured_at, journeys.timezone)`), not the device zone and not UTC. Flag `DateTime.now()` used for a journey day, and `DateTime(y, m, d)` built in the device zone then compared with a journey date.
  `rg -n "DateTime\.now\(\)|toLocal\(\)|toUtc\(\)|DateTime\(" apps/mobile/lib packages/ourney_core/lib --glob '!*.g.dart'`
- Adding days with `Duration(days: n)` across DST gives 23 or 25 hours; add calendar days to `LocalDate` instead. Past: B-B3 (negative `Timer` delay on DST fall-back, 0ms loop), B-B11 (−1 day across DST spring-forward).
- Midnight rollover while the app stays open: does "today" update (`DayTicker`)? Is a check-in captured at 23:59 and posted at 00:01 counted on the right day?
- Fallback zone: never silently `'UTC'`. Past: C-B12 (`noonInZone` produced a future instant; import fell back to UTC).
- Reminders: one notification per journey per time; reschedule on every change of time, status or enabled flag. Past: B-B8, B-B9, B-B14.

## 4. State and lifecycle

- `ref.read` / `ref.watch` / `context` / `setState` after an `await` in a widget without `if (!mounted) return;` (including inside `finally`). In a provider or notifier, check `ref.mounted` (Riverpod 3) after `await`.
  `rg -n -A3 "await " apps/mobile/lib/features | rg "ref\.(read|watch)|context\.|setState"` then read each hit.
  Past: B-B2 (`WidgetRef` used after dispose), B-B4 (`CaptureScreen._start` `finally`), C-B5 (`AuthScreen._finishSignIn`).
- Controllers (`AnimationController`, `TextEditingController`, `CameraController`, `ScrollController`, `FocusNode`), `StreamSubscription`, `Timer`: created in `initState` / provider and disposed or cancelled in `dispose` / `ref.onDispose`.
- `StreamController.add` after `close`, or after the provider was disposed while awaiting. Past: B-B15.
- State that must reset on sign-out, account deletion or journey switch: drift tables, `SharedPreferences` keys, cached providers, media files, sync cursors. Past: C-B4 (previous account's quiz and EULA flag kept), A-B5.
- `CLAUDE.md` §5: switching journeys must not reset the app or re-initialize the camera. A provider that rebuilds the camera on journey change is a bug.
- Form state lost on back navigation or re-open (draft not restored, step jumps back to 1). Past: U8, U19.
- Value chosen on screen A overwritten by stale data when screen B opens. Past: B-B1 (weight slider), B-B12 (colour not saved to draft).

## 5. Async races

- Two in-flight loads for the same key answering out of order (search-as-you-type, switching journey fast): is the stale result discarded?
- Double tap on a submit button: is the action guarded (disabled while busy, or idempotent)?
- Sync pull or outbox flush racing sign-out / delete account: rows of user A written after the wipe. Past: A-B5.
- `unawaited(...)` and `Future` without `await` or `.catchError`: an error becomes an unhandled zone error and the UI never learns.
  `rg -n "unawaited\(|\.then\(" apps/mobile/lib`
- `Future.wait` where one failure should not cancel the others (or should).
- A `Timer` whose delay can be 0 or negative (computed from clocks) loops forever.

## 6. Offline, outbox and sync

- Every write path works in local-only mode (`AppConfig.localOnly()`) and offline; a server-only feature shows a clear state instead of failing (`NeedsServerView`).
- Two remote calls in a row (`create_journey` then `update_journey`): what happens if the second fails? Fields lost locally? Past: A-B12.
- Outbox (`data/sync/outbox.dart`): entries are idempotent on retry, ordered per entity, marked dead with a reason, and the user can see or retry dead uploads.
- Server data replacing newer local data (prefer the newer by `capturedAt` / `updatedAt`). Past: C-B9.
- drift schema version and migrations (`app_database.dart`, `test/data/migration_test.dart`) match the Supabase migrations and `mapping.dart`; a new column is mapped both ways. Past: A-B6 (`max_members` for couple).

## 7. Error paths

- `on OurneyException catch` that lets `StateError`, `FormatException`, `PostgrestException` or plugin `PlatformException` escape. Or `catch (_) {}` that hides a real failure. Check `error_mapping` covers the remote error.
  `rg -n "catch \(_\)|on [A-Z][A-Za-z]+ catch|catch \(e\) \{\s*\}" apps/mobile/lib`
- The user gets feedback for every failure (`UiInlineError`, `showUiToast`, the camera status pill) and no data is lost (photo kept, draft kept).
- Destructive actions (sign out with unsynced photos, archive, delete, leave group) confirm first and handle failure. Past: C-B6, U6, U12.
- Permission denied permanently (camera, photos, notifications): there is a path to Settings. Past: U7.

## 8. Business rules and app ↔ server parity

- Journey status: `active`, `ended`, imported (`create_imported_journey` sets `ended`, but posting must still work for imports). Past: C out-of-scope import bug.
- Couple journeys have exactly 2 members (app and `create_journey`).
- Privacy rules apply everywhere a photo or metric leaves the device: `hide_metric`, `blur_media`, `hidden_in_share`, global privacy toggles, public links, Wrapped, share cards. Past: C-B1, C-B2, A-B8.
- Blocking filters every social surface (chat, inbox, friends, shared-with-me, squad invites) and every RPC (`blocked_between`). Past: C-B3, A-B9.
- Invitations: expire on leave, kick and code rotation; close when the invitee joins by code. Past: A-B7, A-B16.
- Ended groups and journeys disappear from "today" lists. Past: C-B13.
- Persona/template mapping (`TemplateId` ↔ `PersonaSkinId`, `CLAUDE.md` §4) is preserved through create, import and edit. Past: B-B10, C-B11.

## 9. Supabase SQL and Edge Functions

- Every new table has RLS enabled and policies for select / insert / update / delete (`supabase/tests/01_rls_enabled.test.sql` checks the flag, not the logic).
- `security definer` functions set `search_path` and check `auth.uid()` membership before reading or writing.
- An `update` policy without a matching `select` policy makes `update ... returning` or upsert fail with `42501`. Past: A-B2.
- Edge Functions: verify the JWT, never trust a `user_id` from the body, do not return columns the caller may not see.
- Account deletion removes rows in every user-owned table and every Storage bucket. Past: A-B4.
- For SQL authoring rules load the `supabase-postgres-best-practices` skill.
