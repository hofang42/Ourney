# Bug log

Bugs found by the owner while testing the app on a device. Newest report first.
Status values: `open`, `fixing`, `fixed (PR)`, `needs-decision`.

Source of the first batch: owner's message of 2026-11-15, found on a real device.

| # | Area | Bug | Expected | Status |
|---|------|-----|----------|--------|
| 1 | Create journey | Tapping the `+` button to create a journey shows a broken block (a whole `div`-like panel) that pushes the whole UI down instead of floating above it. | The create entry must float over the UI (sheet/overlay), never reflow the screen below it. | open |
| 2 | Camera / check-in | Taking several photos in one day is still not allowed. | Allow multiple photos per day (extra same-day photos, as in the Figma timeline "ảnh thêm trong ngày"). | open |
| 3 | Limits | Only 2 journeys created but the counter shows `active 2/3`. | Counter must match reality and the cap must not apply (see 10). | open |
| 4 | Camera | The flash cannot be turned on. | Flash toggle works on devices that have a flash. | open |
| 5 | Camera | Camera UI/UX is poor overall. | Camera screen rebuilt to the Figma camera design (overlays, top bar, journey picker, shutter, states). | open |
| 6 | Profile | The three stat tiles (total check-ins, longest streak, journeys finished) are uneven: different sizes, hard to look at. | Three equal-width, equal-height tiles. | open |
| 7 | Reminders | Reminder notifications are not being sent. | Local reminders fire at the chosen time (permission flow, scheduling, timezone). | open |
| 8 | Create journey | Icons on the create-journey screen are rendered black (ugly). | Icons use the skin/kit colours as in Figma. | open |
| 9 | Camera | The "learn lessons" (English) journey shows a counting/timer UI on the camera that is useless. | Remove or replace with something useful per the Figma camera for that skin. | open |
| 10 | Limits | Creation is still capped at 3 journeys. The owner already answered earlier that creating journeys must be unlimited. | No cap on number of journeys (client and server). | open |
| 11 | Dock | No liquid-glass look. Dock icons turn black when pressed. When the selected item sits at the edge, its border touches the dock border (ugly). | Liquid-glass dock per Figma; pressed icons keep their colour; selected item keeps padding from the dock border. | open |
| 12 | Camera | Opening "All journeys" on the camera screen shows the UI duplicated twice. | The picker shows once. | open |

## Notes

- Bugs 3 and 10 are probably the same root cause (a per-user active-journey cap, see `journey_errors.dart`,
  `journeys_list_screen.dart` and the `0005_security_hardening.sql` limits).
- Bug 12 may come from the journey picker sheet being opened twice (once by the journey bar chip and once by the
  existing picker); check `capture_screen.dart`.
- None of these were caught by the test suite: tests run in a widget-test harness, not on a device. The Figma parity
  audit lives in [figma-parity.md](figma-parity.md).
