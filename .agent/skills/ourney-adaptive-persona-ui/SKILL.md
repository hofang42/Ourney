---
name: ourney-adaptive-persona-ui
description: Master UI/UX skill and architecture for Ourney's 6-Persona Adaptive UI System, Dark/Light theme synchronization, tactile buttons, mobile responsiveness across all phone sizes, anti-AI-slop rules, and zero-reset journey switching. Activate whenever creating, modifying, or reviewing any Flutter UI screen or widget in Ourney.
---

# Ourney Adaptive 6-Persona UI & Responsive Design Skill

Activate and follow this skill whenever creating, modifying, or reviewing any screen, widget, modal, timeline, camera HUD, or share card in `apps/mobile` or `packages/ourney_core`.

## 1. Visual Reference Boards (`apps/mobile/assets/design_personas/`)
Always inspect and match the exact visual language of the 6 reference boards:
1. **`PersonaSkinId.quietTransformer` (`TemplateId.weightLoss`)** -> `apps/mobile/assets/design_personas/persona_1_quiet_transformer.jpg`
   - **Camera (`ghostAlignVault`)**: Translucent Day 1 silhouette alignment guide, `Private Vault · Day X` pill, horizontal weight slider (`62.0 KG (-3.2 KG)`).
   - **Timeline (`connectedWeightCurve`)**: Smooth weight trend curve (`65.2 KG ➔ 62.0 KG`) connected into a vertical milestone photo spine (`DAY 01`, `DAY 07 ★`, `DAY 14 ★`, `DAY 21`).
   - **Archive (`sideBySideArchive`)**: Side-by-side `DAY 01 vs DAY 21` split comparison + `Hide Exact Weight: ON` toggle + `Export Progress Card` button.
2. **`PersonaSkinId.accountabilitySquad` (`TemplateId.englishDaily`)** -> `apps/mobile/assets/design_personas/persona_2_accountability_squad.jpg`
   - **Timeline (`steppingStoneQuest`)**: Vertical S-curve winding stepping-stone trail to the Day 30 Trophy with tilted study Polaroid nodes.
   - **Camera (`studyTimerSnap`)**: Top pill `45 MIN STUDY · 🔥 21 STREAK` + bottom timestamp badge `06:15 AM`.
   - **Squad (`squadPolaroidWall`)**: `4/5 CHECKED IN TODAY` progress bar, `2x2` Polaroid grid with reaction pills (`🔥 4`, `👏 3`), and a dashed waiting slot with a violet `Nudge 👋` button.
3. **`PersonaSkinId.memoryCollectors` (`TemplateId.travel`)** -> `apps/mobile/assets/design_personas/persona_3_memory_collectors.jpg`
   - **Timeline (`scrapbookThread`)**: Continuous terracotta stitched line connecting tilted Polaroids with masking-tape strips.
   - **Camera (`disposableFilmStamp`)**: `FILM ROLL 24/36` pill + amber retro date/temperature stamp (`16 OCT '26 · 15°C DA LAT`).
   - **Share (`filmContactSheet`)**: 35mm Kodak film contact sheet mosaic (20 frames on `#141312` film strip) + Olive Sage `Share Trip Poster` CTA.
4. **`PersonaSkinId.coupleRituals` (`TemplateId.couple`)** -> `apps/mobile/assets/design_personas/persona_4_couple_rituals.jpg`
   - **Timeline (`duoSplitTimeline`)**: Paired horizontal diptych cards (`His Photo` left + Heart/Flame node center + `Her Photo` right).
   - **Camera (`halfFrameDuo`)**: Split half-frame camera (Partner's completed photo on left, live camera viewfinder on right).
   - **Share (`coupleMosaicPoster`)**: `18 DAYS TOGETHER · 36 MOMENTS` woven diptych grid + Rose Coral CTA.
5. **`PersonaSkinId.aestheticFlexer` (`TemplateId.workout30`)** -> `apps/mobile/assets/design_personas/persona_5_aesthetic_flexers.jpg`
   - **Timeline (`athleticTelemetry`)**: Neon lime pace/distance sparkline (`92.4 KM TOTAL`) + glowing vertical run milestone spine.
   - **Camera/Studio (`stravaStickerStudio`)**: Full-bleed photo with bold Bricolage Grotesque transparent telemetry overlay and style switcher pills (`Bold HUD`, `Minimal Stamp`, `Film Strip`).
   - **Share (`transparentStorySticker`)**: 9:16 Story card with a 21-bar active streak heatmap + Electric Coral `Share to Instagram Story` CTA.
6. **`PersonaSkinId.minimalistHabit` (`TemplateId.custom`)** -> `apps/mobile/assets/design_personas/persona_6_minimalist_habit.jpg`
   - **Camera (`zeroText3Sec`)**: 1-tap Braun orange shutter circle, single top pill, zero text input friction.
   - **Timeline (`chainCalendarGrid`)**: 7-column monthly calendar grid where completed days are square photos linked by an unbroken orange chain line, and remaining days are dashed squares.
   - **Share (`zenSummaryCard`)**: Minimalist typographic summary card (`24/30 DAYS COMPLETED · 96% CONSISTENCY`).

## 2. Synchronized Theme, Button & Responsive Rules
- **Dark & Light Theme Always**: Read all colors/radii/borders from `OurneyPersonaTheme.of(context)` (`apps/mobile/lib/app/theme/persona_theme.dart`). Test every widget in both `Brightness.light` and `Brightness.dark`.
- **Unified 3-Tab Bottom Dock**: Every main screen uses the 3-tab dock (`Journeys` left, `Snap Shutter` center hero button, `Squad` right) with vector icons only (zero hardcoded text icons like `"3-tab"` or `"..."`).
- **Tactile Buttons**: Minimum `48x48dp` hit target, `52dp` primary CTA height, `0.96` scale press animation (`110ms`), and physical bottom border lip when `pTheme.bottomLipHeight > 0`.
- **Responsive Across All Mobile Sizes**:
  - Compact (`< 360dp`): `16dp` screen padding, flexible camera/grid ratios (never fixed widths).
  - Standard (`360–409dp`): `20dp` screen padding, `16dp` card padding, `12dp` grid gap.
  - Large / Pro Max (`410–599dp`): `24dp` screen padding, `480dp` max card width.
  - Foldable / Tablet (`>= 600dp`): `520dp` centered feed constraint or 2-pane split layout.
- **Zero-Reset Journey Switching**:
  - Never reset the app or restart the camera when switching journeys. Update `activePersonaSkinProvider` and let `AnimatedTheme` (`320ms`) + `AnimatedSwitcher` (`260ms`) morph the UI smoothly.
- **Verification**: Always run `flutter analyze` and `dart analyze` and verify 0 issues.
