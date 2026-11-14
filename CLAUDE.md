# Ourney — Master Engineering & UI/UX Synchronization Rules (CLAUDE.md)

Every AI coding agent or developer working on Ourney MUST follow these rules to keep all screens, themes, buttons, and responsive layouts 100% synchronized across the codebase.

---

## 1. Mandatory Quality Gates & Anti-AI-Slop Policy
1. **Lint Check First**: Always run `dart analyze` (in `packages/ourney_core`) and `flutter analyze` (in `apps/mobile`) after creating or modifying any file. Fix all errors and warnings before finishing.
2. **Dark & Light Theme Mandatory**: Every screen, sheet, dialog, timeline, camera HUD, and widget MUST support both **Light Mode** and **Dark Mode** via the V1.0 UI kit tokens (`context.ui`, `apps/mobile/lib/ui/`, see its README; design source `design/figma-v1/`). Build UI only from `lib/ui` components. Never hardcode static light-only or dark-only colors inside widgets.
3. **Zero Hardcoded Text Icons / Zero AI Slop**:
   - Never use placeholder text (`"..."`, `"3-tab"`, `"icon"`, `"[+]"`) in place of icons. Always use the Ourney icon set (next bullet) drawn as SVG paths or `CustomPainter`.
   - No system/default icons anywhere in the app (owner decision 2026-11-11): no emoji and no Unicode symbol glyphs (`●`, `★`, `♥`, `✓`…) as icons, including journey type badges, streak (`flame` icon), reactions and HUD text. Use only the Ourney designed icon set (prototype: `design/ourney-v2-app/src/app/icons.tsx`) or custom SVG/`CustomPainter` illustrations. Emoji typed by users in captions stay as user content. Material `Icons` and `CupertinoIcons` count as default icons too. The Flutter port of the icon set is not built yet; until it lands, new Flutter UI must not add more default icons.
   - All text widgets displaying dynamic user content or Vietnamese diacritics (`ệ`, `ữ`, `ấ`) must use proper line height (`height: 1.3–1.45`) and overflow handling (`TextOverflow.ellipsis`, `Flexible`, `Expanded`).

---

## 2. Synchronized Navigation & Button Standards
1. **Unified 5-Tab Bottom Dock** (V2, approved 2026-11-11; see `docs/design-v2/feedback-2026-11-11.md`). This is the target state: the Flutter dock (`app_dock.dart`, `ui/components/dock.dart`) and `ourney_dock_test.dart` still have 3 tabs and will be updated when the V2 prototype is ported to code:
   - Every primary screen shares the same 5-tab dock, in this order:
     - `Journeys` (Map/Timeline vector icon) · `Squad` (Group/People vector icon)
     - **Center**: `Snap Shutter` (`76x76pt` Hero Shutter on Camera screen; `56x40pt` quick-snap pill on Hub/Timeline/Squad screens, colored with `pTheme.primaryAccent`; long-press opens the journey wheel)
     - `Activity` (Bell vector icon) · `Profile` (UserCircle vector icon)
   - Liquid glass is allowed only on the floating navigation layer (dock, floating camera buttons, top bar once content scrolls under it, journey-wheel backdrop, sheet top edge), never on cards, timelines, share cards or primary buttons (exception, owner decision 2026-11-12: the Aesthetic Flexer skin may use glass on its content cards such as metrics, summary and squad cards, as part of its material); keep the 2px border + hard shadow and a solid fallback for Reduce Transparency. Exception (owner decision 2026-11-12): the Quiet Transformer skin uses a 1.5px border + 2px hard shadow on the dock and primary button, matching its calm, hairline look.
2. **Button Hierarchy & Touch Targets**:
   - Minimum touch target: **`48x48dp`** (`>= 44pt` iOS HIG) on all interactive controls.
   - Primary buttons: `52dp` height (or `44dp` compact), capsule/rounded corners matching `pTheme.cardRadius`, a "press-in" state (owner decision 2026-11-12, V2): the hard shadow drops to 0 and the button shifts 4px toward the shadow, 110ms; no scale-down, and physical bottom lip when `pTheme.bottomLipHeight > 0`.

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
| **2** | `accountabilitySquad` | `englishDaily` | `persona_2_accountability_squad.jpg` | `steppingStoneQuest` (S-curve winding path to Day 30 Trophy) | `studyTimerSnap` (`45 MIN STUDY · 21 STREAK` with the `flame` icon + timestamp) | `squadPolaroidWall` (`4/5 Checked In` 2x2 grid + `Nudge` button with the `nudge` icon) |
| **3** | `memoryCollectors` | `travel` | `persona_3_memory_collectors.jpg` | `scrapbookThread` (Stitched terracotta line + taped Polaroids) | `disposableFilmStamp` (`FILM ROLL` + retro date/temp stamp) | `filmContactSheet` (35mm Kodak 20-frame contact sheet poster) |
| **4** | `coupleRituals` | `couple` | `persona_4_couple_rituals.jpg` | `duoSplitTimeline` (His & Her paired daily photos + heart nodes) | `halfFrameDuo` (Left: Partner's photo, Right: Live viewfinder) | `coupleMosaicPoster` (`18 DAYS TOGETHER · 36 MOMENTS` diptych grid) |
| **5** | `aestheticFlexer` | `workout30` | `persona_5_aesthetic_flexers.jpg` | `athleticTelemetry` (Neon pace sparkline + vertical run nodes) | `stravaStickerStudio` (`Bold HUD`, `Minimal Stamp`, `Film Strip`) | `transparentStorySticker` (9:16 Story card + 21-bar active heatmap) |
| **6** | `minimalistHabit` | `custom` | `persona_6_minimalist_habit.jpg` | `chainCalendarGrid` (7-column photo calendar with continuous orange line) | `zeroText3Sec` (1-tap Braun orange shutter, zero text inputs) | `zenSummaryCard` (`24/30 Days · 96% Consistency` minimal poster) |

---

## 5. Seamless Multi-Journey Switching (Zero App Reset)
- **Never reset the app or re-initialize the camera** when switching journeys.
- The app theme is the single kit theme (`OurneyTheme`) with the V2 shell palette. Skins (V2 spec, `docs/design-v2/orchestration/brief.md` section C.5) apply only on screens wrapped in `UiSkinScope` (journey detail, check-in, squad, sharing): `UiSkin.apply` (`lib/ui/skins.dart`) recolors bg, surface, ink, muted, accent and button for that journey's skin, variant and brightness. Screens outside a scope stay on the neutral shell, and the camera still uses the legacy `uiStyleForSkin` accent on its neutral dark theme. Legacy `uiStyleForSkin` / `lib/ui/journey_styles.dart` remain until the remaining screens migrate.
- **Global Hub (`JourneysScreen`)**: neutral shell theme; each journey row shows its own persona accent.
- **Create Journey (`CreateJourneyScreen`)**: Morphs live into whichever template card the user selects, displaying its preview board from `assets/design_personas/`.
