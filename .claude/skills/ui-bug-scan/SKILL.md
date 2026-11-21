---
name: ui-bug-scan
description: Scan Ourney's Flutter screens for UI/UX bugs — RenderFlex overflow and clipping, safe-area and keyboard overlap, dark/light theme and contrast breaks, touch targets under 48dp, text scaling and Vietnamese diacritics, missing empty/loading/error/offline states, inconsistent components and CLAUDE.md UI rule violations (default icons, hardcoded colours, glass misuse). Renders every screen in a width x theme x text-scale x locale matrix with screenshots and guideline matchers, then reviews the code. Use when asked to "scan for bugs", "quét bug", "quét UI", "rà UI/UX", "UI/UX review", "check dark mode", "check overflow", or before shipping a screen. For logic bugs use find-bugs; for a deep screen-reader audit use flutter-accessibility.
argument-hint: "[screen, route, feature folder or file; empty = screens changed on this branch]"
---

# UI bug scan (Ourney)

Scope: $ARGUMENTS

- Empty: screens and `lib/ui` components touched by `git diff origin/main...HEAD -- apps/mobile/lib` (run `git fetch origin main` first) (Ourney PRs target `main`).
- A route (`/journeys`), a feature folder (`features/checkin`), or a file: scan that.

Goal: a list of real, reproducible UI/UX bugs with evidence (screenshot, matcher output or code line), ranked P0–P3, in the same shape as the 2026-11-18 `ux-audit` in `docs/bug.md` (U1–U23). Report only; do not fix unless the user asks.

Run both halves: **render** (Phase 2) catches what reading code misses (overflow at 2x, glass contrast, safe-area overlap), **read** (Phase 3) catches states and rules that a single render does not reach.

## Phase 1: Inputs

1. List the screens in scope and, for each, its route (`apps/mobile/lib/app/app_routes.dart`, feature `routes.dart`) and the providers it watches.
2. Read the rules the screens must follow: `CLAUDE.md` §1–5, `apps/mobile/lib/ui/README.md` (kit components, glass rules), and for persona screens the board via `/design-ref`.
3. Read `docs/bug.md` §3 (U1–U23) and `docs/bugs.md` so you do not report known bugs again; note if a known one is still present.
4. For each screen, list its states: loading, empty, data, error, offline / local-only (`NeedsServerView`), permission denied, long content, one item vs many, light/dark, every persona skin it can wear (`UiSkinScope`, 6 skins x 3 variants).

## Phase 2: Render matrix (screenshots + matchers)

1. Copy [`templates/scan_test.dart`](templates/scan_test.dart) to `apps/mobile/test/zz_uxscan/scan_test.dart` (temporary; never commit `test/zz_*`).
2. Fill `screens` with the routes in scope. For a screen that needs data, add provider overrides to `pumpOurneyApp(overrides: [...])` or seed a local layer (`apps/mobile/test/data/data_test_helpers.dart`: `localLayer`, `memoryDb`, `TestClock`). Add one test per state from Phase 1 (empty, error, long Vietnamese title of ~60 characters, 30+ items). For a single widget, pump it with `testApp(widget, brightness:)` instead of the whole app.
3. Run from `apps/mobile` (Flutter is at `E:\tools\flutter\bin` if not on PATH):
   `flutter test test/zz_uxscan --update-goldens`
   The template sets an iPhone safe area (59 top, 34 bottom), loads the real fonts, and for each cell of the matrix (320/360/393/430dp, light/dark, text scale 1.0/1.35/2.0, vi/en) records layout exceptions, writes `test/zz_uxscan/out/<screen>_<config>.png`, and runs `labeledTapTargetGuideline`, `iOSTapTargetGuideline`, `androidTapTargetGuideline` and `textContrastGuideline`. The `reminders: notifications unavailable` log lines and `FlutterLocalNotificationsPlatform._instance` stack traces are normal in tests, not failures.
4. **Look at every PNG** (Read the file). For each, check the visual list in Phase 3 §A–C: clipped or overlapping text, content under the home indicator or the dock, a dark-mode surface that stayed light, a hard shadow or border that vanished, misaligned rows, inconsistent spacing.
5. For each failing matcher, find the widget from the `SemanticsNode` rect and label. `textContrastGuideline` samples pixels, so on glass over photos confirm against the tokens before reporting.

## Phase 3: Checklist (check EVERY item for EVERY screen in scope)

Greps find candidates in `apps/mobile/lib/features` and `apps/mobile/lib/ui`; read each hit before reporting.

### A. Layout, overflow, clipping

