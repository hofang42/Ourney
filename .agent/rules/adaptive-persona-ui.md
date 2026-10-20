---
trigger: always_on
description: Comprehensive UI/UX Design System, Dark/Light Theme Synchronization, Button & Component Standards, Mobile Responsive Rules, Anti-AI-Slop Policy, and 6-Persona Adaptive UI Rules for Ourney.
---

# Ourney — Master UI/UX & Design Synchronization Rules

Every AI agent, Claude session, or developer creating or modifying any screen, widget, modal, or share card in `apps/mobile` MUST strictly follow these rules to keep all screens 100% synchronized.

---

## 1. Mandatory Quality Gates & Anti-AI-Slop Policy

1. **Zero Lint Errors Mandatory**:
   - Always run `dart analyze` (in `packages/ourney_core`) and `flutter analyze` (in `apps/mobile`) after creating or modifying any Dart/Flutter file. Zero errors or warnings are tolerated.
2. **Strict Anti-AI-Slop Rules**:
   - **NO Hardcoded Text Icons**: Never use text strings like `"..."`, `"3-tab"`, `"icon"`, `"[+]"`, or ASCII art as system navigation or action icons. Always use vector `Icons`, `CupertinoIcons`, or custom `CustomPainter` / SVG paths.
   - **Emoji Discipline**: Never use emojis in place of system navigation icons (e.g., bottom dock, back button, settings, camera controls). Emojis are strictly reserved for user-facing Journey badges (`⚖️`, `📚`, `✈️`, `💞`, `💪`, `✨`), streak flames (`🔥`), and friend reactions (`👏`, `💪`).
   - **No Generic Rainbow Gradients or Random Shadows**: Only use the exact surface, border, and accent tokens from `OurneyPersonaTheme.of(context)`.
   - **No Unbounded Text Overflow**: Every dynamic user text (`title`, `caption`, `displayName`, `metricValue`) must handle long strings gracefully with `maxLines`, `TextOverflow.ellipsis`, or `Flexible`/`Expanded` so Vietnamese diacritics (`ệ`, `ữ`, `ấ`, `ẫ`) never clip vertically or overflow horizontally.

---

## 2. Synchronized Dark & Light Theme System (`OurneyPersonaTheme`)

Every screen and custom widget MUST support both **Light Mode (`Brightness.light`)** and **Dark Mode (`Brightness.dark`)** automatically:

1. **Never Hardcode Static Colors**:
   - Forbidden: `Colors.white`, `Colors.black`, `Color(0xFFF6F2EA)` directly inside screen widgets (except inside `OurneyPersonaTheme` token definitions or over dark media scrims).
   - Required: Always read `final pTheme = OurneyPersonaTheme.of(context);` and use:
     - `pTheme.background` -> `Scaffold` background
     - `pTheme.surface` -> Primary cards, sheets, bottom dock
     - `pTheme.surfaceElevated` -> Secondary pills, input backgrounds, inactive slots
     - `pTheme.ink` -> Primary headings and body text
     - `pTheme.inkMuted` -> Subtitles, timestamps, helper text
     - `pTheme.primaryAccent` -> Primary CTA, active nodes, shutter accent
     - `pTheme.secondaryAccent` -> Group/Squad actions, secondary badges
     - `pTheme.border` -> Card/divider borders (`width: pTheme.borderWidth`)
2. **Camera & Media Surfaces Exception**:
   - Live Camera viewfinders, full-bleed photo viewers, and 35mm film contact sheets always use dark media surfaces (`#0B0C0E`–`#141312`) with translucent glass overlays (`BackdropFilter` blur `16` + `Colors.black.withValues(alpha: 0.55)`) so photography pops in both Light and Dark mode.

---

## 3. Unified Navigation, Button & Component Standards

To keep all 6 persona styles feeling like **one cohesive Ourney app**, all screens share the same structural skeletons and interaction physics:

### 3.1. The 3-Tab Bottom Navigation Dock
- Every primary screen uses the exact same 3-destination bottom dock (`height: 68pt` + bottom safe area inset):
  1. **Left Tab (`Journeys`)**: Map/Timeline icon (`CupertinoIcons.map` / `Icons.map_outlined`) + label.
  2. **Center Hero Button (`Snap Shutter`)**:
     - On **Hub / Timeline / Squad screens**: Pill/Circle quick-camera trigger (`56x40pt` or `52x52pt`) colored with `pTheme.primaryAccent`.
     - On **Camera Screen**: Full `76x76pt` Hero Shutter Button with outer ring (`3pt`) and tactile inner core (`scale: 0.94` on press + `HapticFeedback.mediumImpact()`).
  3. **Right Tab (`Squad`)**: Group icon (`CupertinoIcons.person_2` / `Icons.people_outline`) + label.

