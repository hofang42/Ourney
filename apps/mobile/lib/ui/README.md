# Ourney UI kit (V1.0 foundation, migrating to V2)

Built from `design/figma-v1/index.css` + `App.tsx`. Import `package:ourney/ui/ui.dart`.
Screens in `lib/features/**` must use only this folder for UI (never `lib/shared/` widgets).

Rules baked in: light + dark via `context.ui`, 48dp hit targets, Soft Neo-Brutalism sticker press (`translate(offset, offset)` over 110ms, zero scale-down; 0.96 press scale only on shadowless ghost controls),
Vietnamese line height 1.3-1.5 with ellipsis, gutters 16/20/24dp, max width 480/520dp.

## Foundation
| File | Contents |
| --- | --- |
| `journey_style_for.dart` | `uiStyleForSkin(PersonaSkinId)` -> `UiJourneyStyle` |
| `tokens.dart` | `OurneyUi` (ThemeExtension, `context.ui`: bg, surface, fill, ink, inkMuted, border, brand, success, warn, danger...), `UiRadius`, `UiSpace` (`gutter(width)`, `maxContent`), `UiSize`, `UiMotion` (durations + `reduced`/`of`/`fadeOf`), `UiCurves` (`easeOutStrong`, `easeInOutStrong`, `drawer`, `dockOvershoot`, `stampDecel`, `m3Decelerate`, `m3Accelerate`), `UiCamera` |
| `motion.dart` | `UiSprings` (`snappy`, `bouncy`, `gentle`, `forSkin`), `UiHaptics` (`selection`, `pressLight`, `reject`, `shutterMedium`, `stampImpact`, `success`, `warning`, `milestoneSuccess`), `UiHeroTags`, `UiHero` (reduce-motion safe), `UiPageTransition` + `buildUiPage` (`CustomTransitionPage`), `UiDirectionalSwitcher`, `UiStaggerItem`, `UiCountRoll`, `UiRefreshScaffold` |
| `typography.dart` | `UiText.h1/h2/eyebrow/muted/button/fieldLabel/body/display`, `UiFonts` |
| `theme.dart` | `OurneyTheme.build(brightness, [skin])` (also behind `buildAppTheme`); installs the `OurneyUi` extension |
| `journey_styles.dart` | `uiJourneyStyles` (10 styles: accent, paper, ink, onAccent) |
| `journey_icons.dart` | `uiJourneyGlyph(emoji, template)`, `uiTemplateGlyph(template)`: drawn OurneyIcon of a journey (no emoji in system UI) |

