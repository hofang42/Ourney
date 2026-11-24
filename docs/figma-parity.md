# Figma V2 parity audit (Flutter vs `design/ourney-v2-app`)

Audit date: 2026-11-15, branch `ui/v2-13-flow-screens`. Read-only audit; no `lib/` or `test/` file was touched.

**Sources.** Figma: `design/ourney-v2-app/src/app/{routes.tsx, create.tsx, flow.tsx, overlay.tsx, brand.tsx, icons.tsx, store.tsx, app.css}`. Flutter: `apps/mobile/lib/{app,features,ui}`.

**How to read the statuses.**

| Status | Meaning |
|---|---|
| MATCH | Details actually compared (structure, copy, tokens, states) and equal. Used sparingly. |
| PARTIAL | A Flutter counterpart exists and is on the V2 shell, but concrete differences are listed. "(shallow)" = structure and key strings compared, pixel/spacing/animation not diffed, so there are probably more differences than listed. |
| MISSING | No Flutter counterpart. |
| V1-STALE | Counterpart still follows the old V1.0 design (doc comments say `V1.0 Detail`, `QuickSetup`, `Hub`). |
| IN PROGRESS (agent) | Being ported right now by another agent; not audited. |
| N/A | Prototype-only chrome in Figma Make (reviewer panel, scenario gallery, style guide, phone frame). |

**Honest summary.** The shared UI kit (`lib/ui/components`: buttons, chips, sheets, dock, wheel, cards, skeleton, state card, icons, fonts) is a faithful port. Many screens carry the kit, but the screens are built around the V1/backend feature set, not the Figma flow. The biggest divergences: (a) the per-skin journey screens (Home / Post / Done / Squad / Share x 6 skins) collapse into one generic screen per role, (b) share cards have no skin variants, (c) whole Figma features do not exist (Settings screen, Edit journey + "Giao diện" layout switch, Wrapped story, Import past journey, MissedDay overlay, in-app reminder banner, NotFound), (d) the create flow keeps the V1 name/emoji/metric form in place of Figma's per-type "DNA" question cards.

---

## 1. Figma inventory (every screen / sheet / overlay)

Routes (`routes.tsx` lines 9801-9843): `/style-guide`, `/camera`, `/hub`, `/squad`, `/activity`, `/join/:code`, `/me`, `/settings`, `/settings/terms|privacy|contact`, `/settings/delete/:step`, `/splash`, `/onboarding/:step`, `/login`, `/otp`, `/profile-setup`, `/create/1`, `/create/2/:question`, `/create/3`, `/create/3/extra/1|2`, `/create/4`, `/create/5`, `/import`, `/j/:id` (+ `/camera /post /done /squad /share /day/:day /edit /import /wrapped`), `*` NotFound. `JourneyAttachment` (routes.tsx:9668) routes to the 6 skin screens by `journey.skin`.

Shared components in `app.css` (class families): `app-dock`/`shell-dock`/`dock-pill`/`dock-tab` (+ one `*-dock` per skin), `screen-header`/`pushed-header`/`scenario-header`/`simple-flow-header`, `app-sheet`/`journey-action-sheet`/`quiet-sheet`/`create-sheet`/`permission-sheet`/`invite-sheet`/`squad-share-sheet`/`poster-share-sheet`/`memory-contact-sheet`, `hub-*-skeleton`/`skeleton-<skin>`, `*-offline-banner`, `*-toast`/`system-toast`, `*-share-tabs`/`*-share-card` x6, `step-segments`, `corner-check-badge`, `dna-journey-card`/`dna-progress`, `*-attendance-chip`, `privacy-chip`/`private-chip`/`pending-chip`, `avatar-picker`, `system-switch`, `theme-segmented`, `app-icon-picker`.

---

## 2. Parity matrix

### 2.1 Entry / auth flow (flow.tsx)

