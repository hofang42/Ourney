# Ourney — Adaptive 6-Persona UI System & Dynamic Theme Engine

> **Core Principle**: **One App Shell, Six Reactive Journey Skins (`OurneyPersonaThemeExtension`) — Zero App Reset.**
> Ourney adapts its visual language, timeline renderer, camera HUD, and share card studio dynamically based on the active journey's archetype (`PersonaSkinId`), while keeping a unified 3-tab navigation structure (`Journeys · [Snap] · Squad`) and supporting both **Light Mode** and **Dark Mode** on every single screen.

---

## 1. Architectural Answers to Multi-Style Switching

### Q1: When a user switches from one Journey to another (e.g., from *Weight Loss* to *Da Lat Trip*), how does the app render the new UI? Does it reset the app?
**NO app reset, NO route reload, and NO camera restart.**
In Flutter, switching journeys updates a single `activeJourneyIdProvider` in Riverpod.
1. **`AnimatedTheme` + `ThemeExtension<OurneyPersonaTheme>` (320ms `Curves.easeOutCubic`)**:
   - Colors, surface tokens, border widths, corner radii, and typography accents smoothly interpolate over `320ms` using `ThemeExtension.lerp()`.
2. **Modular Strategy Widgets (`AnimatedSwitcher` 260ms)**:
   - Each Journey's `PersonaSkinId` selects a lightweight layout strategy for:
     - `TimelineVariant`: `connectedCurve` | `steppingStoneQuest` | `scrapbookThread` | `duoSplitTimeline` | `athleticTelemetry` | `chainCalendarGrid`
     - `CameraHudVariant`: `ghostAlignVault` | `studyTimerBadge` | `disposableFilmStamp` | `halfFrameDuo` | `stravaStickerHud` | `zeroText3Sec`
     - `ShareCardVariant`: `sideBySideArchive` | `squadPolaroidWall` | `filmContactSheet` | `coupleDiptychMosaic` | `transparentSticker` | `zenSummaryCard`
   - Because the underlying `CameraController` remains mounted inside the persistent shell, switching between journeys on the Camera screen only cross-fades the **HUD overlay layer** (`< 16ms`, 60/120fps) without re-initializing the hardware camera sensor.

### Q2: Which UI is used for the Main "Journeys Hub" & "Create Journey" screen?
We use a **3-Layer Chameleon Shell Architecture**:
1. **Default Base Neutral Shell ("Ourney Editorial Base")**:
   - When the user is a brand-new user (0 journeys) or browsing the global **Journeys Hub**, the outer shell uses the signature **Ourney Warm Alabaster / Obsidian Base** (`#F6F2EA` Light / `#0F0F14` Dark, Coral `#FF4D6D` primary).
2. **Active Journey Ambient Tint**:
   - When the user has an active/selected journey, the top header and primary action accents subtly inherit the active journey's `PersonaSkinId` accent color so the app feels personal and cohesive.
3. **Interactive Live Preview on "Create Journey" (`CreateJourneyScreen`)**:
   - On the Create Journey screen, as soon as the user taps one of the 6 Journey Archetype cards, **the preview card and screen accents morph live in real-time** into that archetype's UI skin (using its reference asset in `assets/design_personas/`), letting the user *feel* the exact style they are choosing before tapping "Start Journey".

---

## 2. The 6 Persona UI Skins (`PersonaSkinId`)