- [ ] No `RenderFlex overflowed`, unbounded-height (`ListView`/`GridView` in a `Column` without `Expanded`), unbounded-width (`TextField` in a `Row`), or `Incorrect use of ParentData widget` at any cell of the matrix.
- [ ] Text in a `Row` sits in `Expanded`/`Flexible` and has `maxLines` + `TextOverflow.ellipsis`, or wraps on purpose (`CLAUDE.md` §1.3). `rg -n "Text\(" <files>` then check the parent.
- [ ] No fixed pixel widths or heights that hold text or a camera preview (`CLAUDE.md` §3.1). `rg -n "width: [0-9]{3}|height: [0-9]{2,3}[,)]" <files>`; a fixed-height box around `Text` clips at 1.35x.
- [ ] Gutters 16/20/24dp by width and content capped at 480/520dp (`OurneyLayout`, `UiScaffold`, `CLAUDE.md` §3).
- [ ] Safe area: pinned bottom buttons, sheets and the dock clear the home indicator; nothing hides under the status bar or notch. Keyboard (`MediaQuery.viewInsetsOf`) does not cover the focused field or the submit button. Past: U1, U2.
- [ ] `Stack` children with `Positioned` do not collide when a sibling grows (two lines in Vietnamese, 2x text). Past: U2.
- [ ] Long user content (journey title, caption, display name, emoji, a 40-character word with no spaces) never breaks layout.

### B. Theme, colour, contrast

- [ ] Colours come from `context.ui` / `UiSkin.apply` / `UiJourneyStyle`, never literals. `rg -n "Color\(0x|Colors\.[a-z]" apps/mobile/lib/features` (exceptions must be documented in the kit).
- [ ] Every screen, sheet and dialog renders in both brightnesses; no surface stays light in dark mode, and dark mode keeps the outline and the hard shadow visible (`ui.outline`, `ui.hardShadow()`).
- [ ] Text on accent, pastel, photo or glass reaches 4.5:1 (3:1 for large text and icons). Check token pairs with `contrastRatio` (`lib/shared/color_utils.dart`).
- [ ] State is not shown by colour alone (selected chip, privacy tag, error field): add an icon, weight or label. Past: U14.
- [ ] Liquid glass only on the floating layer (dock, floating camera buttons, scrolled top bar, wheel backdrop, sheet edge), never on cards, timelines, share cards or primary buttons; solid fallback with Reduce Transparency / high contrast (`CLAUDE.md` §2.1, skin exceptions there).

### C. Touch targets and interaction

- [ ] Every tappable control is at least 48x48dp (`UiSize.tap`), including calendar cells, chips, segment tabs, inline text actions and close buttons. Past: U5.
- [ ] Tappables use `UiPressable` / `UiButton` / `UiIconButton`, not a bare `GestureDetector` (no semantics, no press state). `rg -n "GestureDetector|InkWell\(" apps/mobile/lib/features`.
- [ ] Primary buttons: 52dp (44 compact), press-in state (shadow to 0, shift 4px, 110ms, no scale), disabled look, busy state that blocks double submit (`CLAUDE.md` §2.2).
- [ ] Destructive or irreversible actions confirm (`showUiConfirmSheet`) and give feedback; leaving a form with unsaved changes warns. Past: U6, U12, U19.
- [ ] Back and close do what they say, root tabs have no back button, nothing navigates to a surprising screen. Past: U4, U9.
- [ ] Gestures (swipe, long-press on the Snap button, drag) have a visible tap alternative.

### D. Text scaling and Vietnamese text

- [ ] At 1.35x and 2.0x nothing clips, overlaps or breaks mid-word (`Chec / k-in`). `FittedBox` is acceptable for a big number, not for body copy. Past: U15, U17.
- [ ] Text with diacritics (`ệ ữ ấ`) uses line height 1.3–1.45 so marks are not cut; stacked diacritics are not clipped by a tight `SizedBox` or `ClipRect`.
- [ ] Text styles come from `UiText` / `context.ui` typography, not ad-hoc `fontSize:` (`rg -n "fontSize:" apps/mobile/lib/features`).

### E. States

- [ ] Loading: skeleton or `UiStateCard(kind: loading)`; no layout jump when data arrives; no infinite spinner when the provider errors.
- [ ] Empty: `UiEmptyState` / `UiStateCard(kind: empty)` with a next step, not a blank screen.
- [ ] Error: `UiInlineError` / `UiStateCard(kind: error)` with retry; errors are human, localized, no raw exception or URL. Past: U22.
- [ ] Offline and local-only: `UiStateCard(kind: offline)` or `NeedsServerView`; buttons that need the server explain why.
- [ ] Permission denied (camera, photos, notifications), including "denied forever" with a path to Settings. Past: U7.
- [ ] Transient camera state shows in `UiCameraStatusPill`, never a toast (`CLAUDE.md` §4, camera decision).
- [ ] Every `AsyncValue` in the screen handles `loading`, `error` and `data` (`rg -n "\.when\(|\.value\b|\.requireValue" <files>`; `.requireValue` in build throws while loading).

### F. Consistency and Ourney rules