| Figma | Flutter | Status |
|---|---|---|
| `SplashFlow` `/splash` (V2 wordmark + sticker field + loading) | `app/app.dart` `_SplashGate` shows the V1.0 coral splash; `UiSplash` kit widget | IN PROGRESS (agent). Note: currently V1-STALE, which is what the user saw. |
| `OnboardingFlow` `/onboarding/:step` (+ quiz) | `features/onboarding/onboarding_screen.dart`, `onboarding_quiz.dart`, `onboarding_art.dart` | IN PROGRESS (agent) |
| `LoginFlow` `/login` | `features/auth/auth_screen.dart` | IN PROGRESS (agent) |
| `OtpFlow` `/otp` | `features/auth/auth_screen.dart` (OTP stage) | IN PROGRESS (agent) |
| `ProfileSetupFlow` `/profile-setup` | `features/profile/profile_setup_screen.dart` | IN PROGRESS (agent) |
| `PermissionSheet` (camera/notification pre-prompt) | `features/onboarding/permission_sheets.dart`, `ui/components/sheets.dart` `UiPermissionSheetContent` | IN PROGRESS (agent) |
| `ErrorMessage`, `OfflineBanner` (flow.tsx) | `UiInlineError`, `UiBanner(offline)` | PARTIAL (shallow): kit exists, usage inside the flow screens belongs to the agents |

### 2.2 App shell and global overlays (routes.tsx `Root`)

| Figma | Flutter | Status / differences |
|---|---|---|
| `FloatingDock` (5 tabs, centre snap pill, long-press wheel, per-skin `*-dock`, camera dark dock) | `app/app_dock.dart`, `ui/components/dock.dart`, `journey_wheel.dart` | PARTIAL: 5 tabs, accent pill, wheel and camera dock are present. Per-skin dock chrome (quiet/squad/memory/couple/flexer/minimal CSS variants, selection capsule, readonly dock) not verified; wheel/dock labels not diffed. |
| `Root` theme variables (`--bg/--surface/--ink/--muted`, skin variables, `largeType`/`reduceMotion`/`reduceTransparency` classes) | `ui/skins.dart`, `ui/components/skin_scope.dart`, `app/theme/*`; `MediaQuery` accessibility flags | PARTIAL: `themeMode` is hard-wired to `ThemeMode.system` (`app/app.dart:39`); no in-app light/dark/system preference (see Settings). |
| `ReminderNotification` (in-app banner, 6 skin tones) | none (OS local notifications only, `features/reminders`) | MISSING |
| `MissedDayOverlay` ("NGÀY 9 - NGHỈ/LỠ" chip + action sheet "ngày nghỉ./ngày lỡ.") | none (the month grid (`widgets/timeline_archive.dart`) and `today_card.dart` render a missed state only) | MISSING |
| "Chụp thêm ảnh hôm nay" floating retake hero (`today-retake-hero`) | none on journey home (`checkin_screen` supports extra photos) | MISSING |
| `system-toast` (global toast) | ad-hoc SnackBars per screen | PARTIAL (shallow) |
| `CreateSheet` (the "+" sheet) | `journeys_list_screen.dart` `_menuOpen` add menu | PARTIAL (shallow): menu instead of Figma's drag-to-close create sheet |
| `InviteSheet` | `groups/ui/invite_sheet.dart`, `invite_screen.dart` | PARTIAL (shallow) |
| `CameraJourneyPicker` (search, pinned / not yet today / done today sections, ended toggle, "thay hành trình đã ghim") | `camera/journey_picker_sheet.dart` | PARTIAL: search + sections + pin added in commit d507bfa; ended toggle and "replace pinned" sheet not verified. |
| `JourneyActionSheet` (drag handle, scrim, destructive/primary/secondary buttons) | `showUiSheet`, `showUiConfirmSheet`, `journeys/ui/journey_actions.dart` | PARTIAL (shallow): kit sheet equals the pattern; each Figma sheet's copy not compared. |
| `MemberSheet` (member -> report -> block -> done, 4 views in one sheet) | `safety/ui/report_screens.dart`, `block_dialogs.dart` (separate routes/dialogs) | PARTIAL: flow split across routes; no member bottom sheet with `@handle.ourney`. |
| `NotFound` (`*`) | none (`GoRouter` has no `errorBuilder`) | MISSING |
| `ReviewerPanel`, `SkinProof`, `PhoneOverlay`, `StyleGuide`, `JourneyScenarioScreen`, `AdaptiveJourneyScreen`, `AdaptiveJourneyVisual` | n/a | N/A (prototype tooling) |