| `PersonaSkinId` | Mapped `TemplateId` | Target User Archetype | Visual Reference Asset | Timeline Renderer | Camera HUD | Share / Group Card |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `quietTransformer` | `weightLoss` | **1. The Quiet Transformer** *(Body Recomp, Weight Loss, Skincare)* | `assets/design_personas/persona_1_quiet_transformer.jpg` | **Connected Weight & Photo Curve** (Sparkline + vertical nodes) | **Ghost-Align Camera** (Day 1 silhouette guide + `🔒 Private Vault` + weight slider) | **Side-by-Side Progress Archive** (`DAY 01 vs DAY 21` + `Hide Exact Weight` toggle) |
| `accountabilitySquad` | `englishDaily` | **2. The Accountability Squad** *(IELTS, Study, Book Club, 5AM Club)* | `assets/design_personas/persona_2_accountability_squad.jpg` | **Stepping-Stone Quest Trail** (Winding S-curve path to Day 30 Trophy) | **Study Timer & Snap HUD** (`📖 45 MIN STUDY · 🔥 21 STREAK` + timestamp) | **Squad Today Polaroid Wall** (`4/5 Checked In` + `Nudge 👋` button) |
| `memoryCollectors` | `travel` | **3. The Memory Collectors** *(Da Lat Trip, Friends Vacation, Youth)* | `assets/design_personas/persona_3_memory_collectors.jpg` | **Scrapbook Trip Thread** (Stitched terracotta line + taped Polaroids) | **Disposable Film Camera** (`FILM ROLL 24/36` + retro date/temp stamp) | **Trip Contact Sheet Poster** (35mm Kodak 20-frame mosaic) |
| `coupleRituals` | `couple` *(or group=2)* | **4. Couples Building Rituals** *(Home Cooking, Long Distance, Saving)* | `assets/design_personas/persona_4_couple_rituals.jpg` | **Side-by-Side Duo Timeline** (His & Her paired daily photos + heart nodes) | **Half-Frame Duo Camera** (Left: Partner's photo, Right: Live camera viewfinder) | **30-Day Couple Mosaic Poster** (Diptych woven story card) |
| `aestheticFlexer` | `workout30` | **5. The Aesthetic Flexer** *(Running Club, Gym, Pilates, Strava Gen-Z)* | `assets/design_personas/persona_5_aesthetic_flexers.jpg` | **Athletic Telemetry Timeline** (Neon pace curve + vertical run nodes) | **Transparent Sticker Studio** (`Bold HUD`, `Minimal Stamp`, `Film Strip`) | **1-Tap Instagram Story Export** (With 21-day active heatmap bar) |
| `minimalistHabit` | `custom` | **6. The Zero-Friction Minimalist** *(Reading, Hydration, Desk Ritual)* | `assets/design_personas/persona_6_minimalist_habit.jpg` | **Don't Break The Chain Grid** (7-column photo calendar connected by orange line) | **3-Second Zero-Text Snap** (1-tap shutter, zero text input friction) | **Zen Monthly Summary Card** (`24/30 Days · 96% Consistency`) |

---

## 3. Exact Color & Surface Tokens (Light & Dark Mandatory)

Every `PersonaSkinId` **MUST** define both Light and Dark mode palettes:

| `PersonaSkinId` | Light `bg` / `surface` / `ink` | Dark `bg` / `surface` / `ink` | `primaryAccent` | `secondaryAccent` | Border & Elevation Style |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`quietTransformer`** | `#EFF3F0` / `#FFFFFF` / `#0F172A` | `#0B0F12` / `#151C21` / `#F1F5F9` | `#10B981` (Emerald) | `#FF4D6D` (Coral Shutter) | Hairline `1px` border, soft clinical elevation |
| **`accountabilitySquad`** | `#F7F1E5` / `#FFFDF9` / `#1E1B18` | `#12131A` / `#1D1F2B` / `#F8FAFC` | `#FF9F1C` (Flame Gold) | `#7556F8` (Squad Violet) | Tactile `2px` ink border + `3px` bottom lip |
| **`memoryCollectors`** | `#F4EFE6` / `#FFFFFF` / `#231F1E` | `#141312` / `#1F1D1B` / `#F5F2EB` | `#CC4A2F` (Terracotta) | `#4A6B53` (Olive Sage) | Paper shadow + masking tape + film sprocket |
| **`coupleRituals`** | `#F9F0EE` / `#FFFFFF` / `#261F22` | `#171215` / `#241C21` / `#FCE7F3` | `#E15B72` (Rose Coral) | `#9D174D` (Deep Berry) | Soft rounded `24px` paired diptych frames |
| **`aestheticFlexer`** | `#F3F4F6` / `#FFFFFF` / `#090A0F` | `#090A0F` / `#14161F` / `#F8FAFC` | `#FF4D6D` (Electric Coral) | `#3DE88C` (Neon Lime) | Frosted glass (`BackdropFilter`) + glowing `1px` stroke |
| **`minimalistHabit`** | `#F5F3EE` / `#FFFFFF` / `#1C1C1E` | `#0E0E10` / `#18181B` / `#F4F4F5` | `#EA580C` (Braun Orange) | `#27272A` (Matte Charcoal) | Crisp `1px` geometric grid, zero ornamental clutter |

---

> **Contrast (F6).** Every text pair of every skin, in both modes, is held to WCAG AA 4.5:1 by `apps/mobile/test/app/theme_contrast_test.dart`: `ink` and `inkMuted` on `background`, `surface` and `surfaceElevated`, and the label on `primaryAccent` and `secondaryAccent` fills. Squad Violet and Terracotta are the nearest AA-safe shades of the original `#7C5CFF` and `#D95338`; `inkMuted` of Memory Collectors (light) went from `#6E665E` to `#6A625A` for the same reason. An accent used alone, as an icon or an indicator bar, is not held to 3:1 (Flame Gold on cream cannot reach it), so such an accent always comes with a label or a shape.

## 4. Mandatory Rules for Engineers & AI Agents

1. **Always Support Dark & Light Theme**:
   - Never hardcode light-only or dark-only colors on any screen. Always read from `OurneyPersonaTheme.of(context)` which resolves automatically based on `Theme.of(context).brightness` and `activePersonaSkinProvider`.
2. **Never Reset the App When Switching Journeys**:
   - Switching a journey only updates `activeJourneyIdProvider`. Let `AnimatedTheme` and `AnimatedSwitcher` morph the UI smoothly in place.
3. **No Hardcoded Text Icons or Gibberish Labels**:
   - Use vector `CustomPaint`, SVG icons, or clean `CupertinoIcons`/`Icons` — never use raw text placeholders like `"3-tab"` or `"..."` in the bottom navigation bar.
   - The bottom navigation bar always has 3 destinations: **Journeys** (left), **Snap Shutter** (center hero button), and **Squad** (right).
4. **Always Verify Zero Lint Errors**:
   - Run `flutter analyze` across `packages/ourney_core` and `apps/mobile` after any UI or domain change.
