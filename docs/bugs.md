# Bug log

Bugs found by the owner while testing the app on a device. Newest report first.
Status values: `open`, `fixing`, `fixed (PR)`, `needs-decision`. `fixed (local)` = fixed on branch
`fix/device-bugs-2026-11-15`, not merged and not yet re-checked on a device.

Source of the first batch: owner's message of 2026-11-15, found on a real device.

| # | Area | Bug | Expected | Status |
|---|------|-----|----------|--------|
| 1 | Create journey | Tapping the `+` button to create a journey shows a broken block (a whole `div`-like panel) that pushes the whole UI down instead of floating above it. | The create entry must float over the UI (sheet/overlay), never reflow the screen below it. | fixed (local) |
| 2 | Camera / check-in | Taking several photos in one day is still not allowed. | Allow multiple photos per day (extra same-day photos, as in the Figma timeline "ảnh thêm trong ngày"). | fixed (local) |
| 3 | Limits | Only 2 journeys created but the counter shows `active 2/3`. | Counter must match reality and the cap must not apply (see 10). | fixed (local) |
| 4 | Camera | The flash cannot be turned on. | Flash toggle works on devices that have a flash. | fixed (local) |
| 5 | Camera | Camera UI/UX is poor overall. | Camera screen rebuilt to the Figma camera design (overlays, top bar, journey picker, shutter, states). | fixed (local) |
| 6 | Profile | The three stat tiles (total check-ins, longest streak, journeys finished) are uneven: different sizes, hard to look at. | Three equal-width, equal-height tiles. | fixed (local) |
| 7 | Reminders | Reminder notifications are not being sent. | Local reminders fire at the chosen time (permission flow, scheduling, timezone). | fixed (local) |
| 8 | Create journey | Icons on the create-journey screen are rendered black (ugly). | Icons use the skin/kit colours as in Figma. | fixed (local) |
| 9 | Camera | The "learn lessons" (English) journey shows a counting/timer UI on the camera that is useless. | Remove or replace with something useful per the Figma camera for that skin. | fixed (local) |
| 10 | Limits | Creation is still capped at 3 journeys. The owner already answered earlier that creating journeys must be unlimited. | No cap on number of journeys (client and server). | fixed (local) |
| 11 | Dock | No liquid-glass look. Dock icons turn black when pressed. When the selected item sits at the edge, its border touches the dock border (ugly). | Liquid-glass dock per Figma; pressed icons keep their colour; selected item keeps padding from the dock border. | fixed (local) |
| 12 | Camera | Opening "All journeys" on the camera screen shows the UI duplicated twice. | The picker shows once. | fixed (local) |

## Root causes and fixes (branch `fix/device-bugs-2026-11-15`)

| # | Root cause | Fix |
|---|------------|-----|
| 1 | The add/overflow menus were laid out inline (`Align` in the column), so opening them reflowed the hub. | New kit component `UiMenuAnchor` (`ui/components/surfaces.dart`) floats the menu in an overlay with a tap-outside barrier; used by the hub and journey detail. |
| 2 | Every layer assumed one check-in per day: unique `(journey_id, user_id, local_date)` on server (0001) and local DB, delete-then-insert in the repository, upsert on that key in sync, a "replace today's photo" sheet in the UI. | Migration `0014_multi_photo_per_day.sql` drops the constraint and makes `group_today` return each member's latest photo; local DB schema v6; sync upserts on `id`; extra photos show "Đã thêm ảnh thứ N" and never add a streak day. |
| 3, 10 | A 3-active-journey cap in `ourney_core` rules, the client repository and server RPCs (`create_journey`, `join_by_code`). | Cap removed everywhere; migration `0013_unlimited_journeys.sql`; hub counter is `Active · N`. |
| 4 | All three flash states drew the same glyph, and the state was only visible in a long-press tooltip; errors were silent. | `UiCameraTool` emphasis (off / auto outline / on filled), a toast on each change, "no flash" toast on error, flash mode re-applied before each shot. |
| 5 | Old camera layout (text chip bar with cut names, duplicated day pill, dots, swipe hint, profile button). | Rebuilt to Figma V2: one name chip, title block, image-only disc strip with "All (N)"; screen split into `camera/widgets/*`. |
| 6 | Tiles sized to their content. | `IntrinsicHeight` + stretch, single-line values. |
| 7 | The OS permission was only requested on `/reminders`, but reminders get switched on elsewhere (create quiz, 21:00 alert default); without permission the scheduler plans nothing. | `offerReminderPermission` shows the V2 notification sheet once after creating a journey with a reminder and after a check-in. |
| 8 | Sticker icons were given `color: ui.ink`, which `OurneyIcon` uses as the fill, so ink-on-ink became a black blob. | Colour overrides removed. |
| 9 | The squad overlay ran a stopwatch from camera open. | Replaced by a clock stamp plus last study minutes and streak. |
| 11 | Active tab used one solid colour for fill and outline; dock 64 high with a 52 pill (4dp gap); the default shader glass dropped the border and shadow. | `dock_tab.dart` keeps sticker colours, dock 76 high, `UiGlass` BackdropFilter with border and hard shadow (ADR 0003 updated). |
| 12 | `JourneyPickerSheet` wrapped itself in `UiSheet` inside `showUiSheet`, which already does. | Wrapper removed; `UiSheet` asserts it is never nested. |

## Not verified yet

- ~~pgTAP for 0013/0014~~: verified locally on 2026-11-16 with Supabase CLI 2.121.0 (same as CI), 479/479 pass.
  Test 04 #51 was updated: after 0013, u13 can join ended group 141, so deleting u14 hands 141 over to u13
  instead of removing it (`_journeys_dying_with` rule, 0004).
- On a device: flash, notification delivery (Android 12+ inexact alarms may fire up to ~1h late), camera look,
  dock glass performance, local DB upgrade v5 to v6.
- After deploying 0014, old app builds that upsert on `journey_id,user_id,local_date` fail (42P10) and must update.

## Notes

- None of these were caught by the test suite: tests run in a widget-test harness, not on a device. The Figma parity
  audit lives in [figma-parity.md](figma-parity.md).