### 2.3 Hub / Squad / Activity / Profile / Settings

| Figma | Flutter | Status / differences |
|---|---|---|
| `HubScreen` `/hub` ("hành trình." header, "chào {name}.", offline banner, `hub-create-progress` resume card, hero, section heading "N đang chạy", `JourneyCard` list, `new-journey-card`, loading `HubSkeleton`, error/empty `HubStateCard`) | `journeys/ui/journeys_list_screen.dart` | PARTIAL: Flutter uses time-of-day greeting ("Chào buổi tối, Linh"), `TodayCard`, Active/Shelf/Shared segments (V1 Hub), no resume-create card, no offline banner on Hub, loading is `UiStateCard(loading)` not skeletons, empty state is `DayZero` text + button without the camera sticker card or "một tấm mỗi ngày…" line. |
| `HubHero` states default/done/milestone/group (timer 03:12:40, cat/flag stickers, avatars) | `UiStreakHero` in `ui/components/journey_widgets.dart` | PARTIAL: kit widget has the 4 states; Hub still leads with V1 `TodayCard`. Timer / waiting avatars not verified. |
| `JourneyCard` (dna card, pin, pending-sync chip, menu) | `journeys/ui/journey_row.dart`, `UiJourneyCard` | PARTIAL (shallow) |
| `SquadScreen` `/squad` (locked sign-in state, offline, join-inline code field, "hôm nay" strip, skeleton, empty "chưa có hội nào.", pending invites "lời mời đang chờ") | `groups/ui/groups_list_screen.dart` | PARTIAL: actions + cards present; no today strip, pending-invites block, skeletons; locked state is "needs server" copy. |
| `JoinScreen` `/join/:code` (8 boxes, ticket preview, keyboard, 5 error strings) | `groups/ui/join_screen.dart` | PARTIAL: code boxes + preview ticket present (doc cites Figma); custom on-screen keyboard and exact error copy not compared. |
| `ActivityScreen` `/activity` ("hoạt động.", Hôm nay / Tuần này, invite rows, skin badge, nudge rows, empty/offline/skeleton) | `social/ui/inbox_screen.dart` | PARTIAL: groups feed, skeleton and sections exist; data model is friend requests/consents/shares/chats, Figma rows (Minh vừa điểm danh, An vừa thêm 2 ảnh, nhắc giờ, mốc) are not generated. Copy not diffed. |
| `ProfileScreen` `/me` ("hồ sơ.", identity, 3 stats, badges, shelf "kệ hành trình đã xong.") + edit sheet ("sửa hồ sơ.", avatar colours, username rules) | `profile/profile_screen.dart`, `profile_stats_section.dart`, `profile_edit_screen.dart`, `avatar_picker.dart` | PARTIAL: stats + 4 badges ported. Shelf lives in Hub segment, not Profile; edit is a route not a sheet; avatar picker not diffed. |
| `SettingsScreen` `/settings` (account, reminders per journey + streak alert + denied-state hint, "giao diện" Sáng/Tối/Theo máy, app-icon picker x7, privacy switches + blocked list, "thông tin" links, version) | split: `reminders/ui/reminders_screen.dart`, `profile_screen.dart` links, `safety/ui/safety_hub_screen.dart` + `blocked_users_screen.dart` | MISSING as a screen. Theme picker MISSING, app-icon picker MISSING, global hide-kg/blur switches only per journey in create form. |
| `LegalPage` terms/privacy (updated 01/11/2026) | `safety/ui/legal_screens.dart` | PARTIAL (shallow): has "last updated" key; legal text not compared. |
| `ContactPage` (mail, bug form) | `safety/ui/contact_screen.dart` | PARTIAL (shallow) |
| `DeleteAccountScreen` `/settings/delete/:step` (3 steps, OTP, progress) | `profile/widgets/delete_account_dialog.dart` (sheet, same 3 steps) | PARTIAL: same flow, delivered as a sheet not routed pages. |

