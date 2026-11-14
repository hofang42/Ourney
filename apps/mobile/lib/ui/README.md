# Ourney UI kit (V1.0 foundation, migrating to V2)

Built from `design/figma-v1/index.css` + `App.tsx`. Import `package:ourney/ui/ui.dart`.
Screens in `lib/features/**` must use only this folder for UI (never `lib/shared/` widgets).

Rules baked in: light + dark via `context.ui`, 48dp hit targets, 0.96 press scale (110ms),
Vietnamese line height 1.3-1.5 with ellipsis, gutters 16/20/24dp, max width 480/520dp.

## Foundation
| File | Contents |
| --- | --- |
| `journey_style_for.dart` | `uiStyleForSkin(PersonaSkinId)` -> `UiJourneyStyle` |
| `tokens.dart` | `OurneyUi` (ThemeExtension, `context.ui`: bg, surface, fill, ink, inkMuted, border, brand, success, warn, danger...), `UiRadius`, `UiSpace` (`gutter(width)`, `maxContent`), `UiSize`, `UiMotion`, `UiCamera` |
| `typography.dart` | `UiText.h1/h2/eyebrow/muted/button/fieldLabel/wordmark/body/display`, `UiFonts` |
| `theme.dart` | `OurneyTheme.build(brightness, [skin])` (also behind `buildAppTheme`); installs the `OurneyUi` extension |
| `journey_styles.dart` | `uiJourneyStyles` (10 styles: accent, paper, ink, onAccent) |
| `journey_icons.dart` | `uiJourneyIcon(emoji, template)`, `uiTemplateIcon(template)`: vector icon of a journey (no emoji in system UI) |

## CSS class -> Flutter widget
| CSS / TSX | Widget |
| --- | --- |
| `button:active` + `:focus-visible` | `UiPressable` |
| `.brand-primary`, `.primary-wide` | `UiButton` (primary; `accent`/`onAccent` for journey color) |
| `.secondary-wide` | `UiButton.secondary` |
| `.text-action`, `.auth-link` | `UiTextAction`, `UiButton.ghost` |
| `.icon-button`, `IconButton` | `UiIconButton` |
| `.segments`, `.hub-segments` | `UiSegmented<T>` (`scrollable`), `UiSegment` (optional `key` per tab) |
| `.language-chip`, `.inbox-filters button` | `UiChip` |
| `.imported-badge`, `.add-more-label` | `UiTag` |
| `Privacy` | `UiPrivacyTag` + `UiPrivacy` |
| `.style-label`, `.new-dot` | `UiStyleLabel`, `UiNewDot` |
| `.eyebrow` | `UiEyebrow` |
| `.list-heading`, `.section-title` | `UiListHeading` |
| `.journey-row` | `UiRow` |
| `.shared-compact-list > button`, `.hub-all-done`, `.template-choice` | `UiCard` |
| `.hub-add-menu`, `.overflow-menu` | `UiMenuSurface`, `UiMenuItem` |
| `.topbar` | `UiTopBar` |
| `.detail-nav` | `UiBackHeader` |
| `.avatar`, `Avatar` | `UiAvatar`; `.avatar-picker` -> `UiAvatarPicker` |
| `.dock` | `UiDock`, `UiDockItem`, `UiSnapPill` (`.camera-capsule`) |
| `.camera-dock`, `.shutter` | `UiDock(camera: true, center: UiShutter(...))`, `UiShutter` |
| `.glass-chip` | `UiGlassChip` (camera journey / streak chips) |
| `.day-hud` | `UiDayHud` |
| `.camera-tools .icon-button`, `.camera-secondary-controls` | `UiCameraTool`, `UiLibraryThumb` |
| `.page-dots` | `UiPageDots` |
| profile avatar entry in top bars | `UiProfileEntry` (feature wrapper: `ProfileEntryButton`, key `profile-entry`) |
| `.success-mark` | `UiSuccessMark` |
| `.stamp` | `UiStamp` |
| `.streak-celebrate`, `.shared-streak strong` | `UiStreakNumber` |
| `.polaroid` | `UiPolaroid` |
| `.field-label` + input | `UiTextField` |
| `.otp-row` | `UiOtpField` |
| `.switch-row` | `UiSwitchRow` |
| `.bottom-sheet`, `.modal-layer` | `UiSheet`, `showUiSheet` |
| `.permission-sheet` | `UiPermissionSheetContent`, `showUiPermissionSheet` |
| `.progress-track` | `UiProgressBar` |
| `.progress-ring` | `UiProgressRing` |
| `.all-done-illustration`, `.hub-all-done > span` | `UiCheckBadge` |
| empty states | `UiEmptyState` |
| inline errors | `UiInlineError` |
| `.toast` | `showUiToast` (`bottomOffset` lifts it above a pinned button) |
| `.wordmark` | `UiWordmark` |
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
`journey_chain.dart` calendar) and the day viewer. Journey-style screens use
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
| `tokens.dart` | Shell palette is now the V2 shell (`#FFF8EE`/`#121212`, brand `#FF8A3D`). New `UiBorder` (2 / 1.5 / 1), `UiShadow.hard(color, offset)` (no blur), `ctx.ui.outline`, `stickerBorder()`, `hardShadow()` |
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
| `UiStreakHero(streak:, title:, subtitle:, onTap:, state:)` | Hub hero: big Space Grotesk streak number (FittedBox, safe at 1.35x) + flame (trophy at `milestone`); states `normal done milestone group` |
| `UiJourneyCard(title:, type:, day:, totalDays:, streak:, todayDone:, members:, onTap:, onSnap:)` | Type badge, `Ngày N/M` + streak chips, progress bar, 3 avatars + `+N`, 48dp snap button until done today |
| `UiStateCard(kind:, title:, body:, actionLabel:, onAction:)` | Kinds `empty offline error loading` (plus / cloud-off / warning icons, `UiSkeleton` for loading) |

New drawn icons in `ourney_icons.dart`: type-weight/study/trip/couple/workout/custom, flame, trophy, lock, check, warning, wifi-off, cloud-off, clock, timer, image, plus, back, close, settings, share, switch-camera, lightning, calendar, heart, star.
