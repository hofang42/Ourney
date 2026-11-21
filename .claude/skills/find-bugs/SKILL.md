---
name: find-bugs
description: Find logic bugs, state and lifecycle bugs, async races, null/empty and off-by-one errors, date/timezone mistakes, offline/sync and error-path bugs, plus security holes (RLS, data leaks) in Ourney's Dart/Flutter app, ourney_core and Supabase code. Use when asked to "scan for bugs", "find bugs", "quét bug", "tìm lỗi", "soát lỗi logic", review a branch or a feature for correctness, or audit code before a PR. For layout, theme and visual bugs use ui-bug-scan; for screen readers and contrast use flutter-accessibility.
argument-hint: "[file, folder or feature; empty = this branch vs main]"
---

<!-- Modified for Ourney from getsentry/skills skills/find-bugs (Apache-2.0). See NOTICE.md. -->

# Find Bugs

Review code for bugs, security vulnerabilities, and code quality issues.

Scope: $ARGUMENTS

- Empty: the changes on this branch. Ourney PRs target `main`, so the diff is `git fetch origin main` then `git diff origin/main...HEAD`.
- A file, folder or feature name (`checkin`, `data/sync`, `ourney_core`, `supabase/migrations/0014*`): scan that code as it is now, not only a diff.

## Phase 1: Complete Input Gathering

1. Get the FULL diff (`git fetch origin main` then `git diff origin/main...HEAD`), or list every file in the scope (`git ls-files <path>`).
2. If output is truncated, read each file individually until you have seen every changed line (whole-folder scope: every line of every file).
3. List all files in scope before proceeding.
4. Read what already exists, so you do not report known bugs: `docs/bug.md` (the 2026-11-18 scan, codes `A-B*`, `B-B*`, `C-B*`, `U*`), `docs/bugs.md` (device bugs), and the tests for the files in scope (`apps/mobile/test/**`, `packages/ourney_core/test/**`, `supabase/tests/*.test.sql`).

## Phase 2: Attack Surface Mapping

For each file in scope, identify and list:

* All user inputs (text fields, pickers, sliders, deep links / universal links, route params in `go_router`, push payloads, imported photos and EXIF dates)
* All database queries (drift: `apps/mobile/lib/data/db/`, repositories in `apps/mobile/lib/data/repositories/`; Postgres RPCs and policies in `supabase/migrations/`)
* All authentication/authorization checks (RLS policies, `security definer` RPCs, `auth.uid()` checks, block / consent / `hide_metric` / `hidden_in_share` / privacy toggles)
* All session/state operations (Riverpod providers, `ref.read` / `ref.watch` / `ref.listen`, `StatefulWidget` state, `SharedPreferences`, the outbox, sync cursors, sign-out and account deletion)
* All async boundaries (`await`, `Stream`, `StreamController`, `Timer`, `Future.wait`, `unawaited`, isolates, camera and notification plugins)
* All external calls (Supabase client, Edge Functions in `supabase/functions/`, Storage uploads, camera, image_picker, share_plus, local notifications, connectivity)
* All date and time arithmetic (`LocalDate`, `JourneyClock`, `computeStreak`, `DateTime.now()`, `Duration`, time zones)
* All cryptographic operations (rare here: invite codes, tokens, random ids)

## Phase 3: Checklist (check EVERY item for EVERY file)

Logic and lifecycle items (the Ourney-specific detail for each is in [`references/dart-flutter-checklist.md`](references/dart-flutter-checklist.md); load it now):

* [ ] **Null / empty / single / many**: empty lists, `first` / `single` / `getSingle` on 0 or 2+ rows, empty strings, missing JSON keys, deleted users
* [ ] **Off-by-one and boundaries**: day N of M, inclusive/exclusive end dates, streak edges, index math, `substring` / UTF-16 surrogate pairs
* [ ] **Date and timezone**: device zone vs journey zone, local date vs UTC instant, DST, midnight, day rollover while the app is open
* [ ] **State and lifecycle**: `ref` or `context` used after `await` without `mounted` / `ref.mounted`, controllers not disposed, listeners leaked, state kept across sign-out or journey switch
* [ ] **Async races**: two in-flight requests answering out of order, double taps, sync pull racing sign-out, `StreamController` used after `close`, `Future` errors nobody awaits
* [ ] **Offline / sync**: outbox ordering and retry, idempotency, local-only mode, partial failure between two remote calls, server row overriding newer local data
* [ ] **Error paths**: catch blocks too narrow (`on OurneyException` letting `StateError` through) or too broad (swallowing), user sees nothing, data lost on failure
* [ ] **Business rules**: journey status (`active` / `ended` / imported), couple = 2 members, multi-photo per day, privacy and consent rules, reminders rescheduled on every change
* [ ] **App ↔ server parity**: rule enforced in Dart but not in SQL (or the reverse), drift schema vs migration, mapping drops a field