### 2.4 Create journey (create.tsx)

| Figma | Flutter | Status / differences |
|---|---|---|
| `CreateStepOne` `/create/1` (type carousel of 6 types with tagline, "Nhập hành trình đã qua" link, `PreviewCard`) | `create_flow_screen.dart` `_typeStep`, `TemplatePickerScreen` | PARTIAL: type choice present, carousel/preview-card/import link not verified; import link MISSING. |
| `CreateStepTwo` `/create/2/:question` (per-type DNA questions: goal/film/sport/habit choice cards, weight slider 40-120 kg, up to 3 pages) | `_detailStep` (name, emoji, metric switches, blur) | V1-STALE: this is the V1 QuickSetup form; Figma questions that drive the skin/DNA do not exist. `create_journey_screen.dart` (V1 QuickSetup) is kept as legacy route `/journeys/new/:template`. |
| `CreateStepThree` ("đi cùng ai?") + `CreateStepThreeExtra` 1/2 ("tên hai người.", "ai chụp nửa nào?") | `_whoStep` | PARTIAL (shallow): who choice exists; couple names/halves pages not verified. |
| `CreateStepFour` ("đặt nhịp.": duration chips, reminder time, who sees) + `CalendarSheet` ("sửa ngày.") | `_rhythmStep`, `CreateCalendar`, `CreateDurationChip` | PARTIAL (shallow) |
| `CreateStepFive` ("đang đúc DNA…" forge animation, then ticket per skin) | `_reviewStep` + `widgets/departure_ticket.dart` | PARTIAL: ticket with per-skin tag exists; DNA forging animation and "Hồ sơ riêng tư - 30 ngày" ticket variants not verified. |
| `ExitCreateSheet` ("thoát khỏi việc tạo?") + Hub resume card | `PopScope` + `journeys_createExit` label | PARTIAL: no resume-from-Hub. |
| `CreateFrame` step segments "bước n/5" | `CreateStepSegments` | MATCH (shallow, count and label equal) |

### 2.5 In-journey screens (6 skins; Figma has a separate component per skin)