- [ ] No `Icons.*`, `CupertinoIcons.*`, emoji or Unicode symbols as icons in system UI; `OurneyIcon` only (`CLAUDE.md` §1.3). `rg -n "Icons\.|CupertinoIcons\.|[●★♥✓]" apps/mobile/lib/features apps/mobile/lib/ui`.
- [ ] No placeholder text (`"..."`, `"icon"`, `"[+]"`, `TODO`) on screen.
- [ ] Screens use `lib/ui` components only, not `lib/shared/` widgets or raw Material (`ElevatedButton`, `AlertDialog`, `showModalBottomSheet`, `SnackBar`). `rg -n "ElevatedButton|TextButton|OutlinedButton|AlertDialog|showModalBottomSheet|SnackBar|ListTile" apps/mobile/lib/features`.
- [ ] The same thing looks the same everywhere: section headings (`UiListHeading`), rows (`UiRow`), chips, cards; same capitalization; no duplicated heading + label. Past: U10, U18, U21, U23.
- [ ] The 5-tab dock appears on every primary screen in the order Journeys · Squad · Snap · Activity · Profile (`CLAUDE.md` §2.1); switching journeys never resets the app or the camera (§5).
- [ ] Persona screens inside `UiSkinScope` recolour correctly for all 6 skins; screens outside stay on the neutral shell; the Hub shows each row's persona accent (§5).
- [ ] All copy is localized (vi + en ARB); no internal English names (`Memory Collectors`, `QUIET TRANSFORMER`) on a Vietnamese screen. Past: U20.

### G. Motion

- [ ] Animations respect `MediaQuery.disableAnimationsOf(context)` (Reduce Motion); press feedback is 110ms; nothing loops forever without purpose.

## Phase 4: Verification

For each candidate:

- Reproduce it in the matrix (screenshot or matcher) or point to the exact code path and the state that reaches it.
- Check it is not intended (an owner decision in `CLAUDE.md`, `docs/design-v2/`, the kit README "Known gap").
- Grade confidence: **chắc chắn** (seen in a screenshot or failing matcher), **có khả năng** (code reading, state is reachable), **nghi ngờ** (needs a real device: blur, haptics, real camera, keyboard on iOS).

## Phase 5: Pre-conclusion audit

Before the report, list:

1. Every screen and state rendered, with the matrix cells used.
2. Every checklist item A–G per screen: issue found or clean.
3. What you could not verify and why (needs device, needs server data, skin not reachable in a test).

Then delete `apps/mobile/test/zz_uxscan/` (keep the PNGs only if the user asks; move them out of the repo).

## Output format

Write in the user's language (Vietnamese by default). Start with a table, then one block per bug, P0 first:

| Mã | Lỗi | Mức · Độ chắc |
| --- | --- | --- |

```markdown
#### U<n>. <one-line title naming the screen and the symptom>

- **Mức độ:** `P0|P1|P2|P3` · **Độ chắc:** chắc chắn | có khả năng | nghi ngờ
- **Màn hình & vị trí:** route / screen — `path/file.dart:line`
- **Ảnh hưởng:** who hits it and when (width, theme, text scale, persona skin, state)
- **Bằng chứng:** PNG name from `out/`, matcher output, or the code line and why it fails
- **Vi phạm:** rule broken (`CLAUDE.md` §x, kit README, WCAG criterion) if any
- **Hướng sửa:** concrete change using `lib/ui` components and tokens, plus the widget test that should guard it
```

Severity: **P0** crash, data loss, or a primary flow blocked; **P1** primary action hidden, clipped or unreachable on a common config (360dp, dark, 1.35x), or an a11y blocker; **P2** visible defect or rule violation with a workaround; **P3** polish and consistency.

If nothing significant is found, say so; do not invent issues.

## Sources

Written for Ourney from these checklists (read 2026-11-21); no text copied beyond short rule names:

- [getsentry/skills `find-bugs`](https://github.com/getsentry/skills/tree/a582c51ee29d0f35e6ac321340796f77d43da733/skills/find-bugs) (Apache-2.0): the phase structure (complete input, map, check every item, verify, pre-conclusion audit).
- [vercel-labs/web-interface-guidelines `command.md`](https://github.com/vercel-labs/web-interface-guidelines/blob/434b7f91364665f2f733b310ec54809bf8f37937/command.md) (MIT): content handling (long, empty, user-generated), destructive confirmation, unsaved-changes warning, gesture alternatives, safe areas, reduced motion, error copy with a next step.
- [verygoodopensource/vgv-ai-flutter-plugin `accessibility`](https://github.com/verygoodopensource/vgv-ai-flutter-plugin/tree/316390b5d95f54e692db76f2b73140324ecd79d7/plugin/skills/accessibility) (MIT): fixed-height text containers, `GestureDetector` targets, colour-only state, Reduce Motion gating (full audit lives in `flutter-accessibility`).
- [flutter/agent-plugins `flutter-fix-layout-issues`](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-fix-layout-issues) (BSD-3-Clause): the layout error signatures in §A.
- Flutter `flutter_test` accessibility guidelines (`meetsGuideline`), Apple HIG (44pt targets, safe areas, Dynamic Type), Material 3 accessibility (48dp targets), WCAG 2.2 (1.4.3, 1.4.4, 1.4.11, 2.5.8).
- Ourney's own 2026-11-18 `ux-audit` (`docs/bug.md` §3, U1–U23): the "Past" references and the report shape.
