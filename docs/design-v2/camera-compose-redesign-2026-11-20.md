# Camera + Post (caption) redesign spec — Ourney

> Implemented 2026-11-21. Deviations: flash-off/flash-auto glyphs already existed (no new icons, `ghost` reuses `eye`); `UiCaptionField` keeps the kit border at rest (owner: all inputs share the 1.5dp border) instead of no border; weight slider not re-added (the metric field is the weight input); toast safety net (step 5) skipped because the camera no longer calls `showUiToast`; OTP and join-code boxes use `UiRadius.otp` (10), text fields `UiRadius.field` (16), `UiRadius.input` is back to 12 for other surfaces.

Date 2026-11-20. Read-only research on worktree `review-previous-context-ca1461`. Paths are relative to `apps/mobile/`.

## 1. What is there now (and why it feels wrong)

**Camera** (`lib/features/camera/capture_screen.dart` `_buildCamera`): a Column of top bar (`widgets/camera_top_bar.dart`: name chip, then flash, flip and grid), a 3:4 viewfinder inset by the screen gutter (16/20/24) with radius 32, `JourneyTitleBlock` (title, day, count), a row with the library thumb and `JourneyDiscStrip`, and the camera `AppDock` (92dp, `UiShutter` 76dp). Five stacked bands use up the height, so the preview is only about 70% of the width on a 390dp phone. That is the "cramped and small" feeling.
- Inside the preview: the persona HUD `capture_overlays.dart` `CaptureSkinOverlay` (quiet: ghost, vault chip and weight slider; squad: a 44px mono clock and a study chip; memory: `FILM ROLL` and a date stamp; couple: the half-frame partner panel; flexer: bold/stamp/strip HUD pickers, pace and the film-strip painter), a streak `UiGlassChip`, the `LatestPhotoThumb` and a gradient.
- **Flash bug, root cause:** `_toggleFlash` calls `showUiToast`, which is a floating `SnackBar` with `bottomOffset: 36` (`lib/ui/components/feedback.dart:368`). The camera `Scaffold` has no `bottomNavigationBar`, because the dock sits inside the body Column. The SnackBar therefore lands about 36dp above the safe area, right on the dock and the 76dp shutter, and it stays for 4s. The flash icon already changes state (`UiCameraToolEmphasis`), so the toast is redundant.

**Post screen** (`lib/features/checkin/checkin_screen.dart` `_compose`): the header row (Retake text, journey title and privacy tag), a 3:4 `_PhotoPreview` capped at 45% of the height, a caption label, a raw Material `TextField` with an **underline** border, a `0/140` counter that is always visible, the metric `UiTextField`, `PostExtrasSection` (`post_extras.dart`) and a full-width Post button.
- **"Square fields":** the kit `UiTextField` / `UiTextArea` (`lib/ui/components/inputs.dart`, `text_area.dart`) are 56dp boxes with `UiRadius.input = 12` (`lib/ui/tokens.dart:292`), a 2dp **ink** outline and a hard shadow. At 56dp tall a 12dp radius reads as a square box. They are used app-wide, including in post extras (place, couple names, distance).

## 2. What leading apps do (short)