| Figma | Flutter | Status / differences |
|---|---|---|
| `Quiet/Squad/Memory/Couple/Flexer/MinimalJourneyHome` (+ TopBar, Photo) | `journeys/ui/journey_detail_screen.dart` (one screen, `UiSkinScope`, `JourneyTimeline` per skin in `widgets/timeline_variants.dart`) | V1-STALE shell with V2 timelines: file doc says "V1.0 `Detail`" (hero + four stats + calendar + check-in button). Timelines per skin exist; per-skin intro copy ("Nhìn lại từng chút một."), chart card, offline chip, read-only "Hành trình đã kết thúc - chỉ xem" lock, milestone cards are not per skin. |
| `Quiet/Squad/Memory/Couple/Flexer/MinimalPost` (post screen per skin) | `checkin/checkin_screen.dart` + `post_extras.dart` (mood/minutes/place/couple/flexer/pace inputs) | PARTIAL: one screen with skin-conditional extras; skin chrome/copy not compared. |
| `*Done` (success per skin) | `checkin/checkin_success.dart` (46 skin refs) | PARTIAL (shallow) |
| `*Squad` / `SquadToday` / `CouplePair` / `SquadAvatarStack` (group wall per skin) | `groups/ui/group_today_screen.dart` (4 skin refs) | V1-STALE (mostly): single group Today; Squad polaroid wall, couple pair, memory contact sheet per skin missing. |
| `*Share`, `SquadShareSheet`, `PosterShareSheet`, `QuietPrivacySheet`, `ComposeJourneyTargets`, share tabs (story/feed ratios) | `share_card/ui/share_card.dart` (0 skin refs), `share_card_screen.dart`, `sharing/ui/share_journey_sheet.dart` | V1-STALE: one neutral share card; Figma has 6 skin share cards + ratio tabs + privacy sheets. |
| `JourneyDayScreen` (`DayVisual`, day menu, collage, `DayPhotoStack`, `DeletedDayPlaceholder`) | `journeys/ui/day_viewer_screen.dart` | PARTIAL: photo+caption+metric on black; day overflow menu, multi-photo stack, deleted placeholder not present. |
| `JourneyEditScreen` + `LayoutPreview` ("cập nhật hành trình.", name, camera pin, cover, colour, **Giao diện** layout switch, ticket, import button, couple fields) | none (only couple rename sheet; pin at create) | MISSING |
| `JourneyWrappedScreen` + `WrappedVisual` + `wrappedPagesFor` (story pages, "Hành trình đã về đích", ratio tabs) | none | MISSING |
| `ImportJourneyFlow`, `ImportedJourneyHome`, `ImportedJourneyShare` (`/import`, `/j/:id/import`) | none | MISSING |

### 2.6 Camera

| Figma | Flutter | Status / differences |
|---|---|---|
| `CameraScreen` `/camera` (6 skin pills, HUD per skin: ghost, study time, grain/stamp, couple split, flexer HUD chips, minimal scene; pin hint "Ghim tối đa 3…"; offline pill; latest-photo thumb; state cards "camera đang tắt./chưa bật." with sticker; no-journey draft suggestions "Tự đặt / rủ hội bạn / chỉ hai đứa / một mình") | `camera/capture_screen.dart`, `capture_overlays.dart`, `camera_session.dart` | PARTIAL: skin overlays (ghost/stamp/strip/duo/study) are implemented. Differences: no pin hint, no offline pill, no-journey state is a generic empty state (no draft suggestion chips), denied/restricted copy differs ("Chưa có quyền camera" vs "camera đang tắt."), state cards have no sticker. |

### 2.7 Other Flutter-only screens (no Figma counterpart; do not delete, but not designed)

`social/ui/friends_screen.dart`, `add_friends_screen.dart`, `chat_screen.dart`, `invite_accept_screen.dart`, `sharing/ui/insights_screen.dart`, `retell_screen.dart`, `story_editor_screen.dart`, `follow_journey_screen.dart`, `shared_journey_screen.dart`, `safety/ui/*report*`. Backend features without a Figma design: restyle only after the design owner provides frames.

---

## 3. Counts

Rows counted per Figma screen/sheet/overlay component (excluding N/A prototype tooling and section 2.7).

| Status | Count |
|---|---|
| MATCH | 1 (create step segments, shallow) |
| PARTIAL | 28 |
| V1-STALE | 5 (create step 2, journey home x6 as one row, squad wall, share cards, plus V1 splash noted under agent) |
| MISSING | 9 (ReminderNotification, MissedDayOverlay, retake hero, NotFound, Settings screen, JourneyEdit/Giao diện, Wrapped, Import flow x3 counted as 1 row, import link) |
| IN PROGRESS (agent) | 6 (Splash, Onboarding, Login, OTP, ProfileSetup, PermissionSheet) |
| N/A | 7 |

(Counts are of matrix rows, some rows aggregate 6 skins or 3 import screens; treat them as indicative.)

## 4. Top 10 gaps (largest visible first)