## CSS class -> Flutter widget
| CSS / TSX | Widget |
| --- | --- |
| `button:active` + `:focus-visible` | `UiPressable` |
| `.brand-primary`, `.primary-wide` | `UiButton` (primary; `accent`/`onAccent` for journey color) |
| `.secondary-wide` | `UiButton.secondary` |
| `.text-action`, `.auth-link` | `UiTextAction`, `UiButton.ghost` |
| `.icon-button`, `IconButton` | `UiIconButton` |
| `components/month_nav.dart` | `UiMonthHeader` (pinned month heading: heading + button + `expanded`, height `extentOf`), `UiJumpChips` (48dp month / year chips) for long timelines |
| `components/layout.dart` | `UiScaffold.slivers`: sliver page frame (gutter, max width, pinned headers stack inside one group) for lazily built lists |
| `.segments`, `.hub-segments` | `UiSegmented<T>` (`scrollable`), `UiSegment` (optional `key` per tab) |
| `.language-chip`, `.inbox-filters button` | `UiChip` |
| `.imported-badge`, `.add-more-label` | `UiTag` |
| `Privacy` | `UiPrivacyTag` + `UiPrivacy` |
| `.style-label`, `.new-dot` | `UiStyleLabel`, `UiNewDot` |
| `.eyebrow` | `UiEyebrow` |
| `.list-heading`, `.section-title` | `UiListHeading` |
| `.journey-row` | `UiRow` |
| `.shared-compact-list > button`, `.hub-all-done`, `.template-choice` | `UiCard` |
| `.hub-add-menu`, `.overflow-menu` | `UiMenuSurface`, `UiMenuItem`, floated by `UiMenuAnchor` (overlay, never reflows the page) |
| `.topbar` | `UiTopBar` |
| `.detail-nav` | `UiBackHeader` |
| `.avatar`, `Avatar` | `UiAvatar`; `.avatar-picker` -> `UiAvatarPicker` |
| `.dock` | `UiDock`, `UiDockItem`, `UiSnapPill` (`.camera-capsule`) |
| `.camera-dock`, `.shutter` | `UiDock(camera: true, center: UiShutter(...))`, `UiShutter` |
| Journey wheel (long-press the Snap button, 400ms) | `showUiJourneyWheel(context, items:, activeId:, onSelect:, anchor:)` (`UiJourneyWheel`, `UiJourneyWheelItem`): blurred dim backdrop + `UiTypeBadge`s fanned in an arc above `anchor`; tap selects and closes, backdrop / close button / back dismisses; never navigates. Reduce Motion: no animation; Reduce Transparency / high contrast: solid scrim, no blur. Wired in `AppDock` (shell and camera dock) |
| `.glass-chip` | `UiGlassChip` (camera journey / streak chips) |
| `.day-hud` | `UiDayHud` |
| `.camera-tools .icon-button`, `.camera-secondary-controls` | `UiCameraTool`, `UiLibraryThumb` |
| Camera state label (flash, errors; replaces the toast) | `UiCameraStatusPill` (32dp glass capsule inside the preview, 150ms in / 1.2s / 200ms out, live region) |
| `.page-dots` | `UiPageDots` |
| profile avatar entry in top bars | `UiProfileEntry` (no top bar uses it since the V2 dock has a Profile tab) |
| `.success-mark` | `UiSuccessMark` |
| `.stamp` | `UiStamp` |
| `.streak-celebrate`, `.shared-streak strong` | `UiStreakNumber` |
| `.polaroid` | `UiPolaroid` |
| `.field-label` + input | `UiTextField` (52dp, `UiRadius.field` 16, 1.5dp `ui.fieldBorder`, 2dp accent on focus, no shadow; `pill: true` for single-line searches), `UiTextArea`, `UiCaptionField` (label-less, growing caption) |
| `.otp-row` | `UiOtpField` (48x52 boxes, `UiRadius.otp` 10, same border and focus as fields) |
| `.switch-row` | `UiSwitchRow` |
| `.bottom-sheet`, `.modal-layer` | `UiSheet`, `showUiSheet` |
| `.permission-sheet` | `UiPermissionSheetContent`, `showUiPermissionSheet` |
| `.progress-track` | `UiProgressBar` |
| `.progress-ring` | `UiProgressRing` |
| `.all-done-illustration`, `.hub-all-done > span` | `UiCheckBadge` |
| empty states | `UiEmptyState` |
| inline errors | `UiInlineError` |
| `.toast` | `showUiToast` (clears the `UiScaffold` pinned bottom slot automatically; `bottomOffset` adds more) |
| `.ourney-wordmark` | `UiRansomWordmark` (≥96px), `UiCompactWordmark` (64–95px), `UiOSticker` (<64px) |
| `.splash-screen` | `UiSplash` (shown on first launch by `OurneyApp`) |
| screen frame (`.screen`, safe area, gutters) | `UiScaffold` |

## Screens built on the kit
Onboarding (`features/onboarding/onboarding_screen.dart`, `onboarding_art.dart`), Sign in
(`features/auth/auth_screen.dart`), Profile setup (`features/profile/profile_setup_screen.dart`),
Camera permission + Notification sheets (`features/onboarding/permission_sheets.dart`).
The reminders permission prompt also uses `showUiPermissionSheet`.