### 3.2. Synchronized Button Hierarchy & Tactile Physics
- **Minimum Touch Target**: Every interactive button, icon button, reaction pill, or calendar day cell MUST have a minimum hit area of **`48x48dp`** (`>= 44pt` iOS HIG).
- **Primary Button (`OurneyPrimaryButton`)**:
  - Height: `52dp` (standard) or `44dp` (compact card action).
  - Radius: Capsule (`999px`) or `16dp` rounded rect matching `pTheme.cardRadius`.
  - Tactile Lip: If `pTheme.bottomLipHeight > 0` (e.g., `accountabilitySquad` has a `3dp` bottom lip), render the physical bottom border lip and translate `Y +2dp` when pressed.
  - Press Feedback: `AnimatedScale(scale: isPressed ? 0.96 : 1.0, duration: 110ms, curve: Curves.easeOut)` + `HapticFeedback.lightImpact()`.
- **Secondary / Ghost Pill Button**:
  - Background: `pTheme.surfaceElevated`, border: `1dp` `pTheme.border`, text: `pTheme.ink`.

---

## 4. Mobile Responsive Rules Across Device Sizes

Every screen must render cleanly without overflow across **4 device classes** and **Dynamic Type (`textScaler` up to `1.35x`)**:

1. **Compact Phones (`width < 360dp`, e.g., iPhone SE / mini, small Android)**:
   - Horizontal screen padding: `16dp` (reduced from `20dp`).
   - Camera viewfinder: Constrained by `Flexible` + `AspectRatio(1.0)` or `LayoutBuilder` so it never pushes the `76pt` shutter button off-screen.
   - Side-by-side comparison cards (`DAY 01 vs DAY 21`) and `2x2` Squad Polaroid grids must use `Expanded` / `GridView` with `childAspectRatio` calculated from `constraints.maxWidth`—never fixed pixel widths like `width: 180`.
2. **Standard Phones (`360dp <= width < 410dp`, e.g., iPhone 15/16, Galaxy S24)**:
   - Horizontal screen padding: `20dp`.
   - Card internal padding: `16dp`, grid gap: `12dp`.
3. **Large / Pro Max Phones (`410dp <= width < 600dp`, e.g., iPhone 16 Pro Max, S24 Ultra)**:
   - Horizontal screen padding: `24dp`.
   - Timeline cards cap max content width at `480dp` centered so single-column photos don't stretch excessively tall.
4. **Foldables & Tablets (`width >= 600dp`, e.g., Galaxy Z Fold unfolded, iPad)**:
   - Center primary mobile feeds inside a `ConstrainedBox(constraints: BoxConstraints(maxWidth: 520))` or switch to a 2-pane split layout (Left: Journey Timeline, Right: Day Detail / Share Card Preview).
5. **Safe Area & Keyboard Insets**:
   - Always respect `MediaQuery.paddingOf(context)` (Dynamic Island / notch at top, home indicator bar at bottom) and `MediaQuery.viewInsetsOf(context).bottom` when typing captions or metrics.

---

## 5. The 6 Persona UI Styles (Backed by `assets/design_personas/`)

Each Journey's `TemplateId` maps 1-to-1 to a `PersonaSkinId`. When building or updating any of the 6 persona layouts, match its visual reference asset in `apps/mobile/assets/design_personas/`:

### Persona 1: `PersonaSkinId.quietTransformer` (`TemplateId.weightLoss`)
- **Reference Image**: `apps/mobile/assets/design_personas/persona_1_quiet_transformer.jpg`
- **Palette**:
  - Light: Bg `#EFF3F0`, Surface `#FFFFFF`, Ink `#0F172A`, Primary `#10B981` (Emerald), Secondary `#FF4D6D`
  - Dark: Bg `#0B0F12`, Surface `#151C21`, Ink `#F1F5F9`, Primary `#10B981`, Secondary `#FF6B88`