Security items (kept from upstream, reworded for Supabase and a mobile client):

* [ ] **Injection**: SQL built by string concatenation in migrations, RPCs or Edge Functions; `format()` without `%L` / `%I`
* [ ] **Authentication**: auth checks on all protected operations? Edge Functions verify the JWT?
* [ ] **Authorization/IDOR**: RLS enabled and correct for every table touched, `security definer` functions check the caller, ids from the client never trusted
* [ ] **Race conditions**: TOCTOU in any read-then-write pattern (client or SQL)
* [ ] **Session**: data of user A left in drift, preferences, providers or media after sign-out, then shown to user B
* [ ] **Cryptography**: secure random for invite codes, no secrets or tokens in logs or `debugPrint`
* [ ] **Information disclosure**: blocked users, unconsented sharers, hidden metrics, hidden photos, error messages that leak internals
* [ ] **DoS**: unbounded queries or loops, `Timer` with 0 or negative delay, missing rate limits on RPCs
* [ ] **Business logic**: edge cases, state machine violations, numeric overflow

## Phase 4: Verification

For each potential issue:

* Check if it's already handled elsewhere in the code (callers, the repository layer, SQL constraints, RLS)
* Search for existing tests covering the scenario
* Read surrounding context to verify the issue is real
* **Prove it when you can.** Write a temporary failing test in `apps/mobile/test/zz_bugscan/` (Dart) or in `packages/ourney_core/test/zz_bugscan/` (`dart test test/zz_bugscan`). Reuse `apps/mobile/test/data/data_test_helpers.dart` (`memoryDb`, `TestClock`, `testJourneyClock`, `FakeRemoteApi`, `localLayer`, `supabaseLayer`) and `apps/mobile/test/app/test_helpers.dart` (`pumpOurneyApp`). SQL issues: a pgTAP case shaped like `supabase/tests/*.test.sql` (needs a local Supabase; otherwise mark the finding "not run"). Run with the full Flutter path if `flutter` is not on PATH (`E:\tools\flutter\bin\flutter test test/zz_bugscan`). Delete both `zz_bugscan/` folders before finishing unless the user wants the tests kept as regressions.
* Grade confidence: **chắc chắn** (test fails as described), **có khả năng** (code reading only, path is reachable), **nghi ngờ** (depends on timing or device behaviour you could not reproduce).

## Phase 5: Pre-Conclusion Audit

Before finalizing, you MUST:

1. List every file you reviewed and confirm you read it completely
2. List every checklist item and note whether you found issues or confirmed it's clean
3. List any areas you could NOT fully verify and why
4. Only then provide your final findings

## Output Format

**Prioritize**: security vulnerabilities and data loss > crashes and wrong data > code quality

**Skip**: stylistic/formatting issues, anything `flutter analyze` / `dart analyze` already reports, and bugs already listed in `docs/bug.md` or `docs/bugs.md` (mention them by code if they are still open in scope).

Write the report in the user's language (Vietnamese by default for Ourney). For each issue:

* **File:Line** - Brief description
* **Severity**: Critical/High/Medium/Low
* **Confidence**: chắc chắn / có khả năng / nghi ngờ
* **Scenario**: the user steps or timing that trigger it
* **Problem**: What's wrong
* **Evidence**: Why this is real (failing temp test and its output, or the code path; not already fixed, no existing test)
* **Fix**: Concrete suggestion, plus the regression test that should guard it
* **References**: rule in `CLAUDE.md`, `docs/SRS.md`, an ADR, OWASP, or the Dart/Flutter docs if applicable

If you find nothing significant, say so - don't invent issues.

Do not make changes - just report findings. I'll decide what to address. (Temporary tests in the `zz_bugscan/` folders are the one exception, and they are removed at the end.)
