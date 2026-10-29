# Ourney UI kit (V1.0)

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
| `theme.dart` | `OurneyTheme.build(brightness, [skin])` (also behind `buildAppTheme`); installs `OurneyUi`, legacy `OurneyColors`, `OurneyPersonaTheme` |
| `journey_styles.dart` | `uiJourneyStyles` (10 styles: accent, paper, ink, onAccent) |

## CSS class -> Flutter widget
| CSS / TSX | Widget |
| --- | --- |
| `button:active` + `:focus-visible` | `UiPressable` |
| `.brand-primary`, `.primary-wide` | `UiButton` (primary; `accent`/`onAccent` for journey color) |
| `.secondary-wide` | `UiButton.secondary` |
| `.text-action`, `.auth-link` | `UiTextAction`, `UiButton.ghost` |
| `.icon-button`, `IconButton` | `UiIconButton` |
| `.segments`, `.hub-segments` | `UiSegmented<T>` (`scrollable`), `UiSegment` |
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
| `.toast` | `showUiToast` |
| `.wordmark` | `UiWordmark` |
| `.splash-screen` | `UiSplash` (shown on first launch by `OurneyApp`) |
| screen frame (`.screen`, safe area, gutters) | `UiScaffold` |

## Screens built on the kit
Onboarding (`features/onboarding/onboarding_screen.dart`, `onboarding_art.dart`), Sign in
(`features/auth/auth_screen.dart`), Profile setup (`features/profile/profile_setup_screen.dart`),
Camera permission + Notification sheets (`features/onboarding/permission_sheets.dart`).
The reminders permission prompt also uses `showUiPermissionSheet`.

Also rebuilt on the kit: Camera (`features/camera/capture_screen.dart`, dark chrome, hero shutter
in `AppDock(shutter: ...)`), Compose + Posted (`features/checkin`), Squad tab, Squad wall, invite and
join (`features/groups/ui`), Profile + edit (`features/profile`), Share card screen
(`features/share_card/ui`). The shell dock is `lib/app/app_dock.dart` (a `UiDock` wrapper with the
active journey accent); the camera screen draws its own camera-mode dock.