- **Signature Screens**:
  1. **Camera (`ghostAlignVault`)**: Translucent Day 1 silhouette alignment overlay (`30%` opacity toggle), top `Private Vault · Day X` pill, bottom horizontal weight slider (`62.0 KG (-3.2 KG)`).
  2. **Timeline (`connectedWeightCurve`)**: Top smooth weight trend curve (`65.2 KG ➔ 62.0 KG`) connected directly into a vertical photo milestone spine (`DAY 01`, `DAY 07 ★`, `DAY 14 ★`, `DAY 21 · TODAY`).
  3. **Archive / Share (`sideBySideArchive`)**: Side-by-side `DAY 01` vs `DAY 21` split comparison frame + `SwitchListTile` for **`Hide Exact Weight: ON (-3.2 KG Transformation)`** + `Export Progress Card` CTA.

### Persona 2: `PersonaSkinId.accountabilitySquad` (`TemplateId.englishDaily`)
- **Reference Image**: `apps/mobile/assets/design_personas/persona_2_accountability_squad.jpg`
- **Palette**:
  - Light: Bg `#F7F1E5`, Surface `#FFFDF9`, Ink `#1E1B18`, Primary `#FF9F1C` (Flame Orange), Secondary `#7556F8` (Squad Violet), `2dp` ink border + `3dp` bottom lip.
  - Dark: Bg `#12131A`, Surface `#1D1F2B`, Ink `#F8FAFC`, Primary `#FFB547`, Secondary `#9D85FF`.
- **Signature Screens**:
  1. **Timeline (`steppingStoneQuest`)**: Vertical S-curve winding stepping-stone trail leading up to the `DAY 30 GOAL` trophy, with tilted Polaroid study checkpoints along the path.
  2. **Camera (`studyTimerSnap`)**: Top tactile pill `45 MIN STUDY · 🔥 21 STREAK`, bottom timestamp pill `06:15 AM`.
  3. **Squad / Share (`squadPolaroidWall`)**: Top progress bar `4/5 CHECKED IN TODAY`, `2x2` Polaroid grid of member check-ins with emoji reaction counters (`🔥 4`, `👏 3`), and a dashed waiting card (`MINH · WAITING`) with a violet `Nudge Minh 👋` button.

### Persona 3: `PersonaSkinId.memoryCollectors` (`TemplateId.travel`)
- **Reference Image**: `apps/mobile/assets/design_personas/persona_3_memory_collectors.jpg`
- **Palette**:
  - Light: Bg `#F4EFE6`, Surface `#FFFFFF`, Ink `#231F1E`, Primary `#CC4A2F` (Terracotta), Secondary `#4A6B53` (Olive Sage).
  - Dark: Bg `#141312`, Surface `#1F1D1B`, Ink `#F5F2EB`, Primary `#E05A47`, Secondary `#658B6E`.
- **Signature Screens**:
  1. **Timeline (`scrapbookThread`)**: Continuous terracotta red stitched thread running vertically down the page, connecting tilted Polaroid photo cards with masking-tape strips at top (`DAY 01 · PINE FOREST`, `DAY 02 · CLOUD HUNTING`, `DAY 03 · CAMPFIRE`).
  2. **Camera (`disposableFilmStamp`)**: Top pill `FILM ROLL 24/36`, analog viewfinder with amber monospace date/location stamp (`16 OCT '26 · 15°C DA LAT`).
  3. **Share (`filmContactSheet`)**: 35mm Kodak film contact sheet mosaic (4x5 or 5x4 grid of trip photos on `#141312` film strip with frame numbers) + Olive Sage `Share Trip Poster` button.

### Persona 4: `PersonaSkinId.coupleRituals` (`TemplateId.couple`)
- **Reference Image**: `apps/mobile/assets/design_personas/persona_4_couple_rituals.jpg`
- **Palette**:
  - Light: Bg `#F9F0EE`, Surface `#FFFFFF`, Ink `#261F22`, Primary `#E15B72` (Rose Coral), Secondary `#9D174D`.
  - Dark: Bg `#171215`, Surface `#241C21`, Ink `#FCE7F3`, Primary `#F472B6`, Secondary `#E15B72`.
- **Signature Screens**:
  1. **Timeline (`duoSplitTimeline`)**: Vertical timeline where each day is a paired horizontal diptych card: **Left = Partner A's photo**, **Center = Heart/Flame milestone node**, **Right = Partner B's photo**.
  2. **Camera (`halfFrameDuo`)**: Split half-frame camera where the left half displays the partner's already-snapped photo (`HIS PHOTO · 07:30 AM`) and the right half is the live camera viewfinder (`Snap Her Half · Complete Pair`).
  3. **Share (`coupleMosaicPoster`)**: `18 DAYS TOGETHER · 36 MOMENTS` woven grid poster + Rose Coral `Share Our Story` button.

