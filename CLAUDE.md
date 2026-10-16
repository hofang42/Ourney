# Ourney — Master Engineering & UI/UX Synchronization Rules (CLAUDE.md)

Every AI coding agent or developer working on Ourney MUST follow these rules to keep all screens, themes, buttons, and responsive layouts 100% synchronized across the codebase.

---

## 1. Mandatory Quality Gates & Anti-AI-Slop Policy
1. **Lint Check First**: Always run `dart analyze` (in `packages/ourney_core`) and `flutter analyze` (in `apps/mobile`) after creating or modifying any file. Fix all errors and warnings before finishing.
2. **Dark & Light Theme Mandatory**: Every screen, sheet, dialog, timeline, camera HUD, and widget MUST support both **Light Mode** and **Dark Mode** via `OurneyPersonaTheme.of(context)`. Never hardcode static light-only or dark-only colors inside widgets.
3. **Zero Hardcoded Text Icons / Zero AI Slop**:
   - Never use placeholder text (`"..."`, `"3-tab"`, `"icon"`, `"[+]"`) in place of icons. Always use vector `Icons`, `CupertinoIcons`, or `CustomPainter` / SVG paths.
   - Never use emojis as system navigation icons. Emojis are only allowed in Journey template badges, streak indicators (`🔥`), and user reactions (`👏`, `💪`).
   - All text widgets displaying dynamic user content or Vietnamese diacritics (`ệ`, `ữ`, `ấ`) must use proper line height (`height: 1.3–1.45`) and overflow handling (`TextOverflow.ellipsis`, `Flexible`, `Expanded`).

---

## 2. Synchronized Navigation & Button Standards
1. **Unified 3-Tab Bottom Dock**:
   - Every primary screen shares the same 3-tab dock structure:
     - **Left**: `Journeys` (Map/Timeline vector icon)
     - **Center**: `Snap Shutter` (`76x76pt` Hero Shutter on Camera screen; `56x40pt` quick-snap pill on Hub/Timeline/Squad screens, colored with `pTheme.primaryAccent`)
     - **Right**: `Squad` (Group/People vector icon)
2. **Button Hierarchy & Touch Targets**:
   - Minimum touch target: **`48x48dp`** (`>= 44pt` iOS HIG) on all interactive controls.
   - Primary buttons: `52dp` height (or `44dp` compact), capsule/rounded corners matching `pTheme.cardRadius`, `0.96` press scale animation (`110ms`), and physical bottom lip when `pTheme.bottomLipHeight > 0`.

---

## 3. Mobile Responsive Rules (All Screen Sizes)
1. **Compact Phones (`width < 360dp`, e.g., iPhone SE / mini)**:
   - Horizontal screen padding `16dp`. Use `LayoutBuilder` / `Flexible` / `AspectRatio` for camera previews and `2x2` Polaroid grids—never hardcode fixed pixel widths that overflow narrow screens.
2. **Standard Phones (`360dp <= width < 410dp`, e.g., iPhone 16, Galaxy S24)**:
   - Horizontal screen padding `20dp`, card padding `16dp`, grid spacing `12dp`.
3. **Pro Max / Large Phones (`410dp <= width < 600dp`)**:
   - Horizontal screen padding `24dp`, max card content width `480dp`.
4. **Tablets & Foldables (`width >= 600dp`)**:
   - Constrain single-column feeds to `maxWidth: 520dp` centered, or use a 2-pane split view (Timeline left, Detail/Share Card right).
5. **Safe Area & Dynamic Type**:
   - Always respect `MediaQuery.paddingOf(context)`, `MediaQuery.viewInsetsOf(context)`, and Dynamic Type scaling up to `1.35x`.

---

## 4. The 6 Adaptive Persona UI Styles (`PersonaSkinId`)
Each `TemplateId` maps 1-to-1 to a `PersonaSkinId` and a visual reference board in `apps/mobile/assets/design_personas/`:

| # | `PersonaSkinId` | `TemplateId` | Visual Reference Asset | Timeline Variant | Camera HUD Variant | Share / Squad Variant |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | `quietTransformer` | `weightLoss` | `persona_1_quiet_transformer.jpg` | `connectedWeightCurve` (Weight trend curve + vertical nodes) | `ghostAlignVault` (Day 1 silhouette guide + `Private Vault` + weight slider) | `sideBySideArchive` (`DAY 01 vs DAY 21` + `Hide Exact Weight` toggle) |
| **2** | `accountabilitySquad` | `englishDaily` | `persona_2_accountability_squad.jpg` | `steppingStoneQuest` (S-curve winding path to Day 30 Trophy) | `studyTimerSnap` (`45 MIN STUDY · 🔥 21 STREAK` + timestamp) | `squadPolaroidWall` (`4/5 Checked In` 2x2 grid + `Nudge 👋` button) |
| **3** | `memoryCollectors` | `travel` | `persona_3_memory_collectors.jpg` | `scrapbookThread` (Stitched terracotta line + taped Polaroids) | `disposableFilmStamp` (`FILM ROLL` + retro date/temp stamp) | `filmContactSheet` (35mm Kodak 20-frame contact sheet poster) |
| **4** | `coupleRituals` | `couple` | `persona_4_couple_rituals.jpg` | `duoSplitTimeline` (His & Her paired daily photos + heart nodes) | `halfFrameDuo` (Left: Partner's photo, Right: Live viewfinder) | `coupleMosaicPoster` (`18 DAYS TOGETHER · 36 MOMENTS` diptych grid) |
| **5** | `aestheticFlexer` | `workout30` | `persona_5_aesthetic_flexers.jpg` | `athleticTelemetry` (Neon pace sparkline + vertical run nodes) | `stravaStickerStudio` (`Bold HUD`, `Minimal Stamp`, `Film Strip`) | `transparentStorySticker` (9:16 Story card + 21-bar active heatmap) |
| **6** | `minimalistHabit` | `custom` | `persona_6_minimalist_habit.jpg` | `chainCalendarGrid` (7-column photo calendar with continuous orange line) | `zeroText3Sec` (1-tap Braun orange shutter, zero text inputs) | `zenSummaryCard` (`24/30 Days · 96% Consistency` minimal poster) |

---

## 5. Seamless Multi-Journey Switching (Zero App Reset)
- **Never reset the app or re-initialize the camera** when switching journeys.
- Updating `activePersonaSkinProvider` triggers `MaterialApp.router`'s `AnimatedTheme` (`320ms`, `Curves.easeOutCubic`) via `OurneyPersonaTheme.lerp()`, while screen sub-layouts morph in `260ms` via `AnimatedSwitcher`.
- **Global Hub (`JourneysScreen`)**: Uses `OurneyPersonaTheme.editorialNeutralBase(brightness)`, while each `JourneyCard` displays its own persona accent badge.
- **Create Journey (`CreateJourneyScreen`)**: Morphs live into whichever template card the user selects, displaying its preview board from `assets/design_personas/`.