| App | Capture screen | Caption entry |
|---|---|---|
| iOS Camera / Pixel | Near full-bleed preview. The shutter sits centred in a bottom row with the last photo on the left and flip on the right. Flash is one top-corner glyph whose state is shown by the glyph itself (slash, "A", yellow fill), plus a small in-preview badge when it will fire. No toast. ([Apple guide](https://support.apple.com/en-us/guide/iphone/iph3dc593597/14.0/ios/14.0), [Macworld](https://www.macworld.com/article/3041873/11-gotta-know-ios-camera-tricks-for-beginners.html)). Camera Control HIG: short control names, key controls in the middle ([HIG](https://developer.apple.com/design/human-interface-guidelines/camera-control.md)) | Photos: caption added later in the Info panel, single field |
| Locket | A square, heavily rounded preview card in the middle. Below it: flash on the left, a large white shutter in the centre, flip on the right. Nothing on top of the image ([XDA](https://www.xda-developers.com/locket-simpler-snapchat-iphones-home-screen/)) | (From using the app; not confirmed by a source) a pill-shaped "Add a message" on the photo itself, one line, short |
| BeReal | Rounded full-width preview, shutter centred below it, flash and flip as icons beside the shutter | Caption is added after posting via an "Add a caption…" bar under the post, with a send button on the right ([Alphr](https://www.alphr.com/add-caption-bereal/)) |
| Instagram Stories / Snapchat | Full-bleed preview with tools in a vertical rail at top-right. Mode changes are shown by the icon state only | Snapchat: a translucent caption bar across the photo, limit of about 80 chars ([Typecount](https://typecount.com/blog/snapchat-character-limit)). Instagram feed: a separate "New post" screen with a small thumbnail beside a borderless multi-line caption and **Share** as a large bottom button |
| Threads / X composer | n/a | Borderless multi-line text. The counter appears only near the limit (a ring). The primary action stays above the keyboard |
| Strava | n/a | "Save activity": a rounded filled title field with a placeholder that suggests a title, then a larger description field, with Save at the bottom |

**Takeaways:**
1. Make the preview as large as possible and keep the bottom row symmetric (library, shutter, flip).
2. Show mode state on the control itself. If a word is needed, use a small transient pill at the top of the preview, never a bottom toast.
3. Keep nothing decorative on the image.
4. Use rounded, filled fields with no heavy outline, a prompt-like placeholder and a counter shown only near the limit.
5. Keep the primary action reachable while the keyboard is open, and shrink the photo when typing.

## 3. Camera spec

```
 390dp, camera always dark (UiCamera.*)       320dp: same, preview shrinks (Expanded+AspectRatio)
┌──────────────────────────────────────┐
│ safe top                             │
│ [● Giảm cân · Ngày 12  ▾]   (⚡)(▦)  │ 48dp row, gutter 12; chip = name + day, accent dot
│ ┌──────────────────────────────────┐ │ preview inset 8dp (not the gutter), radius 28
│ │        ( ⚡ Flash: tự động )      │ │ <- status pill, top-centre, 1.2s, 32dp tall
│ │                          [🔥 12] │ │ streak chip (kept, small)
│ │                                  │ │
│ │          live 3:4 preview        │ │
│ │                                  │ │
│ │           ( .5  1x  2 )          │ │ zoom pill, only if the session supports it
│ └──────────────────────────────────┘ │
│  [lib]   ○ ◉ ○ ○  Tất cả(6)    [⟲]   │ 56dp row: library | disc strip | flip
│ ╭──────────────────────────────────╮ │
│ │ Hành trình    ( SHUTTER 76 )  Nhóm│ │ AppDock camera, unchanged
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

- **Layout.** Use `Column[topBar 48, gap 8, Expanded(Center(AspectRatio 3/4, preview)), gap 8, controlsRow 56, AppDock]`.
  - The preview has a horizontal inset of `UiSpace.sm` (8) and `UiRadius.viewfinder` (32), or 28 if the owner wants it tighter.
  - Approximate preview width: 304dp at 320dp (it gets height-limited on SE: `AspectRatio` inside `Expanded` already handles that), 374dp at 390dp, 414dp at 430dp.
  - On tablets (600dp or wider), keep `maxContent` 520.
  - Remove `JourneyTitleBlock` from the camera. Its day information moves into the chip as "Name · Ngày N" (vi) / "Name · Day N" (en). Keep `_FitOrGlide`.
- **Tools.** The top-right holds flash (only if `hasFlash`) and grid. **Flip moves to the controls row on the right**, mirroring library on the left (thumb reach, iOS/Locket pattern).
  - All are `UiCameraTool` with a 48dp target.
  - Flash cycles off, auto, on. Each state needs its own glyph: `lightning-off` (with a slash), `lightning-auto` (bolt with an "A"), and `lightning` filled with an accent disc. Two glyphs are new in `ourney_icons.dart`. Shape, not colour alone, carries the state.
- **State indicator.** Add a new kit widget `UiCameraStatusPill` in `camera_chrome.dart`.
  - Look: glass dark capsule, 32dp tall, icon plus text, `UiText.body 13 / h1.3`, max width = preview − 32.
  - Position: inside the preview, top-centre, 12dp below its top edge.
  - Motion: fades in 150ms, holds 1.2s, fades out 200ms. Reduce Motion: no fade, holds 1.5s.
  - A11y: a `SemanticsService.announce` of the state, plus the tool's own `label`/`value`.
  - Used for the flash state, "flash unavailable", and "grid on/off" (optional).
  - **The camera must not call `showUiToast` at all.** For `camera_captureFailed`, use the same pill in danger tint.
  - Fix the kit as a safety net too: `showUiToast` gains a `bottomOffset` computed above the dock when the route has an `AppDock`, or the camera passes `bottomOffset: 92 + 16 + safeBottom`.
- **Removed from the preview.** In `capture_overlays.dart`, remove:
  - squad: `_time()`, the `overlay-time` clock and the `overlay-study` chip
  - memory: `overlay-film` and `overlay-film-date`
  - flexer: `overlay-hud-bold/stamp/strip`, the `overlay-hud-pick-*` chips, `overlay-pace` and `_StripPainter`
  - quiet: the `overlay-vault` chip, the `overlay-weight` label and the weight slider (the weight is entered on the Post screen, which already has the metric field)
  - the bottom gradient (no stamps left to protect)
  - `LatestPhotoThumb` in the preview (the disc's "shot today" ring and the journey screen cover it)
- **Kept** (functional, not decoration):
  - Quiet ghost silhouette: a grid-style tool `ghost` (eye glyph) in the top bar, shown only for `quietTransformer`, default on.
  - Couple partner photo: changed from a half-frame panel to a **72×96 PiP thumbnail** at top-start (radius 12, 2dp `UiCamera.outline`). Tap it to enlarge it to the half-frame for 3s or while held. Without a partner photo, show nothing.
  - Streak chip.
  - Grid.
  - The minimal persona already shows nothing.
- **Journey selection.** Unchanged in behaviour: the chip opens `showJourneyPickerSheet`, the disc strip stays in the controls row, a swipe on the preview cycles journeys, and a long press on the shutter opens the wheel.
  - Persona shows only as accent: the chip dot, the selected disc ring, the shutter colour (`style.accent`) and the active flash disc.
  - Switching journeys never touches `CameraSession` (CLAUDE.md §5; the current code already complies).
- **Zoom.** Phase 2, only if `CameraSession` exposes zoom levels: a 32dp glass segmented pill at the bottom-centre of the preview (0.5/1/2). Pinch to zoom also works.
- **A11y.** The labels stay `camera_shutterFor(title)`, `camera_flashOff/Auto/On`, `camera_switchLens`, `camera_grid` and `camera_gallery`, with new keys `camera_ghost` and `camera_partnerPhoto`. The status pill is a live region. Every target is at least 48dp. The chip handles text scale up to 1.35 by shrinking and then gliding.
- **Theme.** The camera stays dark in both app themes (it already forces `OurneyTheme.build(Brightness.dark, ...)`). No light variant is needed. This is documented as an exception.

## 4. Post (caption) spec

```
 Idle                                    Typing (keyboard up)
┌──────────────────────────────────┐   ┌──────────────────────────────────┐
│ (✕)      Giảm cân · Riêng tư      │   │ (✕)      Giảm cân · Riêng tư      │
│ ┌──────────────────────────────┐ │   │ ┌──────┐ ╭──────────────────────╮ │
│ │                              │ │   │ │photo │ │Cân nặng và năng lượng│ │
│ │   photo 3:4, radius 20,      │ │   │ │ 72x96│ │hôm nay ra sao?|      │ │
│ │   up to 55% height           │ │   │ └──────┘ ╰──────────────────────╯ │
│ │  [Chụp lại ⟲]  (glass, b-l)  │ │   │                          118/140 │ <- only >= 120
│ └──────────────────────────────┘ │   │ [ Cân nặng (kg)    72,5      🔒 ] │
│ ╭──────────────────────────────╮ │   ├──────────────────────────────────┤
│ │ Hôm nay có gì mới?           │ │   │ [        Đăng  ➤  (accent)      ] │ <- sits on keyboard
│ ╰──────────────────────────────╯ │   │ ░░░░░░░░ keyboard ░░░░░░░░░░░░░░ │
│ Chi tiết: [😊 mood chips…]        │   └──────────────────────────────────┘
│ [ Cân nặng (kg)   72,5        🔒 ]│
│ [          Đăng  ➤              ]│ bottom bar, safe area, 52dp
└──────────────────────────────────┘
```

- **Separate screen** (as today, like Instagram and Strava, unlike Snapchat's overlay bar). Ourney needs room for persona extras, and posting stays at two taps (shutter, then Post).
- **Header.**
  - Left: a `UiIconButton` close/back (48dp, `close` glyph) that returns to the camera.
  - Centre: journey title and `UiPrivacyTag`.
  - Right: empty.
  - **Retake** moves to a glass `UiTag`-style button at the bottom-left of the photo (`checkin-retake`; it keeps its key).
- **Photo.**
  - Idle: 3:4, radius `UiRadius.card`, max height `min(55% of the height, 520)`.
  - Focused (`viewInsets.bottom > 0`): animates (`UiMotion` 220ms, easeOut; instant under Reduce Motion) into a 72×96 thumbnail beside the caption, as in Instagram's composer. Tapping the thumbnail dismisses the keyboard.
  - The "from library" tag stays.
- **Caption field.** New kit `UiCaptionField` (or `UiTextArea(variant: filled)`).
  - Shape and colour: filled `ui.fill` background, **radius 16** (new token `UiRadius.field = 16`), no visible border at rest, 2dp `style.accent` border on focus.
  - Size: min height 52, padding 16/14, `UiText.body 16 h1.45`, 1 to 5 lines growing, `TextCapitalization.sentences`, `TextInputAction.done` (Return closes the keyboard; captions are short).
  - No label above it; the placeholder is the label. Placeholder: `template.captionPromptVi/En` (e.g. "Hôm nay có gì mới?" / "What's new today?"). Semantic label: `checkin_captionLabel`.
  - Limit: 140 code points (`_CodePointLimit`). Show the counter only from 120 upwards (right-aligned, 12px, danger at 140). The semantics counter always stays.
- **Persona extras** (`post_extras.dart`).
  - They stay below the caption under a muted "Chi tiết" / "Details" label: mood chips (quiet), minutes chips (squad), place field (memory), couple names and partner photo (couple), distance and pace keypad (flexer).
  - The metric field moves directly under the caption. It holds the weight that the camera slider used to provide; the prefill from the last value stays.
  - The minimal persona keeps its 3s countdown hint above the button.
  - All text inputs use the new rounded filled style.
- **Primary action.** `UiButton` 52dp in the accent colour, label `postLabel` (per persona copy). It sits in a bottom bar that follows `MediaQuery.viewInsetsOf` so it rides on the keyboard; the field scrolls if needed. Remove the always-visible header Post (already removed per U21).
- **Light/dark.** All colours come from `context.ui` and `style.accent`, so both themes are covered.

**Kit-level change (fixes "square fields" everywhere).**
- Tokens: `UiRadius.input` goes from 12 to **16**, and `UiRadius.field = 16` is added. Single-line search fields use `UiRadius.capsule`.
- `UiTextField` / `UiTextArea`: 52dp height (`UiSize.input`, replacing the private 56), `ui.fill` background, 1.5dp `ui.border` outline at rest (not 2dp ink), and focus as a 2dp `ui.brand` (or accent) border instead of the 3dp spread ring. Remove the hard shadow. Keep the label above for forms (auth, create journey). The caption uses the label-less variant.
- OTP boxes keep 12, or follow the token; the owner decides.
- Update `lib/ui/README.md` and the `design/figma-v1` note to match.

## 5. Conflicts with CLAUDE.md (owner to decide)

- **§4 "Camera HUD Variant" column** (`ghostAlignVault`, `studyTimerSnap`, `disposableFilmStamp`, `halfFrameDuo`, `stravaStickerStudio`, `zeroText3Sec`): this spec drops the stamps, clock, film roll, HUD picker and vault chip. It keeps only the quiet ghost (as a tool) and the couple partner photo (as PiP).
  - Recommendation: replace the column with "Camera: shared camera; persona = accent (+ ghost guide for quiet, partner PiP for couple)". Keep the timeline and share variants as they are.
- **§4 quiet "weight slider" on the camera:** moved to the Post screen's metric field.
- **§2 / §1:** no conflict. The 76×76 hero shutter, the 3-tab dock, 48dp targets, the Ourney icon set (two new flash glyphs drawn in `ourney_icons.dart`) and dark camera chrome are all kept.

## 6. Implementation plan (ordered)

1. **Kit: icons and pill.**
   - `lib/ui/components/ourney_icons.dart`: add `lightning-off`, `lightning-auto` and `ghost` (or reuse `eye`).
   - `lib/ui/components/camera_chrome.dart`: add `UiCameraStatusPill` and an `active`/accent emphasis on `UiCameraTool`.
   - Test: `test/ui/chips_inputs_bars_test.dart` (pill semantics, reduce motion).
2. **Kit: fields.**
   - `lib/ui/tokens.dart` (`UiRadius.input` = 16, add `field`), `lib/ui/components/inputs.dart` (`UiTextField` restyle, height = `UiSize.input`) and `text_area.dart` (`variant: filled`, `showCounterFrom`, label optional).
   - Update `test/ui/chips_inputs_bars_test.dart`. Run golden or visual checks on the auth and create-journey screens.
3. **Camera layout** (`lib/features/camera/capture_screen.dart`):
   - Preview inset 8. Remove `JourneyTitleBlock` from `_buildCamera`.
   - Controls row: library | discs | flip.
   - `_tools` = flash + grid (+ ghost for quiet).
   - Replace `showUiToast` in `_toggleFlash` and `_capture` with pill state (`_status`, a `Timer`).
   - Remove `LatestPhotoThumb` from the viewfinder.
   - In `widgets/camera_top_bar.dart`, the chip shows "title · Ngày N" (new l10n `camera_chipDay`).
4. **Overlays** (`lib/features/camera/capture_overlays.dart`):
   - Delete the squad, memory and flexer HUDs, the vault, the weight slider and `_StripPainter`.
   - Keep `_GhostPainter` (driven by the top-bar tool).
   - Turn the couple panel into a PiP.
   - The minimal persona keeps nothing.
   - Remove the `onWeightChanged`/`lastPace`/`lastKm`/`lastMinutes` params and the `pendingWeightProvider` writes from the camera (keep the provider if the checkin still reads it, or drop it in step 6).
   - Remove the now-unused l10n keys (`camera_filmRoll`, `camera_hud*`, `camera_lastPace*`, `camera_squad*`, `camera_privateVault`, `camera_weightSlider*`, `camera_lastWeight`, `camera_dayStreakBold`, `camera_dayHud`) from `l10n/camera_{en,vi}.arb`, then regenerate.
5. **Toast safety net:** `lib/ui/components/feedback.dart` `showUiToast` places itself above the dock (it reads an inherited dock height, or callers pass it). Add a test that a toast on `/capture` does not overlap `capture-shutter`.
6. **Post screen** (`lib/features/checkin/checkin_screen.dart`):
   - Header with the close button, Retake on the photo, `_PhotoPreview` that collapses on focus, `UiCaptionField` with key `checkin-caption`, a counter from 120 (key `checkin-caption-counter`), metric directly after the caption, and a bottom bar following `viewInsets`.
   - `post_extras.dart`: add the "Details" label; fields pick up the kit style automatically.
   - New l10n `checkin_details` (vi "Chi tiết").
7. **Docs:** update the CLAUDE.md §4 column (after owner approval), `lib/ui/README.md` (`UiCameraStatusPill`, field variant), and `docs/design-v2/bugs.md` (flash toast over the shutter: root cause and fix).
8. **Tests to update or remove:**
   - `test/features/camera/capture_overlays_test.dart` (most cases go; keep ghost and couple PiP)
   - `capture_persona_test.dart`, `capture_v2_layout_test.dart` and `capture_layout_test.dart` (title block gone, flip moved, preview size checked at 320/390/430 with no overflow at text scale 1.35)
   - `capture_screen_test.dart` (flash cycles icon and pill; no SnackBar)
   - `test/features/checkin/checkin_screen_test.dart` (caption keys, counter threshold, retake location, keyboard bottom bar)
   - pending-weight tests
   - Then run `flutter analyze` in `apps/mobile` and `dart analyze` in `packages/ourney_core`.

**Sources:** [Apple iPhone guide](https://support.apple.com/en-us/guide/iphone/iph3dc593597/14.0/ios/14.0) · [Apple HIG, Camera Control](https://developer.apple.com/design/human-interface-guidelines/camera-control.md) · [Macworld iOS camera tips](https://www.macworld.com/article/3041873/11-gotta-know-ios-camera-tricks-for-beginners.html) · [XDA on Locket](https://www.xda-developers.com/locket-simpler-snapchat-iphones-home-screen/) · [Locket App Store](https://apps.apple.com/us/app/1600525061) · [Alphr, BeReal caption](https://www.alphr.com/add-caption-bereal/) · [Typecount, Snapchat limits](https://typecount.com/blog/snapchat-character-limit). The Instagram, Threads/X and Strava composer details come from using the apps; no source was fetched for them.