### Persona 5: `PersonaSkinId.aestheticFlexer` (`TemplateId.workout30`)
- **Reference Image**: `apps/mobile/assets/design_personas/persona_5_aesthetic_flexers.jpg`
- **Palette**:
  - Dark (Default): Bg `#090A0F`, Surface `#14161F`, Ink `#F8FAFC`, Primary `#FF4D6D` (Electric Coral), Secondary `#3DE88C` (Neon Lime).
  - Light: Bg `#F3F4F6`, Surface `#FFFFFF`, Ink `#090A0F`, Primary `#FF4D6D`, Secondary `#10B981`.
- **Signature Screens**:
  1. **Timeline (`athleticTelemetry`)**: Top neon green pace/distance sparkline card (`92.4 KM TOTAL · 5:04 AVG PACE`) + vertical glowing green spine connecting daily workout photo cards (`DAY 01`, `DAY 07 ★`, `DAY 14 ★`, `DAY 21 · 5.42 KM`).
  2. **Camera / Studio (`stravaStickerStudio`)**: Full-bleed workout photo with bold Bricolage Grotesque transparent telemetry overlay (`DAY 21 · 🔥 21 STREAK · 5.42 KM · 5:04 /KM`) and style selector pills (`Bold HUD`, `Minimal Stamp`, `Film Strip`).
  3. **Share (`transparentStorySticker`)**: 9:16 Story export preview with a 21-bar active streak heatmap at bottom (`21 DAYS ACTIVE`) + Electric Coral `Share to Instagram Story` button.

### Persona 6: `PersonaSkinId.minimalistHabit` (`TemplateId.custom`)
- **Reference Image**: `apps/mobile/assets/design_personas/persona_6_minimalist_habit.jpg`
- **Palette**:
  - Light: Bg `#F5F3EE`, Surface `#FFFFFF`, Ink `#1C1C1E`, Primary `#EA580C` (Braun Coral-Orange), Secondary `#27272A`.
  - Dark: Bg `#0E0E10`, Surface `#18181B`, Ink `#F4F4F5`, Primary `#F97316`, Secondary `#E4E4E7`.
- **Signature Screens**:
  1. **Camera (`zeroText3Sec`)**: Clean viewfinder with a single top pill (`DAILY READING · DAY 24`), zero text input fields, and a single Braun-orange shutter circle at bottom for a 3-second check-in.
  2. **Timeline (`chainCalendarGrid`)**: 7-column monthly calendar grid (`OCTOBER · 24 DAY STREAK`) where completed days are square photo thumbnails linked horizontally by a continuous orange chain line, and future/missed days are clean dashed squares (`01..30`).
  3. **Share (`zenSummaryCard`)**: Minimalist typographic poster (`24 / 30 DAYS COMPLETED · 96% CONSISTENCY`) with one featured square photo + matte charcoal `Export Minimal Card` button.

---

## 6. Seamless Multi-Journey Switching & Hub / Create Screen Rules

1. **Zero App Reset on Journey Switch**:
   - Switching from Journey A to Journey B only updates `activePersonaSkinProvider` (via `activeJourneyIdProvider`).
   - `MaterialApp.router` uses `themeAnimationDuration: Duration(milliseconds: 320)` and `OurneyPersonaTheme.lerp()` to smoothly morph all colors, borders, and radii in place.
   - Screen body variants (`TimelineLayoutVariant`, `CameraHudVariant`, `ShareCardVariant`) transition via `AnimatedSwitcher(duration: Duration(milliseconds: 260))` without unmounting the shell or restarting the camera sensor.
2. **Global Hub (`JourneysScreen`) UI**:
   - Uses the neutral **Ourney Editorial Base** (`OurneyPersonaTheme.editorialNeutralBase(brightness)`), while each individual `JourneyCard` in the list renders with its own template's accent color and badge.
3. **Create Journey (`CreateJourneyScreen`) UI**:
   - Uses **Live Chameleon Preview**: tapping any of the 6 template cards immediately calls `ref.read(activePersonaSkinProvider.notifier).selectTemplate(template.id)` so the user sees the screen morph live into that persona's exact theme and preview board (`template.designAssetPath`).