Journeys (`features/journeys/ui/`): Hub (`journeys_list_screen.dart`, `journey_row.dart`,
`today_card.dart`, `shelf_view.dart`, day-zero), Today sheet (`today_sheet.dart`,
`showTodaySheet`), template grid, quick setup, journey detail (hero, stats,
timeline with the Recent window and By month archive) and the day viewer. Journey-style screens use
`JourneyPalette.of(context, style)` (`journey_style.dart`).
Also rebuilt on the kit: Camera (`features/camera/capture_screen.dart`, dark chrome, hero shutter
in `AppDock(shutter: ...)`), Compose + Posted (`features/checkin`), Squad tab, Squad wall, invite and
join (`features/groups/ui`), Profile + edit (`features/profile`), Share card screen
(`features/share_card/ui`). The shell dock is `lib/app/app_dock.dart` (a `UiDock` wrapper with the
active journey accent); the camera screen draws its own camera-mode dock.

## V2 sticker language (design source `design/ourney-v2-app/`, Figma Make "Ourney V2")
PR 1 adds the foundation; screens migrate in later PRs.

| File | Contents |
| --- | --- |
| `tokens.dart` | Shell palette is now the V2 shell (`#FFF8EE` light, warm `#1B1916` dark, brand `#FF8A3D`). New `UiBorder` (2 / 1.5 / 1), `UiShadow.hard(color, offset)` (no blur), palette fields `outline`, `hardShadowColor`, `sheet`, `stickerBorder()`, `hardShadow()`. Light: outline = shadow = ink. Dark: mid-tone outline (3:1+), drop shadow darker than bg, `sheet` one step above bg |
| `skins.dart` | `uiSkins` (quiet, squad, memory, couple, flexer, minimal) x 3 variants x light/dark; `UiSkin.apply(OurneyUi, variantIndex:)` recolors the shell for a journey; `UiTypePastel` journey-type colors |
| `typography.dart` | `UiText.heading(font:, size:)` for per-skin heading fonts (Space Grotesk, Fraunces, Playfair Display, Barlow Condensed; Space Mono for labels), all OFL, bundled in `assets/fonts` |
| `components/pressable.dart` | `shadowOffset`: sticker press (translate by the offset, shadow disappears). Without it, the 0.96 scale press |
| `components/buttons.dart` | `UiButton` primary/secondary: 2dp outline + 4/3dp hard shadow |
| `components/glass.dart` | `UiGlass` liquid-glass surface: blur + saturation + tint + specular edge; opaque fallback for high contrast / `reduceTransparency`. `UiGlass.camera` for dark camera chrome |

Glass rules: blur 10-20dp, tint 15-30% over photos, clip tightly, keep text at 4.5:1, never one live blur per scrolling row.
Known gap: V2 disabled buttons use a dashed border; Flutter has no dashed `Border`, so a solid muted outline is used.

## V2 journey widgets
`components/journey_widgets.dart` (exported from `ui.dart`); all light + dark, tokens only, sticker cards.

| Widget | Contents |
| --- | --- |
| `UiTypeBadge(type:, size:)` | Pastel rounded sticker with the type icon. Ids `weight study trip couple workout custom`; `UiTypeBadge.idFor('Giảm cân')` maps the V2 labels |
| `UiStreakHero(streak:, title:, semanticLabel:, subtitle:, onTap:, state:)` | Hub hero: big Space Grotesk streak number (FittedBox, safe at 1.35x) + flame (trophy at `milestone`); states `normal done milestone group` |
| `UiJourneyCard(title:, type:, snapLabel:, dayLabel:, streakLabel:, day:, totalDays:, streak:, todayDone:, members:, onTap:, onSnap:)` | Type badge, `Ngày N/M` + streak chips, progress bar, 3 avatars + `+N`, 48dp snap button until done today |
| `UiStateCard(kind:, title:, body:, actionLabel:, onAction:)` | Kinds `empty offline error loading` (plus / cloud-off / warning icons, `UiSkeleton` for loading) |

New drawn icons in `ourney_icons.dart`: type-weight/study/trip/couple/workout/custom, flame, trophy, lock, check, warning, wifi-off, cloud-off, clock, timer, image, plus, back, close, settings, share, switch-camera, lightning, calendar, heart, star.