1. Skin share cards: all 6 Figma `*Share` cards + share tabs/sheets missing (`share_card.dart` has no skin variants).
2. Journey Home is the V1.0 `Detail` screen; the 6 distinct skin homes (intro copy, chart card, states, read-only lock) are not built.
3. Create step 2 is the V1 name/emoji/metric form; Figma per-type DNA question cards (goal, film, sport, habit, weight slider) missing, which also starves skin/DNA selection.
4. No Settings screen: theme picker (Sáng/Tối/Theo máy), app-icon picker, privacy switches, blocked list, info links are scattered or absent.
5. Journey Edit + "Giao diện" layout switch (`JourneyEditScreen`, `LayoutPreview`) missing.
6. Wrapped story (end-of-journey) missing.
7. Hub still V1 (TodayCard, segments, greeting) vs Figma hero + JourneyCards + "hành trình mới." card + skeleton + create-resume + offline banner.
8. Squad wall / group Today per skin (polaroid wall, couple pair, memory contact sheet) and Squad tab extras (today strip, pending invites) missing.
9. Import past journey flow (3 screens) missing.
10. Overlays: MissedDay overlay, in-app ReminderNotification banner, retake hero, NotFound page, camera state cards/pin hint/no-journey suggestions.

## 5. Work list in independent chunks (disjoint file scopes)

Sizes: S = under 1 day, M = 1-2 days, L = 3+ days for one agent. Flow screens (section 2.1) are excluded, in progress.

| # | Chunk | Scope (exclusive files) | Size |
|---|---|---|---|
| A | Skin share cards + share sheets (6 variants, ratio tabs, QuietPrivacySheet, Squad/Poster sheets) | `features/share_card/**`, `features/sharing/ui/share_journey_sheet.dart` + l10n | L |
| B | Journey Home per skin (replace V1 Detail shell; read-only/offline states; Missed overlay; retake hero) | `features/journeys/ui/journey_detail_screen.dart`, `widgets/timeline_*`, new `journeys/ui/home/*` | L |
| C | Create flow V2 questions (step 2 DNA, step 3 extras, step 5 forge animation, exit sheet + Hub resume) | `features/journeys/ui/create/**`, `journeys/domain/journey_form.dart`, create l10n | L |
| D | Settings screen + theme preference + app-icon picker + global privacy switches | new `features/settings/**`, `app/app.dart` themeMode, `app/theme/**`, profile links | M |
| E | Edit journey + layout ("Giao diện") switch + Wrapped story | new `features/journeys/ui/edit/**`, `features/journeys/ui/wrapped/**`, journeys routes | L |
| F | Hub rebuild (hero, JourneyCard list, new-journey card, skeletons, offline banner) + Activity feed rows | `features/journeys/ui/journeys_list_screen.dart`, `today_card.dart`, `journey_row.dart`; `features/social/ui/inbox_screen.dart` | M |
| G | Squad tab + group Today per skin + MemberSheet | `features/groups/ui/**`, safety member sheet | M |
| H | Import past journey flow | new `features/import/**` | M |
| I | Camera polish (pin hint, offline pill, state cards with stickers, no-journey draft chips, copy) + Day viewer menu/multi-photo | `features/camera/**`, `journeys/ui/day_viewer_screen.dart` | S-M |
| J | Global: NotFound page, in-app ReminderNotification banner, toast helper | `app/router.dart`, new `app/overlays/**` | S |

Chunks A, D, H, J have fully disjoint scopes. B/C/E/F all touch `features/journeys`, but at different files; coordinate on `journeys/routes.dart` (E and C add routes) through a single owner.

## 6. Caveats

* "(shallow)" rows were compared at structure/key-copy level only; expect more diffs when an agent ports them against the Figma code.
* Spacing, radius, colour tokens: the kit (`ui/tokens.dart`, `UiRadius`) mirrors the Figma values (radius 999/12/14/8/16 are the most used in `app.css`; fonts Space Grotesk + Be Vietnam Pro bundled). Per-screen overrides were not diffed.
* No screen has been run side by side with the Figma preview; this audit is code against code.
